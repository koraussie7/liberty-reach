"""AI Chat & Models API router for DADA-AI Flutter app.
Routes Gemini models to Google Generative AI, others to OpenCode.
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import httpx, json, os

router = APIRouter(prefix="/ai", tags=["AI"])

OPENDCODE_API_KEY = os.getenv("OPENDCODE_API_KEY", "csk-dm666k8pcynxxtwtp4vjkrrny6dchdwwnnxwwefpx8fve4nm")
OPENDCODE_BASE = "https://opencode.ai/zen/go/v1"

# Gemini config
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY") or os.getenv("AUXILIARY_VISION_API_KEY")

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


async def _call_gemini(model: str, messages: list) -> dict:
    """Call Google Gemini API for chat."""
    import google.generativeai as genai

    genai.configure(api_key=GEMINI_API_KEY)

    # Map model name to Gemini API model name
    gemini_model_name = model
    if model == "gemini-2.5-flash":
        gemini_model_name = "models/gemini-2.5-flash"
    elif model == "gemini-2.5-pro":
        gemini_model_name = "models/gemini-2.5-pro"
    elif model == "gemini-2.0-flash":
        gemini_model_name = "models/gemini-2.0-flash"

    # Build contents from messages
    contents = []
    for msg in messages:
        role = msg.get("role", "user")
        content = msg.get("content", "")
        # Gemini uses "user" and "model" roles
        gemini_role = "model" if role in ("assistant", "model") else "user"
        contents.append({"role": gemini_role, "parts": [{"text": content}]})

    genai_model = genai.GenerativeModel(gemini_model_name)
    response = await genai_model.generate_content_async(
        contents,
        generation_config=genai.types.GenerationConfig(
            max_output_tokens=4096,
            temperature=0.7,
        ),
    )

    reply = response.text or "(empty response)"
    return {
        "choices": [{
            "message": {"content": reply, "role": "assistant"},
            "index": 0,
            "finish_reason": "stop",
        }],
        "model": model,
        "provider": "gemini",
    }


async def _call_opencode(model: str, messages: list) -> dict:
    """Call OpenCode API (OpenAI-compatible)."""
    async with httpx.AsyncClient(timeout=120) as client:
        payload = {
            "model": model,
            "messages": messages,
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
                "message": {"content": f"(API error: {resp.status_code})"}
            }]
        }


@router.post("/chat")
async def chat(request: ChatRequest):
    """Proxy chat request to the appropriate AI provider based on model."""
    try:
        model = request.model

        # Route Gemini models to Google Gemini API
        if model.startswith("gemini-"):
            if not GEMINI_API_KEY:
                return {
                    "choices": [{
                        "message": {"content": "(Gemini API key not configured)"}
                    }]
                }
            return await _call_gemini(model, request.messages)

        # Route local models to Ollama
        if model.startswith("gemma-") or model == "local":
            async with httpx.AsyncClient(timeout=120) as client:
                payload = {
                    "model": model.replace("local", "gemma-4-e4b-it"),
                    "messages": request.messages,
                    "stream": False,
                }
                resp = await client.post(
                    "http://localhost:11434/v1/chat/completions",
                    json=payload,
                )
                if resp.status_code == 200:
                    return resp.json()
                return {
                    "choices": [{
                        "message": {"content": f"(Local AI error: {resp.status_code})"}
                    }]
                }

        # Default: route to OpenCode
        return await _call_opencode(model, request.messages)

    except Exception as e:
        return {
            "choices": [{
                "message": {"content": f"(connection error: {e})"}
            }]
        }
