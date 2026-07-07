from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..crud import counselling_crud
from ..database import get_db
from ..dependencies import admin_only, get_current_user, mentor_or_above, require_role
from ..models.counselling import CounsellorWeeklyAvailability
from ..models.user import User, UserRole
from ..schemas.counselling import (
    CounsellingAnalyticsResponse,
    MentorProfileCreate,
    MentorProfileResponse,
    MentorProfileUpdate,
)
from ..schemas.wellness import CounsellingSlotResponse

_DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']


def _fmt_time(t: str) -> str:
    """Convert '14:30' → '2:30 PM'."""
    try:
        h, m = map(int, t.split(':'))
        period = 'AM' if h < 12 else 'PM'
        h12 = h % 12 or 12
        return f"{h12}:{m:02d} {period}"
    except Exception:
        return t


def _mentor_dict(m, db: Session, current_user: User) -> dict:
    """Build the mentor dict shown to other users. Contact details (phone,
    location) and internal verification/admin fields are private — only
    included for admins/super_admins or the counsellor viewing their own
    record. Everyone else (school partners, students, etc.) gets the public
    profile subset only.
    """
    is_privileged = (
        current_user.active_role in (UserRole.admin, UserRole.super_admin)
        or current_user.id == m.user_id
    )
    photo = m.profile_image_url or (m.user.photo_url if m.user else None)
    weekly_slots = (
        db.query(CounsellorWeeklyAvailability)
        .filter(
            CounsellorWeeklyAvailability.counsellor_id == m.user_id,
            CounsellorWeeklyAvailability.is_active == True,  # noqa: E712
        )
        .order_by(
            CounsellorWeeklyAvailability.day_of_week,
            CounsellorWeeklyAvailability.start_time,
        )
        .all()
    )
    availability = [
        f"{_DAYS[s.day_of_week]}: {_fmt_time(s.start_time)} – {_fmt_time(s.end_time)}"
        f" ({s.mode.capitalize()})"
        for s in weekly_slots
    ]
    result = {
        "id": m.id,
        "user_id": m.user_id,
        "display_name": m.display_name,
        "bio": m.bio,
        "expertise": m.expertise,
        "category": m.category,
        "profile_image_url": photo,
        "is_active": m.is_active,
        "featured": m.featured,
        "rating": m.rating,
        "session_count": m.session_count,
        "created_at": m.created_at,
        # Public extended profile fields
        "qualification": m.qualification,
        "years_of_experience": m.years_of_experience,
        "counselling_mode": m.counselling_mode,
        "languages_known": m.languages_known,
        "organization": m.organization,
        # Weekly availability as formatted strings
        "weekly_availability": availability,
    }
    if is_privileged:
        result.update({
            "phone": m.user.phone if m.user else None,
            "location": m.user.location if m.user else None,
            "gender": m.gender,
            "date_of_birth": m.date_of_birth,
            "city": m.city,
            "state": m.state,
            "pin_code": m.pin_code,
            "id_proof_type": m.id_proof_type,
            "id_proof_doc_url": m.id_proof_doc_url,
            "professional_cert_url": m.professional_cert_url,
            "verification_status": m.verification_status,
            "admin_remark": m.admin_remark,
        })
    return result

router = APIRouter(prefix="/counselling", tags=["Counselling"])


# ── Mentor Profiles ────────────────────────────────────────────────────────────

@router.get("/mentors/me", response_model=MentorProfileResponse,
            summary="Get the current counsellor's profile")
