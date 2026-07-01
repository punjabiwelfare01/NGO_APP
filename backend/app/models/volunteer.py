import enum

from sqlalchemy import (
    Boolean, Column, Date, DateTime, Enum as SAEnum,
    Float, ForeignKey, Integer, String, UniqueConstraint, func,
)
from sqlalchemy.orm import relationship

from ..database import Base


class ActivityCategory(str, enum.Enum):
    education_support   = "education_support"
    awareness_programs  = "awareness_programs"
    school_partner      = "school_partner"
    donation_drives     = "donation_drives"
    event_organization  = "event_organization"
    digital_branding    = "digital_branding"
    documentation       = "documentation"


class SubmissionStatus(str, enum.Enum):
    submitted        = "submitted"
    under_review     = "under_review"
    approved         = "approved"
    rejected         = "rejected"
    needs_correction = "needs_correction"


class VolunteerActivity(Base):
    __tablename__ = "volunteer_activities"

    id              = Column(Integer, primary_key=True, index=True)
    title           = Column(String, nullable=False)
    event_id        = Column(Integer, ForeignKey("events.id"), nullable=True)
    category        = Column(SAEnum(ActivityCategory), nullable=False)
    subdivision     = Column(String, nullable=True)
    description     = Column(String, nullable=True)
    expected_work   = Column(String, nullable=True)
    proof_required  = Column(String, nullable=True)   # JSON array: ["photo","report"]
    work_instructions = Column(String, nullable=True)
    reward_hours    = Column(Float, default=0.0)
    location        = Column(String, nullable=True)
    start_date      = Column(Date, nullable=True)
    end_date        = Column(Date, nullable=True)
    duration        = Column(String, nullable=True)
    application_deadline = Column(DateTime, nullable=True)
    max_students    = Column(Integer, nullable=True)
    certificate_eligible = Column(Boolean, default=True, nullable=False)
    stipend_amount  = Column(Float, nullable=True)
    is_active       = Column(Boolean, default=True, nullable=False)
    status          = Column(String, default="active", nullable=False)  # draft/active/completed/cancelled
    created_by      = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at      = Column(DateTime, server_default=func.now())
    updated_at      = Column(DateTime, server_default=func.now(), onupdate=func.now())

    assignments = relationship("ActivityAssignment", back_populates="activity", cascade="all, delete-orphan")
    submissions = relationship("WorkSubmission",     back_populates="activity", cascade="all, delete-orphan")
    applications = relationship("ActivityApplication", back_populates="activity", cascade="all, delete-orphan")


class ActivityApplication(Base):
    __tablename__ = "activity_applications"
    __table_args__ = (UniqueConstraint("student_id", "activity_id"),)

    id          = Column(Integer, primary_key=True, index=True)
    student_id  = Column(Integer, ForeignKey("users.id"), nullable=False)
    activity_id = Column(Integer, ForeignKey("volunteer_activities.id"), nullable=False)
    status      = Column(String, default="applied", nullable=False)
    note        = Column(String, nullable=True)
    applied_at  = Column(DateTime, server_default=func.now())
    updated_at  = Column(DateTime, server_default=func.now(), onupdate=func.now())

    activity = relationship("VolunteerActivity", back_populates="applications")


class ActivityAssignment(Base):
    __tablename__ = "activity_assignments"

    id             = Column(Integer, primary_key=True, index=True)
    student_id     = Column(Integer, ForeignKey("users.id"), nullable=False)
    activity_id    = Column(Integer, ForeignKey("volunteer_activities.id"), nullable=False)
    assigned_by    = Column(Integer, ForeignKey("users.id"), nullable=True)
    location       = Column(String, nullable=True)
    scheduled_date = Column(DateTime, nullable=True)
    status         = Column(String, default="assigned", nullable=False)
    notes          = Column(String, nullable=True)
    created_at     = Column(DateTime, server_default=func.now())

    activity = relationship("VolunteerActivity", back_populates="assignments")
    student = relationship("User", foreign_keys=[student_id])


class WorkSubmission(Base):
    __tablename__ = "work_submissions"

    id                  = Column(Integer, primary_key=True, index=True)
    student_id          = Column(Integer, ForeignKey("users.id"), nullable=False)
    assignment_id       = Column(Integer, ForeignKey("activity_assignments.id"), nullable=True)
    activity_id         = Column(Integer, ForeignKey("volunteer_activities.id"), nullable=False)
    title               = Column(String, nullable=False)
    description         = Column(String, nullable=False)
    hours_worked        = Column(Float, default=0.0)
    people_reached      = Column(Integer, default=0)
    donation_collected  = Column(Float, default=0.0)
    transaction_id      = Column(String, nullable=True)
    proof_files         = Column(String, nullable=True)  # JSON array of file paths
    status              = Column(SAEnum(SubmissionStatus), default=SubmissionStatus.submitted)
    remarks             = Column(String, nullable=True)
    reviewer_notes      = Column(String, nullable=True)
    reviewed_by         = Column(Integer, ForeignKey("users.id"), nullable=True)
    reviewed_at         = Column(DateTime, nullable=True)
    created_at          = Column(DateTime, server_default=func.now())

    activity   = relationship("VolunteerActivity", back_populates="submissions")
    daily_logs = relationship("DailyLog", back_populates="submission", cascade="all, delete-orphan")


class DailyLog(Base):
    __tablename__ = "daily_logs"

    id            = Column(Integer, primary_key=True, index=True)
    student_id    = Column(Integer, ForeignKey("users.id"), nullable=False)
    submission_id = Column(Integer, ForeignKey("work_submissions.id"), nullable=True)
    date          = Column(Date, nullable=False)
    title         = Column(String, nullable=True)
    content       = Column(String, nullable=True)    # Blog text
    reflection    = Column(String, nullable=True)    # What I learned
    media_files   = Column(String, nullable=True)    # JSON array of URLs
    is_public     = Column(Boolean, default=False, nullable=False)
    status        = Column(String, default="draft", nullable=False)  # draft/submitted/approved
    created_at    = Column(DateTime, server_default=func.now())

    submission = relationship("WorkSubmission", back_populates="daily_logs")


class ImpactStory(Base):
    __tablename__ = "impact_stories"

    id             = Column(Integer, primary_key=True, index=True)
    student_id     = Column(Integer, ForeignKey("users.id"), nullable=False)
    title          = Column(String, nullable=False)
    story          = Column(String, nullable=True)
    category       = Column(String, nullable=True)   # "Volunteer of Month", "Donation Champion"
    impact_numbers = Column(String, nullable=True)   # "250 students reached"
    photo_url      = Column(String, nullable=True)
    is_featured    = Column(Boolean, default=False)
    is_public      = Column(Boolean, default=False)
    created_by     = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at     = Column(DateTime, server_default=func.now())
