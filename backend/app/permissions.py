"""
Permission constants, role-permission mapping, and role ordering for CareSkill RBAC.

Role hierarchy (lowest → highest privilege):
  guest → student → content_creator → mentor → admin → super_admin

Higher roles inherit all permissions of lower roles when using require_role().
For explicit permission checks use has_permission() or require_permission().
"""

from enum import Enum

from .models.user import UserRole


# Ordered from least to most privileged. Index value == privilege level.
ROLE_HIERARCHY: list[UserRole] = [
    UserRole.guest,
    UserRole.student,
    UserRole.content_creator,
    UserRole.mentor,
    UserRole.admin,
    UserRole.super_admin,
]


class Permission(str, Enum):
    # ── user management ───────────────────────────────────────────────────────
    MANAGE_USERS = "manage_users"           # list all users, deactivate accounts
    ASSIGN_ROLE  = "assign_role"            # change another user's role

    # ── event management ──────────────────────────────────────────────────────
    CREATE_EVENT  = "create_event"
    EDIT_EVENT    = "edit_event"
    PUBLISH_EVENT = "publish_event"
    DELETE_EVENT  = "delete_event"

    # ── learning content ──────────────────────────────────────────────────────
    CREATE_LESSON     = "create_lesson"
    EDIT_LESSON       = "edit_lesson"
    DELETE_LESSON     = "delete_lesson"
    MANAGE_CATEGORIES = "manage_categories"

    # ── counselling ───────────────────────────────────────────────────────────
    MANAGE_COUNSELLING = "manage_counselling"   # create/edit mentor profiles
    VIEW_ANALYTICS     = "view_analytics"       # booking analytics dashboard

    # ── gamification ──────────────────────────────────────────────────────────
    AWARD_BADGES = "award_badges"
    AWARD_XP     = "award_xp"

    # ── quiz & safety ──────────────────────────────────────────────────────────
    CREATE_QUIZ               = "create_quiz"
    MANAGE_SAFETY_QUESTIONS   = "manage_safety_questions"
    MANAGE_EMERGENCY_CONTACTS = "manage_emergency_contacts"


# Explicit permission sets per role.
# Note: these are NOT automatically cumulative. Use has_permission() which
# respects the hierarchy, or require_role() for route-level guards.
ROLE_PERMISSIONS: dict[UserRole, frozenset] = {
    UserRole.guest: frozenset(),

    UserRole.student: frozenset(),

    UserRole.content_creator: frozenset({
        Permission.CREATE_EVENT,
        Permission.EDIT_EVENT,
        Permission.PUBLISH_EVENT,
        Permission.CREATE_LESSON,
        Permission.EDIT_LESSON,
        Permission.DELETE_LESSON,
        Permission.CREATE_QUIZ,
        Permission.MANAGE_SAFETY_QUESTIONS,
    }),

    # Mentor adds counselling management, analytics, and XP/badge award on top
    # of content_creator's permissions.
    UserRole.mentor: frozenset({
        Permission.CREATE_EVENT,
        Permission.EDIT_EVENT,
        Permission.PUBLISH_EVENT,
        Permission.CREATE_LESSON,
        Permission.EDIT_LESSON,
        Permission.DELETE_LESSON,
        Permission.CREATE_QUIZ,
        Permission.MANAGE_SAFETY_QUESTIONS,
        Permission.MANAGE_COUNSELLING,
        Permission.VIEW_ANALYTICS,
        Permission.AWARD_BADGES,
        Permission.AWARD_XP,
    }),

    # Admin and super_admin have every permission.
    UserRole.admin:       frozenset(Permission),
    UserRole.super_admin: frozenset(Permission),
}


def has_permission(role: UserRole, permission: Permission) -> bool:
    """Return True if the given role has the specified permission."""
    return permission in ROLE_PERMISSIONS.get(role, frozenset())
