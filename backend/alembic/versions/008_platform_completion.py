"""Add reports, notifications, settings, audit, reset security, and counselling workflows.

Revision ID: 008
Revises: 007
Create Date: 2026-06-21
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "008"
down_revision: Union[str, None] = "007"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    columns = {item["name"] for item in inspector.get_columns("certificates")}
    additions = {
        "event_id": sa.Column("event_id", sa.Integer(), sa.ForeignKey("events.id"), nullable=True),
        "activity_id": sa.Column("activity_id", sa.Integer(), sa.ForeignKey("volunteer_activities.id"), nullable=True),
        "assignment_id": sa.Column("assignment_id", sa.Integer(), sa.ForeignKey("activity_assignments.id"), nullable=True),
        "submission_id": sa.Column("submission_id", sa.Integer(), sa.ForeignKey("work_submissions.id"), nullable=True),
        "revoked_by": sa.Column("revoked_by", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
        "revoked_at": sa.Column("revoked_at", sa.DateTime(), nullable=True),
        "revoke_reason": sa.Column("revoke_reason", sa.String(), nullable=True),
    }
    with op.batch_alter_table("certificates") as batch:
        for name, column in additions.items():
            if name not in columns:
                batch.add_column(column)

    # Reuse the canonical SQLAlchemy definitions so migration and runtime schema
    # cannot drift as these workflow tables evolve.
    from app.models.platform import (
        Notification, NotificationPreference, UserSetting, NGOProfileSetting,
        BankSetting, RolePermissionSetting, AppSetting, AdminAuditLog,
        Announcement, PasswordResetToken, ReminderJob, EventReportFile,
        SchoolCounsellorRequest, CounsellorSessionReport,
    )
    for model in (
        Notification, NotificationPreference, UserSetting, NGOProfileSetting,
        BankSetting, RolePermissionSetting, AppSetting, AdminAuditLog,
        Announcement, PasswordResetToken, ReminderJob, EventReportFile,
        SchoolCounsellorRequest, CounsellorSessionReport,
    ):
        model.__table__.create(bind=bind, checkfirst=True)


def downgrade() -> None:
    for table in (
        "counsellor_session_reports", "school_counsellor_requests",
        "event_reports", "reminder_jobs", "password_reset_tokens",
        "announcements", "admin_audit_logs", "app_settings",
        "role_permission_settings", "bank_settings", "ngo_profile_settings",
        "user_settings", "notification_preferences", "notifications",
    ):
        op.drop_table(table)
    with op.batch_alter_table("certificates") as batch:
        for column in ("revoke_reason", "revoked_at", "revoked_by", "submission_id", "assignment_id", "activity_id", "event_id"):
            batch.drop_column(column)
