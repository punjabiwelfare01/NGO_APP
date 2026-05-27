from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..crud import user_crud
from ..database import get_db
from ..dependencies import admin_only, get_current_user, require_role
from ..models.user import User, UserRole
from ..schemas.user import UserCreate, UserResponse, UserStats, UserUpdate, XPAdd

router = APIRouter(prefix="/users", tags=["Users"])

# ── helpers ────────────────────────────────────────────────────────────────────

def _assert_self_or_admin(current_user: User, target_id: int) -> None:
    """Raise 403 if the caller is neither the target user nor an admin/super_admin."""
    if current_user.id != target_id and current_user.role not in (
        UserRole.admin, UserRole.super_admin
    ):
        raise HTTPException(status_code=403, detail="Access denied")


# ── routes ─────────────────────────────────────────────────────────────────────

@router.get("/", response_model=list[UserResponse],
            summary="List all users [admin only]")
def list_users(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    _: User = Depends(admin_only),
):
    return user_crud.get_users(db, skip=skip, limit=limit)


@router.post("/", response_model=UserResponse, status_code=201,
             summary="Create a user without a password [admin only]")
def create_user(
    payload: UserCreate,
    db: Session = Depends(get_db),
    _: User = Depends(admin_only),
):
    return user_crud.create_user(db, payload)


@router.get("/{user_id}", response_model=UserResponse,
            summary="Get a user profile [self or admin]")
def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _assert_self_or_admin(current_user, user_id)
    user = user_crud.get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.patch("/{user_id}", response_model=UserResponse,
              summary="Update a user profile [self or admin]")
def update_user(
    user_id: int,
    payload: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _assert_self_or_admin(current_user, user_id)
    user = user_crud.update_user(db, user_id, payload)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.post("/{user_id}/xp", response_model=UserResponse,
             summary="Award XP to a user [admin / mentor]")
def add_xp(
    user_id: int,
    payload: XPAdd,
    db: Session = Depends(get_db),
    _: User = Depends(require_role(UserRole.admin, UserRole.super_admin, UserRole.mentor)),
):
    user = user_crud.add_xp(db, user_id, payload.amount)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.get("/{user_id}/stats", response_model=UserStats,
            summary="Get learning stats [self, mentor, or admin]")
def get_stats(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(
        UserRole.student, UserRole.mentor, UserRole.admin, UserRole.super_admin,
        UserRole.content_creator,
    )),
):
    _assert_self_or_admin(current_user, user_id)
    stats = user_crud.get_user_stats(db, user_id)
    if not stats:
        raise HTTPException(status_code=404, detail="User not found")
    return stats
