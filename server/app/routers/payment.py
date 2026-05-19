"""Unified Payment API — Stripe (real money) + DADA Point (internal token)."""
import os
import json
import logging
import sqlite3
from typing import Optional
from datetime import datetime

import stripe
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.routers.platform_routes import LEADERBOARD_DB, record_points

log = logging.getLogger("dada.payment")

stripe.api_key = os.getenv("STRIPE_SECRET_KEY", "")

router = APIRouter(prefix="/payment", tags=["Payment"])

# ── Models ──────────────────────────────────────────────────────
class PaymentRequest(BaseModel):
    amount: int                  # DADA Point or fiat amount (KRW cents for Stripe)
    currency: str = "krw"        # krw, usd
    payment_method: str          # "stripe" or "dada_point"
    product_id: str = ""
    user_id: str
    description: Optional[str] = None

class PaymentResponse(BaseModel):
    status: str
    payment_method: str
    message: str
    checkout_url: Optional[str] = None
    transaction_id: Optional[str] = None

# ── DB helpers ──────────────────────────────────────────────────
TXN_DB = os.getenv("TXN_DB", "/root/DADA-AI/transactions.db")

def _init_txn_db():
    os.makedirs(os.path.dirname(TXN_DB) or ".", exist_ok=True)
    conn = sqlite3.connect(TXN_DB)
    conn.execute("""CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        product_id TEXT DEFAULT '',
        amount INTEGER NOT NULL,
        currency TEXT DEFAULT 'krw',
        payment_method TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'completed',
        description TEXT,
        stripe_session_id TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
    )""")
    conn.commit()
    conn.close()

_init_txn_db()

def _record_txn(user_id: str, product_id: str, amount: int, currency: str,
                method: str, status: str = "completed", desc: str = "",
                session_id: str = "") -> int:
    conn = sqlite3.connect(TXN_DB)
    cur = conn.execute(
        "INSERT INTO transactions (user_id, product_id, amount, currency, payment_method, status, description, stripe_session_id) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        (user_id, product_id, amount, currency, method, status, desc, session_id),
    )
    txn_id = cur.lastrowid
    conn.commit()
    conn.close()
    return txn_id

def _get_user_points(user_id: str) -> int:
    """Get total DADA Points for a user from the leaderboard DB."""
    conn = sqlite3.connect(LEADERBOARD_DB)
    row = conn.execute(
        "SELECT COALESCE(SUM(points), 0) FROM user_points WHERE user_id = ?",
        (user_id,),
    ).fetchone()
    conn.close()
    return row[0] if row else 0

def _deduct_points(user_id: str, amount: int) -> bool:
    """Deduct DADA Points by recording a negative transaction."""
    current = _get_user_points(user_id)
    if current < amount:
        return False
    # Record negative points (debit)
    record_points(user_id, f"User_{user_id[:8]}" if user_id else "User", -amount, f"payment_debit:{user_id}")
    return True

# ── Endpoints ───────────────────────────────────────────────────

