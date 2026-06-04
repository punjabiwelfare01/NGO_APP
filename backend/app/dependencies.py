"""
FastAPI dependency factories for authentication and role-based access control.

Role hierarchy (lowest → highest):
  guest(0) → student(1) → content_creator(2) → mentor(3) → admin(4) → super_admin(5)

require_role() uses this hierarchy: a user at level N satisfies any requirement
whose minimum level is ≤ N. Example: require_role(mentor) grants access to
mentor, admin, and super_admin — but not to content_creator or student.

Usage in routers:
  # Any authenticated user:
  current_user: User = Depends(get_current_user)

  # Minimum role (with inheritance):
  _: User = Depends(require_role(UserRole.mentor))

  # Named permission check:
  _: User = Depends(require_permission(Permission.MANAGE_USERS))

  # Self or admin (inline ownership check):
  if current_user.id != target_id and current_user.role not in (
      UserRole.admin, UserRole.super_admin
  ):
      raise HTTPException(403, "Access denied")
"""

from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError
from sqlalchemy.orm import Session

from .crud.auth_crud import decode_token, is_token_revoked
from .database import get_db
from .models.user import User, UserRole
from .permissions import ROLE_HIERARCHY, ROLE_PERMISSIONS, Permission

_bearer = HTTPBearer(auto_error=False)


# ── authentication ─────────────────────────────────────────────────────────────

def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(get_db),
) -> User:
    """Validate JWT, check blacklist, return the authenticated User (raises 401 otherwise)."""
    if not credentials:
        raise HTTPException(status_code=401, detail="Not authenticated")
    try:
        payload = decode_token(credentials.credentials)
        user_id = int(payload["sub"])
        jti     = payload.get("jti", "")
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
        payload = decode_token(credentials.credentials)
        user_id = int(payload["sub"])
        jti     = payload.get("jti", "")
    except Exception:
        return None
    if is_token_revoked(db, jti):
        return None
    return db.query(User).filter(User.id == user_id, User.is_active.is_(True)).first()


# ── role helpers ───────────────────────────────────────────────────────────────

def _role_level(role: UserRole) -> int:
    """Return the privilege level of a role (higher = more privileged)."""
    try:
        return ROLE_HIERARCHY.index(role)
    except ValueError:
        return -1


# ── dependency factories ───────────────────────────────────────────────────────

def require_role(*allowed: UserRole):
    """
    Dependency factory that enforces role-based access with hierarchy inheritance.

    The minimum level among `allowed` roles is computed. Any caller whose role
    sits at or above that level is granted access. This means require_role(mentor)
    also admits admin and super_admin without listing them explicitly.

    Raises HTTP 403 when the caller's role is below the minimum required level.
    """
    if not allowed:
        raise ValueError("require_role() called with no roles")

    min_level = min(_role_level(r) for r in allowed)

    def _guard(current_user: User = Depends(get_current_user)) -> User:
        if _role_level(current_user.role) >= min_level:
            return current_user
        raise HTTPException(
            status_code=403,
            detail=f"Access denied. Required role(s): {[r.value for r in allowed]}",
        )
    return _guard


def require_permission(permission: Permission):
    """
    Dependency factory that enforces a named permission.

    Checks ROLE_PERMISSIONS for the caller's role. Use this for fine-grained
    checks that go beyond simple hierarchy (e.g., VIEW_ANALYTICS which is
    granted to mentor+ but not to content_creator even though cc < mentor).
    """
    def _guard(current_user: User = Depends(get_current_user)) -> User:
        if permission in ROLE_PERMISSIONS.get(current_user.role, frozenset()):
            return current_user
        raise HTTPException(
            status_code=403,
            detail=f"Access denied. Required permission: {permission.value}",
        )
    return _guard


# ── convenience aliases ────────────────────────────────────────────────────────

def admin_only(
    current_user: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
) -> User:
    return current_user


def mentor_or_above(
    current_user: User = Depends(
        require_role(UserRole.mentor, UserRole.admin, UserRole.super_admin)
    ),
) -> User:
    return current_user


def content_creator_or_above(
    current_user: User = Depends(
        require_role(UserRole.content_creator, UserRole.mentor, UserRole.admin, UserRole.super_admin)
    ),
) -> User:
    return current_user


def non_student(
    current_user: User = Depends(
        require_role(UserRole.content_creator, UserRole.mentor, UserRole.admin, UserRole.super_admin)
    ),
) -> User:
    return current_user
