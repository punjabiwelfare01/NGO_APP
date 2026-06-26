from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session

from ..crud import volunteer_crud
from ..database import get_db
from ..dependencies import get_current_user, require_role
from ..models.user import User, UserRole
from ..models.volunteer import ActivityCategory
from ..schemas.volunteer import (
    ActivityAssignmentCreate, ActivityAssignmentOut,
    DailyLogCreate, DailyLogOut, DailyLogUpdate,
    ImpactStoryCreate, ImpactStoryOut,
    VolunteerActivityCreate, VolunteerActivityOut, VolunteerActivityUpdate,
    VolunteerStats, WorkSubmissionCreate, WorkSubmissionOut, WorkSubmissionReview,
)

router = APIRouter(prefix="/volunteer", tags=["Volunteer"])


# ── Activities (public listing, admin creates) ────────────────────────────────

@router.get("/activities", response_model=List[VolunteerActivityOut])
def list_activities(
    category: Optional[ActivityCategory] = None,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    return volunteer_crud.get_activities(db, category=category)


@router.get("/activities/{activity_id}", response_model=VolunteerActivityOut)
def get_activity(
    activity_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    obj = volunteer_crud.get_activity(db, activity_id)
    if not obj:
        raise HTTPException(404, "Activity not found")
    return obj


@router.post("/activities", response_model=VolunteerActivityOut)
def create_activity(
    data: VolunteerActivityCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(UserRole.event_manager, UserRole.admin, UserRole.super_admin)),
):
    return volunteer_crud.create_activity(db, data, current_user.id)


@router.patch("/activities/{activity_id}", response_model=VolunteerActivityOut)
def update_activity(
    activity_id: int,
    data: VolunteerActivityUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    obj = volunteer_crud.update_activity(db, activity_id, data)
    if not obj:
        raise HTTPException(404, "Activity not found")
    return obj


# ── Assignments ───────────────────────────────────────────────────────────────

@router.post("/assignments", response_model=ActivityAssignmentOut)
def assign_activity(
    data: ActivityAssignmentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    return volunteer_crud.assign_activity(db, data, current_user.id)


@router.get("/assignments/me", response_model=List[ActivityAssignmentOut])
def my_assignments(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return volunteer_crud.get_assignments_for_student(db, current_user.id)


@router.get("/assignments", response_model=List[ActivityAssignmentOut])
def all_assignments(
    db: Session = Depends(get_db),
    _: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    return volunteer_crud.get_all_assignments(db)


# ── Work Submissions ──────────────────────────────────────────────────────────

@router.post("/submissions", response_model=WorkSubmissionOut)
def submit_work(
    data: WorkSubmissionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    activity = volunteer_crud.get_activity(db, data.activity_id)
    if not activity:
        raise HTTPException(404, "Activity not found")
    return volunteer_crud.create_submission(db, data, current_user.id)


@router.get("/submissions/me", response_model=List[WorkSubmissionOut])
def my_submissions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return volunteer_crud.get_submissions_for_student(db, current_user.id)


@router.get("/submissions/pending", response_model=List[WorkSubmissionOut])
def pending_submissions(
    db: Session = Depends(get_db),
    _: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    return volunteer_crud.get_pending_submissions(db)


@router.patch("/submissions/{submission_id}/review", response_model=WorkSubmissionOut)
def review_submission(
    submission_id: int,
    data: WorkSubmissionReview,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    obj = volunteer_crud.review_submission(db, submission_id, data, current_user.id)
    if not obj:
        raise HTTPException(404, "Submission not found")
    return obj


# ── Daily Logs ────────────────────────────────────────────────────────────────

@router.post("/logs", response_model=DailyLogOut)
def create_log(
    data: DailyLogCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return volunteer_crud.create_daily_log(db, data, current_user.id)


@router.get("/logs/me", response_model=List[DailyLogOut])
def my_logs(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return volunteer_crud.get_logs_for_student(db, current_user.id)


@router.get("/logs/public", response_model=List[DailyLogOut])
def public_logs(db: Session = Depends(get_db)):
    return volunteer_crud.get_public_logs(db)


@router.patch("/logs/{log_id}", response_model=DailyLogOut)
def update_log(
    log_id: int,
    data: DailyLogUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    log = volunteer_crud.get_log(db, log_id)
    if not log:
        raise HTTPException(404, "Log not found")
    if log.student_id != current_user.id and current_user.role not in (
        UserRole.admin, UserRole.super_admin
    ):
        raise HTTPException(403, "Access denied")
    return volunteer_crud.update_log(db, log_id, data)


@router.patch("/logs/{log_id}/approve", response_model=DailyLogOut)
def approve_log(
    log_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    obj = volunteer_crud.approve_log(db, log_id)
    if not obj:
        raise HTTPException(404, "Log not found")
    return obj


# ── Impact Stories / Wall of Impact ──────────────────────────────────────────

@router.get("/impact", response_model=List[ImpactStoryOut])
def wall_of_impact(
    featured_only: bool = False,
    db: Session = Depends(get_db),
):
    return volunteer_crud.get_public_stories(db, featured_only=featured_only)


@router.post("/impact", response_model=ImpactStoryOut)
def create_story(
    data: ImpactStoryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    return volunteer_crud.create_impact_story(db, data, current_user.id)


@router.patch("/impact/{story_id}/publish", response_model=ImpactStoryOut)
def publish_story(
    story_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    obj = volunteer_crud.publish_story(db, story_id)
    if not obj:
        raise HTTPException(404, "Story not found")
    return obj


# ── Volunteer Stats ───────────────────────────────────────────────────────────

@router.get("/stats/me", response_model=VolunteerStats)
def my_volunteer_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return volunteer_crud.get_volunteer_stats(db, current_user.id)


@router.get("/stats/{student_id}", response_model=VolunteerStats)
def student_volunteer_stats(
    student_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_role(UserRole.admin, UserRole.super_admin)),
):
    return volunteer_crud.get_volunteer_stats(db, student_id)
