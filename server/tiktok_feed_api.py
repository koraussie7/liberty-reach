"""
TikTok K-pop Feed API for DADA-AI Loops
Serves TikTok videos stored on the 110 server as a feed
"""
import json, os, time, re
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse

TIKTOK_VIDEO_DIR = "/root/loops/storage/app/public/tiktok"
SERVER_IP = "185.55.240.110"
SERVER_PORT = "8080"

# Cached metadata
_cache = {"videos": None, "timestamp": 0}
CACHE_TTL = 60  # seconds

def get_videos():
    now = time.time()
    if _cache["videos"] and (now - _cache["timestamp"]) < CACHE_TTL:
        return _cache["videos"]
    
    videos = []
    if not os.path.isdir(TIKTOK_VIDEO_DIR):
        print(f"Directory not found: {TIKTOK_VIDEO_DIR}")
        return videos
    
    for f in sorted(os.listdir(TIKTOK_VIDEO_DIR)):
        if not f.endswith(".mp4"):
            continue
        fpath = os.path.join(TIKTOK_VIDEO_DIR, f)
        size_kb = os.path.getsize(fpath) // 1024
        
        # Parse metadata from filename
        vid = f.replace("tiktok_", "").replace(".mp4", "")
        
        # Look up view count from file if we stored it
        meta_path = fpath + ".meta"
        title = f"K-pop Loop"
        views = 0
        likes = 0
        author = "K-pop TikTok"
        
        if os.path.exists(meta_path):
            try:
                with open(meta_path) as mf:
                    meta = json.loads(mf.read())
                title = meta.get("title", title)
                views = meta.get("views", 0)
                likes = meta.get("likes", 0)
                author = meta.get("author", author)
            except:
                pass
        
        video_url = f"https://{SERVER_IP}:{SERVER_PORT}/storage/app/public/tiktok/{f}"
        
        videos.append({
            "id": vid,
            "title": title[:50],
            "description": f"🔥 {views:,} views | ❤️ {likes:,} likes",
            "video_url": video_url,
            "thumbnail_url": video_url,  # Use video as thumbnail for now
            "view_count": views,
            "reward_points": likes // 100,
            "creator": author,
        })
    
    # Sort by views descending
    videos.sort(key=lambda v: v["view_count"], reverse=True)
    _cache["videos"] = videos
    _cache["timestamp"] = now
    return videos

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        path = urlparse(self.path).path
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        
        if path == "/loops/tiktok":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            try:
                vids = get_videos()
                self.wfile.write(json.dumps({"data": vids, "count": len(vids)}).encode())
            except Exception as e:
                self.wfile.write(json.dumps({"error": str(e), "data": []}).encode())
        elif path == "/loops/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            vids = get_videos()
            total_size = sum(os.path.getsize(os.path.join(TIKTOK_VIDEO_DIR, f)) for f in os.listdir(TIKTOK_VIDEO_DIR) if f.endswith(".mp4")) // (1024*1024) if os.path.isdir(TIKTOK_VIDEO_DIR) else 0
            self.wfile.write(json.dumps({
                "status": "ok",
                "videos_count": len(vids),
                "total_size_mb": total_size,
                "dir": TIKTOK_VIDEO_DIR,
            }).encode())
        elif path == "/loops/feed":
            # Also serve TikTok videos via the standard feed endpoint
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            try:
                vids = get_videos()
                # Return the first 50
                self.wfile.write(json.dumps({"data": vids[:50], "count": len(vids)}).encode())
            except Exception as e:
                self.wfile.write(json.dumps({"error": str(e), "data": []}).encode())
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(json.dumps({"error": "not found"}).encode())
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()
    
    def log_message(self, fmt, *a):
        pass

if __name__ == "__main__":
    port = 8767
    print(f"TikTok Feed API on port {port} (videos from {TIKTOK_VIDEO_DIR})")
    server = HTTPServer(("0.0.0.0", port), Handler)
    server.serve_forever()
