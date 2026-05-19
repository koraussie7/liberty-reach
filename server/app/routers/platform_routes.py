"""Platform API routes for DADA-AI Flutter app.
Loops, Leaderboard, Blockchain, Commerce endpoints.
"""
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
import httpx, json, os, sqlite3, logging
from typing import Optional

log = logging.getLogger("dada.platform")

router = APIRouter(tags=["Platform"])

# ── Config ─────────────────────────────────────────────────────
LEADERBOARD_DB = os.getenv("LEADERBOARD_DB", "/root/DADA-AI/leaderboard.db")
VIDEO_HOST = os.getenv("VIDEO_HOST", "https://dada.privseai.com/videos")
LOOPS_110_STORAGE = os.getenv("LOOPS_110_STORAGE", "http://185.55.240.110:8080/storage")

def init_db():
    os.makedirs(os.path.dirname(LEADERBOARD_DB) or ".", exist_ok=True)
    conn = sqlite3.connect(LEADERBOARD_DB)
    conn.execute("""CREATE TABLE IF NOT EXISTS user_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        display_name TEXT NOT NULL DEFAULT '',
        points INTEGER NOT NULL DEFAULT 0,
        action TEXT DEFAULT '',
        recorded_at TEXT NOT NULL DEFAULT (datetime('now'))
    )""")
    conn.execute("CREATE INDEX IF NOT EXISTS idx_up_id ON user_points(user_id)")
    conn.commit()
    conn.close()

def record_points(user_id: str, display_name: str, points: int, action: str = ""):
    conn = sqlite3.connect(LEADERBOARD_DB)
    conn.execute("INSERT INTO user_points (user_id, display_name, points, action) VALUES (?, ?, ?, ?)",
                 (user_id, display_name, points, action))
    conn.commit()
    conn.close()

def get_leaderboard(period: str, limit: int = 50) -> list:
    days = {"weekly": 7, "monthly": 30, "daily": 1}.get(period)
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
            "WHERE display_name LIKE ? GROUP BY user_id ORDER BY total DESC LIMIT ?",
            ('%[Creator]%', limit)
        ).fetchall()
    else:  # all
        rows = conn.execute(
            "SELECT user_id, display_name, SUM(points) as total FROM user_points "
            "GROUP BY user_id ORDER BY total DESC LIMIT ?", (limit,)
        ).fetchall()
    conn.close()
    return [{"rank": i+1, "user_id": r[0], "display_name": r[1], "points": r[2]} for i, r in enumerate(rows)]

init_db()

# ── Models ──────────────────────────────────────────────────────
class RewardRequest(BaseModel):
    user_id: str
    user_address: str = ""
    points: int = 1
    action: str = "watch"
    seconds: int = 60

class CommerceRequest(BaseModel):
    product_id: str = ""
    query: str = ""
    price: float = 0.0
    category: str = "general"

class LoopsPost(BaseModel):
    caption: str = ""
    video_url: str = ""
    user_id: str = ""

