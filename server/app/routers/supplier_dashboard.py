"""Supplier Dashboard Router — Riverpod 3.0 backend API.
Provides endpoints for the supplier/provider dashboard:
  - GET  /supplier/stats         → summary statistics
  - GET  /supplier/orders        → filtered order list
  - POST /supplier/order         → create new order
  - POST /supplier/order/status  → update order status
  - GET  /supplier/service-types → available service categories

WebSocket integration:
  - Broadcasts real-time events to /ws clients registered as 'supplier_register'
  - Events: new_order, order_status_changed
"""

import os
import json
import uuid
import sqlite3
import logging
from datetime import datetime
from typing import Optional

from fastapi import APIRouter
from pydantic import BaseModel

logger = logging.getLogger("supplier_dashboard")

router = APIRouter(tags=["supplier"])

# ── DB Setup ────────────────────────────────────────────────────────

SUPPLIER_DB = os.getenv("SUPPLIER_DB", "/root/liberty-web/supplier.db")


def _get_db():
    conn = sqlite3.connect(SUPPLIER_DB)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    conn = _get_db()
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS supplier_accounts (
            id TEXT PRIMARY KEY, name TEXT NOT NULL, service_type TEXT NOT NULL,
            email TEXT, phone TEXT, is_active INTEGER DEFAULT 1,
            created_at TEXT DEFAULT (datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS supplier_orders (
            id TEXT PRIMARY KEY, supplier_id TEXT DEFAULT '',
            service_type TEXT NOT NULL,
            customer_name TEXT NOT NULL DEFAULT '',
            customer_phone TEXT DEFAULT '',
            items TEXT DEFAULT '{}', total_amount REAL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'pending',
            note TEXT DEFAULT '',
            created_at TEXT DEFAULT (datetime('now')),
            confirmed_at TEXT, completed_at TEXT
        );
    """)
    conn.commit()
    conn.close()
    logger.info(f"Supplier DB initialized: {SUPPLIER_DB}")


init_db()


# ── WebSocket Broadcast Helper ──────────────────────────────────────

async def broadcast_supplier_event(event_type: str, data: dict):
    """Send real-time event to all connected supplier dashboard clients."""
    from app.main import supplier_connections
    import json as json_mod
    payload = json_mod.dumps({"type": event_type, **data})
    dead = []
    for cid, ws in supplier_connections.copy().items():
        try:
            await ws.send_text(payload)
        except Exception:
            dead.append(cid)
    for cid in dead:
        supplier_connections.pop(cid, None)


# ── Models ───────────────────────────────────────────────────────────

class SupplierOrderCreate(BaseModel):
    supplier_id: str = ""
    service_type: str
    customer_name: str = ""
    customer_phone: str = ""
    items: dict = {}
    total_amount: float = 0
    note: str = ""


class SupplierStatusUpdate(BaseModel):
    order_id: str
    status: str  # pending, confirmed, preparing, completed, cancelled


ORDER_COLUMNS = [
    "id", "supplier_id", "service_type", "customer_name", "customer_phone",
    "items", "total_amount", "status", "note", "created_at",
    "confirmed_at", "completed_at",
]


def _row_to_dict(row: sqlite3.Row) -> dict:
    return {col: row[col] for col in ORDER_COLUMNS if col in row.keys()}


# ── Endpoints ────────────────────────────────────────────────────────

@router.get("/supplier/stats")
async def get_supplier_stats():
    """Dashboard summary stats — Riverpod DashboardSummary pattern."""
    conn = _get_db()
    total = conn.execute("SELECT COUNT(*) as c FROM supplier_orders").fetchone()["c"]
    pending = conn.execute("SELECT COUNT(*) as c FROM supplier_orders WHERE status='pending'").fetchone()["c"]
    confirmed = conn.execute("SELECT COUNT(*) as c FROM supplier_orders WHERE status='confirmed'").fetchone()["c"]
    completed = conn.execute("SELECT COUNT(*) as c FROM supplier_orders WHERE status='completed'").fetchone()["c"]
    revenue = conn.execute(
        "SELECT COALESCE(SUM(total_amount),0) as r FROM supplier_orders WHERE status='completed'"
    ).fetchone()["r"]
    today = conn.execute(
        "SELECT COALESCE(SUM(total_amount),0) as r, COUNT(*) as c "
        "FROM supplier_orders WHERE date(created_at)=date('now')"
    ).fetchone()
    by_svc = conn.execute(
        "SELECT service_type, COUNT(*) as cnt FROM supplier_orders GROUP BY service_type"
    ).fetchall()
    conn.close()

    return {
        "total_orders": total, "pending": pending, "confirmed": confirmed,
        "completed": completed, "total_revenue": float(revenue),
        "today_revenue": float(today["r"]), "today_orders": today["c"],
        "by_service": {r["service_type"]: r["cnt"] for r in by_svc},
    }


@router.get("/supplier/orders")
async def get_supplier_orders(status: str = "", service_type: str = ""):
    """Get all orders — Riverpod FutureProvider.family pattern."""
    conn = _get_db()
    query = "SELECT * FROM supplier_orders WHERE 1=1"
    params: list = []
    if status:
        query += " AND status=?"
        params.append(status)
    if service_type:
        query += " AND service_type=?"
        params.append(service_type)
    query += " ORDER BY created_at DESC LIMIT 100"
    rows = conn.execute(query, params).fetchall()
    conn.close()
    return [_row_to_dict(r) for r in rows]


@router.post("/supplier/order")
async def create_supplier_order(order: SupplierOrderCreate):
    """Create a new customer → supplier order."""
    oid = uuid.uuid4().hex[:12]
    conn = _get_db()
    conn.execute(
        """INSERT INTO supplier_orders
           (id, supplier_id, service_type, customer_name, customer_phone,
            items, total_amount, status, note)
           VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', ?)""",
        (oid, order.supplier_id, order.service_type,
         order.customer_name, order.customer_phone,
         json.dumps(order.items), order.total_amount, order.note)
    )
    conn.commit()
    row = conn.execute("SELECT * FROM supplier_orders WHERE id=?", (oid,)).fetchone()
    conn.close()
    result = _row_to_dict(row)
    logger.info(f"Supplier order created: {oid} ({order.service_type})")
    # Broadcast real-time event to supplier dashboards
    await broadcast_supplier_event("new_order", {"order": result})
    return result


@router.post("/supplier/order/status")
async def update_order_status(update: SupplierStatusUpdate):
    """Supplier confirms, prepares, or completes an order."""
    now = datetime.utcnow().isoformat()
    conn = _get_db()
    ts_field = ""
    ALLOWED_TS_FIELDS = {"confirmed_at", "completed_at"}
    if update.status in ("confirmed", "completed"):
        candidate = f"{update.status}_at"
        ts_field = candidate if candidate in ALLOWED_TS_FIELDS else ""
    if ts_field:
        conn.execute(
            f"UPDATE supplier_orders SET status=?, {ts_field}=? WHERE id=?",
            (update.status, now, update.order_id)
        )
    else:
        conn.execute(
            "UPDATE supplier_orders SET status=? WHERE id=?",
            (update.status, update.order_id)
        )
    conn.commit()
    row = conn.execute("SELECT * FROM supplier_orders WHERE id=?", (update.order_id,)).fetchone()
    conn.close()
    if not row:
        return {"error": "Order not found"}
    result = _row_to_dict(row)
    logger.info(f"Supplier order {update.order_id} → {update.status}")
    # Broadcast real-time event to supplier dashboards
    await broadcast_supplier_event("order_status_changed", {"order": result})
    return result


@router.get("/supplier/service-types")
async def get_service_types():
    """Available service categories for the dashboard tabs."""
    return {"services": [
        {"id": "hotel", "name": "호텔", "icon": "hotel"},
        {"id": "food", "name": "배달", "icon": "delivery_dining"},
        {"id": "massage", "name": "마사지", "icon": "spa"},
        {"id": "taxi", "name": "택시", "icon": "local_taxi"},
    ]}
