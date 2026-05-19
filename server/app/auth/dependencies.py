"""FastAPI dependency injection for auth-protected routes."""
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.auth.auth_handler import decode_access_token

security = HTTPBearer(auto_error=False)


async def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
) -> dict | None:
    """Return user info if a valid JWT is provided, otherwise None.

    Use this for routes where auth is optional (browsing, chat).
    """
    if credentials is None:
        return None
    payload = decode_access_token(credentials.credentials)
    return payload


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """Require a valid JWT. Returns user payload.

    Raises 401 if token is missing or invalid.
    Use this for protected routes (payment, booking, profile).
    """
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
            headers={"WWW-Authenticate": "Bearer"},
        )
    payload = decode_access_token(credentials.credentials)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return payload


# Shorthand type alias for route signatures
User = Optional[dict]  # optional user
AuthUser = dict        # authenticated user
