from __future__ import annotations

from datetime import date, datetime
from typing import List, Optional

from pydantic import BaseModel

from ..models.volunteer import ActivityCategory, SubmissionStatus


# ── VolunteerActivity ─────────────────────────────────────────────────────────

class VolunteerActivityCreate(BaseModel):
    title: str
    event_id: Optional[int] = None
    category: ActivityCategory
    subdivision: Optional[str] = None
    description: Optional[str] = None
    expected_work: Optional[str] = None
    proof_required: Optional[str] = None  # JSON string
    reward_hours: float = 0.0
    location: Optional[str] = None
    duration: Optional[str] = None
    application_deadline: Optional[datetime] = None
    max_students: Optional[int] = None
    certificate_eligible: bool = True
    stipend_amount: Optional[float] = None


class VolunteerActivityUpdate(BaseModel):
    title: Optional[str] = None
    category: Optional[ActivityCategory] = None
    subdivision: Optional[str] = None
    description: Optional[str] = None
    expected_work: Optional[str] = None
    proof_required: Optional[str] = None
    reward_hours: Optional[float] = None
    is_active: Optional[bool] = None
    event_id: Optional[int] = None
    location: Optional[str] = None
    duration: Optional[str] = None
    application_deadline: Optional[datetime] = None
    max_students: Optional[int] = None
    certificate_eligible: Optional[bool] = None
    stipend_amount: Optional[float] = None


class VolunteerActivityOut(BaseModel):
    id: int
    title: str
    event_id: Optional[int] = None
    category: ActivityCategory
    subdivision: Optional[str]
    description: Optional[str]
    expected_work: Optional[str]
    proof_required: Optional[str]
    reward_hours: float
    is_active: bool
    created_by: Optional[int]
    created_at: Optional[datetime]
    location: Optional[str] = None
    duration: Optional[str] = None
    application_deadline: Optional[datetime] = None
    max_students: Optional[int] = None
    certificate_eligible: bool = True
    stipend_amount: Optional[float] = None

    model_config = {"from_attributes": True}


# ── ActivityAssignment ────────────────────────────────────────────────────────

class ActivityAssignmentCreate(BaseModel):
    student_id: int
    activity_id: int
    location: Optional[str] = None
    scheduled_date: Optional[datetime] = None
    notes: Optional[str] = None


class ActivityAssignmentOut(BaseModel):
    id: int
    student_id: int
    activity_id: int
    assigned_by: Optional[int]
    location: Optional[str]
    scheduled_date: Optional[datetime]
    status: str
    notes: Optional[str]
    created_at: Optional[datetime]
    activity: Optional[VolunteerActivityOut] = None

    model_config = {"from_attributes": True}


class ActivityApplicationCreate(BaseModel):
    note: Optional[str] = None


class ActivityApplicationOut(BaseModel):
    id: int
    student_id: int
    activity_id: int
    status: str
    note: Optional[str] = None
    applied_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    activity: Optional[VolunteerActivityOut] = None

    model_config = {"from_attributes": True}


class StudentActivityOut(VolunteerActivityOut):
    application_status: Optional[str] = None
    assignment_id: Optional[int] = None


class StudentWorkSummary(BaseModel):
    total_hours: float
    activities_completed: int
    donation_raised: float
    certificates_earned: int
    pending_approvals: int
    volunteer_rank: str
    open_activities: int = 0
    applied: int = 0
    assigned: int = 0
    in_progress: int = 0
    submitted: int = 0
    verified: int = 0
    completed: int = 0


# ── WorkSubmission ────────────────────────────────────────────────────────────

class WorkSubmissionCreate(BaseModel):
    activity_id: int
    assignment_id: Optional[int] = None
    title: str
    description: str
    hours_worked: float = 0.0
    people_reached: int = 0
    donation_collected: float = 0.0
    transaction_id: Optional[str] = None
    proof_files: Optional[str] = None  # JSON array string
    remarks: Optional[str] = None


class WorkSubmissionReview(BaseModel):
    status: SubmissionStatus
    reviewer_notes: Optional[str] = None


class WorkSubmissionOut(BaseModel):
    id: int
    student_id: int
    assignment_id: Optional[int]
    activity_id: int
    title: str
    description: str
    hours_worked: float
    people_reached: int
    donation_collected: float
    transaction_id: Optional[str]
    proof_files: Optional[str]
    status: SubmissionStatus
    remarks: Optional[str]
    reviewer_notes: Optional[str]
    reviewed_by: Optional[int]
    reviewed_at: Optional[datetime]
    created_at: Optional[datetime]
    activity: Optional[VolunteerActivityOut] = None

    model_config = {"from_attributes": True}


# ── DailyLog ──────────────────────────────────────────────────────────────────

class DailyLogCreate(BaseModel):
    date: date
    title: Optional[str] = None
    content: Optional[str] = None
    reflection: Optional[str] = None
    media_files: Optional[str] = None  # JSON array string
    submission_id: Optional[int] = None


class DailyLogUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    reflection: Optional[str] = None
    media_files: Optional[str] = None
    status: Optional[str] = None    # draft/submitted/approved


class DailyLogOut(BaseModel):
    id: int
    student_id: int
    submission_id: Optional[int]
    date: date
    title: Optional[str]
    content: Optional[str]
    reflection: Optional[str]
    media_files: Optional[str]
    is_public: bool
    status: str
    created_at: Optional[datetime]

    model_config = {"from_attributes": True}


# ── ImpactStory ───────────────────────────────────────────────────────────────

class ImpactStoryCreate(BaseModel):
    student_id: int
    title: str
    story: Optional[str] = None
    category: Optional[str] = None
    impact_numbers: Optional[str] = None
    photo_url: Optional[str] = None
    is_featured: bool = False


class ImpactStoryOut(BaseModel):
    id: int
    student_id: int
    title: str
    story: Optional[str]
    category: Optional[str]
    impact_numbers: Optional[str]
    photo_url: Optional[str]
    is_featured: bool
    is_public: bool
    created_by: Optional[int]
    created_at: Optional[datetime]

    model_config = {"from_attributes": True}


# ── Volunteer Stats (per-student summary) ─────────────────────────────────────

class VolunteerStats(BaseModel):
    total_hours: float
    activities_completed: int
    donation_raised: float
    certificates_earned: int
    pending_approvals: int
    volunteer_rank: str  # Bronze / Silver / Gold / Platinum
