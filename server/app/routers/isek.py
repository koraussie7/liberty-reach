"""ISEK — Agent-to-Agent (A2A) Network Integration.

Provides endpoints for ISEK relay management, AgentCard registration,
A2A messaging, ERC-8004 on-chain identity, and agent discovery.
"""
import os
import json
import uuid
import logging
import subprocess

import httpx
from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse

logger = logging.getLogger("isek")

router = APIRouter(tags=["isek"])

ISEK_RELAY_URL = os.getenv("ISEK_RELAY_URL", "http://localhost:8766")
ISEK_AGENT_NAME = os.getenv("ISEK_AGENT_NAME", "DADA-Hermes")
ISEK_RELAY_PORT = int(os.getenv("ISEK_RELAY_PORT", "9001"))
ISEK_AGENT_PORT = int(os.getenv("ISEK_AGENT_PORT", "9999"))


# ── Initialisation ──────────────────────────────────────────────────────────

def init_isek() -> bool:
    """Check whether the ISEK Python package is installed."""
    try:
        import isek  # noqa: F401
        logger.info("ISEK package is available.")
        return True
    except ImportError:
        logger.warning("ISEK not installed — run: pip install isek && isek setup")
        return False


_INIT_ISEK = init_isek()


# ── Helper ──────────────────────────────────────────────────────────────────

def _build_agent_card(
    name: str,
    url: str,
    description: str,
    skills: list | None = None,
) -> dict | None:
    """Build an ISEK AgentCard dict from the `a2a` / `isek` packages.

    Falls back to a plain dict if the packages are not installed.
    """
    try:
        from a2a.types import AgentCard, AgentCapabilities, AgentSkill

        card = AgentCard(
            name=name,
            url=url,
            description=description,
            version="1.0",
            capabilities=AgentCapabilities(
                streaming=True,
                tools=True,
                task_execution=True,
            ),
            defaultInputModes=["text/plain"],
            defaultOutputModes=["text/plain"],
            skills=[
                AgentSkill(
                    id=s.get("id", "skill"),
                    name=s.get("name", "Skill"),
                    description=s.get("desc", ""),
                    tags=s.get("tags", []),
                )
                for s in (skills or [])
            ],
        )
        return card.model_dump()
    except ImportError:
        logger.debug("a2a/types not available; returning plain dict.")
        return {
            "name": name,
            "url": url,
            "description": description,
            "version": "1.0",
            "capabilities": {"streaming": True, "tools": True, "task_execution": True},
            "defaultInputModes": ["text/plain"],
            "defaultOutputModes": ["text/plain"],
            "skills": [
                {"id": s.get("id", "skill"), "name": s.get("name", "Skill"),
                 "description": s.get("desc", ""), "tags": s.get("tags", [])}
                for s in (skills or [])
            ],
        }


# ── Existing endpoints (health, agents, register, message) ──────────────────


@router.get("/isek/health")
async def isek_health():
    try:
        async with httpx.AsyncClient(timeout=5) as c:
            r = await c.get(f"{ISEK_RELAY_URL}/health")
            return {
                "isek_online": r.status_code == 200,
                "status": r.json() if r.status_code == 200 else {},
            }
    except Exception as e:
        return {"isek_online": False, "error": str(e)}


@router.get("/isek/agents")
async def isek_agents():
    """List agents on the ISEK network."""
    try:
        async with httpx.AsyncClient(timeout=10) as c:
            r = await c.get(f"{ISEK_RELAY_URL}/agents")
            if r.status_code == 200:
                return JSONResponse(r.json())
    except Exception:
        pass
    return {"agents": [], "error": "ISEK relay unreachable"}


@router.post("/isek/agent/register")
async def isek_register_agent(req: Request):
    """Register this server as an ISEK agent."""
    body = await req.json()
    name = body.get("name", ISEK_AGENT_NAME)
    model = body.get("model", "gpt-4o-mini")
    skills = body.get("skills", [])
    description = body.get("description", f"DADA-AI agent: {name}")

    # Build a proper AgentCard (either from the real package or a plain dict)
    agent_card = _build_agent_card(
        name=name,
        url=f"http://localhost:{ISEK_AGENT_PORT}",
        description=description,
        skills=skills,
    )
    if agent_card is None:
        return JSONResponse({"error": "failed to build AgentCard"}, status_code=500)

    # Also forward to the ISEK relay if it is reachable
    payload = {
        "name": name,
        "description": description,
        "capabilities": [s.get("id", "skill") for s in skills],
        "endpoint": f"http://localhost:{ISEK_AGENT_PORT}",
    }
    try:
        async with httpx.AsyncClient(timeout=10) as c:
            r = await c.post(f"{ISEK_RELAY_URL}/agents/register", json=payload)
            return JSONResponse(
                {"agent_card": agent_card, "relay_response": r.json()},
                status_code=r.status_code,
            )
    except Exception as e:
        return JSONResponse({"agent_card": agent_card, "relay_error": str(e)})


