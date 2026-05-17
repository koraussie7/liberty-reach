"""
Legacy routes ported from server.py — DO NOT EDIT these route implementations.
These are exact copies of the original route logic from the legacy server.py,
preserving behavior for backward compatibility.
"""
import base64
import csv
import json
import logging
import os
import sqlite3
import sys
import uuid
from datetime import datetime
from typing import Dict, Optional

import httpx
from fastapi import APIRouter, Request, Response, WebSocket, WebSocketDisconnect
from fastapi.responses import FileResponse
from pydantic import BaseModel

# Optional dependencies (not needed by ported routes but kept for env compatibility)
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

try:
    import google.generativeai as genai
    _HAS_GENAI = True
except ImportError:
    genai = None
    _HAS_GENAI = False

log = logging.getLogger("dada.legacy")

# ── Environment ──────────────────────────────────────────────────────────────
LOCALAI_URL = os.getenv("LOCALAI_URL", "http://localhost:11434")
MINIMA_URL = os.getenv("MINIMA_URL", "https://localhost:9005")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
CEREBRAS_API_KEY = os.getenv("CEREBRAS_API_KEY")
if not CEREBRAS_API_KEY:
    log.warning("CEREBRAS_API_KEY not set - Hermes agent will fail")
CEREBRAS_MODEL = os.getenv("CEREBRAS_MODEL", "llama3.1-8b")
CEREBRAS_API_URL = "https://api.cerebras.ai/v1/chat/completions"
OPENCODE_API_KEY = os.getenv("OPENCODE_API_KEY")
if not OPENCODE_API_KEY:
    log.warning("OPENCODE_API_KEY not set - OpenCode agent will fail")
OPENCODE_API_URL = os.getenv("OPENCODE_API_URL", "https://opencode.ai/zen/v1/chat/completions")
OPENCODE_MODEL = os.getenv("OPENCODE_MODEL", "claude-sonnet-4")
OPENCODE_AGENT_PROMPT = os.getenv("OPENCODE_AGENT_PROMPT", (
    "You are an expert coding assistant integrated into Liberty Reach messenger. "
    "Help users with code generation, debugging, refactoring, and architecture questions. "
    "Provide clear, concise code examples. "
    "When appropriate, explain tradeoffs and suggest best practices."
))
LEADERBOARD_DB = os.getenv("LEADERBOARD_DB", "leaderboard.db")
UPLOAD_DIR = os.getenv("UPLOAD_DIR", "/root/liberty-web/uploads")
LOOPS_API_URL = os.getenv("LOOPS_API_URL", "http://185.55.240.110:8080/api")
LOOPS_TOKEN = os.getenv("LOOPS_TOKEN", "")
HOME_VIDEOS_DIR = os.getenv("HOME_VIDEOS_DIR", "/root/youtube_shorts")
HOME_THUMBS_DIR = HOME_VIDEOS_DIR
HOME_H264_DIR = os.path.join(HOME_VIDEOS_DIR, "h264")
PUBLIC_HOST = os.getenv("PUBLIC_HOST", "https://privseai.com")
API_KEY = os.getenv("API_KEY", "")
os.makedirs(UPLOAD_DIR, exist_ok=True)

# ── Shared HTTP Client ────────────────────────────────────────────────────────
_http_client = None

def get_http_client():
    global _http_client
    if _http_client is None:
        _http_client = httpx.AsyncClient(timeout=120)
    return _http_client

# ── Gemini ────────────────────────────────────────────────────────────────────
if _HAS_GENAI and GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    log.info("Gemini AI configured")

# ── Prompts ───────────────────────────────────────────────────────────────────
HERMES_AGENT_PROMPT = """You are Hermes, an autonomous AI agent with tool-use capabilities.

You have access to the following tools and capabilities:
- You can reason step-by-step about complex problems
- You can generate structured JSON output for function calls
- You can analyze code, data, and text

When responding:
1. Think step-by-step before answering
2. If the user asks for structured data, respond in JSON
3. Be concise but thorough
4. You can use the following internal tools by responding with a JSON block:
   {
     "tool": "analyze",
     "input": "what to analyze"
   }
   {
     "tool": "code",
     "language": "python",
     "code": "print('hello')"
   }

Your knowledge cutoff is current. You are powered by Cerebras hardware acceleration."""

