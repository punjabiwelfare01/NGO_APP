"""Admin Settings feature: NGO profile, official bank/UPI details, and the
public read-only endpoints every role's home/donation screens rely on."""


class TestNgoProfile:
    def test_admin_can_update_ngo_profile(self, client, admin_headers):
        resp = client.patch("/admin/settings/ngo-profile", json={
            "name": "Punjabi Welfare Trust",
            "registration_number": "736",
            "phone": "9211772333",
            "address": "Sadar Bazar Delhi Cantt",
        }, headers=admin_headers)
        assert resp.status_code == 200, resp.text
        assert resp.json()["phone"] == "9211772333"

    def test_student_cannot_update_ngo_profile(self, client, student_headers):
        resp = client.patch("/admin/settings/ngo-profile", json={"phone": "123"}, headers=student_headers)
        assert resp.status_code == 403

    def test_public_endpoint_visible_to_any_authenticated_role(self, client, admin_headers, student_headers):
        client.patch("/admin/settings/ngo-profile", json={
            "name": "Punjabi Welfare Trust", "phone": "9211772333",
        }, headers=admin_headers)
        resp = client.get("/admin/settings/ngo-profile/public", headers=student_headers)
        assert resp.status_code == 200
        assert resp.json()["phone"] == "9211772333"

    def test_public_endpoint_returns_defaults_when_unset(self, client, student_headers):
        resp = client.get("/admin/settings/ngo-profile/public", headers=student_headers)
        assert resp.status_code == 200
        assert resp.json()["name"] == "Punjabi Welfare Trust"


class TestBankSettings:
    def test_admin_update_requires_confirmation(self, client, admin_headers):
        resp = client.patch("/admin/settings/bank", json={
            "account_holder": "Punjabi Welfare Trust", "upi_id": "trust@upi",
        }, headers=admin_headers)
        assert resp.status_code == 400

    def test_admin_can_update_bank_with_confirmation(self, client, admin_headers):
        resp = client.patch("/admin/settings/bank", json={
            "account_holder": "Punjabi Welfare Trust",
            "bank_name": "Union Bank of India",
            "account_number": "35270101011873",
            "ifsc_code": "UBIN0535273",
            "upi_id": "trust@upi",
            "confirmation": "CONFIRM",
        }, headers=admin_headers)
        assert resp.status_code == 200, resp.text
        assert resp.json()["upi_id"] == "trust@upi"

    def test_student_cannot_read_admin_bank_endpoint(self, client, student_headers):
        resp = client.get("/admin/settings/bank", headers=student_headers)
        assert resp.status_code == 403

    def test_bank_public_endpoint_visible_to_any_role_and_matches_admin_write(
        self, client, admin_headers, student_headers, school_partner_headers,
    ):
        client.patch("/admin/settings/bank", json={
            "upi_id": "trust@upi", "confirmation": "CONFIRM",
        }, headers=admin_headers)

        for headers in (student_headers, school_partner_headers):
            resp = client.get("/admin/settings/bank/public", headers=headers)
            assert resp.status_code == 200
            assert resp.json()["upi_id"] == "trust@upi"

    def test_bank_public_endpoint_never_exposes_confirmation_field(self, client, admin_headers, student_headers):
        client.patch("/admin/settings/bank", json={
            "upi_id": "trust@upi", "confirmation": "CONFIRM",
        }, headers=admin_headers)
        resp = client.get("/admin/settings/bank/public", headers=student_headers)
        assert resp.json().get("confirmation") is None


class TestRolesAndPermissions:
    def test_admin_can_list_roles(self, client, admin_headers):
        resp = client.get("/admin/roles", headers=admin_headers)
        assert resp.status_code == 200
        roles = [r["role"] for r in resp.json()]
        assert "student" in roles and "mentor" in roles

    def test_update_role_permissions(self, client, admin_headers):
        resp = client.patch(
            "/admin/roles/mentor/permissions",
            json={"permissions": ["view_students", "manage_sessions"]},
            headers=admin_headers,
        )
        assert resp.status_code == 200
        assert set(resp.json()["permissions"]) == {"view_students", "manage_sessions"}


class TestAnnouncements:
    def test_create_and_list_announcement(self, client, admin_headers):
        create = client.post("/admin/announcements", json={
            "title": "Platform Update",
            "message": "New feature rolled out.",
        }, headers=admin_headers)
        assert create.status_code == 201, create.text

        listing = client.get("/admin/announcements", headers=admin_headers)
        assert len(listing.json()) == 1

    def test_delete_announcement(self, client, admin_headers):
        created = client.post("/admin/announcements", json={
            "title": "Temp", "message": "msg",
        }, headers=admin_headers).json()
        resp = client.delete(f"/admin/announcements/{created['id']}", headers=admin_headers)
        assert resp.status_code == 204
        assert client.get("/admin/announcements", headers=admin_headers).json() == []


class TestAppSettings:
    def test_update_and_read_app_settings(self, client, admin_headers):
        resp = client.patch("/admin/app-settings", json={
            "values": {"maintenance_mode": False, "max_upload_mb": 25},
        }, headers=admin_headers)
        assert resp.status_code == 200
        values = resp.json()["values"]
        assert values["maintenance_mode"] is False
        assert values["max_upload_mb"] == 25
