"""Counsellor profile feature: mentor profile CRUD, extended profile fields,
the school-facing directory privacy fix (phone/location only visible to
admins or the counsellor themselves), and the featured flag.
"""


class TestMentorOwnProfile:
    def test_get_own_profile_requires_mentor_role(self, client, student_headers):
        resp = client.get("/counselling/mentors/me", headers=student_headers)
        assert resp.status_code == 403

    def test_get_own_profile_404_before_created(self, client, mentor_headers):
        resp = client.get("/counselling/mentors/me", headers=mentor_headers)
        assert resp.status_code == 404

    def test_create_own_profile_via_patch(self, client, mentor_headers):
        resp = client.patch("/counselling/mentors/me", json={
            "display_name": "Dr. Meera",
            "bio": "Career counsellor",
            "expertise": "Career, Anxiety",
            "category": "career_counsellor",
        }, headers=mentor_headers)
        assert resp.status_code == 200, resp.text
        body = resp.json()
        assert body["display_name"] == "Dr. Meera"
        assert body["featured"] is False

        resp2 = client.get("/counselling/mentors/me", headers=mentor_headers)
        assert resp2.status_code == 200
        assert resp2.json()["bio"] == "Career counsellor"

    def test_update_own_profile(self, client, mentor_headers):
        client.patch("/counselling/mentors/me", json={"display_name": "Dr. Meera"}, headers=mentor_headers)
        resp = client.patch("/counselling/mentors/me", json={"bio": "Updated bio"}, headers=mentor_headers)
        assert resp.status_code == 200
        assert resp.json()["bio"] == "Updated bio"


class TestExtendedProfile:
    def test_extended_profile_empty_before_creation(self, client, mentor_headers):
        resp = client.get("/counselling/mentors/me/extended", headers=mentor_headers)
        assert resp.status_code == 200
        assert resp.json() == {}

    def test_update_extended_profile_creates_and_persists(self, client, mentor_headers):
        resp = client.patch("/counselling/mentors/me/extended", json={
            "qualification": "M.A. Psychology",
            "years_of_experience": 8,
            "counselling_mode": "online",
            "languages_known": "English, Hindi",
            "organization": "Punjabi Welfare Trust",
            "gender": "female",
            "city": "Delhi",
            "state": "Delhi",
            "pin_code": "110001",
        }, headers=mentor_headers)
        assert resp.status_code == 200, resp.text
        body = resp.json()
        assert body["qualification"] == "M.A. Psychology"
        assert body["years_of_experience"] == 8
        assert body["city"] == "Delhi"

        # A second GET should reflect the same persisted values.
        resp2 = client.get("/counselling/mentors/me/extended", headers=mentor_headers)
        assert resp2.json()["organization"] == "Punjabi Welfare Trust"

    def test_extended_profile_includes_verification_fields(self, client, mentor_headers):
        """Regression: the previously-active endpoint never returned
        verification/doc fields, so the Verification Documents card in the
        app could never show real status after an upload."""
        resp = client.get("/counselling/mentors/me/extended", headers=mentor_headers)
        assert resp.status_code == 200
        body = resp.json()
        assert body == {}  # no profile yet — nothing to assert field names on

        client.patch("/counselling/mentors/me/extended", json={"qualification": "MSc"}, headers=mentor_headers)
        resp2 = client.get("/counselling/mentors/me/extended", headers=mentor_headers)
        body2 = resp2.json()
        for field in (
            "id_proof_type", "id_proof_number", "id_proof_doc_url",
            "professional_cert_url", "verification_status", "verified_by",
            "verified_at", "admin_remark",
        ):
            assert field in body2, f"expected {field} in extended profile response"
        assert body2["verification_status"] == "pending"

    def test_upload_verification_doc_then_visible_via_extended_profile(self, client, mentor_headers):
        client.patch("/counselling/mentors/me/extended", json={"qualification": "MSc"}, headers=mentor_headers)
        resp = client.post(
            "/counsellor/upload-verification-doc",
            data={"doc_type": "id_proof"},
            files={"file": ("aadhar.png", b"fake-image-bytes", "image/png")},
            headers=mentor_headers,
        )
        assert resp.status_code == 200, resp.text
        url = resp.json()["url"]
        assert url.startswith("/uploads/counsellor_docs/")

        follow_up = client.get("/counselling/mentors/me/extended", headers=mentor_headers)
        assert follow_up.json()["id_proof_doc_url"] == url

    def test_duplicate_extended_profile_endpoint_removed(self, client, mentor_headers):
        """The old /counsellor/profile/extended endpoint duplicated
        /counselling/mentors/me/extended and was never called by the app —
        it should no longer exist. Unmatched backend routes fall through to
        the Flutter web SPA's index.html (200, text/html) rather than a JSON
        404, so assert on content-type/shape rather than status code."""
        resp = client.get("/counsellor/profile/extended", headers=mentor_headers)
        assert "application/json" not in resp.headers.get("content-type", "")


