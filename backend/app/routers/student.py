import uuid
from pathlib import Path
from typing import List

import aiofiles
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy import or_
from sqlalchemy.orm import Session

from ..crud import volunteer_crud
from ..database import get_db
from ..dependencies import get_current_user
from ..models.event import Event, EventStatus
from ..models.user import User, UserRole
from ..models.volunteer import VolunteerActivity
from ..schemas.volunteer import (
    ActivityApplicationCreate,
    ActivityApplicationOut,
    ActivityAssignmentOut,
    StudentActivityOut,
    StudentWorkSummary,
    WorkSubmissionCreate,
    WorkSubmissionOut,
)

router = APIRouter(prefix="/student", tags=["Student Work"])

_UPLOADS_DIR = Path(__file__).parent.parent.parent / "uploads"
_PROOF_ALLOWED = {".pdf", ".png", ".jpg", ".jpeg", ".webp", ".mp4", ".mov"}
_PROOF_MAX_BYTES = 50 * 1024 * 1024  # 50 MB


def _student(user: User = Depends(get_current_user)) -> User:
    if user.role != UserRole.student:
        raise HTTPException(403, "Student access required")
    return user


def _activity_payload(activity, application=None, assignment=None):
    data = StudentActivityOut.model_validate(activity).model_dump()
    data["application_status"] = application.status if application else None
    data["assignment_id"] = assignment.id if assignment else None
    return data


@router.post("/upload-proof", summary="Upload a proof file for work submission")
async def upload_proof(
    file: UploadFile = File(...),
    user: User = Depends(get_current_user),
):
    original = Path(file.filename or "proof")
    ext = original.suffix.lower()
    if ext not in _PROOF_ALLOWED:
        raise HTTPException(400, f"File type '{ext}' not allowed. Allowed: {', '.join(sorted(_PROOF_ALLOWED))}")

    content = await file.read()
    if len(content) > _PROOF_MAX_BYTES:
        raise HTTPException(413, "File too large. Maximum size is 50 MB.")

    _UPLOADS_DIR.mkdir(parents=True, exist_ok=True)
    filename = f"proof_{user.id}_{uuid.uuid4()}{ext}"
    dest = _UPLOADS_DIR / filename

    async with aiofiles.open(dest, "wb") as out:
        await out.write(content)

    return {"url": f"/uploads/{filename}", "original_name": original.name}


_VISIBLE_EVENT_STATUSES = [
    EventStatus.published,
    EventStatus.registration_open,
    EventStatus.live,
]


@router.get("/activities", response_model=List[StudentActivityOut])
def activities(db: Session = Depends(get_db), user: User = Depends(_student)):
    applications = {
        item.activity_id: item
        for item in volunteer_crud.get_applications_for_student(db, user.id)
    }
    assignments = {
        item.activity_id: item
        for item in volunteer_crud.get_assignments_for_student(db, user.id)
    }
    # Include explicitly active activities AND activities belonging to any
    # currently published/live event (even if is_active wasn't flipped yet).
    all_activities = (
        db.query(VolunteerActivity)
        .outerjoin(Event, VolunteerActivity.event_id == Event.id)
        .filter(
            or_(
                VolunteerActivity.is_active.is_(True),
                Event.status.in_(_VISIBLE_EVENT_STATUSES),
            )
        )
        .order_by(VolunteerActivity.id.desc())
        .all()
    )
    return [
        _activity_payload(item, applications.get(item.id), assignments.get(item.id))
        for item in all_activities
    ]


@router.get("/activities/{activity_id}", response_model=StudentActivityOut)
def activity(activity_id: int, db: Session = Depends(get_db), user: User = Depends(_student)):
    item = volunteer_crud.get_activity(db, activity_id)
    if not item:
        raise HTTPException(404, "Activity not found")
    # Allow access when the activity is explicitly active OR linked to a published event
    event_visible = (
        item.event_id is not None
        and db.query(Event)
        .filter(Event.id == item.event_id, Event.status.in_(_VISIBLE_EVENT_STATUSES))
        .first()
        is not None
    )
    if not item.is_active and not event_visible:
        raise HTTPException(404, "Activity not found")
    application = volunteer_crud.get_application(db, activity_id, user.id)
    assignment = next((a for a in volunteer_crud.get_assignments_for_student(db, user.id) if a.activity_id == activity_id), None)
    return _activity_payload(item, application, assignment)


