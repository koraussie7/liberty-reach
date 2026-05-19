"""Supplier Dashboard Integration — syncs service requests to supplier_orders + WebSocket broadcast.

When a customer creates a hotel/food/massage request, this module:
  1. Inserts a corresponding row into supplier_orders (SQLite)
  2. Broadcasts a real-time 'new_order' event to all connected supplier dashboard clients
"""

import json
import logging
import sqlite3
import uuid
from datetime import datetime
from typing import Optional

logger = logging.getLogger("supplier_integration")

SUPPLIER_DB = "/root/liberty-web/supplier.db"


def _get_db():
    conn = sqlite3.connect(SUPPLIER_DB)
    conn.row_factory = sqlite3.Row
    return conn


async def sync_to_supplier(
    service_type: str,
    customer_name: str = "",
    customer_phone: str = "",
    items: dict = None,
    total_amount: float = 0,
    note: str = "",
    supplier_id: str = "",
) -> dict:
    """Create a supplier_order record and broadcast it to all dashboard WebSocket clients.

    Returns the created order dict.
    """
    oid = f"syn_{uuid.uuid4().hex[:12]}"
    now = datetime.utcnow().isoformat()
    items_json = json.dumps(items or {}, ensure_ascii=False)

    conn = _get_db()
    conn.execute(
        """INSERT INTO supplier_orders
           (id, supplier_id, service_type, customer_name, customer_phone,
            items, total_amount, status, note, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', ?, ?)""",
        (oid, supplier_id, service_type, customer_name, customer_phone,
         items_json, total_amount, note, now)
    )
    conn.commit()
    row = conn.execute("SELECT * FROM supplier_orders WHERE id=?", (oid,)).fetchone()
    conn.close()

    if not row:
        logger.error(f"Failed to create supplier_order for {service_type}")
        return {}

    result = dict(row)
    logger.info(f"Supplier order synced: {oid} ({service_type})")

    # Broadcast to all connected supplier dashboard clients
    await _broadcast_supplier_event("new_order", {"order": result, "source": service_type})
    return result


async def _broadcast_supplier_event(event_type: str, data: dict):
    """Send real-time event to all connected supplier dashboard WebSocket clients."""
    from app.main import supplier_connections

    payload = json.dumps({"type": event_type, **data}, ensure_ascii=False, default=str)
    dead = []
    for cid, ws in list(supplier_connections.copy().items()):
        try:
            await ws.send_text(payload)
        except Exception:
            dead.append(cid)
    for cid in dead:
        supplier_connections.pop(cid, None)
        logger.debug(f"Removed dead supplier connection: {cid}")
