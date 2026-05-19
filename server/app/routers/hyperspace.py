"""Hyperspace AI Integration — P2P node, agent API, blockchain RPC, Pods, Earnings."""
import os
import json
import sqlite3
import subprocess
import logging
import httpx
from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse

logger = logging.getLogger("hyperspace")

router = APIRouter(tags=["hyperspace"])

HYPERSPACE_AGENT_URL = os.getenv("HYPERSPACE_AGENT_URL", "http://localhost:8080")
HYPERSPACE_RPC_URL = os.getenv("HYPERSPACE_RPC_URL", "http://localhost:8545")
HYPERSPACE_CLI = os.getenv("HYPERSPACE_CLI", "hyperspace")
# Safety: ensure HYPERSPACE_CLI is a simple command name, not a path with args
if not HYPERSPACE_CLI or "/" in HYPERSPACE_CLI or ".." in HYPERSPACE_CLI:
    HYPERSPACE_CLI = "hyperspace"
HYP_EARNINGS_DB = os.getenv("HYP_EARNINGS_DB", "hyperspace_earnings.db")

def init_hyperspace_db():
    conn = sqlite3.connect(HYP_EARNINGS_DB)
    conn.execute("""CREATE TABLE IF NOT EXISTS hyperspace_earnings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source TEXT NOT NULL,
        points INTEGER NOT NULL DEFAULT 0,
        recorded_at TEXT NOT NULL DEFAULT (datetime('now'))
    )""")
    conn.execute("""CREATE TABLE IF NOT EXISTS hyperspace_pods (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
    )""")
    conn.commit()
    conn.close()
    logger.info(f"Hyperspace earnings DB initialized: {HYP_EARNINGS_DB}")

init_hyperspace_db()

def _run_hyperspace(args: list[str]) -> dict:
    try:
        result = subprocess.run(
            [HYPERSPACE_CLI] + args,
            capture_output=True, text=True, timeout=30
        )
        if result.returncode != 0:
            return {"error": result.stderr.strip()}
        return json.loads(result.stdout) if result.stdout.strip() else {"ok": True}
    except FileNotFoundError:
        return {"error": "hyperspace CLI not installed"}
    except subprocess.TimeoutExpired:
        return {"error": "hyperspace command timed out"}
    except json.JSONDecodeError:
        result = subprocess.run([HYPERSPACE_CLI] + args, capture_output=True, text=True, timeout=30)
        return {"raw": result.stdout.strip()}

@router.get("/hyperspace/status")
async def hyperspace_status():
    # Run status without --json flag (not supported by the CLI)
    try:
        result = subprocess.run(
            [HYPERSPACE_CLI, "status"],
            capture_output=True, text=True, timeout=15
        )
        if result.returncode != 0:
            status = {"running": False, "error": result.stderr.strip()}
        else:
            output = result.stdout.strip()
            running = "STOPPED" not in output
            peer_id = ""
            points = "0.00"
            for line in output.split("\n"):
                line = line.strip()
                if "Peer ID:" in line:
                    peer_id = line.split("Peer ID:")[-1].strip()
                elif "Points:" in line:
                    points = line.split("Points:")[-1].strip()
            status = {
                "running": running,
                "peer_id": peer_id,
                "points": points,
                "raw_output": output,
            }
    except FileNotFoundError:
        status = {"running": False, "error": "hyperspace CLI not installed"}
    except subprocess.TimeoutExpired:
        status = {"running": False, "error": "hyperspace command timed out"}
    except Exception as e:
        status = {"running": False, "error": str(e)}
    try:
        async with httpx.AsyncClient(timeout=5) as c:
            r = await c.get(f"{HYPERSPACE_AGENT_URL}/v1/models")
            status["agent_online"] = r.status_code == 200
            status["models"] = r.json() if r.status_code == 200 else []
    except Exception:
        status["agent_online"] = False
    try:
        async with httpx.AsyncClient(timeout=5) as c:
            r = await c.post(HYPERSPACE_RPC_URL, json={"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1})
            if r.status_code == 200:
                d = r.json()
                status["chain_block"] = int(d.get("result","0x0"), 16)
                status["chain_online"] = True
    except Exception:
        status["chain_online"] = False
    return JSONResponse(status)

@router.post("/hyperspace/start")
async def hyperspace_start():
    return _run_hyperspace(["start", "--daemon"])

@router.post("/hyperspace/stop")
async def hyperspace_stop():
    return _run_hyperspace(["stop"])

@router.post("/hyperspace/chat")
async def hyperspace_chat(req: Request):
    body = await req.json()
    try:
        async with httpx.AsyncClient(timeout=120) as c:
            r = await c.post(f"{HYPERSPACE_AGENT_URL}/v1/chat/completions", json=body, headers={"Content-Type": "application/json"})
            return JSONResponse(r.json(), status_code=r.status_code)
    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=502)

@router.get("/hyperspace/models")
async def hyperspace_models():
    try:
        async with httpx.AsyncClient(timeout=10) as c:
            r = await c.get(f"{HYPERSPACE_AGENT_URL}/v1/models")
            return JSONResponse(r.json(), status_code=r.status_code)
    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=502)