# ── Loops Feed ──────────────────────────────────────────────────
@router.get("/loops/feed")
async def loops_feed(page: int = 1, limit: int = 20):
    """Method 1: Server-side merge — combine remote + local videos deduped & sorted."""
    combined = {"data": [], "page": page}

    # 1) Try external API first
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            resp = await client.get("https://privseai.com/api/web/feed", params={"page": page, "per_page": limit})
            if resp.status_code == 200:
                data = resp.json()
                combined["data"] = data.get("data", [])
    except Exception:
        pass

    # 2) Also scan local/110 videos (deduped by id)
    local_items = []
    from_110 = False
    try:
        import subprocess
        result = subprocess.run(
            ["ssh", "-i", "/root/.ssh/id_225to110",
             "-o", "StrictHostKeyChecking=no",
             "-o", "ConnectTimeout=5",
             "root@185.55.240.110",
             "ls /root/loops/storage/app/public/tiktok/*.mp4 2>/dev/null | xargs -n1 basename"],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0 and result.stdout.strip():
            files = sorted([f.strip() for f in result.stdout.strip().split('\n') if f.strip().endswith('.mp4')], reverse=True)
            from_110 = True
        else:
            videos_dir = "/root/youtube_shorts"
            files = sorted([f for f in os.listdir(videos_dir) if f.endswith(".mp4") and (f.startswith("kpop_") or f.startswith("tiktok_"))], reverse=True)
    except Exception:
        videos_dir = "/root/youtube_shorts"
        files = sorted([f for f in os.listdir(videos_dir) if f.endswith(".mp4") and (f.startswith("kpop_") or f.startswith("tiktok_"))], reverse=True)

    storage_base = f"https://privseai.com/videos" if from_110 else VIDEO_HOST

    start = (page - 1) * limit
    seen_ids = {v.get("id") for v in combined["data"]}
    for fname in files[start:start + limit]:
        vid = fname[:-4]
        if vid not in seen_ids:
            local_items.append({
                "id": vid,
                "title": f"비디오 #{vid[:8]}",
                "description": "🔥 한국 핫 쇼츠 🔥 #shorts #korea #trending",
                "video_url": f"{storage_base}/tiktok/{fname}",
                "thumbnail_url": f"{storage_base}/tiktok/{vid}.jpg",
                "view_count": 0,
                "reward_points": 15,
                "likes": 0, "comments": 0,
                "creator": "DADA-AI",
                "source": "110" if from_110 else "local",
            })
            seen_ids.add(vid)

    combined["data"].extend(local_items)

    # 3) Sort by newest (descending id for tiktok videos)
    combined["data"].sort(key=lambda v: v.get("id", ""), reverse=True)
    combined["total"] = len(combined["data"])
    return combined


# ── Home Feed (proxy for Flutter app) ────────────────────────────
@router.get("/home/feed")
async def home_feed(page: int = 1, limit: int = 20):
    """Home feed — mirrors /loops/feed for Flutter app compatibility."""
    return await loops_feed(page=page, limit=limit)


@router.post("/loops/upload")
async def loops_upload(post: LoopsPost):
    """Stub for loops upload."""
    return {"success": True, "message": "Upload endpoint ready", "caption": post.caption}

# ── Video Proxy ──────────────────────────────────────────────────
import httpx as _httpx

@router.get("/videos/tiktok/{filename:path}")
async def proxy_tiktok_video(filename: str):
    """Proxy TikTok videos from 110 server over HTTPS.
    
    Flutter app runs on HTTPS, but 110 server videos are HTTP only.
    This endpoint streams the video through the DADA server so
    browsers don't block mixed content.
    """
    from fastapi.responses import StreamingResponse
    source_url = f"{LOOPS_110_STORAGE}/tiktok/{filename}"
    try:
        async with _httpx.AsyncClient(timeout=30) as client:
            resp = await client.get(source_url)
            if resp.status_code != 200:
                from fastapi import HTTPException
                raise HTTPException(resp.status_code, "Source not found")
            return StreamingResponse(
                resp.aiter_bytes(),
                media_type=resp.headers.get("content-type", "video/mp4"),
                headers={
                    "Content-Disposition": f'inline; filename="{filename}"',
                    "Access-Control-Allow-Origin": "*",
                    "Cache-Control": "public, max-age=86400",
                }
            )
    except _httpx.RequestError as e:
        from fastapi import HTTPException
        raise HTTPException(502, f"Proxy error: {e}")

# ── Leaderboard ─────────────────────────────────────────────────
@router.get("/leaderboard/stats")
async def leaderboard_stats():
    conn = sqlite3.connect(LEADERBOARD_DB)
    total_users = conn.execute("SELECT COUNT(DISTINCT user_id) FROM user_points").fetchone()[0] or 0
    total_points = conn.execute("SELECT COALESCE(SUM(points), 0) FROM user_points").fetchone()[0] or 0
    total_txs = conn.execute("SELECT COUNT(*) FROM user_points").fetchone()[0] or 0
    conn.close()
    return {
        "offchain": {
            "total_users": total_users,
            "total_points_distributed": total_points,
            "total_transactions": total_txs,
        },
        "remaining": max(0, 1000000 - total_points),
    }

@router.get("/leaderboard/my-rank")
async def leaderboard_my_rank(user_id: str = Query(...)):
    entries = get_leaderboard("all", 10000)
    rank = next((e["rank"] for e in entries if e["user_id"] == user_id), None)
    points = next((e["points"] for e in entries if e["user_id"] == user_id), 0)
    return {"rank": rank, "points": points, "user_id": user_id}

@router.get("/leaderboard/{period}")
async def leaderboard_period(period: str, limit: int = 50):
    if period not in ("weekly", "monthly", "daily", "all", "creators"):
        raise HTTPException(400, f"Invalid period: {period}")
    data = get_leaderboard(period, limit)
    return {"data": data, "period": period}

# ── Blockchain / Reward ────────────────────────────────────────
@router.get("/blockchain/health")
async def blockchain_health():
    return {"status": "healthy", "service": "blockchain"}

@router.get("/blockchain/info")
async def blockchain_info():
    return {"network": "minima", "block_height": 0, "peers": 0}

@router.get("/blockchain/balance")
async def blockchain_balance(address: str = "0x0"):
    return {"address": address, "balance": 0, "tokens": []}

@router.post("/blockchain/reward")
async def blockchain_reward(req: RewardRequest):
    points = max(1, req.points)
    record_points(req.user_id or "anonymous", f"User_{req.user_id[:8]}" if req.user_id else "Anonymous", points, req.action)
    return {"success": True, "points_earned": points, "action": req.action}

# ── Commerce ────────────────────────────────────────────────────
@router.post("/commerce/analyze")
async def commerce_analyze(req: CommerceRequest):
    """AI commerce analysis stub."""
    return {
        "success": True,
        "analysis": {
            "title": f"Trending in {req.category}",
            "estimated_price": req.price or 29900,
            "confidence": 0.85,
            "recommendation": "Buy now - trending item",
            "category": req.category,
        }
    }

@router.get("/commerce/trending")
async def commerce_trending():
    return {
        "data": [
            {"id": "1", "title": "AI Speaker Mini", "price": 32000, "badge": "50% OFF", "reward_points": 200},
            {"id": "2", "title": "Wireless Earbuds Pro", "price": 45000, "badge": "HOT", "reward_points": 300},
            {"id": "3", "title": "LED Desk Lamp", "price": 15000, "reward_points": 100},
        ]
    }

# ── Marqo Search ──────────────────────────────────────────────────


@router.post("/commerce/search")
async def commerce_search(request: dict):
    """Semantic product search via Marqo."""
    if not os.getenv("MARQO_URL"):
        return {"error": "Marqo not configured"}
    query = request.get("q", "")
    limit = request.get("limit", 10)
    if not query:
        return {"error": "q is required"}
    try:
        from app.marqo_service import get_marqo
        svc = get_marqo()
        results = await svc.search_commerce(query, limit)
        return {"query": query, "results": results}
    except Exception as e:
        import logging
        logging.getLogger("dada.platform").error(f"Commerce search error: {e}")
        return {"error": str(e)}


@router.get("/messages/search")
async def messages_search(q: str = "", limit: int = 10):
    """Semantic message search via Marqo."""
    if not os.getenv("MARQO_URL"):
        return {"error": "Marqo not configured"}
    if not q:
        return {"error": "q is required"}
    try:
        from app.marqo_service import get_marqo
        svc = get_marqo()
        results = await svc.search_messages(q, limit)
        return {"query": q, "results": results}
    except Exception as e:
        import logging
        logging.getLogger("dada.platform").error(f"Message search error: {e}")
        return {"error": str(e)}
