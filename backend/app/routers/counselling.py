from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..crud import counselling_crud
from ..database import get_db
from ..dependencies import admin_only, get_current_user, mentor_or_above, require_role
from ..models.user import User, UserRole
from ..schemas.counselling import (
    CounsellingAnalyticsResponse,
    MentorProfileCreate,
    MentorProfileResponse,
    MentorProfileUpdate,
)
from ..schemas.wellness import CounsellingSlotResponse

router = APIRouter(prefix="/counselling", tags=["Counselling"])


# ── Mentor Profiles ────────────────────────────────────────────────────────────

@router.get("/mentors", response_model=list[MentorProfileResponse],
            summary="List active mentor profiles [authenticated]")
def list_mentors(
    category: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return counselling_crud.list_mentors(db, category=category)


@router.get("/mentors/{mentor_id}", response_model=MentorProfileResponse,
            summary="Get mentor profile detail [authenticated]")
def get_mentor(
    mentor_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    profile = counselling_crud.get_mentor(db, mentor_id)
    if not profile:
        raise HTTPException(status_code=404, detail="Mentor profile not found")
    return profile


@router.post("/mentors", response_model=MentorProfileResponse, status_code=201,
             summary="Create mentor profile [admin only]")
def create_mentor_profile(
    payload: MentorProfileCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(admin_only),
):
    # Payload must target a user; use current_user.id or allow specifying user_id
    existing = counselling_crud.get_mentor_by_user(db, current_user.id)
    if existing:
        raise HTTPException(status_code=409, detail="Mentor profile already exists for this user")
    return counselling_crud.create_mentor_profile(db, current_user.id, payload)


@router.post("/mentors/for-user/{user_id}", response_model=MentorProfileResponse, status_code=201,
             summary="Create mentor profile for a specific user [admin only]")
def create_mentor_profile_for_user(
    user_id: int,
    payload: MentorProfileCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(admin_only),
):
    existing = counselling_crud.get_mentor_by_user(db, user_id)
    if existing:
        raise HTTPException(status_code=409, detail="Mentor profile already exists for this user")
    return counselling_crud.create_mentor_profile(db, user_id, payload)


@router.patch("/mentors/{mentor_id}", response_model=MentorProfileResponse,
              summary="Update mentor profile [admin or the mentor themselves]")
def update_mentor_profile(
    mentor_id: int,
    payload: MentorProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    profile = counselling_crud.get_mentor(db, mentor_id)
    if not profile:
        raise HTTPException(status_code=404, detail="Mentor profile not found")
    # Only admin/super_admin or the owning mentor may update a mentor profile.
    # content_creator is intentionally excluded — creating/editing mentors is
    # an administrative operation, not a content-management task.
    is_admin = current_user.role in (UserRole.admin, UserRole.super_admin)
    is_owner = (current_user.role == UserRole.mentor and profile.user_id == current_user.id)
    if not is_admin and not is_owner:
        raise HTTPException(status_code=403, detail="Access denied")
    updated = counselling_crud.update_mentor_profile(db, mentor_id, payload)
    return updated


# ── Slots ──────────────────────────────────────────────────────────────────────

@router.get("/slots", response_model=list[CounsellingSlotResponse],
            summary="List all available counselling slots [authenticated]")
def list_slots(
    category: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return counselling_crud.list_all_available_slots(db, category=category)


@router.get("/slots/mentor/{user_id}", response_model=list[CounsellingSlotResponse],
            summary="List slots for a specific mentor [authenticated]")
def list_mentor_slots(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return counselling_crud.list_slots_by_user(db, user_id)


# ── Analytics ─────────────────────────────────────────────────────────────────

@router.get("/analytics", response_model=CounsellingAnalyticsResponse,
            summary="Booking analytics summary [mentor, admin, super_admin]")
def get_analytics(
    db: Session = Depends(get_db),
    current_user: User = Depends(mentor_or_above),
):
    return counselling_crud.get_analytics(db)


# ── Google Calendar stub ───────────────────────────────────────────────────────

@router.post("/calendar/sync/{mentor_id}",
             summary="Google Calendar sync stub [admin, mentor]")
def calendar_sync(
    mentor_id: int,
    current_user: User = Depends(
        require_role(UserRole.admin, UserRole.super_admin, UserRole.mentor)
    ),
):
    return {
        "status": "stub",
        "message": "Google Calendar integration pending OAuth2 setup. "
                   "Required: Google Cloud project, OAuth2 credentials, "
                   "google-auth + google-api-python-client packages.",
        "mentor_id": mentor_id,
    }
