"""Marqo vector search service for DADA-AI.
Provides semantic search for commerce products, messages, and agent memory."""

import os
import logging
from typing import Optional

import httpx

log = logging.getLogger("dada.marqo")

MARQO_URL = os.getenv("MARQO_URL", "http://localhost:8882")


class MarqoService:
    """Singleton service wrapping the Marqo vector search API."""

    def __init__(self):
        self.client = httpx.AsyncClient(timeout=30, base_url=MARQO_URL)
        self._ready = False

    async def _request(self, method: str, path: str, **kwargs):
        url = f"{MARQO_URL}{path}"
        try:
            resp = await self.client.request(method, url, **kwargs)
            if resp.status_code >= 400:
                log.warning(f"Marqo {method} {path} -> {resp.status_code}")
                return None
            return resp.json()
        except Exception as e:
            log.error(f"Marqo request error: {e}")
            return None

    @property
    def ready(self) -> bool:
        return self._ready

    async def init_indexes(self):
        """Create default indexes if they don't exist."""
        indexes = {
            "commerce": {
                "treat_urls_and_pointers_as_images": False,
                "model": "ViT-B/32",
            },
            "messages": {
                "treat_urls_and_pointers_as_images": False,
                "model": "ViT-B/32",
            },
            "agent_memory": {
                "treat_urls_and_pointers_as_images": False,
                "model": "ViT-B/32",
            },
        }
        for name, settings in indexes.items():
            existing = await self._request("GET", f"/indexes/{name}")
            if existing is None:
                result = await self._request("POST", "/indexes", json={
                    "indexName": name,
                    **settings,
                })
                if result:
                    log.info(f"Marqo index '{name}' created")
            else:
                log.info(f"Marqo index '{name}' already exists")
        self._ready = True

    async def index_documents(self, index: str, documents: list):
        if not documents:
            return
        return await self._request(
            "POST", f"/indexes/{index}/documents", json=documents
        )

    async def search(self, index: str, query: str, limit: int = 10, **kwargs):
        body = {"q": query, "limit": limit, **kwargs}
        return await self._request("POST", f"/indexes/{index}/search", json=body)

    # ── Commerce ──────────────────────────────────────────────────────────

    async def index_commerce_products(self, products: list):
        docs = []
        for p in products:
            docs.append({
                "_id": str(p.get("id", "")),
                "title": p.get("name", p.get("title", "")),
                "price": p.get("price", 0),
                "badge": p.get("badge", ""),
                "reward_points": p.get("reward_points", 0),
                "image_url": p.get("image_url", ""),
            })
        return await self.index_documents("commerce", docs)

    async def search_commerce(self, query: str, limit: int = 10):
        return await self.search("commerce", query, limit)

    # ── Messages ──────────────────────────────────────────────────────────

    async def index_message(self, msg: dict):
        doc = {
            "_id": msg.get("_id"),
            "sender": msg.get("sender", ""),
            "content": msg.get("content", ""),
            "room": msg.get("room", ""),
            "timestamp": msg.get("timestamp", ""),
            "type": msg.get("type", "chat"),
        }
        return await self.index_documents("messages", [doc])

    async def search_messages(self, query: str, limit: int = 10):
        return await self.search("messages", query, limit)

    # ── Agent Memory (RAG) ────────────────────────────────────────────────

    async def index_agent_memory(self, session_id: str, role: str, content: str):
        doc = {
            "session_id": session_id,
            "role": role,
            "content": content,
            "timestamp": __import__("datetime").datetime.utcnow().isoformat(),
        }
        return await self.index_documents("agent_memory", [doc])

    async def search_agent_memory(
        self, query: str, session_id: Optional[str] = None, limit: int = 5
    ):
        body = {"q": query, "limit": limit, "searchableAttributes": ["content"]}
        if session_id:
            body["filter"] = f"session_id:{session_id}"
        return await self._request(
            "POST", "/indexes/agent_memory/search", json=body
        )


# ── Singleton ────────────────────────────────────────────────────────────────

_instance: Optional[MarqoService] = None


def get_marqo() -> MarqoService:
    global _instance
    if _instance is None:
        _instance = MarqoService()
    return _instance


MARQO_ENABLED = os.getenv("MARQO_URL") is not None


async def init_marqo():
    """Initialize Marqo indexes and index default products."""
    if not MARQO_ENABLED:
        log.info("Marqo not configured — skipping")
        return
    try:
        svc = get_marqo()
        await svc.init_indexes()
        log.info("Marqo ready — indexes initialized")
    except Exception as e:
        log.warning(f"Marqo init failed (non-fatal): {e}")
