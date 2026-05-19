"""
Social login API routes.

POST /auth/social-login
POST /auth/refresh
GET  /auth/me
"""
import logging

from fastapi import APIRouter, HTTPException, Depends, status

from app.auth.auth_handler import (
    create_access_token,
    decode_access_token,
    verify_firebase_id_token,
    verify_dev_token,
)
from app.auth.dependencies import get_current_user
import hashlib, secrets, sqlite3, os
from datetime import datetime, timezone

log = logging.getLogger("dada.auth")

router = APIRouter(prefix="/auth", tags=["auth"])


# ── Models ─────────────────────────────────────────────────────────────
from pydantic import BaseModel


class SocialLoginRequest(BaseModel):
    provider: str  # "kakao" | "apple" | "google" | "facebook" | "zalo" | "wechat"
    id_token: str
    access_token: str | None = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: dict


class RefreshRequest(BaseModel):
    access_token: str


class UserResponse(BaseModel):
    uid: str
    email: str | None = None
    name: str | None = None
    picture: str | None = None
    provider: str | None = None


# ── Routes ─────────────────────────────────────────────────────────────


@router.post("/social-login", response_model=TokenResponse)
async def social_login(req: SocialLoginRequest):
    """Exchange a social ID token for a DADA-AI JWT.

    The Flutter app authenticates with the social SDK (Kakao/Apple/Google/Facebook)
    and sends the resulting ID token here. We verify it via Firebase Admin SDK
    (or dev-mode fallback) and issue our own JWT.
    """
    # 1. Verify the social token
    user_info = await verify_firebase_id_token(req.id_token)

    if user_info is None:
        # Dev-mode fallback (no Firebase configured)
        user_info = await verify_dev_token(req.provider, req.id_token)

    if user_info is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid {req.provider} token",
        )

    # 2. Create our JWT
    uid = user_info["uid"]
    access_token = create_access_token(
        user_id=uid,
        provider=req.provider,
        extra={
            "name": user_info.get("name"),
            "email": user_info.get("email"),
            "picture": user_info.get("picture"),
        },
    )

    return TokenResponse(
        access_token=access_token,
        user={
            "uid": uid,
            "email": user_info.get("email"),
            "name": user_info.get("name"),
            "picture": user_info.get("picture"),
            "provider": req.provider,
        },
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(req: RefreshRequest):
    """Refresh an expiring JWT."""
    payload = decode_access_token(req.access_token)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )
    new_token = create_access_token(
        user_id=payload["sub"],
        provider=payload.get("provider", "unknown"),
        extra={
            "name": payload.get("name"),
            "email": payload.get("email"),
            "picture": payload.get("picture"),
        },
    )
    return TokenResponse(
        access_token=new_token,
        user={
            "uid": payload["sub"],
            "email": payload.get("email"),
            "name": payload.get("name"),
            "picture": payload.get("picture"),
            "provider": payload.get("provider"),
        },
    )


@router.get("/me", response_model=UserResponse)
async def get_me(user: dict = Depends(get_current_user)):
    """Return the currently authenticated user's profile."""
    return UserResponse(
        uid=user["sub"],
        email=user.get("email"),
        name=user.get("name"),
        picture=user.get("picture"),
        provider=user.get("provider"),
    )


# ── Users DB ───────────────────────────────────────────────────────

USER_DB = os.getenv("USER_DB", "/root/DADA-AI/server/users.db")

def _init_user_db():
    os.makedirs(os.path.dirname(USER_DB) or ".", exist_ok=True)
    conn = sqlite3.connect(USER_DB)
    conn.execute("""CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        display_name TEXT NOT NULL DEFAULT '',
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        vault_id TEXT DEFAULT '',
        vault_name TEXT DEFAULT '',
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
    )""")
    conn.commit()
    conn.close()

_init_user_db()


def _hash_password(password: str, salt: str = "") -> tuple[str, str]:
    if not salt:
        salt = secrets.token_hex(16)
    h = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), 100000)
    return h.hex(), salt


def _get_user_by_email(email: str) -> dict | None:
    conn = sqlite3.connect(USER_DB)
    conn.row_factory = sqlite3.Row
    row = conn.execute("SELECT * FROM users WHERE email = ?", (email,)).fetchone()
    conn.close()
    return dict(row) if row else None