ORCHESTRATOR_SYSTEM_PROMPT = """You are the DADA-AI Orchestrator.
You collaborate with two agents: Hermes (design/review) and OpenClaw (execution).

## Role Division (must follow)

**Hermes (your main role)**
- Overall strategy and architecture design
- Work priority decisions
- Code review and quality management
- Next step instructions

**OpenClaw (execution agent)**
- File creation, modification, testing, Git operations per Hermes instructions
- Command execution (cargo, flutter, git, docker, etc.)
- Detailed error reporting

## Collaboration Routine (all work must follow this order)

1. **Hermes Analysis**
   - Identify all outstanding tasks
   - Prioritize (urgency + importance)
   - Establish concrete work plan

2. **OpenClaw Execution**
   - Execute according to Hermes' plan
   - File create/edit, command execution, testing
   - Report progress in real time

3. **Hermes Review**
   - Review OpenClaw's work
   - Flag issues or approve
   - Give next task instructions

## Response Format (must follow)

### 🔷 Hermes Analysis
(current situation analysis + priorities)

### 🛠️ OpenClaw Execution Plan
(specific commands and task list for this round)

### 📋 Next Steps
(what to do next)

### ✅ Status
(current progress)"""

# ── Leaderboard DB ────────────────────────────────────────────────────────────
def init_leaderboard_db():
    conn = sqlite3.connect(LEADERBOARD_DB)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS user_points (
            user_id TEXT NOT NULL,
            display_name TEXT NOT NULL DEFAULT '',
            points INTEGER NOT NULL DEFAULT 0,
            recorded_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
    """)
    conn.execute("CREATE INDEX IF NOT EXISTS idx_up_id ON user_points(user_id)")
    conn.execute("CREATE INDEX IF NOT EXISTS idx_up_at ON user_points(recorded_at)")
    conn.commit()
    conn.close()
    log.info(f"Leaderboard DB initialized: {LEADERBOARD_DB}")

def record_points(user_id: str, display_name: str, points: int):
    conn = sqlite3.connect(LEADERBOARD_DB)
    conn.execute(
        "INSERT INTO user_points (user_id, display_name, points) VALUES (?, ?, ?)",
        (user_id, display_name, points),
    )
    conn.commit()
    conn.close()

def get_leaderboard(period: str, limit: int = 50) -> list:
    days = {"weekly": 7, "monthly": 30}.get(period)
    conn = sqlite3.connect(LEADERBOARD_DB)
    if days:
        rows = conn.execute(
            "SELECT user_id, display_name, SUM(points) as total FROM user_points "
            "WHERE recorded_at >= datetime('now', ? || ' days') "
            "GROUP BY user_id ORDER BY total DESC LIMIT ?",
            (f"-{days}", limit)
        ).fetchall()
    elif period == "creators":
        rows = conn.execute(
            "SELECT user_id, display_name, SUM(points) as total FROM user_points "
            "WHERE display_name LIKE ? "
            "GROUP BY user_id ORDER BY total DESC LIMIT ?",
            ('%[Creator]%', limit)
        ).fetchall()
    else:
        rows = conn.execute(
            "SELECT user_id, display_name, SUM(points) as total FROM user_points "
            "GROUP BY user_id ORDER BY total DESC LIMIT ?",
            (limit,)
        ).fetchall()
    conn.close()

    result = []
    for i, (uid, name, pts) in enumerate(rows):
        pts = pts or 0
        badge = "Newbie"
        if pts >= 1000:
            badge = "Active"
        if pts >= 5000:
            badge = "Star"
        if pts >= 20000:
            badge = "Legend"
        result.append({
            "rank": i + 1,
            "user_id": uid,
            "display_name": name or uid,
            "points": pts,
            "badge": badge,
        })
    return result

init_leaderboard_db()

# ── API Key Verification ──────────────────────────────────────────────────────
def verify_api_key(request: Request) -> bool:
    if not API_KEY:
        return True
    return request.headers.get("X-API-Key", "") == API_KEY

# ── Preference Model ──────────────────────────────────────────────────────────
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "..", "preference_model"))
try:
    from train_preference_model import predict_preference  # type: ignore
    PREFERENCE_MODEL_AVAILABLE = True
except Exception as e:
    log.warning(f"Preference model not available: {e}")
    PREFERENCE_MODEL_AVAILABLE = False

# ── OpenCode Helper ───────────────────────────────────────────────────────────
async def _call_opencode(messages: list, system_prompt: str, model: str = None) -> dict:
    body = {
        "model": model or OPENCODE_MODEL,
        "messages": [{"role": "system", "content": system_prompt}] + messages,
        "temperature": 0.65,
        "max_tokens": 4096,
    }
    headers = {
        "Authorization": f"Bearer {OPENCODE_API_KEY}",
        "Content-Type": "application/json",
    }
    c = get_http_client()
    resp = await c.post(OPENCODE_API_URL, json=body, headers=headers)
    if resp.status_code != 200:
        return {"error": f"OpenCode error: {resp.status_code}", "detail": resp.text[:500]}
    data = resp.json()
    reply = data["choices"][0]["message"]["content"]
    return {"reply": reply, "model": body["model"], "provider": "opencode"}

# ── Minima Helper ─────────────────────────────────────────────────────────────
async def minima_cmd(cmd: str) -> dict:
    async with httpx.AsyncClient(timeout=15, verify=False) as c:
        r = await c.post(MINIMA_URL, content=cmd.encode(), headers={"Content-Type": "text/plain"})
        return r.json()

# ── Home Feed Helpers ─────────────────────────────────────────────────────────
def _resolve_video(fname: str) -> str:
    """Return path to best available video file (prefer H264)."""
    h264_path = os.path.join(HOME_H264_DIR, fname)
    if os.path.isfile(h264_path):
        return h264_path
    return os.path.join(HOME_VIDEOS_DIR, fname)

def _resolve_thumb(thumb_name: str) -> str | None:
    """Return path to thumbnail (prefer H264 thumbs)."""
    h264_thumb = os.path.join(HOME_H264_DIR, thumb_name)
    if os.path.isfile(h264_thumb):
        return h264_thumb
    orig_thumb = os.path.join(HOME_THUMBS_DIR, thumb_name)
    return orig_thumb if os.path.isfile(orig_thumb) else None

def _build_loops_entry(fname: str, public_host: str = PUBLIC_HOST) -> dict | None:
    """Convert an mp4 filename to a loops-compatible video entry."""
    if not fname.endswith(".mp4"):
        return None
    video_id = fname[:-4]
    thumb_name = f"{video_id}.jpg"
    thumb_path = _resolve_thumb(thumb_name)
    return {
        "id": video_id,
        "title": f"커플 챌린지 #{video_id[:8]}",
        "description": "🔥 한국 핫 쇼츠 🔥 #shorts #korea #trending",
        "video_url": f"{public_host}/home/video/{fname}",
        "thumbnail_url": f"{public_host}/home/thumb/{thumb_name}" if thumb_path else None,
        "view_count": 0,
        "reward_points": 15,
        "creator": "DADA-AI",
    }

# ── WebSocket State ───────────────────────────────────────────────────────────
active_connections: Dict[str, WebSocket] = {}

# ── Minima / Blockchain private implementations ───────────────────────────────
# (Used by /minima/* aliases — re-implemented here to avoid depending on stubs)
async def _blockchain_health():
    try:
        data = await minima_cmd("status")
        ok = data.get("status") is True
    except Exception:
        ok = False
    return {"status": "healthy" if ok else "unreachable"}

async def _blockchain_info():
    try:
        data = await minima_cmd("status")
        resp = data.get("response", {})
        return {
            "version": resp.get("version", ""),
            "uptime": resp.get("uptime", ""),
            "blocks": resp.get("length", 0),
            "minima": resp.get("minima", "0"),
            "coins": resp.get("coins", "0"),
            "address": resp.get("miniaddress", ""),
        }
    except Exception as e:
        return {"error": str(e)}

async def _blockchain_address():
    try:
        data = await minima_cmd("newaddress")
        addr = data.get("response", {}).get("address", "unknown")
        return {"address": addr}
    except Exception as e:
        return {"error": str(e)}

async def _blockchain_balance():
    try:
        data = await minima_cmd("balance")
        resp = data.get("response", {})
        if isinstance(resp, list):
            tokens = resp
            addr = ""
            coins = "0"
        else:
            tokens = resp.get("tokens", []) if resp else []
            addr = resp.get("address", "") if resp else ""
            coins = resp.get("coins", "0") if resp else "0"
        dada = next(
            (t for t in tokens
             if (isinstance(t.get("token"), dict) and t["token"].get("name") == "DADAPOINT")
             or t.get("token") == "DADAPOINT"),
            None,
        )
        return {
            "address": addr,
            "coins": coins,
            "dada_point_balance": int(dada.get("confirmed", dada.get("amount", 0))) if dada else 0,
        }
    except Exception as e:
        return {"error": str(e)}

class _RewardRequest(BaseModel):
    user_address: str
    action: str  # "watch", "ai", "relay"
    action_id: str
    seconds: int

async def _blockchain_reward(req: _RewardRequest, request: Request):
    if not verify_api_key(request):
        return {"error": "Invalid or missing API key"}
    points = max(1, req.seconds // {"watch": 15, "ai": 30, "relay": 60}.get(req.action, 60))
    token = "DADAPOINT"
    cmd = f"send {req.user_address} {points} {token}"
    try:
        data = await minima_cmd(cmd)
        if data.get("status"):
            tx_id = data.get("response", {}).get("txpow", {}).get("txpowid", "unknown")
            record_points(req.user_address, f"User_{req.user_address[:8]}", points)
            return {
                "success": True,
                "points_earned": points,
                "tx_id": tx_id,
                "action": req.action,
            }
        return {"success": False, "error": data.get("error", "Minima send failed")}
    except Exception as e:
        return {"success": False, "error": str(e)}

# ══════════════════════════════════════════════════════════════════════════════
# ROUTER
# ══════════════════════════════════════════════════════════════════════════════
router = APIRouter(tags=["Legacy"])

# ── /opencode/chat ────────────────────────────────────────────────────────────
@router.post("/opencode/chat")
async def opencode_chat(request: dict):
    if not request.get("messages"):
        return {"error": "messages is required"}
    try:
        msgs = request["messages"]
        system_prompt = request.get("system", HERMES_AGENT_PROMPT)
        temperature = request.get("temperature", 0.7)
        max_tokens = request.get("max_tokens", 4096)
        stream = request.get("stream", False)

        body = {
            "model": request.get("model", CEREBRAS_MODEL),
            "messages": [{"role": "system", "content": system_prompt}] + msgs,
            "temperature": temperature,
            "max_tokens": max_tokens,
            "stream": stream,
        }
        headers = {
            "Authorization": f"Bearer {CEREBRAS_API_KEY}",
            "Content-Type": "application/json",
        }
        c = get_http_client()
        resp = await c.post(CEREBRAS_API_URL, json=body, headers=headers)

        if resp.status_code != 200:
            log.error(f"Cerebras error {resp.status_code}: {resp.text[:300]}")
            return {"error": f"Cerebras API error: {resp.status_code}", "detail": resp.text[:500]}

        return resp.json()
    except Exception as e:
        log.error(f"Hermes agent error: {e}")
        return {"error": str(e)}

# ── /opencode/zen ─────────────────────────────────────────────────────────────
@router.post("/opencode/zen")
async def opencode_zen(request: dict):
    if not OPENCODE_API_KEY:
        return {"error": "OpenCode API key not configured on server"}
    if not request.get("messages"):
        return {"error": "messages is required"}
    try:
        msgs = request["messages"]
        system_prompt = request.get("system", OPENCODE_AGENT_PROMPT)
        temperature = request.get("temperature", 0.7)
        max_tokens = request.get("max_tokens", 4096)
        model = request.get("model", OPENCODE_MODEL)

        body = {
            "model": model,
            "messages": [{"role": "system", "content": system_prompt}] + msgs,
            "temperature": temperature,
            "max_tokens": max_tokens,
        }
        headers = {
            "Authorization": f"Bearer {OPENCODE_API_KEY}",
            "Content-Type": "application/json",
        }
        c = get_http_client()
        resp = await c.post(OPENCODE_API_URL, json=body, headers=headers)

        if resp.status_code != 200:
            log.error(f"OpenCode error {resp.status_code}: {resp.text[:300]}")
            return {"error": f"OpenCode API error: {resp.status_code}", "detail": resp.text[:500]}

        data = resp.json()
        reply = data["choices"][0]["message"]["content"]
        return {"reply": reply, "model": model, "provider": "opencode"}
    except Exception as e:
        log.error(f"OpenCode error: {e}")
        return {"error": str(e)}

# ── /ai/orchestrate ───────────────────────────────────────────────────────────
@router.post("/ai/orchestrate")
async def ai_orchestrate(request: dict):
    if not request.get("messages"):
        return {"error": "messages is required"}
    try:
        messages = request["messages"]
        user_text = messages[-1].get("content", "")
        system_prompt = request.get("system") or ORCHESTRATOR_SYSTEM_PROMPT

        if not OPENCODE_API_KEY:
            local_body = {
                "model": "qwen2.5-coder:7b",
                "messages": [{"role": "system", "content": system_prompt}] + messages,
                "temperature": 0.65,
                "max_tokens": 8192,
            }
            c = get_http_client()
            resp = await c.post(f"{LOCALAI_URL}/v1/chat/completions", json=local_body)
            raw = resp.json()["choices"][0]["message"]["content"] if resp.status_code == 200 else f"(local error: {resp.status_code})"
        else:
            result = await _call_opencode(messages, system_prompt)
            if "error" in result:
                return result
            raw = result["reply"]

        sections = {"plan": "", "code": "", "commands": "", "review": ""}
        current = None
        for line in raw.split("\n"):
            ll = line.strip()
            if "hermes plan" in ll.lower() or "1. hermes" in ll.lower():
                current = "plan"
            elif "opencode code" in ll.lower() or "2. opencode" in ll.lower():
                current = "code"
            elif "openclaw" in ll.lower() or "3. openclaw" in ll.lower():
                current = "commands"
            elif "hermes review" in ll.lower() or "4. hermes" in ll.lower():
                current = "review"
            elif current:
                sections[current] += line + "\n"

        return {
            "plan": sections["plan"].strip(),
            "code": sections["code"].strip(),
            "commands": sections["commands"].strip(),
            "review": sections["review"].strip(),
            "raw": raw,
            "model": OPENCODE_MODEL,
            "provider": "opencode",
        }
    except Exception as e:
        log.error(f"Orchestrator error: {e}")
        return {"error": str(e)}

# ── /ai/preference/predict ────────────────────────────────────────────────────
@router.post("/ai/preference/predict")
async def preference_predict(request: dict):
    if not PREFERENCE_MODEL_AVAILABLE:
        return {"error": "Preference model not trained yet"}
    prompt = request.get("prompt", "")
    response_a = request.get("response_a", "")
    response_b = request.get("response_b", "")
    if not all([prompt, response_a, response_b]):
        return {"error": "prompt, response_a, response_b are required"}
    result = predict_preference(prompt, response_a, response_b)
    return {"result": result[0], "score": result[1]}

# ── /ai/preference/train ──────────────────────────────────────────────────────
@router.post("/ai/preference/train")
async def preference_train():
    try:
        from train_preference_model import train_preference_model  # type: ignore
        train_preference_model()
        return {"status": "training completed"}
    except Exception as e:
        return {"error": str(e)}

# ── /ai/preference/feedback ───────────────────────────────────────────────────
@router.post("/ai/preference/feedback")
async def preference_feedback(request: dict):
    prompt = request.get("prompt", "")
    response_a = request.get("response_a", "")
    response_b = request.get("response_b", "")
    preferred = request.get("preferred", "")
    user_id = request.get("user_id", "anonymous")
    if not all([prompt, response_a, response_b, preferred]):
        return {"error": "All fields required"}
    csv_path = os.path.join(os.path.dirname(__file__), "..", "..", "..", "preference_model", "user_preferences.csv")
    with open(csv_path, "a", newline="") as f:
        w = csv.writer(f)
        w.writerow([user_id, prompt, response_a, response_b, preferred, datetime.utcnow().isoformat()])
    return {"status": "feedback saved"}

# ── /minima/health ────────────────────────────────────────────────────────────
@router.get("/minima/health")
async def minima_health():
    return await _blockchain_health()

# ── /minima/info ──────────────────────────────────────────────────────────────
@router.get("/minima/info")
async def minima_info():
    return await _blockchain_info()

# ── /minima/address ───────────────────────────────────────────────────────────
@router.get("/minima/address")
async def minima_address():
    return await _blockchain_address()

# ── /minima/balance ───────────────────────────────────────────────────────────
@router.get("/minima/balance")
async def minima_balance():
    return await _blockchain_balance()

# ── /minima/reward ────────────────────────────────────────────────────────────
@router.post("/minima/reward")
async def minima_reward(req: _RewardRequest, request: Request):
    return await _blockchain_reward(req, request)

# ── /home/feed ────────────────────────────────────────────────────────────────
@router.get("/home/feed")
async def home_feed():
    """Return list of videos for the home screen couple challenge section."""
    videos = []
    try:
        files = sorted(os.listdir(HOME_VIDEOS_DIR), key=lambda f: os.path.getmtime(os.path.join(HOME_VIDEOS_DIR, f)), reverse=True)
        for fname in files:
            entry = _build_loops_entry(fname)
            if entry:
                videos.append({
                    "id": entry["id"],
                    "title": entry["title"],
                    "video_url": entry["video_url"],
                    "thumbnail_url": entry["thumbnail_url"],
                    "view_count": entry["view_count"],
                })
    except Exception as e:
        log.warning(f"Home feed error: {e}")
        return {"error": str(e), "data": []}
    return {"data": videos}

# ── /home/video/{filename} ────────────────────────────────────────────────────
@router.get("/home/video/{filename:path}")
async def home_video(filename: str):
    """Stream video files for the home feed (prefer H264 if available)."""
    file_path = _resolve_video(filename)
    if not os.path.isfile(file_path) or not filename.endswith(".mp4"):
        return Response(status_code=404, content="Video not found")
    headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, OPTIONS",
        "Access-Control-Allow-Headers": "Range, Content-Range",
    }
    return FileResponse(file_path, media_type="video/mp4", headers=headers)

# ── /home/thumb/{filename} ────────────────────────────────────────────────────
@router.get("/home/thumb/{filename:path}")
async def home_thumb(filename: str):
    """Serve thumbnail images for home feed videos."""
    file_path = _resolve_thumb(filename)
    if not file_path or not filename.endswith(".jpg"):
        return Response(status_code=404, content="Thumbnail not found")
    return FileResponse(file_path, media_type="image/jpeg")

# ── /couple ───────────────────────────────────────────────────────────────────
@router.get("/couple")
async def couple_page():
    """Serve the couple challenge web page."""
    html_path = os.path.join(os.path.dirname(__file__), "..", "..", "..", "static", "home.html")
    return FileResponse(html_path, media_type="text/html")

# ── /ws/{client_id} ───────────────────────────────────────────────────────────
@router.websocket("/ws/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: str):
    await websocket.accept()
    active_connections[client_id] = websocket
    log.info(f"WebSocket connected: {client_id}")

    # Broadcast join to all other peers
    join_msg = json.dumps({"type": "peer_joined", "peer_id": client_id})
    for cid, ws in active_connections.items():
        if cid != client_id:
            try:
                await ws.send_text(join_msg)
            except Exception:
                pass

    try:
        while True:
            data = await websocket.receive_text()
            log.debug(f"WS msg from {client_id}: {data[:100]}")

            try:
                msg = json.loads(data)
                msg_type = msg.get("type", "message")

                if msg_type == "ping":
                    await websocket.send_text(json.dumps({"type": "pong"}))

                elif msg_type == "chat":
                    target = msg.get("target", "*")
                    sender = msg.get("sender", client_id)
                    content = msg.get("content", "")
                    timestamp = msg.get("timestamp", "")

                    if target == "*":
                        # Broadcast to all peers
                        broadcast = json.dumps({
                            "type": "chat", "sender": sender,
                            "content": content, "timestamp": timestamp
                        })
                        for cid, ws in active_connections.items():
                            if cid != client_id:
                                try:
                                    await ws.send_text(broadcast)
                                except Exception:
                                    pass
                    elif target in active_connections:
                        # Send to specific peer
                        target_msg = json.dumps({
                            "type": "chat", "sender": sender,
                            "content": content, "timestamp": timestamp
                        })
                        try:
                            await active_connections[target].send_text(target_msg)
                        except Exception:
                            pass
                    # Also echo back to sender for confirmation
                    await websocket.send_text(json.dumps({
                        "type": "ack", "sender": sender,
                        "content": content, "timestamp": timestamp
                    }))

                elif msg_type == "join":
                    # Re-broadcast peer info
                    for cid, ws in active_connections.items():
                        if cid != client_id:
                            try:
                                await ws.send_text(json.dumps({
                                    "type": "peer_joined", "peer_id": client_id
                                }))
                            except Exception:
                                pass

            except json.JSONDecodeError:
                await websocket.send_text(f"[DADA-AI] {data}")

    except WebSocketDisconnect:
        active_connections.pop(client_id, None)
        log.info(f"WebSocket disconnected: {client_id}")
        # Broadcast leave
        leave_msg = json.dumps({"type": "peer_left", "peer_id": client_id})
        for cid, ws in active_connections.items():
            try:
                await ws.send_text(leave_msg)
            except Exception:
                pass

# ── /loops/video/{video_id} ───────────────────────────────────────────────────
@router.get("/loops/video/{video_id}")
async def loops_video(video_id: str):
    if not LOOPS_API_URL:
        return {"error": "Loops API URL not configured"}
    headers = {"Authorization": f"Bearer {LOOPS_TOKEN}"} if LOOPS_TOKEN else {}
    try:
        async with httpx.AsyncClient(timeout=10) as c:
            r = await c.get(f"{LOOPS_API_URL}/v1/video/{video_id}", headers=headers)
            return r.json()
    except Exception as e:
        return {"error": str(e)}