class TestDirectoryPrivacy:
    """The school-facing directory (GET /counselling/mentors[/id]) must not
    leak phone/location/verification data to non-privileged callers."""

    def _make_mentor(self, client, mentor_headers):
        client.patch("/counselling/mentors/me", json={"display_name": "Dr. Meera"}, headers=mentor_headers)
        client.patch("/counselling/mentors/me/extended", json={
            "qualification": "M.A. Psychology", "city": "Delhi",
        }, headers=mentor_headers)

    def test_school_partner_does_not_see_private_fields(self, client, mentor_headers, school_partner_headers):
        self._make_mentor(client, mentor_headers)
        resp = client.get("/counselling/mentors", headers=school_partner_headers)
        assert resp.status_code == 200
        mentors = resp.json()
        assert len(mentors) == 1
        m = mentors[0]
        assert m["display_name"] == "Dr. Meera"
        for private_field in ("phone", "location", "city", "state", "pin_code",
                               "verification_status", "admin_remark",
                               "id_proof_doc_url", "professional_cert_url"):
            assert private_field not in m, f"{private_field} leaked to school partner"

    def test_student_does_not_see_private_fields(self, client, mentor_headers, student_headers):
        self._make_mentor(client, mentor_headers)
        resp = client.get("/counselling/mentors", headers=student_headers)
        assert resp.status_code == 200
        assert "phone" not in resp.json()[0]

    def test_admin_sees_private_fields(self, client, mentor_headers, admin_headers):
        self._make_mentor(client, mentor_headers)
        resp = client.get("/counselling/mentors", headers=admin_headers)
        assert resp.status_code == 200
        m = resp.json()[0]
        assert "location" in m
        assert m["city"] == "Delhi"

    def test_mentor_sees_own_private_fields_via_detail_endpoint(self, client, mentor_headers):
        self._make_mentor(client, mentor_headers)
        listing = client.get("/counselling/mentors", headers=mentor_headers).json()
        mentor_id = listing[0]["id"]
        resp = client.get(f"/counselling/mentors/{mentor_id}", headers=mentor_headers)
        assert resp.status_code == 200
        assert "city" in resp.json()


class TestFeaturedFlag:
    def test_toggle_featured_by_user_id_requires_admin(self, client, mentor_headers, mentor_user):
        resp = client.patch(
            f"/counselling/mentors/by-user/{mentor_user.id}",
            json={"featured": True},
            headers=mentor_headers,
        )
        assert resp.status_code == 403

    def test_admin_can_toggle_featured_and_it_persists(self, client, mentor_headers, mentor_user, admin_headers, school_partner_headers):
        client.patch("/counselling/mentors/me", json={"display_name": "Dr. Meera"}, headers=mentor_headers)

        resp = client.patch(
            f"/counselling/mentors/by-user/{mentor_user.id}",
            json={"featured": True},
            headers=admin_headers,
        )
        assert resp.status_code == 200, resp.text
        assert resp.json()["featured"] is True

        # Persisted and visible through the public directory too.
        listing = client.get("/counselling/mentors", headers=school_partner_headers).json()
        assert listing[0]["featured"] is True

    def test_toggle_featured_unknown_user_404s(self, client, admin_headers):
        resp = client.patch(
            "/counselling/mentors/by-user/999999",
            json={"featured": True},
            headers=admin_headers,
        )
        assert resp.status_code == 404
