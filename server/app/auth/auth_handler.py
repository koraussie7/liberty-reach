"""
JWT token handler with Firebase Auth verification.

Architecture:
  Flutter App (Kakao/Apple/Google/Facebook SDK)
       ↓ ID Token
  Our Server (POST /auth/social-login)
       ↓ verify with Firebase Admin SDK
       ↓ issue our JWT
  All subsequent API calls use our JWT (Authorization: Bearer <token>)
"""
import os
import json
import logging
from datetime import datetime, timedelta, timezone
from typing import Optional

from jose import JWTError, jwt
import firebase_admin
from firebase_admin import auth as firebase_auth, credentials

log = logging.getLogger("dada.auth")

# ── Configuration ──────────────────────────────────────────────────────
JWT_SECRET = os.getenv("JWT_SECRET", "dada-ai-jwt-secret-change-in-production")
JWT_ALGORITHM = "HS256"
JWT_EXPIRY_HOURS = 72  # 3 days

FIREBASE_CRED_PATH = os.getenv("FIREBASE_CRED_PATH", "/root/DADA-AI/server/firebase-service-account.json")

# ── Firebase Admin SDK initialisation ──────────────────────────────────
_firebase_app: Optional[firebase_admin.App] = None


def init_firebase() -> bool:
    """Initialise Firebase Admin SDK. Returns True if successful."""
    global _firebase_app
    if _firebase_app is not None:
        return True
    if not os.path.exists(FIREBASE_CRED_PATH):
        log.warning("Firebase credentials not found at %s — Firebase auth disabled.", FIREBASE_CRED_PATH)
        return False
    try:
        cred = credentials.Certificate(FIREBASE_CRED_PATH)
        _firebase_app = firebase_admin.initialize_app(cred)
        log.info("Firebase Admin SDK initialised.")
        return True
    except Exception as e:
        log.error("Failed to initialise Firebase: %s", e)
        return False


# ── JWT helpers ────────────────────────────────────────────────────────


def create_access_token(user_id: str, provider: str, extra: dict | None = None) -> str:
    """Create a signed JWT for the given user."""
    now = datetime.now(timezone.utc)
    payload = {
        "sub": user_id,
        "provider": provider,
        "iat": now,
        "exp": now + timedelta(hours=JWT_EXPIRY_HOURS),
    }
    if extra:
        payload.update(extra)
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def decode_access_token(token: str) -> dict | None:
    """Decode and validate a JWT. Returns payload dict or None."""
    try:
        # Explicitly verify algorithm to prevent "none" algorithm attack
        headers = jwt.get_unverified_header(token)
        if headers.get("alg") != JWT_ALGORITHM:
            log.warning("JWT algorithm mismatch: expected %s, got %s", JWT_ALGORITHM, headers.get("alg"))
            return None
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        return payload
    except JWTError as e:
        log.warning("JWT decode failed: %s", e)
        return None


# ── Firebase ID token verification ─────────────────────────────────────


async def verify_firebase_id_token(id_token: str) -> dict | None:
    """Verify a Firebase ID token and return user info dict.

    Returns None if verification fails.
    """
    if not init_firebase():
        log.error("Firebase not available — cannot verify ID token.")
        return None
    try:
        decoded = firebase_auth.verify_id_token(id_token, app=_firebase_app)
        return {
            "uid": decoded.get("uid"),
            "email": decoded.get("email"),
            "name": decoded.get("name"),
            "picture": decoded.get("picture"),
            "phone_number": decoded.get("phone_number"),
            "firebase": decoded,
        }
    except Exception as e:
        log.warning("Firebase token verification failed: %s", e)
        return None


# ── Dev-mode: manual social token verification (no Firebase) ───────────
# These are simplified verifiers used when Firebase is not configured.
# In production, these checks happen on the Firebase side.

DEV_TOKENS = {
    "kakao": {"iss": "kakao.com", "provider": "kakao"},
    "google": {"iss": "accounts.google.com", "provider": "google"},
    "apple": {"iss": "appleid.apple.com", "provider": "apple"},
    "facebook": {"iss": "facebook.com", "provider": "facebook"},
}


async def verify_dev_token(provider: str, access_token: str) -> dict | None:
    """Dev-mode token verification — accepts any token for testing.

    In production, Firebase handles this for all providers uniformly.
    """
    if provider not in DEV_TOKENS:
        return None
    return {
        "uid": f"{provider}_{access_token[:16]}",
        "email": f"user@{provider}.com",
        "name": f"User ({provider.title()})",
        "picture": None,
        "phone_number": None,
        "provider": provider,
    }