def get_my_mentor_profile(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.active_role != UserRole.mentor:
        raise HTTPException(status_code=403, detail="Counsellor access required")
    profile = counselling_crud.get_mentor_by_user(db, current_user.id)
    if not profile:
        raise HTTPException(status_code=404, detail="Counsellor profile not found")
    return profile


@router.patch("/mentors/me", response_model=MentorProfileResponse,
              summary="Create or update the current counsellor's editable public profile")
def update_my_mentor_profile(
    payload: MentorProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.active_role != UserRole.mentor:
        raise HTTPException(status_code=403, detail="Counsellor access required")
    profile = counselling_crud.get_mentor_by_user(db, current_user.id)
    if not profile:
        return counselling_crud.create_mentor_profile(
            db,
            current_user.id,
            MentorProfileCreate(
                display_name=payload.display_name or current_user.name,
                bio=payload.bio,
                expertise=payload.expertise,
                category=payload.category,
                profile_image_url=payload.profile_image_url,
            ),
        )
    return counselling_crud.update_mentor_profile(db, profile.id, payload)

@router.get("/mentors", summary="List active mentor profiles [authenticated]")
def list_mentors(
    category: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    mentors = counselling_crud.list_mentors(db, category=category)
    return [_mentor_dict(m, db, current_user) for m in mentors]


@router.get("/mentors/{mentor_id}", summary="Get mentor profile detail [authenticated]")
def get_mentor(
    mentor_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    profile = counselling_crud.get_mentor(db, mentor_id)
    if not profile:
        raise HTTPException(status_code=404, detail="Mentor profile not found")
    return _mentor_dict(profile, db, current_user)


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
    is_admin = current_user.active_role in (UserRole.admin, UserRole.super_admin)
    is_owner = (current_user.active_role == UserRole.mentor and profile.user_id == current_user.id)
    if not is_admin and not is_owner:
        raise HTTPException(status_code=403, detail="Access denied")
    updated = counselling_crud.update_mentor_profile(db, mentor_id, payload)
    return updated


@router.patch("/mentors/by-user/{user_id}", response_model=MentorProfileResponse,
              summary="Update a mentor profile by user id [admin only]")
def update_mentor_profile_by_user(
    user_id: int,
    payload: MentorProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(admin_only),
):
    # Screens like the school-facing counsellor directory identify a
    # counsellor by user_id (CounsellorProfile.id), not the mentor_profiles
    # primary key used by /mentors/{mentor_id} — this endpoint bridges that.
    profile = counselling_crud.get_mentor_by_user(db, user_id)
    if not profile:
        raise HTTPException(status_code=404, detail="Mentor profile not found")
    return counselling_crud.update_mentor_profile(db, profile.id, payload)


# ── Extended profile (qualification, experience, languages, mode, verification) ─

def _extended_profile_dict(profile) -> dict:
    return {
        "qualification":         profile.qualification,
        "years_of_experience":   profile.years_of_experience,
        "counselling_mode":      profile.counselling_mode,
        "languages_known":       profile.languages_known,
        "organization":          profile.organization,
        "gender":                profile.gender,
        "date_of_birth":         profile.date_of_birth,
        "city":                  profile.city,
        "state":                 profile.state,
        "pin_code":              profile.pin_code,
        # Verification / documents — read-only here, written by the
        # dedicated upload endpoint (docs) or by admin action (status/remark).
        "id_proof_type":         profile.id_proof_type,
        "id_proof_number":       profile.id_proof_number,
        "id_proof_doc_url":      profile.id_proof_doc_url,
        "professional_cert_url": profile.professional_cert_url,
        "verification_status":   profile.verification_status,
        "verified_by":           profile.verified_by,
        "verified_at":           profile.verified_at,
        "admin_remark":          profile.admin_remark,
    }


@router.get("/mentors/me/extended",
            summary="Get current counsellor's extended profile fields")
def get_extended_profile(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.active_role != UserRole.mentor:
        raise HTTPException(status_code=403, detail="Counsellor access required")
    profile = counselling_crud.get_mentor_by_user(db, current_user.id)
    if not profile:
        return {}
    return _extended_profile_dict(profile)


@router.patch("/mentors/me/extended",
              summary="Create or update current counsellor's extended profile fields")
def update_extended_profile(
    payload: dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.active_role != UserRole.mentor:
        raise HTTPException(status_code=403, detail="Counsellor access required")
    profile = counselling_crud.get_mentor_by_user(db, current_user.id)
    if not profile:
        # Auto-create a minimal mentor profile so extended fields can be saved
        profile = counselling_crud.create_mentor_profile(
            db,
            current_user.id,
            MentorProfileCreate(display_name=current_user.name),
        )
    allowed = {
        "qualification", "years_of_experience", "counselling_mode",
        "languages_known", "organization", "gender", "date_of_birth",
        "city", "state", "pin_code", "id_proof_type", "id_proof_number",
    }
    for key, value in payload.items():
        if key in allowed:
            setattr(profile, key, value)
    db.commit()
    db.refresh(profile)
    return _extended_profile_dict(profile)


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
