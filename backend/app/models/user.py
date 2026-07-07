import enum

from sqlalchemy import Boolean, Column, Date, DateTime, Enum as SAEnum, ForeignKey, Integer, String, UniqueConstraint, func
from sqlalchemy.orm import relationship

from ..database import Base


class UserRole(str, enum.Enum):
    super_admin     = "super_admin"
    admin           = "admin"
    event_manager   = "event_manager"
    mentor          = "mentor"
    content_creator = "content_creator"
    support_staff   = "support_staff"
    school_partner  = "school_partner"
    student         = "student"
    guest           = "guest"


class User(Base):
    __tablename__ = "users"

    id              = Column(Integer, primary_key=True, index=True)
    name            = Column(String, nullable=False)
    email           = Column(String, unique=True, nullable=True, index=True)
    hashed_password = Column(String, nullable=True)
    age             = Column(Integer, nullable=True)
    date_of_birth   = Column(Date, nullable=True)
    level           = Column(Integer, default=1)
    xp              = Column(Integer, default=0)
    role            = Column(SAEnum(UserRole), default=UserRole.student, nullable=False)
    # Deprecated: superseded by the user_roles table (UserRoleGrant /
    # granted_roles below), which supports any number of granted roles
    # instead of just one. Mapped under a different Python attribute name
    # (physical column name unchanged) so `secondary_role` below can become
    # a computed property without a naming clash; column is kept in the DB
    # rather than dropped so the migration that introduced user_roles stays
    # reversible. Nothing in the app reads/writes this attribute anymore.
    _secondary_role_legacy = Column("secondary_role", String, nullable=True)
    access_status   = Column(String, default="pending", nullable=False)
    is_active       = Column(Boolean, default=True, nullable=False)
    parent_email    = Column(String, nullable=True)
    class_name      = Column(String, nullable=True)
    school_name     = Column(String, nullable=True)
    location        = Column(String, nullable=True)
    phone           = Column(String, nullable=True)
    requested_role      = Column(String, nullable=True)
    verification_note   = Column(String, nullable=True)
    reset_token         = Column(String, nullable=True)
    reset_token_expires = Column(DateTime, nullable=True)
    photo_url           = Column(String, nullable=True)
    interests           = Column(String, nullable=True)   # JSON array of interest strings
    gov_id_type         = Column(String, nullable=True)
    gov_id_doc_url      = Column(String, nullable=True)
    created_at          = Column(DateTime, server_default=func.now())
    last_login_at       = Column(DateTime, nullable=True)

    course_progress     = relationship("UserCourseProgress",  back_populates="user", cascade="all, delete-orphan")
    counselling_sessions= relationship("CounsellingSession",  foreign_keys="[CounsellingSession.user_id]", back_populates="user", cascade="all, delete-orphan")
    badges              = relationship("UserBadge",           back_populates="user", cascade="all, delete-orphan")
    role_grants         = relationship("UserRoleGrant", foreign_keys="[UserRoleGrant.user_id]", back_populates="user", cascade="all, delete-orphan")

    @property
    def class_level(self) -> str | None:
        return self.class_name

    @property
    def granted_roles(self) -> set["UserRole"]:
        """All roles this account is allowed to act as, sourced from the
        user_roles table. Falls back to just the primary role if no grant
        rows exist yet (e.g. a row created before the user_roles migration
        backfill ran, or in a test that builds a User without going through
        register_user/assign_role)."""
        active = {UserRole(g.role) for g in self.role_grants if g.status == "active"}
        return active or {self.role}

    @property
    def secondary_role(self) -> str | None:
        """Backward-compatible view for API/response code that still reads
        `secondary_role` as a single value (e.g. UserResponse) — an
        arbitrary one of the account's granted roles beyond its primary
        role. Now sourced from user_roles instead of the deprecated column."""
        others = self.granted_roles - {self.role}
        return next(iter(others)).value if others else None

    @property
    def roles(self) -> list[str]:
        """Full list of roles this account currently has access to (primary
        role plus any additional grants), for clients that want to render
        every granted role rather than just primary/secondary."""
        return sorted(r.value for r in self.granted_roles)


class UserRoleGrant(Base):
    """An additional role granted to a user account, beyond User.role (the
    primary role). Replaces the old single secondary_role column — an
    account can hold any number of these. Session-scoped "active role"
    switching still lives in the JWT (see auth.py); this table just records
    what's *granted*."""

    __tablename__ = "user_roles"
    __table_args__ = (UniqueConstraint("user_id", "role", name="uq_user_role"),)

    id         = Column(Integer, primary_key=True, index=True)
    user_id    = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    # Plain string (app-validated against the UserRole enum), not a native
    # SAEnum column — matches how secondary_role/access_status/etc. are
    # stored elsewhere in this codebase, and avoids MySQL/Postgres schema
    # churn (ALTER TYPE / MODIFY ENUM) if new roles are added later.
    role       = Column(String, nullable=False)
    granted_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    granted_at = Column(DateTime, server_default=func.now())
    status     = Column(String, nullable=False, default="active")  # active / inactive

    user = relationship("User", foreign_keys=[user_id], back_populates="role_grants")
