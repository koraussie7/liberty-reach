"""AI Chat & Models API router for DADA-AI Flutter app."""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import httpx, json, os

router = APIRouter(prefix="/ai", tags=["AI"])

OPENDCODE_API_KEY = os.getenv("OPENDCODE_API_KEY", "csk-dm666k8pcynxxtwtp4vjkrrny6dchdwwnnxwwefpx8fve4nm")
OPENDCODE_BASE = "https://opencode.ai/zen/go/v1"
LOCALAI_BASE = "http://127.0.0.1:8081/v1"

MODELS_CACHE = [
    {"id": "deepseek-v4-flash", "provider": "opencode"},
    {"id": "deepseek-v4-pro", "provider": "opencode"},
    {"id": "gemini-2.5-flash", "provider": "gemini"},
    {"id": "gemma-4-e4b-it", "provider": "local"},
]

class ChatRequest(BaseModel):
    model: str = "deepseek-v4-flash"
    messages: list = [{"role": "user", "content": "Say hello"}]
    stream: bool = False

@router.get("/models")
async def list_models():
    """Return available AI models for the Flutter app."""
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(
                f"{OPENDCODE_BASE}/models",
                headers={"Authorization": f"Bearer {OPENDCODE_API_KEY}"}
            )
            if resp.status_code == 200:
                data = resp.json()
                opencode_models = [
                    {"id": m["id"], "provider": "opencode"}
                    for m in data.get("data", [])
                ]
                return {"data": opencode_models + MODELS_CACHE}
    except Exception:
        pass
    return {"data": MODELS_CACHE}

@router.post("/chat")
async def chat(request: ChatRequest):
    """Proxy chat request to OpenCode API (OpenAI-compatible)."""
    try:
        async with httpx.AsyncClient(timeout=120) as client:
            payload = {
                "model": request.model,
                "messages": request.messages,
                "stream": False,
            }
            resp = await client.post(
                f"{OPENDCODE_BASE}/chat/completions",
                headers={
                    "Authorization": f"Bearer {OPENDCODE_API_KEY}",
                    "Content-Type": "application/json",
                },
                json=payload,
            )
            if resp.status_code == 200:
                return resp.json()
            return {
                "choices": [{
                    "message": {
                        "content": f"(API error: {resp.status_code})"
                    }
                }]
            }
    except Exception as e:
        return {
            "choices": [{
                "message": {"content": f"(connection error: {e})"}
            }]
        }
