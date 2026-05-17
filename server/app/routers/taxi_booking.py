"""Taxi Booking (Reverse Auction) — inDriver-style ride bidding."""
import os
import json
import uuid
import logging
from datetime import datetime, timedelta
from typing import Optional, List

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

logger = logging.getLogger("taxi_booking")

router = APIRouter(tags=["taxi"])

TAXI_DB = os.getenv("TAXI_DB", "taxi_rides.json")


def _load_taxi_data() -> dict:
    if os.path.exists(TAXI_DB):
        try:
            with open(TAXI_DB) as f:
                return json.load(f)
        except Exception:
            pass
    return {"requests": {}, "bids": {}}


def _save_taxi_data(data: dict) -> None:
    with open(TAXI_DB, "w") as f:
        json.dump(data, f, indent=2, default=str)


# ── Models ──


class TaxiRequestIn(BaseModel):
    pickup_address: str
    pickup_lat: float = 0.0
    pickup_lng: float = 0.0
    dropoff_address: str
    dropoff_lat: float = 0.0
    dropoff_lng: float = 0.0
    passengers: int = 1
    max_budget: float = 0.0
    notes: Optional[str] = None


class TaxiBidIn(BaseModel):
    driver_id: str
    driver_name: str
    price: float
    estimated_minutes: int
    message: str = ""
    rating: float = 0.0
    car_model: str = ""
    car_color: str = ""


# ── Endpoints ──


@router.post("/taxi/request")
async def create_taxi_request(req: TaxiRequestIn):
    """Create a new taxi ride request (customer posts ride for bidding)."""
    data = _load_taxi_data()
    request_id = f"tr_{uuid.uuid4().hex[:8]}"
    entry = {
        "id": request_id,
        "status": "bidding",
        "created_at": datetime.utcnow().isoformat(),
        "expires_at": (datetime.utcnow() + timedelta(minutes=5)).isoformat(),
        **req.model_dump(),
    }
    data["requests"][request_id] = entry
    _save_taxi_data(data)

    # Broadcast to connected taxi peers
    from app.main import food_connections  # reuse WebSocket pool
    for ws in list(food_connections.values()):
        try:
            await ws.send_text(json.dumps({"type": "taxi_request", "request": entry}))
        except Exception:
            pass

    return {"request_id": request_id, "status": "bidding"}


@router.post("/taxi/bid/{request_id}")
async def submit_taxi_bid(request_id: str, bid: TaxiBidIn):
    """Driver submits a bid on a taxi ride request."""
    data = _load_taxi_data()
    if request_id not in data["requests"]:
        raise HTTPException(404, "Request not found")
    bid_id = f"tb_{uuid.uuid4().hex[:8]}"
    bid_entry = {
        **bid.model_dump(),
        "id": bid_id,
        "submitted_at": datetime.utcnow().isoformat(),
    }
    data["bids"].setdefault(request_id, []).append(bid_entry)
    _save_taxi_data(data)

    from app.main import connections
    req = data["requests"][request_id]
    peer_id = req.get("peer_id")
    if peer_id and peer_id in connections:
        try:
            await connections[peer_id].send_text(
                json.dumps({"type": "taxi_bid", "request_id": request_id, "bid": bid_entry})
            )
        except Exception:
            pass

    return {"status": "bid_submitted", "bid_id": bid_id}


@router.get("/taxi/bids/{request_id}")
async def get_taxi_bids(request_id: str):
    """List all bids for a taxi ride request."""
    data = _load_taxi_data()
    if request_id not in data["requests"]:
        raise HTTPException(404, "Request not found")
    return {
        "request_id": request_id,
        "bids": data["bids"].get(request_id, []),
        "request": data["requests"][request_id],
    }


@router.post("/taxi/select/{request_id}")
async def select_taxi_bid(request_id: str, body: dict):
    """Customer selects the winning driver bid."""
    bid_id = body.get("bid_id") or body.get("driver_id")
    data = _load_taxi_data()
    if request_id not in data["requests"]:
        raise HTTPException(404, "Request not found")
    bids = data["bids"].get(request_id, [])
    matched = [b for b in bids if b.get("id") == bid_id or b.get("driver_id") == bid_id]
    if not matched:
        raise HTTPException(404, "Bid not found for this request")
    selected = matched[0]
    data["requests"][request_id]["status"] = "confirmed"
    data["requests"][request_id]["selected_driver"] = selected["id"]
    data["requests"][request_id]["selected_driver_name"] = selected["driver_name"]
    _save_taxi_data(data)
    return {
        "status": "confirmed",
        "request_id": request_id,
        "bid_id": selected["id"],
        "driver": selected["driver_name"],
    }