def _get_user_by_uid(uid: str) -> dict | None:
    conn = sqlite3.connect(USER_DB)
    conn.row_factory = sqlite3.Row
    row = conn.execute("SELECT * FROM users WHERE uid = ?", (uid,)).fetchone()
    conn.close()
    return dict(row) if row else None


# ── Models ─────────────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    email: str
    password: str
    display_name: str = ""


class RegisterResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: dict
    vault: dict


# ── Routes ─────────────────────────────────────────────────────────

@router.post("/register", response_model=RegisterResponse)
async def register(req: RegisterRequest):
    """Create a DADA-AI account + auto-create a Vultisig FastVault.

    1. Validate input
    2. Create Vultisig FastVault (server-assisted 2-of-2 MPC)
    3. Store user in DB
    4. Return JWT + wallet addresses
    """
    email = req.email.strip().lower()
    if not email or "@" not in email:
        raise HTTPException(400, "Valid email is required")
    if len(req.password) < 6:
        raise HTTPException(400, "Password must be at least 6 characters")
    if _get_user_by_email(email):
        raise HTTPException(409, "Email already registered")

    display_name = req.display_name.strip() or email.split("@")[0]
    vault_name = f"dada_{email.split('@')[0]}"

    # ── Create Vultisig FastVault ──────────────────────────────────
    try:
        from app.routers.wallet_routes import vultisig as _vultisig

        vault_result = _vultisig(
            "create", "fast",
            "--name", vault_name,
            "--password", req.password,
            "--email", email,
            "--two-step",
            password=req.password,
        )
        vault_data = vault_result.get("data", vault_result)
        vault_id = vault_data.get("id") or vault_data.get("vaultId") or ""
    except Exception as e:
        log.error(f"Vultisig vault creation failed: {e}")
        raise HTTPException(502, f"Wallet creation failed: {str(e)}")

    # ── Store user ─────────────────────────────────────────────────
    pw_hash, salt = _hash_password(req.password)
    uid = f"user_{secrets.token_hex(8)}"

    conn = sqlite3.connect(USER_DB)
    try:
        conn.execute(
            "INSERT INTO users (uid, email, display_name, password_hash, salt, vault_id, vault_name) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (uid, email, display_name, pw_hash, salt, vault_id, vault_name),
        )
        conn.commit()
    except Exception as e:
        log.error(f"DB insert failed: {e}")
        raise HTTPException(500, "Account creation failed")
    finally:
        conn.close()

    # ── Issue JWT ──────────────────────────────────────────────────
    access_token = create_access_token(
        user_id=uid,
        provider="vultisig",
        extra={
            "email": email,
            "name": display_name,
            "vault_id": vault_id,
        },
    )

    # Get wallet addresses
    addresses = {}
    try:
        addr_result = _vultisig("addresses", password=req.password)
        addresses = addr_result.get("data", {}).get("addresses", addr_result)
    except Exception:
        pass

    log.info(f"✅ New user registered: {email} → vault={vault_name}")

    return RegisterResponse(
        access_token=access_token,
        user={
            "uid": uid,
            "email": email,
            "name": display_name,
            "provider": "vultisig",
        },
        vault={
            "id": vault_id,
            "name": vault_name,
            "addresses": addresses if isinstance(addresses, dict) else {},
        },
    )


# ── Wallet Auth ─────────────────────────────────────────────────────


class WalletLoginRequest(BaseModel):
    wallet_address: str
    chain: str = "ethereum"


class WalletLoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: dict


@router.post("/wallet-login", response_model=WalletLoginResponse)
async def wallet_login(req: WalletLoginRequest):
    """Login or register using a wallet address.

    The wallet address becomes the user's unique ID.
    No social login, no password — the wallet IS the identity.
    """
    uid = f"wallet_{req.chain}_{req.wallet_address.lower()}"

    access_token = create_access_token(
        user_id=uid,
        provider=f"wallet:{req.chain}",
        extra={
            "wallet_address": req.wallet_address,
            "chain": req.chain,
            "name": f"Wallet {req.wallet_address[:6]}...{req.wallet_address[-4:]}",
        },
    )

    return WalletLoginResponse(
        access_token=access_token,
        user={
            "uid": uid,
            "wallet_address": req.wallet_address,
            "chain": req.chain,
            "name": f"Wallet {req.wallet_address[:6]}...{req.wallet_address[-4:]}",
            "provider": f"wallet:{req.chain}",
        },
    )
