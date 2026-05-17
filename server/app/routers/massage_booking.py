"""Massage Booking (Reverse Auction) — inDriver-style therapist bidding."""
import os
import json
import uuid
import logging
from datetime import datetime, timedelta
from typing import Optional, List

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

logger = logging.getLogger("massage_booking")

router = APIRouter(tags=["massage"])

MASSAGE_DB = os.getenv("MASSAGE_DB", "massage_bookings.json")


def _load_data() -> dict:
    if os.path.exists(MASSAGE_DB):
        try:
            with open(MASSAGE_DB) as f:
                return json.load(f)
        except Exception:
            pass
    return {"requests": {}, "bids": {}}


def _save_data(data: dict) -> None:
    with open(MASSAGE_DB, "w") as f:
        json.dump(data, f, indent=2, default=str)


# ── Models ──


class MassageRequestIn(BaseModel):
    address: str
    lat: float = 0.0
    lng: float = 0.0
    service_type: str = "Deep Tissue"  # Deep Tissue, Swedish, Thai, Sports, Aromatherapy
    duration_minutes: int = 60
    max_budget: float = 0.0
    notes: Optional[str] = None


class MassageBidIn(BaseModel):
    therapist_id: str
    therapist_name: str
    price: float
    estimated_minutes: int
    message: str = ""
    rating: float = 0.0
    specialties: List[str] = []


# ── Endpoints ──


@router.post("/massage/request")
async def create_massage_request(req: MassageRequestIn):
    """Create a new massage booking request."""
    data = _load_data()
    request_id = f"mr_{uuid.uuid4().hex[:8]}"
    entry = {
        "id": request_id,
        "status": "bidding",
        "created_at": datetime.utcnow().isoformat(),
        "expires_at": (datetime.utcnow() + timedelta(minutes=5)).isoformat(),
        **req.model_dump(),
    }
    data["requests"][request_id] = entry
    _save_data(data)

    from app.main import food_connections
    for ws in list(food_connections.values()):
        try:
            await ws.send_text(json.dumps({"type": "massage_request", "request": entry}))
        except Exception:
            pass

    return {"request_id": request_id, "status": "bidding"}


@router.post("/massage/bid/{request_id}")
async def submit_massage_bid(request_id: str, bid: MassageBidIn):
    """Therapist submits a bid on a massage request."""
    data = _load_data()
    if request_id not in data["requests"]:
        raise HTTPException(404, "Request not found")
    bid_id = f"mb_{uuid.uuid4().hex[:8]}"
    bid_entry = {**bid.model_dump(), "id": bid_id, "submitted_at": datetime.utcnow().isoformat()}
    data["bids"].setdefault(request_id, []).append(bid_entry)
    _save_data(data)

    from app.main import connections
    req = data["requests"][request_id]
    peer_id = req.get("peer_id")
    if peer_id and peer_id in connections:
        try:
            await connections[peer_id].send_text(
                json.dumps({"type": "massage_bid", "request_id": request_id, "bid": bid_entry})
            )
        except Exception:
            pass

    return {"status": "bid_submitted", "bid_id": bid_id}


@router.get("/massage/bids/{request_id}")
async def get_massage_bids(request_id: str):
    """List all bids for a massage request."""
    data = _load_data()
    if request_id not in data["requests"]:
        raise HTTPException(404, "Request not found")
    return {
        "request_id": request_id,
        "bids": data["bids"].get(request_id, []),
        "request": data["requests"][request_id],
    }


@router.post("/massage/select/{request_id}")
async def select_massage_bid(request_id: str, body: dict):
    """Customer selects the winning therapist bid."""
    bid_id = body.get("bid_id") or body.get("therapist_id")
    data = _load_data()
    if request_id not in data["requests"]:
        raise HTTPException(404, "Request not found")
    bids = data["bids"].get(request_id, [])
    matched = [b for b in bids if b.get("id") == bid_id or b.get("therapist_id") == bid_id]
    if not matched:
        raise HTTPException(404, "Bid not found")
    selected = matched[0]
    data["requests"][request_id]["status"] = "confirmed"
    data["requests"][request_id]["selected_therapist"] = selected["id"]
    data["requests"][request_id]["selected_therapist_name"] = selected["therapist_name"]
    _save_data(data)
    return {
        "status": "confirmed",
        "request_id": request_id,
        "bid_id": selected["id"],
        "therapist": selected["therapist_name"],
    }
