"""School Partner feature: counsellor request lifecycle (submit, list,
cancel, reveal-gating of contact details) and the school partner's own
profile."""


def _request_payload(counsellor_id: int, **overrides):
    payload = {
        "counsellor_id": counsellor_id,
        "school_name": "Green Valley Public School",
        "coordinator_name": "Mrs. Sharma",
        "coordinator_phone": "9876543210",
        "coordinator_email": "coordinator@greenvalley.edu",
        "topic": "Career Guidance for Class 10",
        "preferred_at": "2030-08-15T10:00:00",
        "mode": "offline",
    }
    payload.update(overrides)
    return payload


class TestSubmitRequest:
    def test_school_partner_can_submit_request(self, client, school_partner_headers, mentor_user):
        resp = client.post(
            "/school/counsellor-requests",
            json=_request_payload(mentor_user.id),
            headers=school_partner_headers,
        )
        assert resp.status_code == 201, resp.text
        assert resp.json()["status"] == "new_request"
        assert resp.json()["school_name"] == "Green Valley Public School"

    def test_contact_details_hidden_before_acceptance(self, client, school_partner_headers, mentor_user):
        resp = client.post(
            "/school/counsellor-requests",
            json=_request_payload(mentor_user.id),
            headers=school_partner_headers,
        )
        body = resp.json()
        # reveal=False while status == "new_request" — phone/email are the
        # school's own coordinator contact, echoed back masked until the
        # counsellor engages, matching the app's stated privacy behaviour.
        assert body["coordinator_phone"] == ""
        assert body["coordinator_email"] == ""

    def test_any_authenticated_role_can_submit(self, client, admin_headers, mentor_user):
        """The endpoint only requires auth, not school_partner role specifically."""
        resp = client.post(
            "/school/counsellor-requests",
            json=_request_payload(mentor_user.id),
            headers=admin_headers,
        )
        assert resp.status_code == 201


class TestMyRequests:
    def test_list_and_detail(self, client, school_partner_headers, mentor_user):
        created = client.post(
            "/school/counsellor-requests",
            json=_request_payload(mentor_user.id),
            headers=school_partner_headers,
        ).json()

        listing = client.get("/school/my-requests", headers=school_partner_headers)
        assert listing.status_code == 200
        assert len(listing.json()) == 1

        detail = client.get(f"/school/my-requests/{created['id']}", headers=school_partner_headers)
        assert detail.status_code == 200
        assert detail.json()["topic"] == "Career Guidance for Class 10"

    def test_cannot_view_other_schools_request(self, client, school_partner_headers, admin_headers, mentor_user):
        created = client.post(
            "/school/counsellor-requests",
            json=_request_payload(mentor_user.id),
            headers=admin_headers,  # different requester
        ).json()
        resp = client.get(f"/school/my-requests/{created['id']}", headers=school_partner_headers)
        assert resp.status_code == 404

    def test_cancel_request(self, client, school_partner_headers, mentor_user):
        created = client.post(
            "/school/counsellor-requests",
            json=_request_payload(mentor_user.id),
            headers=school_partner_headers,
        ).json()
        resp = client.patch(
            f"/school/my-requests/{created['id']}/cancel", headers=school_partner_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["status"] == "cancelled"

    def test_cannot_cancel_already_cancelled_request(self, client, school_partner_headers, mentor_user):
        created = client.post(
            "/school/counsellor-requests",
            json=_request_payload(mentor_user.id),
            headers=school_partner_headers,
        ).json()
        client.patch(f"/school/my-requests/{created['id']}/cancel", headers=school_partner_headers)
        resp = client.patch(f"/school/my-requests/{created['id']}/cancel", headers=school_partner_headers)
        assert resp.status_code == 409

    def test_confirm_time_requires_rescheduled_status(self, client, school_partner_headers, mentor_user):
        created = client.post(
            "/school/counsellor-requests",
            json=_request_payload(mentor_user.id),
            headers=school_partner_headers,
        ).json()
        resp = client.patch(
            f"/school/my-requests/{created['id']}/confirm-time", headers=school_partner_headers,
        )
        assert resp.status_code == 409


class TestSchoolProfile:
    def test_non_school_partner_cannot_access_profile(self, client, student_headers):
        resp = client.get("/school/profile", headers=student_headers)
        assert resp.status_code == 403

    def test_get_and_update_profile(self, client, school_partner_headers):
        resp = client.patch("/school/profile", json={
            "school_name": "Green Valley Public School",
            "school_type": "private",
            "city": "Delhi",
            "state": "Delhi",
        }, headers=school_partner_headers)
        assert resp.status_code == 200, resp.text

        read_back = client.get("/school/profile", headers=school_partner_headers)
        assert read_back.status_code == 200
