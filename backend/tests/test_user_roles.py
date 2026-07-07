"""user_roles table (Phase 1 of the multi-role architecture): replaces the
old single secondary_role column with a proper grant table, while keeping
the existing active_role JWT mechanism and /auth/switch-role contract
unchanged. See test_auth.py::TestMultiRole for the login/switch-role
behaviour itself — this file focuses on the storage layer underneath it."""

from app.models.user import UserRoleGrant


class TestRegistrationCreatesGrantRow:
    def test_register_creates_a_user_roles_row_for_primary_role(self, client, db):
        # /auth/register always forces new accounts to pending "student"
        # regardless of the requested role — that's existing, intentional
        # behaviour (real role assignment happens via admin/assign-role).
        resp = client.post("/auth/register", json={
            "name": "New Student", "email": "newmentor@test.local",
            "password": "testpass123", "age": 16,
        })
        user_id = resp.json()["user"]["id"]
        grants = db.query(UserRoleGrant).filter(UserRoleGrant.user_id == user_id).all()
        assert len(grants) == 1
        assert grants[0].role == "student"
        assert grants[0].status == "active"

    def test_registered_users_roles_field_matches_grant_table(self, client):
        resp = client.post("/auth/register", json={
            "name": "New Student", "email": "newstudent@test.local",
            "password": "testpass123", "age": 16, "role": "student",
        })
        assert resp.json()["user"]["roles"] == ["student"]


class TestRoleGrantsWriteThroughUserRoles:
    def test_grant_creates_active_grant_row(self, client, admin_headers, student_user, db):
        resp = client.post(
            f"/admin/users/{student_user.id}/roles",
            json={"role": "event_manager"},
            headers=admin_headers,
        )
        assert resp.status_code == 201, resp.text
        assert set(resp.json()["roles"]) == {"student", "event_manager"}

        grants = db.query(UserRoleGrant).filter(
            UserRoleGrant.user_id == student_user.id, UserRoleGrant.status == "active",
        ).all()
        assert {g.role for g in grants} == {"student", "event_manager"}

    def test_regranting_same_role_does_not_duplicate_the_row(self, client, admin_headers, student_user, db):
        client.post(
            f"/admin/users/{student_user.id}/roles",
            json={"role": "event_manager"},
            headers=admin_headers,
        )
        client.delete(f"/admin/users/{student_user.id}/roles/event_manager", headers=admin_headers)
        resp = client.post(
            f"/admin/users/{student_user.id}/roles",
            json={"role": "event_manager"},
            headers=admin_headers,
        )
        assert resp.status_code == 201, resp.text

        all_rows = db.query(UserRoleGrant).filter(
            UserRoleGrant.user_id == student_user.id, UserRoleGrant.role == "event_manager",
        ).all()
        # Reactivated the same row rather than inserting a second one —
        # proven by the unique constraint not raising and exactly one row
        # existing for (user_id, role).
        assert len(all_rows) == 1
        assert all_rows[0].status == "active"

    def test_revoking_a_role_deactivates_but_does_not_delete(self, client, admin_headers, student_user, db):
        client.post(
            f"/admin/users/{student_user.id}/roles",
            json={"role": "event_manager"},
            headers=admin_headers,
        )
        resp = client.delete(f"/admin/users/{student_user.id}/roles/event_manager", headers=admin_headers)
        assert resp.status_code == 200
        assert resp.json()["roles"] == ["student"]

        row = db.query(UserRoleGrant).filter(
            UserRoleGrant.user_id == student_user.id, UserRoleGrant.role == "event_manager",
        ).first()
        assert row is not None
        assert row.status == "inactive"

    def test_granted_role_persists_across_login(self, client, admin_headers, student_user):
        client.post(
            f"/admin/users/{student_user.id}/roles",
            json={"role": "event_manager"},
            headers=admin_headers,
        )
        login = client.post("/auth/login", json={"email": "student@test.local", "password": "testpass123"})
        assert login.status_code == 200
        assert set(login.json()["roles"]) == {"student", "event_manager"}


class TestAssignRoleUpdatesGrantTable:
    def test_assigning_a_new_primary_role_grants_it_in_user_roles(self, client, admin_headers, db):
        reg = client.post("/auth/register", json={
            "name": "Pending", "email": "pending2@test.local", "password": "testpass123", "age": 19,
        })
        user_id = reg.json()["user"]["id"]
        client.patch(f"/admin/users/{user_id}/assign-role", json={"role": "mentor"}, headers=admin_headers)

        grants = db.query(UserRoleGrant).filter(
            UserRoleGrant.user_id == user_id, UserRoleGrant.status == "active",
        ).all()
        assert any(g.role == "mentor" for g in grants)

    def test_reassigning_role_does_not_duplicate_grant_row(self, client, admin_headers, db):
        reg = client.post("/auth/register", json={
            "name": "Pending", "email": "pending3@test.local", "password": "testpass123", "age": 19,
        })
        user_id = reg.json()["user"]["id"]
        client.patch(f"/admin/users/{user_id}/assign-role", json={"role": "mentor"}, headers=admin_headers)
        client.patch(f"/admin/users/{user_id}/assign-role", json={"role": "mentor"}, headers=admin_headers)

        rows = db.query(UserRoleGrant).filter(
            UserRoleGrant.user_id == user_id, UserRoleGrant.role == "mentor",
        ).all()
        assert len(rows) == 1
