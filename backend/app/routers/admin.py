from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ..database import get_db
from ..dependencies import admin_only
from ..models.notification import AdminNotification
from ..models.user import User, UserRole
from ..schemas.user import UserResponse

router = APIRouter(prefix="/admin", tags=["Admin"])
PENDING_STATUSES = ("pending", "pending_verification", "pending_review", "under_review")


# ── request bodies ────────────────────────────────────────────────────────────

class AssignRoleBody(BaseModel):
    role: str
    access_status: str = "approved"
    verification_note: Optional[str] = None


class RejectBody(BaseModel):
    reason: Optional[str] = None


class BlockBody(BaseModel):
    reason: Optional[str] = None


# ── helpers ───────────────────────────────────────────────────────────────────

def _get_or_404(db: Session, user_id: int) -> User:
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


# ── stats ─────────────────────────────────────────────────────────────────────

@router.get("/stats", summary="Admin dashboard statistics [admin only]")
def get_stats(
    db: Session = Depends(get_db),
    _: User = Depends(admin_only),
):
    total    = db.query(User).count()
    active   = db.query(User).filter(User.access_status == "approved").count()
    pending  = db.query(User).filter(User.access_status.in_(PENDING_STATUSES)).count()
    blocked  = db.query(User).filter(User.access_status == "deactivated").count()
    rejected = db.query(User).filter(User.access_status == "rejected").count()

    role_counts: dict[str, int] = {}
    for role in UserRole:
        role_counts[role.value] = db.query(User).filter(User.role == role).count()

    return {
        "total_users":    total,
        "active_users":   active,
        "pending_users":  pending,
        "blocked_users":  blocked,
        "rejected_users": rejected,
        "role_counts":    role_counts,
    }


@router.get("/dashboard/summary", summary="Pending access summary [admin only]")
def dashboard_summary(
    db: Session = Depends(get_db),
    _: User = Depends(admin_only),
):
    pending_users = (
        db.query(User)
        .filter(User.access_status.in_(PENDING_STATUSES))
        .all()
    )
    counts = {
        role: sum(
            1
            for user in pending_users
            if (user.requested_role or "student") == role
        )
        for role in (
            "student",
            "mentor",
            "event_manager",
            "content_creator",
            "school_partner",
            "support_staff",
        )
    }
    return {
        "pending_users_count": len(pending_users),
        "pending_student_count": counts["student"],
        "pending_counsellor_count": counts["mentor"],
        "pending_event_manager_count": counts["event_manager"],
        "pending_content_creator_count": counts["content_creator"],
        "pending_school_partner_count": counts["school_partner"],
        "pending_support_staff_count": counts["support_staff"],
        "total_pending_actions": len(pending_users),
    }


# ── user list ─────────────────────────────────────────────────────────────────

@router.get("/users", response_model=list[UserResponse],
            summary="List all users with optional filters [admin only]")
def list_users(
    search: Optional[str] = None,
    role: Optional[str] = None,
    status: Optional[str] = None,
    skip: int = 0,
    limit: int = 200,
    db: Session = Depends(get_db),
    _: User = Depends(admin_only),
):
    q = db.query(User)
    if search:
        like = f"%{search}%"
        q = q.filter(
            (User.name.ilike(like)) | (User.email.ilike(like))
        )
    if role:
        try:
            q = q.filter(User.role == UserRole(role))
        except ValueError:
            pass
    if status:
        q = q.filter(
            User.access_status.in_(PENDING_STATUSES)
            if status in PENDING_STATUSES
            else User.access_status == status
        )
    return q.order_by(User.created_at.desc()).offset(skip).limit(limit).all()


@router.get("/users/pending", response_model=list[UserResponse],
            summary="List users awaiting approval [admin only]")
def list_pending_users(
    db: Session = Depends(get_db),
    _: User = Depends(admin_only),
):
    return (
        db.query(User)
        .filter(User.access_status.in_(PENDING_STATUSES))
        .order_by(User.created_at.desc())
        .all()
    )


@router.get("/users/{user_id}", response_model=UserResponse,
            summary="Get full user detail [admin only]")
def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(admin_only),
):
    return _get_or_404(db, user_id)


# ── approval actions ──────────────────────────────────────────────────────────

@router.patch("/users/{user_id}/approve", response_model=UserResponse,
              summary="Approve user and assign final role [admin only]")