@router.post("/hyperspace/pod/create")
async def hyperspace_pod_create(req: Request):
    body = await req.json()
    name = body.get("name", "my-pod")
    return _run_hyperspace(["pod", "create", name])

@router.post("/hyperspace/pod/invite")
async def hyperspace_pod_invite():
    return _run_hyperspace(["pod", "invite"])

@router.get("/hyperspace/pod/members")
async def hyperspace_pod_members():
    return _run_hyperspace(["pod", "members", "--json"])

@router.get("/hyperspace/pod/models")
async def hyperspace_pod_models():
    return _run_hyperspace(["pod", "models", "--json"])

@router.get("/hyperspace/leaderboard")
async def hyperspace_leaderboard():
    try:
        async with httpx.AsyncClient(timeout=30) as c:
            r = await c.get("https://raw.githubusercontent.com/hyperspaceai/agi/network-snapshots/snapshots/latest.json")
            if r.status_code == 200:
                return JSONResponse(r.json())
    except Exception:
        pass
    return JSONResponse({"error": "snapshot unavailable"})

@router.get("/hyperspace/earnings")
async def hyperspace_earnings():
    conn = sqlite3.connect(HYP_EARNINGS_DB)
    rows = conn.execute("SELECT source, SUM(points) as total FROM hyperspace_earnings GROUP BY source ORDER BY total DESC").fetchall()
    conn.close()
    return JSONResponse([{"source": r[0], "points": r[1]} for r in rows])

@router.post("/blockchain/hyperspace/rpc")
async def hyperspace_rpc(req: Request):
    body = await req.json()
    try:
        async with httpx.AsyncClient(timeout=15) as c:
            r = await c.post(HYPERSPACE_RPC_URL, json=body)
            return JSONResponse(r.json(), status_code=r.status_code)
    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=502)

@router.post("/blockchain/hyperspace/pay")
async def hyperspace_pay(req: Request):
    body = await req.json()
    payload = {"jsonrpc": "2.0", "method": "hspace_pay", "params": [body.get("to"), body.get("amount"), body.get("memo", "")], "id": 1}
    try:
        async with httpx.AsyncClient(timeout=15) as c:
            r = await c.post(HYPERSPACE_RPC_URL, json=payload)
            result = r.json()
            if r.status_code == 200 and "result" in result:
                conn = sqlite3.connect(HYP_EARNINGS_DB)
                conn.execute("INSERT INTO hyperspace_earnings (source, points) VALUES (?, ?)", (f"payment_{body.get('to','?')}", -abs(body.get("amount",0))))
                conn.commit()
                conn.close()
            return JSONResponse(result, status_code=r.status_code)
    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=502)

@router.get("/blockchain/hyperspace/balance/{address}")
async def hyperspace_balance(address: str):
    payload = {"jsonrpc": "2.0", "method": "eth_getBalance", "params": [address, "latest"], "id": 1}
    try:
        async with httpx.AsyncClient(timeout=10) as c:
            r = await c.post(HYPERSPACE_RPC_URL, json=payload)
            return JSONResponse(r.json(), status_code=r.status_code)
    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=502)
