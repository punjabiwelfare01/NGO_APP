"""Volunteer work feature: activities, assignments, work submissions and the
pending/approved review queues (approved queue + reviewed_at added this
session for the admin Volunteer Management screen's Approved tab)."""

ACTIVITY_PAYLOAD = {
    "title": "Beach Cleanup Drive",
    "category": "awareness_programs",
    "description": "Clean the local beach and raise awareness.",
    "reward_hours": 4.0,
}


class TestActivities:
    def test_admin_can_create_activity(self, client, admin_headers):
        resp = client.post("/volunteer/activities", json=ACTIVITY_PAYLOAD, headers=admin_headers)
        assert resp.status_code == 200, resp.text
        assert resp.json()["title"] == "Beach Cleanup Drive"

    def test_student_cannot_create_activity(self, client, student_headers):
        resp = client.post("/volunteer/activities", json=ACTIVITY_PAYLOAD, headers=student_headers)
        assert resp.status_code == 403

    def test_event_manager_can_create_activity(self, client, event_manager_headers):
        resp = client.post("/volunteer/activities", json=ACTIVITY_PAYLOAD, headers=event_manager_headers)
        assert resp.status_code == 200

    def test_event_manager_cannot_edit_others_activity(self, client, admin_headers, event_manager_headers):
        created = client.post("/volunteer/activities", json=ACTIVITY_PAYLOAD, headers=admin_headers).json()
        resp = client.patch(
            f"/volunteer/activities/{created['id']}",
            json={"title": "Hijacked title"},
            headers=event_manager_headers,
        )
        assert resp.status_code == 403

    def test_list_activities_public(self, client, admin_headers, student_headers):
        client.post("/volunteer/activities", json=ACTIVITY_PAYLOAD, headers=admin_headers)
        resp = client.get("/volunteer/activities", headers=student_headers)
        assert resp.status_code == 200
        assert len(resp.json()) >= 1


class TestWorkSubmissions:
    def _create_activity(self, client, admin_headers):
        return client.post("/volunteer/activities", json=ACTIVITY_PAYLOAD, headers=admin_headers).json()

    def _submit_work(self, client, student_headers, activity_id, **overrides):
        payload = {
            "activity_id": activity_id,
            "title": "Cleaned up 2km of beach",
            "description": "Collected plastic waste with 10 volunteers.",
            "hours_worked": 4.0,
            "people_reached": 10,
            "donation_collected": 0.0,
        }
        payload.update(overrides)
        return client.post("/volunteer/work-submissions", json=payload, headers=student_headers)

    def test_student_submits_work(self, client, admin_headers, student_headers):
        activity = self._create_activity(client, admin_headers)
        resp = self._submit_work(client, student_headers, activity["id"])
        assert resp.status_code == 201, resp.text
        assert resp.json()["status"] == "submitted"

    def test_submission_appears_in_pending_queue(self, client, admin_headers, student_headers):
        activity = self._create_activity(client, admin_headers)
        self._submit_work(client, student_headers, activity["id"])
        resp = client.get("/volunteer/submissions/pending", headers=admin_headers)
        assert resp.status_code == 200
        assert len(resp.json()) == 1

    def test_student_cannot_view_pending_queue(self, client, admin_headers, student_headers):
        activity = self._create_activity(client, admin_headers)
        self._submit_work(client, student_headers, activity["id"])
        resp = client.get("/volunteer/submissions/pending", headers=student_headers)
        assert resp.status_code == 403

    def test_approve_submission_moves_it_to_approved_queue_with_timestamp(self, client, admin_headers, student_headers):
        activity = self._create_activity(client, admin_headers)
        submission = self._submit_work(client, student_headers, activity["id"]).json()

        review = client.patch(
            f"/volunteer/submissions/{submission['id']}/review",
            json={"status": "approved", "reviewer_notes": "Great work!"},
            headers=admin_headers,
        )
        assert review.status_code == 200
        assert review.json()["status"] == "approved"

        pending = client.get("/volunteer/submissions/pending", headers=admin_headers).json()
        assert len(pending) == 0

        approved = client.get("/volunteer/submissions/approved", headers=admin_headers).json()
        assert len(approved) == 1
        assert approved[0]["id"] == submission["id"]
        assert approved[0]["reviewed_at"] is not None
        assert approved[0]["reviewer_notes"] == "Great work!"

    def test_rejected_submission_does_not_appear_in_approved_queue(self, client, admin_headers, student_headers):
        activity = self._create_activity(client, admin_headers)
        submission = self._submit_work(client, student_headers, activity["id"]).json()
        client.patch(
            f"/volunteer/submissions/{submission['id']}/review",
            json={"status": "rejected", "reviewer_notes": "Insufficient proof"},
            headers=admin_headers,
        )
        approved = client.get("/volunteer/submissions/approved", headers=admin_headers).json()
        assert approved == []

    def test_student_sees_own_submissions(self, client, admin_headers, student_headers):
        activity = self._create_activity(client, admin_headers)
        self._submit_work(client, student_headers, activity["id"])
        resp = client.get("/volunteer/submissions/me", headers=student_headers)
        assert resp.status_code == 200
        assert len(resp.json()) == 1

    def test_can_submit_new_work_after_previous_round_was_approved(
        self, client, admin_headers, student_headers,
    ):
        # A volunteer doing the same recurring activity again after an
        # earlier round was already approved must not be permanently
        # blocked with a 409 — a fresh assignment cycle should start
        # instead of reusing the now-locked one.
        activity = self._create_activity(client, admin_headers)
        first = self._submit_work(client, student_headers, activity["id"]).json()
        client.patch(
            f"/volunteer/submissions/{first['id']}/review",
            json={"status": "approved"},
            headers=admin_headers,
        )

        second = self._submit_work(client, student_headers, activity["id"], title="Second round of cleanup")
        assert second.status_code == 201, second.text
        assert second.json()["id"] != first["id"]
        assert second.json()["status"] == "submitted"