@router.patch("/users/{user_id}/assign-role", response_model=UserResponse,
              summary="Approve user and assign role [admin only]")
def assign_role(
    user_id: int,
    payload: AssignRoleBody,
    db: Session = Depends(get_db),
    current_user: User = Depends(admin_only),
):
    try:
        role_value = "mentor" if payload.role == "counsellor" else payload.role
        new_role = UserRole(role_value)
    except ValueError:
        raise HTTPException(status_code=422, detail=f"Invalid role: {payload.role}")

    if new_role == UserRole.super_admin and current_user.role != UserRole.super_admin:
        raise HTTPException(status_code=403, detail="Only super_admin can assign super_admin role")

    user = _get_or_404(db, user_id)
    user.role = new_role
    user.access_status = "approved"
    if payload.verification_note:
        user.verification_note = payload.verification_note

    _notify(db, user_id=user_id,
            title="Account Approved",
            message=f"{user.name} has been approved as {new_role.value}.",
            ntype="approval")
    db.commit()
    db.refresh(user)
    return user


@router.patch("/users/{user_id}/reject", response_model=UserResponse,
              summary="Reject a pending user [admin only]")
def reject_user(
    user_id: int,
    payload: RejectBody,
    db: Session = Depends(get_db),
    _: User = Depends(admin_only),
):
    user = _get_or_404(db, user_id)
    user.access_status = "rejected"
    if payload.reason:
        user.verification_note = payload.reason
    db.commit()
    db.refresh(user)
    return user


@router.patch("/users/{user_id}/block", response_model=UserResponse,
              summary="Block a user [admin only]")
def block_user(
    user_id: int,
    payload: BlockBody,
    db: Session = Depends(get_db),
    _: User = Depends(admin_only),
):
    user = _get_or_404(db, user_id)
    user.access_status = "deactivated"
    user.is_active = False
    if payload.reason:
        user.verification_note = payload.reason
    db.commit()
    db.refresh(user)
    return user


@router.patch("/users/{user_id}/unblock", response_model=UserResponse,
              summary="Unblock a user [admin only]")
def unblock_user(
    user_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(admin_only),
):
    user = _get_or_404(db, user_id)
    user.access_status = "approved"
    user.is_active = True
    db.commit()
    db.refresh(user)
    return user


@router.delete("/users/{user_id}", status_code=204,
               summary="Permanently delete a user [admin only]")
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(admin_only),
):
    user = _get_or_404(db, user_id)
    db.delete(user)
    db.commit()


# ── notifications ─────────────────────────────────────────────────────────────

@router.get("/notifications", summary="List admin notifications [admin only]")
def list_notifications(
    db: Session = Depends(get_db),
    _: User = Depends(admin_only),
):
    notes = (
        db.query(AdminNotification)
        .order_by(AdminNotification.created_at.desc())
        .limit(50)
        .all()
    )
    return [_serialize_notification(n) for n in notes]


@router.patch("/notifications/{notification_id}/read",
              summary="Mark a notification as read [admin only]")
def mark_notification_read(
    notification_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(admin_only),
):
    note = db.query(AdminNotification).filter(
        AdminNotification.id == notification_id
    ).first()
    if note:
        note.is_read = True
        db.commit()
    return {"ok": True}


@router.patch("/notifications/read-all",
              summary="Mark all notifications as read [admin only]")
def mark_all_read(
    db: Session = Depends(get_db),
    _: User = Depends(admin_only),
):
    db.query(AdminNotification).filter(
        AdminNotification.is_read.is_(False)
    ).update({"is_read": True})
    db.commit()
    return {"ok": True}


# ── internal helpers ──────────────────────────────────────────────────────────

def _notify(db: Session, *, title: str, message: str,
            ntype: str = "general", user_id: int | None = None):
    note = AdminNotification(
        title=title,
        message=message,
        type=ntype,
        user_id=user_id,
    )
    db.add(note)


def _serialize_notification(n: AdminNotification) -> dict:
    return {
        "id":         n.id,
        "title":      n.title,
        "message":    n.message,
        "type":       n.type,
        "is_read":    n.is_read,
        "user_id":    n.user_id,
        "action_url": n.action_url,
        "created_at": n.created_at.isoformat() if n.created_at else None,
    }
