from sqlalchemy.orm import Session, joinedload

from ..models.counselling import CounsellingNotification, MentorProfile
from ..models.user import User, UserRole
from ..models.wellness import CounsellingAvailability, CounsellingSession
from ..schemas.counselling import MentorProfileCreate, MentorProfileUpdate


def _ensure_mentor_profiles(db: Session) -> None:
    """Auto-create MentorProfile rows for any approved mentor User who lacks one."""
    mentor_users = (
        db.query(User)
        .filter(User.role == UserRole.mentor, User.access_status == "approved")
        .all()
    )
    changed = False
    for u in mentor_users:
        existing = db.query(MentorProfile).filter(MentorProfile.user_id == u.id).first()
        if not existing:
            db.add(MentorProfile(user_id=u.id, display_name=u.name, is_active=True))
            changed = True
    if changed:
        db.commit()


def list_mentors(db: Session, category: str | None = None, active_only: bool = True):
    _ensure_mentor_profiles(db)
    q = db.query(MentorProfile).options(joinedload(MentorProfile.user))
    if active_only:
        q = q.filter(MentorProfile.is_active == True)  # noqa: E712
    if category:
        q = q.filter(MentorProfile.category == category)
    return q.order_by(MentorProfile.session_count.desc()).all()


def get_mentor(db: Session, mentor_id: int):
    return (
        db.query(MentorProfile)
        .options(joinedload(MentorProfile.user))
        .filter(MentorProfile.id == mentor_id)
        .first()
    )


def get_mentor_by_user(db: Session, user_id: int):
    return db.query(MentorProfile).filter(MentorProfile.user_id == user_id).first()


def create_mentor_profile(db: Session, user_id: int, data: MentorProfileCreate) -> MentorProfile:
    profile = MentorProfile(
        user_id=user_id,
        display_name=data.display_name,
        bio=data.bio,
        expertise=data.expertise,
        category=data.category,
        profile_image_url=data.profile_image_url,
    )
    db.add(profile)
    db.commit()
    db.refresh(profile)
    return profile


def update_mentor_profile(db: Session, mentor_id: int, data: MentorProfileUpdate):
    profile = get_mentor(db, mentor_id)
    if not profile:
        return None
    for field, value in data.model_dump(exclude_none=True).items():
        setattr(profile, field, value)
    db.commit()
    db.refresh(profile)
    return profile


def list_slots_by_user(db: Session, user_id: int):
    return (
        db.query(CounsellingAvailability)
        .filter(
            CounsellingAvailability.mentor_id == user_id,
            CounsellingAvailability.is_active == True,  # noqa: E712
        )
        .order_by(CounsellingAvailability.starts_at)
        .all()
    )


def list_all_available_slots(db: Session, category: str | None = None):
    q = (
        db.query(CounsellingAvailability)
        .filter(CounsellingAvailability.is_active == True)  # noqa: E712
    )
    if category:
        q = q.join(MentorProfile, MentorProfile.user_id == CounsellingAvailability.mentor_id).filter(
            MentorProfile.category == category
        )
    return q.order_by(CounsellingAvailability.starts_at).all()


def get_analytics(db: Session) -> dict:
    _ensure_mentor_profiles(db)
    total_mentors = db.query(MentorProfile).count()
    active_mentors = db.query(MentorProfile).filter(MentorProfile.is_active == True).count()  # noqa: E712
    total_bookings = db.query(CounsellingSession).count()
    upcoming_bookings = db.query(CounsellingSession).filter(CounsellingSession.status == "upcoming").count()
    completed_sessions = db.query(CounsellingSession).filter(CounsellingSession.status == "completed").count()
    return {
        "total_mentors": total_mentors,
        "active_mentors": active_mentors,
        "total_bookings": total_bookings,
        "upcoming_bookings": upcoming_bookings,
        "completed_sessions": completed_sessions,
    }


def create_booking_notification(db: Session, user_id: int, session: CounsellingSession) -> None:
    notif = CounsellingNotification(
        user_id=user_id,
        type="confirmation",
        message=f"Your counselling session with {session.counsellor_name} is confirmed for {session.scheduled_at.strftime('%d %b, %I:%M %p')}.",
        booking_ref=str(session.id),
    )
    db.add(notif)
    db.commit()