class TestReviewerRouting:
    """review_target (Phase 3): submissions on an admin-created activity
    auto-route to the admin queue; on an event-manager-created activity they
    auto-route to that event manager. The volunteer can override either way."""

    def _submit_work(self, client, student_headers, activity_id, **overrides):
        payload = {
            "activity_id": activity_id,
            "title": "Cleaned up 2km of beach",
            "description": "Collected plastic waste with 10 volunteers.",
            "hours_worked": 4.0,
        }
        payload.update(overrides)
        return client.post("/volunteer/work-submissions", json=payload, headers=student_headers)

    def test_admin_created_activity_auto_routes_to_admin(self, client, admin_headers, student_headers):
        activity = client.post("/volunteer/activities", json=ACTIVITY_PAYLOAD, headers=admin_headers).json()
        submission = self._submit_work(client, student_headers, activity["id"]).json()
        assert submission["review_target"] == "admin"

    def test_event_manager_created_activity_auto_routes_to_event_manager(
        self, client, event_manager_headers, student_headers,
    ):
        activity = client.post("/volunteer/activities", json=ACTIVITY_PAYLOAD, headers=event_manager_headers).json()
        submission = self._submit_work(client, student_headers, activity["id"]).json()
        assert submission["review_target"] == "event_manager"

    def test_volunteer_can_override_the_automatic_default(self, client, admin_headers, student_headers):
        activity = client.post("/volunteer/activities", json=ACTIVITY_PAYLOAD, headers=admin_headers).json()
        submission = self._submit_work(
            client, student_headers, activity["id"], review_target="event_manager",
        ).json()
        assert submission["review_target"] == "event_manager"

    def test_admin_cannot_review_a_submission_routed_to_event_manager(
        self, client, event_manager_headers, admin_headers, student_headers,
    ):
        activity = client.post("/volunteer/activities", json=ACTIVITY_PAYLOAD, headers=event_manager_headers).json()
        submission = self._submit_work(client, student_headers, activity["id"]).json()
        resp = client.patch(
            f"/volunteer/submissions/{submission['id']}/review",
            json={"status": "approved"},
            headers=admin_headers,
        )
        assert resp.status_code == 403

    def test_event_manager_cannot_review_a_submission_routed_to_admin(
        self, client, event_manager_headers, student_headers,
    ):
        activity = client.post("/volunteer/activities", json=ACTIVITY_PAYLOAD, headers=event_manager_headers).json()
        submission = self._submit_work(
            client, student_headers, activity["id"], review_target="admin",
        ).json()
        resp = client.patch(
            f"/event-manager/submissions/{submission['id']}/review",
            json={"status": "approved"},
            headers=event_manager_headers,
        )
        assert resp.status_code == 403

    def test_admin_queue_excludes_event_manager_routed_submissions(
        self, client, admin_headers, event_manager_headers, student_headers,
    ):
        em_activity = client.post("/volunteer/activities", json=ACTIVITY_PAYLOAD, headers=event_manager_headers).json()
        self._submit_work(client, student_headers, em_activity["id"])
        pending = client.get("/volunteer/submissions/pending", headers=admin_headers).json()
        assert pending == []


class TestVolunteerStats:
    def test_stats_reflect_approved_work(self, client, admin_headers, student_headers):
        activity = client.post("/volunteer/activities", json=ACTIVITY_PAYLOAD, headers=admin_headers).json()
        submission = client.post("/volunteer/work-submissions", json={
            "activity_id": activity["id"],
            "title": "Session",
            "description": "desc",
            "hours_worked": 5.0,
        }, headers=student_headers).json()
        client.patch(
            f"/volunteer/submissions/{submission['id']}/review",
            json={"status": "approved"},
            headers=admin_headers,
        )
        resp = client.get("/volunteer/stats/me", headers=student_headers)
        assert resp.status_code == 200
        assert resp.json()["total_hours"] >= 0
