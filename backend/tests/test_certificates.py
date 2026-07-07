"""Certificates feature: admin-issued certificates, student visibility, and
public QR-token verification. (Signed-PDF download/public-verify round trip
is covered separately in test_production_workflows.py — this file focuses
on the plain CRUD/visibility/permission surface.)"""

CERT_PAYLOAD = {
    "certificate_type": "volunteer",
    "activity_name": "Beach Cleanup Drive",
    "duration": "3 months",
}


def _create_cert(client, admin_headers, student_id, **overrides):
    payload = {**CERT_PAYLOAD, "student_id": student_id, **overrides}
    return client.post("/certificates", json=payload, headers=admin_headers)


class TestCreateAndVisibility:
    def test_admin_can_issue_certificate(self, client, admin_headers, student_user):
        resp = _create_cert(client, admin_headers, student_user.id)
        assert resp.status_code == 200, resp.text
        assert resp.json()["activity_name"] == "Beach Cleanup Drive"

    def test_student_cannot_issue_certificate(self, client, student_headers, student_user):
        resp = client.post("/certificates", json={
            **CERT_PAYLOAD, "student_id": student_user.id,
        }, headers=student_headers)
        assert resp.status_code == 403

    def test_student_sees_own_certificate(self, client, admin_headers, student_headers, student_user):
        _create_cert(client, admin_headers, student_user.id)
        resp = client.get("/certificates/me", headers=student_headers)
        assert resp.status_code == 200
        assert len(resp.json()) == 1

    def test_admin_lists_all_certificates(self, client, admin_headers, student_user):
        _create_cert(client, admin_headers, student_user.id)
        resp = client.get("/certificates", headers=admin_headers)
        assert resp.status_code == 200
        assert len(resp.json()) == 1

    def test_student_cannot_list_all_certificates(self, client, student_headers):
        resp = client.get("/certificates", headers=student_headers)
        assert resp.status_code == 403


class TestPublicVerification:
    def test_verify_by_valid_qr_token(self, client, admin_headers, student_user):
        created = _create_cert(client, admin_headers, student_user.id).json()
        resp = client.get(f"/certificates/verify/{created['qr_token']}")
        assert resp.status_code == 200
        assert resp.json()["activity_name"] == "Beach Cleanup Drive"

    def test_verify_by_invalid_token_404s(self, client):
        resp = client.get("/certificates/verify/not-a-real-token")
        assert resp.status_code == 404

    def test_verification_requires_no_auth(self, client, admin_headers, student_user):
        """Public verification (e.g. an employer scanning a QR code) must
        work without any Authorization header."""
        created = _create_cert(client, admin_headers, student_user.id).json()
        resp = client.get(f"/certificates/verify/{created['qr_token']}")
        assert resp.status_code == 200


class TestUpdateCertificate:
    def test_admin_can_update(self, client, admin_headers, student_user):
        created = _create_cert(client, admin_headers, student_user.id).json()
        resp = client.put(
            f"/certificates/{created['id']}",
            json={"activity_name": "Updated Activity Name"},
            headers=admin_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["activity_name"] == "Updated Activity Name"

    def test_event_manager_can_update(self, client, admin_headers, event_manager_headers, student_user):
        created = _create_cert(client, admin_headers, student_user.id).json()
        resp = client.put(
            f"/certificates/{created['id']}",
            json={"duration": "6 months"},
            headers=event_manager_headers,
        )
        assert resp.status_code == 200

    def test_student_cannot_update(self, client, admin_headers, student_headers, student_user):
        created = _create_cert(client, admin_headers, student_user.id).json()
        resp = client.put(
            f"/certificates/{created['id']}",
            json={"duration": "6 months"},
            headers=student_headers,
        )
        assert resp.status_code == 403
