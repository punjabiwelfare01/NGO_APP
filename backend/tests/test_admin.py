"""Admin user-management feature: approval workflow, role assignment,
secondary roles (multi-role accounts), block/unblock, and deletion."""


def _register_pending(client, email="new@test.local", role="student"):
    resp = client.post("/auth/register", json={
        "name": "New User",
        "email": email,
        "password": "testpass123",
        "age": 19,
        "role": role,
    })
    assert resp.status_code == 201, resp.text
    return resp.json()["user"]["id"]


class TestApprovalWorkflow:
    def test_new_registration_is_pending(self, client, admin_headers):
        user_id = _register_pending(client)
        pending = client.get("/admin/users/pending", headers=admin_headers).json()
        assert any(u["id"] == user_id for u in pending)

    def test_approve_assigns_role_and_clears_pending(self, client, admin_headers):
        user_id = _register_pending(client)
        resp = client.patch(
            f"/admin/users/{user_id}/assign-role",
            json={"role": "student"},
            headers=admin_headers,
        )
        assert resp.status_code == 200, resp.text
        assert resp.json()["access_status"] == "approved"

        pending = client.get("/admin/users/pending", headers=admin_headers).json()
        assert not any(u["id"] == user_id for u in pending)

    def test_non_admin_cannot_approve(self, client, student_headers):
        resp = client.patch(
            "/admin/users/1/assign-role", json={"role": "student"}, headers=student_headers,
        )
        assert resp.status_code == 403

    def test_reject_sets_status(self, client, admin_headers):
        user_id = _register_pending(client)
        resp = client.patch(
            f"/admin/users/{user_id}/reject",
            json={"reason": "Incomplete documents"},
            headers=admin_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["access_status"] == "rejected"

    def test_only_super_admin_can_assign_super_admin_role(self, client, admin_headers, super_admin_headers):
        user_id = _register_pending(client)
        denied = client.patch(
            f"/admin/users/{user_id}/assign-role",
            json={"role": "super_admin"},
            headers=admin_headers,
        )
        assert denied.status_code == 403

        allowed = client.patch(
            f"/admin/users/{user_id}/assign-role",
            json={"role": "super_admin"},
            headers=super_admin_headers,
        )
        assert allowed.status_code == 200


class TestRoleGrants:
    def test_grant_and_revoke_role(self, client, admin_headers):
        user_id = _register_pending(client)
        client.patch(f"/admin/users/{user_id}/assign-role", json={"role": "student"}, headers=admin_headers)

        grant = client.post(
            f"/admin/users/{user_id}/roles",
            json={"role": "event_manager"},
            headers=admin_headers,
        )
        assert grant.status_code == 201, grant.text
        assert set(grant.json()["roles"]) == {"student", "event_manager"}

        revoke = client.delete(f"/admin/users/{user_id}/roles/event_manager", headers=admin_headers)
        assert revoke.status_code == 200, revoke.text
        assert revoke.json()["roles"] == ["student"]

    def test_granting_an_already_held_role_does_not_duplicate_it(self, client, admin_headers):
        user_id = _register_pending(client)
        client.patch(f"/admin/users/{user_id}/assign-role", json={"role": "student"}, headers=admin_headers)
        resp = client.post(
            f"/admin/users/{user_id}/roles",
            json={"role": "student"},
            headers=admin_headers,
        )
        assert resp.status_code == 201, resp.text
        assert resp.json()["roles"] == ["student"]

    def test_cannot_revoke_the_primary_role(self, client, admin_headers):
        user_id = _register_pending(client)
        client.patch(f"/admin/users/{user_id}/assign-role", json={"role": "student"}, headers=admin_headers)
        resp = client.delete(f"/admin/users/{user_id}/roles/student", headers=admin_headers)
        assert resp.status_code == 422

    def test_revoking_a_role_never_granted_returns_404(self, client, admin_headers):
        user_id = _register_pending(client)
        client.patch(f"/admin/users/{user_id}/assign-role", json={"role": "student"}, headers=admin_headers)
        resp = client.delete(f"/admin/users/{user_id}/roles/event_manager", headers=admin_headers)
        assert resp.status_code == 404

    def test_grant_rejects_invalid_role(self, client, admin_headers):
        user_id = _register_pending(client)
        client.patch(f"/admin/users/{user_id}/assign-role", json={"role": "student"}, headers=admin_headers)
        resp = client.post(
            f"/admin/users/{user_id}/roles",
            json={"role": "not_a_role"},
            headers=admin_headers,
        )
        assert resp.status_code == 422

    def test_non_super_admin_cannot_grant_super_admin_role(self, client, admin_headers):
        user_id = _register_pending(client)
        client.patch(f"/admin/users/{user_id}/assign-role", json={"role": "student"}, headers=admin_headers)
        resp = client.post(
            f"/admin/users/{user_id}/roles",
            json={"role": "super_admin"},
            headers=admin_headers,
        )
        assert resp.status_code == 403


class TestBlockUnblock:
    def test_block_then_unblock(self, client, admin_headers):
        user_id = _register_pending(client)
        client.patch(f"/admin/users/{user_id}/assign-role", json={"role": "student"}, headers=admin_headers)

        blocked = client.patch(
            f"/admin/users/{user_id}/block", json={"reason": "Policy violation"}, headers=admin_headers,
        )
        assert blocked.status_code == 200
        assert blocked.json()["access_status"] == "deactivated"
        assert blocked.json()["is_active"] is False

        unblocked = client.patch(f"/admin/users/{user_id}/unblock", headers=admin_headers)
        assert unblocked.status_code == 200
        assert unblocked.json()["access_status"] == "approved"
        assert unblocked.json()["is_active"] is True

    def test_blocked_user_cannot_login(self, client, admin_headers):
        user_id = _register_pending(client, email="blockme@test.local")
        client.patch(f"/admin/users/{user_id}/assign-role", json={"role": "student"}, headers=admin_headers)
        client.patch(f"/admin/users/{user_id}/block", json={}, headers=admin_headers)

        resp = client.post("/auth/login", json={"email": "blockme@test.local", "password": "testpass123"})
        assert resp.status_code in (401, 403)


class TestDeleteUser:
    def test_admin_can_delete_user(self, client, admin_headers):
        user_id = _register_pending(client)
        resp = client.delete(f"/admin/users/{user_id}", headers=admin_headers)
        assert resp.status_code == 204
        assert client.get(f"/admin/users/{user_id}", headers=admin_headers).status_code == 404

    def test_student_cannot_delete_user(self, client, admin_headers, student_headers):
        user_id = _register_pending(client)
        resp = client.delete(f"/admin/users/{user_id}", headers=student_headers)
        assert resp.status_code == 403


class TestDashboardStats:
    def test_admin_stats_endpoint(self, client, admin_headers):
        _register_pending(client)
        resp = client.get("/admin/stats", headers=admin_headers)
        assert resp.status_code == 200

    def test_list_all_users(self, client, admin_headers, student_user):
        resp = client.get("/admin/users", headers=admin_headers)
        assert resp.status_code == 200
        assert any(u["email"] == "student@test.local" for u in resp.json())
