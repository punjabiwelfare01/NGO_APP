"""
Comprehensive RBAC tests for CareSkill.

Verifies that every role can access what it should and is blocked from what it should not.
Each test class targets a specific role or cross-role scenario.

Role hierarchy (lowest → highest):
  guest(0) → student(1) → content_creator(2) → mentor(3) → admin(4) → super_admin(5)
"""

import pytest
from tests.conftest import EVENT_PAYLOAD, SAFETY_QUESTION_PAYLOAD


# ── unauthenticated / guest ────────────────────────────────────────────────────

class TestUnauthenticated:
    def test_no_token_returns_401_on_protected_route(self, client):
        assert client.get("/users/").status_code == 401

    def test_no_token_returns_401_on_events(self, client):
        assert client.get("/events/").status_code == 401

    def test_no_token_returns_401_on_counselling_analytics(self, client):
        assert client.get("/counselling/analytics").status_code == 401

    def test_invalid_token_returns_401(self, client):
        headers = {"Authorization": "Bearer not.a.real.token"}
        assert client.get("/auth/me", headers=headers).status_code == 401


# ── student role ───────────────────────────────────────────────────────────────

class TestStudent:
    def test_student_can_list_events(self, client, student_headers):
        assert client.get("/events/", headers=student_headers).status_code == 200

    def test_student_cannot_create_event(self, client, student_headers):
        resp = client.post("/events/", json=EVENT_PAYLOAD, headers=student_headers)
        assert resp.status_code == 403

    def test_student_cannot_create_event_via_alias(self, client, student_headers):
        resp = client.post("/events/create", json=EVENT_PAYLOAD, headers=student_headers)
        assert resp.status_code == 403

    def test_student_cannot_list_all_users(self, client, student_headers):
        assert client.get("/users/", headers=student_headers).status_code == 403

    def test_student_cannot_create_safety_question(self, client, student_headers):
        resp = client.post("/safety-awareness/", json=SAFETY_QUESTION_PAYLOAD, headers=student_headers)
        assert resp.status_code == 403

    def test_student_cannot_view_counselling_analytics(self, client, student_headers):
        assert client.get("/counselling/analytics", headers=student_headers).status_code == 403

    def test_student_cannot_create_mentor_profile(self, client, student_headers):
        payload = {"display_name": "Dr. Test", "bio": "Bio", "expertise": "Math", "category": "general"}
        assert client.post("/counselling/mentors", json=payload, headers=student_headers).status_code == 403

    def test_student_cannot_assign_role(self, client, student_headers, admin_user):
        resp = client.patch(
            f"/users/{admin_user.id}/role",
            json={"role": "student"},
            headers=student_headers,
        )
        assert resp.status_code == 403

    def test_student_cannot_block_user(self, client, student_headers, mentor_user):
        resp = client.patch(
            f"/users/{mentor_user.id}/status",
            json={"is_active": False},
            headers=student_headers,
        )
        assert resp.status_code == 403

    def test_student_can_view_own_profile(self, client, student_headers, student_user):
        resp = client.get(f"/users/{student_user.id}", headers=student_headers)
        assert resp.status_code == 200

    def test_student_cannot_view_other_user_profile(self, client, student_headers, admin_user):
        resp = client.get(f"/users/{admin_user.id}", headers=student_headers)
        assert resp.status_code == 403


# ── content_creator role ───────────────────────────────────────────────────────

class TestContentCreator:
    def test_cc_can_create_event(self, client, cc_headers):
        resp = client.post("/events/", json=EVENT_PAYLOAD, headers=cc_headers)
        assert resp.status_code == 201

    def test_cc_cannot_delete_event(self, client, cc_headers, admin_headers):
        event = client.post("/events/", json=EVENT_PAYLOAD, headers=admin_headers).json()
        resp = client.delete(f"/events/{event['id']}", headers=cc_headers)
        assert resp.status_code == 403

    def test_cc_cannot_list_all_users(self, client, cc_headers):
        assert client.get("/users/", headers=cc_headers).status_code == 403

    def test_cc_cannot_assign_role(self, client, cc_headers, student_user):
        resp = client.patch(
            f"/users/{student_user.id}/role",
            json={"role": "mentor"},
            headers=cc_headers,
        )
        assert resp.status_code == 403

    def test_cc_cannot_block_user(self, client, cc_headers, student_user):
        resp = client.patch(
            f"/users/{student_user.id}/status",
            json={"is_active": False},
            headers=cc_headers,
        )
        assert resp.status_code == 403

    def test_cc_cannot_view_counselling_analytics(self, client, cc_headers):
        # Analytics is mentor+ only; content_creator is explicitly excluded.
        assert client.get("/counselling/analytics", headers=cc_headers).status_code == 403

    def test_cc_cannot_create_mentor_profile(self, client, cc_headers):
        payload = {"display_name": "Dr. CC", "bio": "Bio", "expertise": "Art", "category": "general"}
        assert client.post("/counselling/mentors", json=payload, headers=cc_headers).status_code == 403

    def test_cc_cannot_create_mentor_profile_for_user(self, client, cc_headers, student_user):
        payload = {"display_name": "Dr. CC", "bio": "Bio", "expertise": "Art", "category": "general"}
        resp = client.post(
            f"/counselling/mentors/for-user/{student_user.id}",
            json=payload,
            headers=cc_headers,
        )
        assert resp.status_code == 403

    def test_cc_can_create_safety_question(self, client, cc_headers):
        resp = client.post("/safety-awareness/", json=SAFETY_QUESTION_PAYLOAD, headers=cc_headers)
        assert resp.status_code in (200, 201)

    def test_cc_cannot_award_xp(self, client, cc_headers, student_user):
        resp = client.post(
            f"/users/{student_user.id}/xp",
            json={"amount": 50},
            headers=cc_headers,
        )
        assert resp.status_code == 403


