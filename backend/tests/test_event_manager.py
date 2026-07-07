"""Event Manager workspace feature: dashboard, creating/editing activities
tied to an event, and assigning students to them."""

from tests.conftest import EVENT_PAYLOAD


def _create_activity(client, headers, **overrides):
    payload = {"title": "Volunteer Support Desk", "category": "event_organization"}
    payload.update(overrides)
    return client.post("/event-manager/activities", json=payload, headers=headers)


class TestDashboard:
    def test_event_manager_can_load_dashboard(self, client, event_manager_headers):
        resp = client.get("/event-manager/dashboard", headers=event_manager_headers)
        assert resp.status_code == 200

    def test_non_event_manager_forbidden(self, client, student_headers):
        resp = client.get("/event-manager/dashboard", headers=student_headers)
        assert resp.status_code == 403

    def test_admin_acting_via_active_role_sees_all_impact_posts(
        self, client, admin_headers, event_manager_user, event_manager_headers,
    ):
        # A multi-role account whose primary `role` is event_manager but whose
        # active session role is admin (via a grant + switch-role) must see
        # every impact post — including other users' drafts — exactly like an
        # account whose primary role is admin. Regression test: the dashboard
        # used to check `user.role` instead of `user.active_role` here, so
        # this scenario incorrectly fell into the "own posts only" branch.
        grant = client.post(
            f"/admin/users/{event_manager_user.id}/roles",
            json={"role": "admin"},
            headers=admin_headers,
        )
        assert grant.status_code == 201, grant.text

        switched = client.post(
            "/auth/switch-role", json={"role": "admin"}, headers=event_manager_headers,
        )
        assert switched.status_code == 200, switched.text
        acting_admin_headers = {"Authorization": f"Bearer {switched.json()['access_token']}"}

        draft = client.post(
            "/impact/posts",
            json={"title": "Someone else's draft", "description": "d", "category": "achievement"},
            headers=admin_headers,
        )
        assert draft.status_code == 201, draft.text

        dash = client.get("/event-manager/dashboard", headers=acting_admin_headers)
        assert dash.status_code == 200, dash.text
        titles = [item["title"] for item in dash.json()["impact_posts"]]
        assert "Someone else's draft" in titles


class TestActivities:
    def test_create_activity_requires_title(self, client, event_manager_headers):
        resp = client.post("/event-manager/activities", json={}, headers=event_manager_headers)
        assert resp.status_code == 400

    def test_create_and_list_own_activity(self, client, event_manager_headers):
        created = _create_activity(client, event_manager_headers)
        assert created.status_code == 201, created.text

        listing = client.get("/event-manager/activities", headers=event_manager_headers)
        assert listing.status_code == 200
        assert len(listing.json()) == 1

    def test_student_cannot_create_activity(self, client, student_headers):
        resp = _create_activity(client, student_headers)
        assert resp.status_code == 403

    def test_admin_sees_all_activities_em_sees_only_own(self, client, admin_headers, event_manager_headers):
        _create_activity(client, admin_headers, title="Admin-created")
        _create_activity(client, event_manager_headers, title="EM-created")

        em_view = client.get("/event-manager/activities", headers=event_manager_headers).json()
        assert len(em_view) == 1
        assert em_view[0]["title"] == "EM-created"

        admin_view = client.get("/event-manager/activities", headers=admin_headers).json()
        assert len(admin_view) == 2

    def test_activity_can_link_to_an_event(self, client, admin_headers, event_manager_headers):
        event = client.post("/events/create", json=EVENT_PAYLOAD, headers=admin_headers).json()
        resp = _create_activity(client, event_manager_headers, event_id=event["id"])
        assert resp.status_code == 201, resp.text

    def test_linking_to_nonexistent_event_404s(self, client, event_manager_headers):
        resp = _create_activity(client, event_manager_headers, event_id=999999)
        assert resp.status_code == 404

    def test_edit_activity_forbidden_for_non_owner_event_manager(self, client, event_manager_headers, db):
        from tests.conftest import _create_user
        from app.models.user import UserRole

        _create_user(db, "em2@test.local", UserRole.event_manager, "EM Two")
        created = _create_activity(client, event_manager_headers).json()

        # A second EM (not the creator) should not be able to edit it.
        # (Reuses the token-issuing flow via login for the second account.)
        login = client.post("/auth/login", json={"email": "em2@test.local", "password": "testpass123"})
        other_headers = {"Authorization": f"Bearer {login.json()['access_token']}"}

        resp = client.put(
            f"/event-manager/activities/{created['id']}",
            json={"title": "Hijacked"},
            headers=other_headers,
        )
        assert resp.status_code == 403


class TestAssignStudents:
    def test_assign_students_to_activity(self, client, event_manager_headers, student_user):
        created = _create_activity(client, event_manager_headers).json()
        resp = client.post(
            f"/event-manager/activities/{created['id']}/assign-students",
            json={"student_ids": [student_user.id]},
            headers=event_manager_headers,
        )
        assert resp.status_code == 200, resp.text
        assert resp.json()["assigned"] == [student_user.id]

    def test_assigning_same_student_twice_is_idempotent(self, client, event_manager_headers, student_user):
        created = _create_activity(client, event_manager_headers).json()
        client.post(
            f"/event-manager/activities/{created['id']}/assign-students",
            json={"student_ids": [student_user.id]},
            headers=event_manager_headers,
        )
        resp = client.post(
            f"/event-manager/activities/{created['id']}/assign-students",
            json={"student_ids": [student_user.id]},
            headers=event_manager_headers,
        )
        assert resp.json()["assigned"] == []
        assert resp.json()["already_assigned"] == 1
