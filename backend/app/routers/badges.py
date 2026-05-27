from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..crud import badge_crud
from ..database import get_db
from ..dependencies import get_current_user, require_role
from ..models.user import User, UserRole
from ..schemas.badge import BadgeResponse, UserBadgeResponse

router = APIRouter(tags=["Badges"])


@router.get("/badges", response_model=list[BadgeResponse],
            summary="List all available badges [public]")
def list_badges(db: Session = Depends(get_db)):
    return badge_crud.get_badges(db)


@router.get("/users/{user_id}/badges", response_model=list[UserBadgeResponse],
            summary="Get a user's earned badges [self, mentor, admin]")
def get_user_badges(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.id != user_id and current_user.role not in (
        UserRole.mentor, UserRole.admin, UserRole.super_admin
    ):
        raise HTTPException(status_code=403, detail="Access denied")
    return badge_crud.get_user_badges(db, user_id)


@router.post("/users/{user_id}/badges/{badge_id}",
             response_model=UserBadgeResponse, status_code=201,
             summary="Award a badge to a user [mentor, admin]")
def award_badge(
    user_id: int,
    badge_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_role(UserRole.mentor, UserRole.admin, UserRole.super_admin)),
):
    badge = badge_crud.get_badge(db, badge_id)
    if not badge:
        raise HTTPException(status_code=404, detail="Badge not found")
    return badge_crud.award_badge(db, user_id, badge_id)