# ── mentor role ────────────────────────────────────────────────────────────────

class TestMentor:
    def test_mentor_can_create_event(self, client, mentor_headers):
        resp = client.post("/events/", json=EVENT_PAYLOAD, headers=mentor_headers)
        assert resp.status_code == 201

    def test_mentor_cannot_delete_event(self, client, mentor_headers, admin_headers):
        event = client.post("/events/", json=EVENT_PAYLOAD, headers=admin_headers).json()
        resp = client.delete(f"/events/{event['id']}", headers=mentor_headers)
        assert resp.status_code == 403

    def test_mentor_cannot_list_all_users(self, client, mentor_headers):
        assert client.get("/users/", headers=mentor_headers).status_code == 403

    def test_mentor_cannot_assign_role(self, client, mentor_headers, student_user):
        resp = client.patch(
            f"/users/{student_user.id}/role",
            json={"role": "content_creator"},
            headers=mentor_headers,
        )
        assert resp.status_code == 403

    def test_mentor_cannot_block_other_user(self, client, mentor_headers, student_user):
        resp = client.patch(
            f"/users/{student_user.id}/status",
            json={"is_active": False},
            headers=mentor_headers,
        )
        assert resp.status_code == 403

    def test_mentor_can_view_counselling_analytics(self, client, mentor_headers):
        assert client.get("/counselling/analytics", headers=mentor_headers).status_code == 200

    def test_mentor_can_award_xp(self, client, mentor_headers, student_user):
        resp = client.post(
            f"/users/{student_user.id}/xp",
            json={"amount": 10},
            headers=mentor_headers,
        )
        assert resp.status_code == 200

    def test_mentor_can_create_and_update_own_public_profile(
        self, client, mentor_headers, mentor_user
    ):
        payload = {
            "display_name": "Meera Kaur",
            "bio": "Education and career counsellor.",
            "expertise": "Career planning, Scholarships",
            "category": "Education Counsellor",
        }
        updated = client.patch(
            "/counselling/mentors/me",
            json=payload,
            headers=mentor_headers,
        )
        assert updated.status_code == 200, updated.text
        assert updated.json()["user_id"] == mentor_user.id
        assert updated.json()["display_name"] == payload["display_name"]

        persisted = client.get(
            "/counselling/mentors/me",
            headers=mentor_headers,
        )
        assert persisted.status_code == 200
        assert persisted.json()["bio"] == payload["bio"]

    def test_mentor_cannot_create_mentor_profile_for_another_user(
        self, client, mentor_headers, student_user
    ):
        # Only admin can create profiles; mentor can only edit their own.
        payload = {"display_name": "Dr. Mentor", "bio": "Bio", "expertise": "CS", "category": "general"}
        resp = client.post(
            f"/counselling/mentors/for-user/{student_user.id}",
            json=payload,
            headers=mentor_headers,
        )
        assert resp.status_code == 403


# ── admin role ─────────────────────────────────────────────────────────────────