@router.post("/isek/message")
async def isek_send_message(req: Request):
    """Send an A2A message to another agent on the ISEK network."""
    body = await req.json()
    try:
        async with httpx.AsyncClient(timeout=30) as c:
            r = await c.post(f"{ISEK_RELAY_URL}/message", json=body)
            return JSONResponse(r.json(), status_code=r.status_code)
    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=502)


# ── New ISEK endpoints (from integration spec) ──────────────────────────────


@router.post("/isek/relay/start")
async def isek_relay_start():
    """Start the ISEK relay as a subprocess.

    The relay enables libp2p-based peer discovery and messaging.
    """
    try:
        result = subprocess.run(
            ["isek", "run", "relay"],
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode == 0:
            return JSONResponse({"status": "started", "output": result.stdout.strip()})
        return JSONResponse(
            {"error": result.stderr.strip()},
            status_code=500,
        )
    except FileNotFoundError:
        return JSONResponse({"error": "ISEK CLI not found — run: pip install isek"}, status_code=500)
    except subprocess.TimeoutExpired:
        return JSONResponse({"error": "ISEK relay start timed out"}, status_code=504)
    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=500)


@router.get("/isek/relay/status")
async def isek_relay_status():
    """Check whether the ISEK relay subprocess is running."""
    try:
        result = subprocess.run(
            ["isek", "status"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        output = result.stdout.strip()
        return JSONResponse({"running": result.returncode == 0, "output": output})
    except FileNotFoundError:
        return JSONResponse({"running": False, "error": "ISEK CLI not found"})
    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=500)


@router.post("/isek/a2a/send")
async def isek_a2a_send(req: Request):
    """Send a Google A2A-protocol message to a target agent.

    Expects JSON body:
        { "target_url": "http://agent-host:9999", "query": "Hello!" }
    """
    body = await req.json()
    target_url = body.get("target_url", f"http://localhost:{ISEK_AGENT_PORT}")
    query = body.get("query", "")

    if not query.strip():
        return JSONResponse({"error": "query is required"}, status_code=400)

    try:
        async with httpx.AsyncClient(timeout=30) as c:
            r = await c.post(
                f"{target_url}/a2a/message",
                json={
                    "jsonrpc": "2.0",
                    "method": "tasks/send",
                    "params": {
                        "id": str(uuid.uuid4()),
                        "message": {
                            "role": "user",
                            "parts": [{"text": query}],
                        },
                    },
                    "id": 1,
                },
            )
            return JSONResponse(r.json(), status_code=r.status_code)
    except httpx.RequestError as e:
        return JSONResponse(
            {"error": f"Cannot reach target agent at {target_url}: {e}"},
            status_code=502,
        )
    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=502)


@router.post("/isek/identity/register")
async def isek_identity_register(req: Request):
    """Register an ERC-8004 blockchain identity for an agent.

    Expects JSON body:
        { "agent_url": "http://agent-host:9999" }
    """
    body = await req.json()
    agent_url = body.get("agent_url", f"http://localhost:{ISEK_AGENT_PORT}")

    try:
        from isek.web3.isek_identiey import ensure_identity
        from a2a.types import AgentCard

        card = AgentCard(
            name="DADA Agent",
            url=agent_url,
            description="DADA-AI on ISEK",
            version="1.0",
            capabilities={},
            defaultInputModes=[],
            defaultOutputModes=[],
        )
        address, agent_id, tx_hash = ensure_identity(card)
        return JSONResponse({
            "address": address,
            "agent_id": agent_id,
            "tx_hash": tx_hash,
        })
    except ImportError as e:
        return JSONResponse(
            {"error": f"isek.web3 or a2a.types not available: {e}"},
            status_code=501,
        )
    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=500)


@router.get("/isek/agents/discover")
async def isek_agents_discover():
    """Discover agents on the ISEK network.

    Returns a list of agent cards discovered via the relay.
    Currently a placeholder — actual discovery requires a running relay.
    """
    try:
        async with httpx.AsyncClient(timeout=10) as c:
            r = await c.get(f"{ISEK_RELAY_URL}/agents")
            if r.status_code == 200:
                data = r.json()
                agents = data if isinstance(data, list) else data.get("agents", [])
                return JSONResponse({"agents": agents})
    except Exception:
        logger.debug("ISEK relay unreachable; returning empty discovery list.")
    return JSONResponse({
        "agents": [],
        "message": "Connect to an ISEK relay to discover agents. "
                   "Start one with POST /isek/relay/start",
    })
