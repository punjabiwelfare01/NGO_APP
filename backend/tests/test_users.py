"""Generic Users feature: role assignment, activate/deactivate, XP awards
and learning stats. (PATCH /users/me/profile is covered in
test_production_workflows.py::test_student_profile_update_is_saved.)"""


class TestRoleAssignment:
    def test_admin_can_assign_role(self, client, admin_headers, student_user):
        resp = client.patch(f"/users/{student_user.id}/role", json={"role": "mentor"}, headers=admin_headers)
        assert resp.status_code == 200, resp.text
        assert resp.json()["role"] == "mentor"

    def test_student_cannot_assign_role(self, client, student_headers, mentor_user):
        resp = client.patch(f"/users/{mentor_user.id}/role", json={"role": "admin"}, headers=student_headers)
        assert resp.status_code == 403

    def test_only_super_admin_can_promote_to_super_admin(self, client, admin_headers, super_admin_headers, student_user):
        denied = client.patch(f"/users/{student_user.id}/role", json={"role": "super_admin"}, headers=admin_headers)
        assert denied.status_code == 403

        allowed = client.patch(f"/users/{student_user.id}/role", json={"role": "super_admin"}, headers=super_admin_headers)
        assert allowed.status_code == 200


class TestUserStatus:
    def test_admin_can_deactivate_and_reactivate(self, client, admin_headers, student_user):
        deactivated = client.patch(
            f"/users/{student_user.id}/status", json={"is_active": False}, headers=admin_headers,
        )
        assert deactivated.status_code == 200
        assert deactivated.json()["is_active"] is False

        reactivated = client.patch(
            f"/users/{student_user.id}/status", json={"is_active": True}, headers=admin_headers,
        )
        assert reactivated.json()["is_active"] is True

    def test_student_cannot_change_status(self, client, student_headers, mentor_user):
        resp = client.patch(f"/users/{mentor_user.id}/status", json={"is_active": False}, headers=student_headers)
        assert resp.status_code == 403


class TestXpAndStats:
    def test_mentor_can_award_xp(self, client, mentor_headers, student_user):
        resp = client.post(f"/users/{student_user.id}/xp", json={"amount": 50}, headers=mentor_headers)
        assert resp.status_code == 200, resp.text

    def test_student_cannot_award_xp(self, client, student_headers, mentor_user):
        resp = client.post(f"/users/{mentor_user.id}/xp", json={"amount": 50}, headers=student_headers)
        assert resp.status_code == 403

    def test_student_can_view_own_stats(self, client, student_headers, student_user):
        resp = client.get(f"/users/{student_user.id}/stats", headers=student_headers)
        assert resp.status_code == 200

    def test_student_cannot_view_others_stats(self, client, student_headers, mentor_user):
        resp = client.get(f"/users/{mentor_user.id}/stats", headers=student_headers)
        assert resp.status_code == 403

    def test_admin_can_view_any_stats(self, client, admin_headers, student_user):
        resp = client.get(f"/users/{student_user.id}/stats", headers=admin_headers)
        assert resp.status_code == 200
