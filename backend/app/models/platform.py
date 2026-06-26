from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String, Text, UniqueConstraint, func

from ..database import Base


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    type = Column(String, nullable=False, default="general")
    title = Column(String, nullable=False)
    message = Column(Text, nullable=False)
    action_url = Column(String, nullable=True)
    entity_type = Column(String, nullable=True)
    entity_id = Column(Integer, nullable=True)
    is_read = Column(Boolean, nullable=False, default=False)
    read_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, server_default=func.now())


class NotificationPreference(Base):
    __tablename__ = "notification_preferences"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, unique=True)
    in_app_enabled = Column(Boolean, nullable=False, default=True)
    email_enabled = Column(Boolean, nullable=False, default=True)
    event_reminders = Column(Boolean, nullable=False, default=True)
    counselling_reminders = Column(Boolean, nullable=False, default=True)
    assignment_updates = Column(Boolean, nullable=False, default=True)
    impact_updates = Column(Boolean, nullable=False, default=True)


class UserSetting(Base):
    __tablename__ = "user_settings"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, unique=True)
    language = Column(String, nullable=False, default="en")
    profile_visibility = Column(String, nullable=False, default="ngo_members")
    show_impact_name = Column(Boolean, nullable=False, default=True)
    data_download_enabled = Column(Boolean, nullable=False, default=True)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())


class NGOProfileSetting(Base):
    __tablename__ = "ngo_profile_settings"

    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False, default="Punjabi Welfare Trust")
    registration_number = Column(String, nullable=True)
    email = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    address = Column(Text, nullable=True)
    website = Column(String, nullable=True)
    logo_url = Column(String, nullable=True)
    updated_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())


class BankSetting(Base):
    __tablename__ = "bank_settings"

    id = Column(Integer, primary_key=True)
    account_holder = Column(String, nullable=True)
    bank_name = Column(String, nullable=True)
    account_number = Column(String, nullable=True)
    ifsc_code = Column(String, nullable=True)
    upi_id = Column(String, nullable=True)
    qr_url = Column(String, nullable=True)
    updated_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())


class RolePermissionSetting(Base):
    __tablename__ = "role_permission_settings"

    id = Column(Integer, primary_key=True)
    role = Column(String, nullable=False, unique=True)
    permissions_json = Column(Text, nullable=False, default="[]")
    updated_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())


class AppSetting(Base):
    __tablename__ = "app_settings"

    id = Column(Integer, primary_key=True)
    key = Column(String, nullable=False, unique=True)
    value = Column(Text, nullable=True)
    is_public = Column(Boolean, nullable=False, default=False)
    updated_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())


class AdminAuditLog(Base):
    __tablename__ = "admin_audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    actor_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    action = Column(String, nullable=False)
    entity_type = Column(String, nullable=True)
    entity_id = Column(String, nullable=True)
    details_json = Column(Text, nullable=True)
    ip_address = Column(String, nullable=True)
    created_at = Column(DateTime, server_default=func.now())


class Announcement(Base):
    __tablename__ = "announcements"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    message = Column(Text, nullable=False)
    audience_role = Column(String, nullable=True)
    is_active = Column(Boolean, nullable=False, default=True)
    publish_at = Column(DateTime, nullable=True)
    expires_at = Column(DateTime, nullable=True)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())


class PasswordResetToken(Base):
    __tablename__ = "password_reset_tokens"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    code_hash = Column(String, nullable=False)
    expires_at = Column(DateTime, nullable=False)
    attempts = Column(Integer, nullable=False, default=0)
    max_attempts = Column(Integer, nullable=False, default=5)
    verified_at = Column(DateTime, nullable=True)
    consumed_at = Column(DateTime, nullable=True)
    request_ip = Column(String, nullable=True)
    created_at = Column(DateTime, server_default=func.now())


class ReminderJob(Base):
    __tablename__ = "reminder_jobs"
    __table_args__ = (UniqueConstraint("notification_type", "entity_type", "entity_id", "user_id"),)

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    notification_type = Column(String, nullable=False)
    entity_type = Column(String, nullable=False)
    entity_id = Column(Integer, nullable=False)
    scheduled_at = Column(DateTime, nullable=False)
    sent_at = Column(DateTime, nullable=True)
    cancelled_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, server_default=func.now())


class EventReportFile(Base):
    __tablename__ = "event_reports"

    id = Column(Integer, primary_key=True, index=True)
    event_id = Column(Integer, ForeignKey("events.id"), nullable=False, index=True)
    status = Column(String, nullable=False, default="draft")
    summary = Column(Text, nullable=True)
    outcomes = Column(Text, nullable=True)
    school_feedback = Column(Text, nullable=True)
    data_json = Column(Text, nullable=True)
    pdf_path = Column(String, nullable=True)
    public_token = Column(String, nullable=True, unique=True)
    impact_post_id = Column(Integer, ForeignKey("impact_posts.id"), nullable=True)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    finalized_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    finalized_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())


class SchoolCounsellorRequest(Base):
    __tablename__ = "school_counsellor_requests"

    id = Column(Integer, primary_key=True, index=True)
    counsellor_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    requested_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    school_name = Column(String, nullable=False)
    coordinator_name = Column(String, nullable=False)
    coordinator_phone = Column(String, nullable=True)
    coordinator_email = Column(String, nullable=True)
    school_address = Column(Text, nullable=True)
    program = Column(String, nullable=True)
    topic = Column(String, nullable=False)
    class_group = Column(String, nullable=True)
    expected_students = Column(Integer, nullable=False, default=0)
    language = Column(String, nullable=True)
    special_requirements = Column(Text, nullable=True)
    preferred_at = Column(DateTime, nullable=False)
    suggested_at = Column(DateTime, nullable=True)
    mode = Column(String, nullable=False, default="offline")
    offline_location = Column(String, nullable=True)
    meeting_link = Column(String, nullable=True)
    assigned_event_manager_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    preparation_notes = Column(Text, nullable=True)
    status = Column(String, nullable=False, default="new_request")
    decline_reason = Column(String, nullable=True)
    decline_note = Column(Text, nullable=True)
    accepted_at = Column(DateTime, nullable=True)
    confirmed_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, server_default=func.now())


class CounsellorSessionReport(Base):
    __tablename__ = "counsellor_session_reports"

    id = Column(Integer, primary_key=True, index=True)
    request_id = Column(Integer, ForeignKey("school_counsellor_requests.id"), nullable=False, unique=True)
    counsellor_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    counsellor_notes = Column(Text, nullable=False)
    students_count = Column(Integer, nullable=False, default=0)
    school_feedback = Column(Text, nullable=True)
    rating = Column(Integer, nullable=True)
    impact_post_id = Column(Integer, ForeignKey("impact_posts.id"), nullable=True)
    created_at = Column(DateTime, server_default=func.now())