@router.post("/activities/{activity_id}/apply", response_model=ActivityApplicationOut, status_code=201)
def apply(
    activity_id: int,
    data: ActivityApplicationCreate,
    db: Session = Depends(get_db),
    user: User = Depends(_student),
):
    item = volunteer_crud.get_activity(db, activity_id)
    if not item:
        raise HTTPException(404, "Activity not found")
    event_visible = (
        item.event_id is not None
        and db.query(Event)
        .filter(Event.id == item.event_id, Event.status.in_(_VISIBLE_EVENT_STATUSES))
        .first()
        is not None
    )
    if not item.is_active and not event_visible:
        raise HTTPException(404, "Activity not found")
    return volunteer_crud.apply_for_activity(db, activity_id, user.id, data.note)


@router.get("/assignments", response_model=List[ActivityAssignmentOut])
def assignments(db: Session = Depends(get_db), user: User = Depends(_student)):
    return volunteer_crud.get_assignments_for_student(db, user.id)


@router.get("/assignments/{assignment_id}", response_model=ActivityAssignmentOut)
def assignment(assignment_id: int, db: Session = Depends(get_db), user: User = Depends(_student)):
    item = volunteer_crud.get_assignment(db, assignment_id)
    if not item or item.student_id != user.id:
        raise HTTPException(404, "Assignment not found")
    return item


@router.post("/assignments/{assignment_id}/submit-work", response_model=WorkSubmissionOut, status_code=201)
def submit_assignment_work(
    assignment_id: int,
    data: WorkSubmissionCreate,
    db: Session = Depends(get_db),
    user: User = Depends(_student),
):
    assignment = volunteer_crud.get_assignment(db, assignment_id)
    if not assignment or assignment.student_id != user.id:
        raise HTTPException(404, "Assignment not found")

    # If a previous submission exists for this assignment, update it (resubmit)
    # rather than blocking with 409. This supports the "Edit & Resubmit" flow.
    from ..models.volunteer import WorkSubmission as WS
    from sqlalchemy import or_, and_
    existing_sub = (
        db.query(WS)
        .filter(
            or_(
                WS.assignment_id == assignment_id,
                and_(
                    WS.assignment_id.is_(None),
                    WS.student_id == user.id,
                    WS.activity_id == assignment.activity_id,
                ),
            )
        )
        .order_by(WS.created_at.desc())
        .first()
    )

    if existing_sub and assignment.status in (
        "submitted", "resubmission_requested", "event_manager_verified",
    ):
        # Update the most-recent submission in-place
        existing_sub.title = data.title
        existing_sub.description = data.description
        existing_sub.hours_worked = data.hours_worked
        existing_sub.people_reached = data.people_reached
        existing_sub.donation_collected = data.donation_collected
        existing_sub.transaction_id = data.transaction_id
        existing_sub.remarks = data.remarks
        if data.proof_files is not None:
            existing_sub.proof_files = data.proof_files
        existing_sub.status = "submitted"
        # Link the orphaned submission to this assignment
        if existing_sub.assignment_id is None:
            existing_sub.assignment_id = assignment_id
        assignment.status = "submitted"
        db.commit()
        db.refresh(existing_sub)
        return existing_sub

    if assignment.status in ("admin_approved", "certificate_generated", "completed"):
        raise HTTPException(409, "Work is already approved — it cannot be resubmitted")

    payload = data.model_copy(update={
        "assignment_id": assignment.id,
        "activity_id": assignment.activity_id,
    })
    return volunteer_crud.create_submission(db, payload, user.id)


@router.get("/work-summary", response_model=StudentWorkSummary)
def work_summary(db: Session = Depends(get_db), user: User = Depends(_student)):
    return volunteer_crud.get_student_work_summary(db, user.id)
