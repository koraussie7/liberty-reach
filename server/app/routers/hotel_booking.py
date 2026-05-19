"""Hotel Booking (Reverse Auction) — P2P bidding system."""
import os
import json
import uuid
import logging
from datetime import datetime, timedelta
from typing import Optional, List, Dict

from fastapi import APIRouter, HTTPException, WebSocket
from pydantic import BaseModel

logger = logging.getLogger("hotel_booking")

router = APIRouter(tags=["hotel"])

# Persistence
HOTEL_DB = os.getenv("HOTEL_DB", "hotel_bookings.json")

def _load_hotel_data() -> dict:
    if os.path.exists(HOTEL_DB):
        try:
            with open(HOTEL_DB) as f:
                return json.load(f)
        except:
            pass
    return {"requests": {}, "bids": {}}

def _save_hotel_data(data: dict) -> None:
    with open(HOTEL_DB, "w") as f:
        json.dump(data, f, indent=2, default=str)

# --- Models ---
class HotelRequestIn(BaseModel):
    check_in: str
    check_out: str
    guests: int
    location: str
    max_budget: Optional[int] = None
    requirements: List[str] = []

class HotelBidIn(BaseModel):
    hotel_id: str
    hotel_name: str
    price: int
    message: str
    amenities: List[str] = []
    rating: float = 0.0

# --- List & Detail endpoints ---
@router.get("/hotel/requests")
async def list_hotel_requests(status: Optional[str] = None):
    """List all hotel requests, optionally filtered by status."""
    data = _load_hotel_data()
    requests = list(data["requests"].values())
    if status:
        requests = [r for r in requests if r.get("status") == status]
    # Sort newest first
    requests.sort(key=lambda r: r.get("created_at", ""), reverse=True)
    return requests

@router.get("/hotel/request/{request_id}")
async def get_hotel_request(request_id: str):
    """Get a single hotel request by ID."""
    data = _load_hotel_data()
    req = data["requests"].get(request_id)
    if not req:
        raise HTTPException(404, "Request not found")
    return req

# --- Existing endpoints ---
@router.post("/hotel/request")
async def create_hotel_request(req: HotelRequestIn):
    data = _load_hotel_data()
    request_id = f"hr_{uuid.uuid4().hex[:8]}"
    entry = {
        "id": request_id,
        "status": "bidding",
        "created_at": datetime.utcnow().isoformat(),
        "expires_at": (datetime.utcnow() + timedelta(minutes=5)).isoformat(),
        **req.model_dump(),
    }
    data["requests"][request_id] = entry
    _save_hotel_data(data)

    # Broadcast to hotel peers via WebSocket
    from app.main import hotel_connections
    for ws in list(hotel_connections.values()):
        try:
            await ws.send_text(json.dumps({"type": "hotel_request", "request": entry}))
        except:
            pass

    # ── Sync to supplier dashboard ──────────────────────────────────
    try:
        from app.routers.supplier_integration import sync_to_supplier
        await sync_to_supplier(
            service_type="hotel",
            customer_name=req.customer_name if hasattr(req, 'customer_name') else "",
            items={
                "check_in": req.check_in,
                "check_out": req.check_out,
                "guests": req.guests,
                "location": req.location,
                "requirements": req.requirements,
                "max_budget": req.max_budget,
            },
            total_amount=float(req.max_budget or 0),
            note=f"호텔 요청: {req.location}, {req.guests}명",
        )
    except Exception as e:
        logger.warning(f"Supplier sync failed: {e}")

    return {"request_id": request_id, "status": "bidding"}

@router.post("/hotel/bid/{request_id}")
async def submit_hotel_bid(request_id: str, bid: HotelBidIn):
    data = _load_hotel_data()
    if request_id not in data["requests"]:
        raise HTTPException(404, "Request not found")
    bid_id = f"hb_{uuid.uuid4().hex[:8]}"
    bid_entry = {**bid.model_dump(), "id": bid_id, "submitted_at": datetime.utcnow().isoformat()}
    data["bids"].setdefault(request_id, []).append(bid_entry)
    _save_hotel_data(data)

    # Notify the requester if connected
    from app.main import connections, hotel_connections
    req = data["requests"][request_id]
    peer_id = req.get("peer_id")
    if peer_id and peer_id in connections:
        try:
            await connections[peer_id].send_text(json.dumps({
                "type": "hotel_bid", "request_id": request_id, "bid": bid_entry
            }))
        except:
            pass

    return {"status": "bid_submitted", "bid_id": bid_id}

@router.get("/hotel/bids/{request_id}")
async def get_hotel_bids(request_id: str):
    data = _load_hotel_data()
    if request_id not in data["requests"]:
        raise HTTPException(404, "Request not found")
    return {
        "request_id": request_id,
        "bids": data["bids"].get(request_id, []),
        "request": data["requests"][request_id]
    }

@router.post("/hotel/select/{request_id}")
async def select_hotel_bid(request_id: str, body: dict):
    hotel_id = body.get("hotel_id")
    data = _load_hotel_data()
    if request_id not in data["requests"]:
        raise HTTPException(404, "Request not found")
    data["requests"][request_id]["status"] = "confirmed"
    data["requests"][request_id]["selected_hotel"] = hotel_id
    _save_hotel_data(data)
    return {"status": "confirmed", "request_id": request_id, "hotel_id": hotel_id}