class TestAdmin:
    def test_admin_can_list_all_users(self, client, admin_headers):
        assert client.get("/users/", headers=admin_headers).status_code == 200

    def test_admin_can_create_event(self, client, admin_headers):
        resp = client.post("/events/", json=EVENT_PAYLOAD, headers=admin_headers)
        assert resp.status_code == 201

    def test_admin_can_delete_event(self, client, admin_headers):
        event = client.post("/events/", json=EVENT_PAYLOAD, headers=admin_headers).json()
        resp = client.delete(f"/events/{event['id']}", headers=admin_headers)
        assert resp.status_code == 204

    def test_admin_can_assign_role_to_student(self, client, admin_headers, student_user):
        resp = client.patch(
            f"/users/{student_user.id}/role",
            json={"role": "mentor"},
            headers=admin_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["role"] == "mentor"

    def test_admin_can_assign_content_creator_role(self, client, admin_headers, student_user):
        resp = client.patch(
            f"/users/{student_user.id}/role",
            json={"role": "content_creator"},
            headers=admin_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["role"] == "content_creator"

    def test_admin_cannot_assign_super_admin_role(self, client, admin_headers, student_user):
        # Only super_admin may promote others to super_admin.
        resp = client.patch(
            f"/users/{student_user.id}/role",
            json={"role": "super_admin"},
            headers=admin_headers,
        )
        assert resp.status_code == 403

    def test_admin_can_block_user(self, client, admin_headers, student_user):
        resp = client.patch(
            f"/users/{student_user.id}/status",
            json={"is_active": False},
            headers=admin_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["is_active"] is False

    def test_admin_can_reactivate_user(self, client, admin_headers, student_user):
        client.patch(
            f"/users/{student_user.id}/status",
            json={"is_active": False},
            headers=admin_headers,
        )
        resp = client.patch(
            f"/users/{student_user.id}/status",
            json={"is_active": True},
            headers=admin_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["is_active"] is True

    def test_admin_can_view_counselling_analytics(self, client, admin_headers):
        assert client.get("/counselling/analytics", headers=admin_headers).status_code == 200

    def test_admin_can_create_mentor_profile(self, client, admin_headers, mentor_user):
        payload = {
            "display_name": "Dr. Admin-Created",
            "bio": "Created by admin",
            "expertise": "Leadership",
            "category": "general",
        }
        resp = client.post("/counselling/mentors", json=payload, headers=admin_headers)
        assert resp.status_code == 201


# ── super_admin role ───────────────────────────────────────────────────────────

class TestSuperAdmin:
    def test_super_admin_can_assign_super_admin_role(
        self, client, super_admin_headers, student_user
    ):
        resp = client.patch(
            f"/users/{student_user.id}/role",
            json={"role": "super_admin"},
            headers=super_admin_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["role"] == "super_admin"

    def test_super_admin_can_list_users(self, client, super_admin_headers):
        assert client.get("/users/", headers=super_admin_headers).status_code == 200

    def test_super_admin_can_delete_event(self, client, super_admin_headers):
        event = client.post("/events/", json=EVENT_PAYLOAD, headers=super_admin_headers).json()
        resp = client.delete(f"/events/{event['id']}", headers=super_admin_headers)
        assert resp.status_code == 204

    def test_super_admin_can_access_calendar_status(self, client, super_admin_headers):
        resp = client.get("/auth/google/calendar/status", headers=super_admin_headers)
        # 200 or 503 (calendar not configured) both indicate RBAC passed
        assert resp.status_code in (200, 503)


# ── role inheritance correctness ───────────────────────────────────────────────

class TestRoleInheritance:
    """Verify that higher roles satisfy lower-role requirements (hierarchy)."""

    def test_admin_satisfies_mentor_requirement(self, client, admin_headers):
        # mentor_or_above route — admin should pass
        assert client.get("/counselling/analytics", headers=admin_headers).status_code == 200

    def test_admin_satisfies_content_creator_requirement(self, client, admin_headers):
        # content_creator_or_above route — admin should pass
        resp = client.post("/events/", json=EVENT_PAYLOAD, headers=admin_headers)
        assert resp.status_code == 201

    def test_mentor_satisfies_content_creator_requirement(self, client, mentor_headers):
        # Routes requiring content_creator should also admit mentor
        resp = client.post("/events/", json=EVENT_PAYLOAD, headers=mentor_headers)
        assert resp.status_code == 201

    def test_content_creator_does_not_satisfy_mentor_requirement(self, client, cc_headers):
        # Analytics is mentor+ — cc should be blocked
        assert client.get("/counselling/analytics", headers=cc_headers).status_code == 403

    def test_content_creator_does_not_satisfy_admin_requirement(self, client, cc_headers):
        assert client.get("/users/", headers=cc_headers).status_code == 403

    def test_mentor_does_not_satisfy_admin_requirement(self, client, mentor_headers):
        assert client.get("/users/", headers=mentor_headers).status_code == 403


# ── blocked / inactive user ────────────────────────────────────────────────────

class TestBlockedUser:
    def test_blocked_user_cannot_authenticate(self, client, admin_headers, student_user):
        # Block the student, then try to use their token.
        # First get student token while active.
        login = client.post(
            "/auth/login",
            json={"email": "student@test.local", "password": "testpass123"},
        )
        token = login.json()["access_token"]
        student_token_headers = {"Authorization": f"Bearer {token}"}

        # Admin blocks the student account.
        client.patch(
            f"/users/{student_user.id}/status",
            json={"is_active": False},
            headers=admin_headers,
        )

        # The previously issued token should no longer work.
        resp = client.get("/auth/me", headers=student_token_headers)
        assert resp.status_code == 401