@router.post("/create", response_model=PaymentResponse)
async def create_payment(req: PaymentRequest):
    """Create a payment using either DADA Point or Stripe."""

    if req.amount <= 0:
        raise HTTPException(400, "Invalid amount")

    if req.payment_method == "dada_point":
        # ── DADA Point 결제 ──────────────────────────────────────
        if not _deduct_points(req.user_id, req.amount):
            raise HTTPException(400, "DADA Point 부족 — 보유 포인트를 확인해주세요.")

        txn_id = _record_txn(
            user_id=req.user_id,
            product_id=req.product_id,
            amount=req.amount,
            currency="point",
            method="dada_point",
            desc=req.description or "",
        )

        log.info(f"✅ DADA Point 결제 완료: user={req.user_id}, amount={req.amount}, txn={txn_id}")
        return PaymentResponse(
            status="success",
            payment_method="dada_point",
            message=f"{req.amount} DADA Point 결제 완료",
            transaction_id=str(txn_id),
        )

    elif req.payment_method == "stripe":
        # ── Stripe 카드 결제 ──────────────────────────────────────
        if not stripe.api_key or stripe.api_key.startswith("sk_test_dummy"):
            raise HTTPException(503, "Stripe not configured — set STRIPE_SECRET_KEY")

        try:
            session = stripe.checkout.Session.create(
                payment_method_types=["card"],
                line_items=[{
                    "price_data": {
                        "currency": req.currency,
                        "product_data": {
                            "name": req.description or "DADA-AI 상품",
                        },
                        "unit_amount": req.amount,  # cents for KRW/USD
                    },
                    "quantity": 1,
                }],
                mode="payment",
                success_url=os.getenv("BASE_URL", "https://privseai.com") + "/payment/success",
                cancel_url=os.getenv("BASE_URL", "https://privseai.com") + "/payment/cancel",
                metadata={
                    "user_id": req.user_id,
                    "product_id": req.product_id,
                    "payment_type": "product",
                },
            )
        except stripe.error.StripeError as e:
            log.error(f"Stripe error: {e}")
            raise HTTPException(502, f"Stripe error: {e.user_message or str(e)}")

        # Record pending transaction
        _record_txn(
            user_id=req.user_id,
            product_id=req.product_id,
            amount=req.amount,
            currency=req.currency,
            method="stripe",
            status="pending",
            desc=req.description or "",
            session_id=session.id,
        )

        return PaymentResponse(
            status="success",
            payment_method="stripe",
            message="Stripe 결제 페이지로 이동합니다.",
            checkout_url=session.url,
        )

    elif req.payment_method == "crypto":
        # ── Stablecoin (USDC) 결제 ────────────────────────────────
        if not stripe.api_key or stripe.api_key.startswith("sk_test_dummy"):
            raise HTTPException(503, "Stripe not configured — set STRIPE_SECRET_KEY")

        try:
            session = stripe.checkout.Session.create(
                payment_method_types=["crypto"],
                line_items=[{
                    "price_data": {
                        "currency": req.currency,
                        "product_data": {
                            "name": req.description or "DADA-AI 상품",
                        },
                        "unit_amount": req.amount,
                    },
                    "quantity": 1,
                }],
                mode="payment",
                success_url=os.getenv("BASE_URL", "https://privseai.com") + "/payment/success",
                cancel_url=os.getenv("BASE_URL", "https://privseai.com") + "/payment/cancel",
                metadata={
                    "user_id": req.user_id,
                    "product_id": req.product_id,
                    "payment_type": "product",
                },
            )
        except stripe.error.StripeError as e:
            log.error(f"Stripe crypto error: {e}")
            raise HTTPException(502, f"Crypto payment error: {e.user_message or str(e)}")

        # Record pending transaction
        _record_txn(
            user_id=req.user_id,
            product_id=req.product_id,
            amount=req.amount,
            currency=req.currency,
            method="crypto",
            status="pending",
            desc=req.description or "",
            session_id=session.id,
        )

        return PaymentResponse(
            status="success",
            payment_method="crypto",
            message="USDC 결제 페이지로 이동합니다. Phantom/MetaMask 등으로 결제하세요.",
            checkout_url=session.url,
        )

    else:
        raise HTTPException(400, f"Invalid payment method: {req.payment_method}")


@router.get("/methods")
async def get_payment_methods(user_id: str):
    """Return available payment methods and DADA Point balance."""
    balance = _get_user_points(user_id) if user_id else 0
    return {
        "methods": [
            {
                "id": "dada_point",
                "name": "DADA Point",
                "description": "보유 포인트로 결제",
                "balance": balance,
                "available": balance > 0,
            },
            {
                "id": "stripe",
                "name": "신용카드 (Stripe)",
                "description": "안전한 카드 결제",
                "available": True,
            },
            {
                "id": "crypto",
                "name": "USDC (Stablecoin)",
                "description": "Phantom/MetaMask 등으로 USDC 결제",
                "available": True,
            },
        ],
        "default": "dada_point" if balance > 0 else "stripe",
    }


@router.get("/history")
async def get_payment_history(user_id: str, limit: int = 50):
    """Return payment history for a user."""
    conn = sqlite3.connect(TXN_DB)
    rows = conn.execute(
        "SELECT id, user_id, product_id, amount, currency, payment_method, status, description, created_at "
        "FROM transactions WHERE user_id = ? ORDER BY created_at DESC LIMIT ?",
        (user_id, limit),
    ).fetchall()
    conn.close()

    return {
        "transactions": [
            {
                "id": r[0], "user_id": r[1], "product_id": r[2],
                "amount": r[3], "currency": r[4],
                "payment_method": r[5], "status": r[6],
                "description": r[7], "created_at": r[8],
            }
            for r in rows
        ]
    }
