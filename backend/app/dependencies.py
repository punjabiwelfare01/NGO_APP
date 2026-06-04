"""
FastAPI dependency factories for authentication and role-based access control.

Usage in routers:
  # Any authenticated user:
  current_user: User = Depends(get_current_user)

  # Specific roles only:
  _: User = Depends(require_role(UserRole.admin, UserRole.super_admin))

  # Self or admin (inline ownership check):
  if current_user.id != target_id and not current_user.role.value in ("admin","super_admin"):
      raise HTTPException(403, "Access denied")
"""

from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError
from sqlalchemy.orm import Session

from .crud.auth_crud import decode_token, is_token_revoked
from .database import get_db
from .models.user import User, UserRole

_bearer = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(get_db),
) -> User:
    """Validate JWT, check blacklist, return the authenticated User (raises 401 otherwise)."""
    if not credentials:
        raise HTTPException(status_code=401, detail="Not authenticated")
    try:
        payload  = decode_token(credentials.credentials)
        user_id  = int(payload["sub"])
        jti      = payload.get("jti", "")
    except (JWTError, KeyError, ValueError):
        raise HTTPException(status_code=401, detail="Invalid or expired token")

    if is_token_revoked(db, jti):
        raise HTTPException(status_code=401, detail="Token has been revoked — please log in again")

    user = db.query(User).filter(User.id == user_id, User.is_active.is_(True)).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found or account inactive")
    return user


def get_optional_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(get_db),
) -> User | None:
    """Like get_current_user but returns None when unauthenticated (for semi-public endpoints)."""
    if not credentials:
        return None
    try:
        payload  = decode_token(credentials.credentials)
        user_id  = int(payload["sub"])
        jti      = payload.get("jti", "")
    except Exception:
        return None
    if is_token_revoked(db, jti):
        return None
    return db.query(User).filter(User.id == user_id, User.is_active.is_(True)).first()


def require_role(*allowed: UserRole):
    """
    Dependency factory that enforces role membership.
    Returns a dependency that raises HTTP 403 when the caller's role is not in `allowed`.
    """
    def _guard(current_user: User = Depends(get_current_user)) -> User:
        management_roles = {
            UserRole.admin,
            UserRole.super_admin,
            UserRole.mentor,
            UserRole.content_creator,
        }
        if current_user.role == UserRole.super_admin:
            return current_user
        if (
            current_user.role == UserRole.admin
            and any(role in management_roles for role in allowed)
        ):
            return current_user
        if current_user.role not in allowed:
            raise HTTPException(
                status_code=403,
                detail=f"Access denied. Required role(s): {[r.value for r in allowed]}",
            )
        return current_user
    return _guard


# ── convenience aliases ───────────────────────────────────────────────────────

def admin_only(current_user: User = Depends(require_role(UserRole.admin, UserRole.super_admin))) -> User:
    return current_user

def mentor_or_above(current_user: User = Depends(
    require_role(UserRole.mentor, UserRole.admin, UserRole.super_admin)
)) -> User:
    return current_user

def content_creator_or_above(current_user: User = Depends(
    require_role(UserRole.content_creator, UserRole.mentor, UserRole.admin, UserRole.super_admin)
)) -> User:
    return current_user

def non_student(current_user: User = Depends(
    require_role(UserRole.content_creator, UserRole.mentor, UserRole.admin, UserRole.super_admin)
)) -> User:
    return current_user
