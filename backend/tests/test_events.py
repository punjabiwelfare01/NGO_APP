"""
Tests for /events/* endpoints.

Covers: create, read, update, delete, role-gating, and the quiz pipeline.
"""

import pytest
from tests.conftest import EVENT_PAYLOAD


# ── create event ───────────────────────────────────────────────────────────────

class TestCreateEvent:
    def test_admin_can_create_event(self, client, admin_headers):
        resp = client.post("/events/create", json=EVENT_PAYLOAD, headers=admin_headers)
        assert resp.status_code == 201
        data = resp.json()
        assert data["title"] == "Test Competition"
        assert data["event_type"] == "competition"
        assert data["status"] == "draft"
        assert "id" in data

    def test_mentor_can_create_event(self, client, mentor_headers):
        resp = client.post("/events/create", json=EVENT_PAYLOAD, headers=mentor_headers)
        assert resp.status_code == 201

    def test_student_cannot_create_event(self, client, student_headers):
        resp = client.post("/events/create", json=EVENT_PAYLOAD, headers=student_headers)
        assert resp.status_code == 403

    def test_unauthenticated_cannot_create_event(self, client):
        resp = client.post("/events/create", json=EVENT_PAYLOAD)
        assert resp.status_code == 401

    def test_create_event_missing_title(self, client, admin_headers):
        payload = {k: v for k, v in EVENT_PAYLOAD.items() if k != "title"}
        resp = client.post("/events/create", json=payload, headers=admin_headers)
        assert resp.status_code == 422

    def test_create_quiz_event_auto_creates_quiz(self, client, admin_headers):
        payload = {**EVENT_PAYLOAD, "event_type": "quiz", "title": "Quiz Event"}
        resp = client.post("/events/create", json=payload, headers=admin_headers)
        assert resp.status_code == 201
        assert resp.json()["quiz_id"] is not None

    def test_create_competition_no_auto_quiz(self, client, admin_headers):
        resp = client.post("/events/create", json=EVENT_PAYLOAD, headers=admin_headers)
        assert resp.status_code == 201
        assert resp.json()["quiz_id"] is None

    def test_created_event_has_creator_id(self, client, admin_user, admin_headers):
        resp = client.post("/events/create", json=EVENT_PAYLOAD, headers=admin_headers)
        assert resp.json()["created_by"] == admin_user.id


# ── list events ────────────────────────────────────────────────────────────────

class TestListEvents:
    def test_admin_sees_draft_events(self, client, admin_headers):
        client.post("/events/create", json=EVENT_PAYLOAD, headers=admin_headers)
        resp = client.get("/events/", headers=admin_headers)
        assert resp.status_code == 200
        events = resp.json()
        assert len(events) >= 1
        assert any(e["status"] == "draft" for e in events)

    def test_student_cannot_see_draft_events(self, client, admin_headers, student_headers):
        client.post("/events/create", json=EVENT_PAYLOAD, headers=admin_headers)
        resp = client.get("/events/", headers=student_headers)
        assert resp.status_code == 200
        # draft events should be filtered out for students
        assert all(e["status"] != "draft" for e in resp.json())

    def test_filter_by_event_type(self, client, admin_headers):
        client.post("/events/create", json=EVENT_PAYLOAD, headers=admin_headers)
        resp = client.get("/events/?event_type=competition", headers=admin_headers)
        assert resp.status_code == 200
        assert all(e["event_type"] == "competition" for e in resp.json())


# ── get single event ───────────────────────────────────────────────────────────

class TestGetEvent:
    def test_admin_can_get_draft_event(self, client, admin_headers):
        create = client.post("/events/create", json=EVENT_PAYLOAD, headers=admin_headers)
        event_id = create.json()["id"]
        resp = client.get(f"/events/{event_id}", headers=admin_headers)
        assert resp.status_code == 200
        assert resp.json()["id"] == event_id

    def test_student_cannot_get_draft_event(self, client, admin_headers, student_headers):
        create = client.post("/events/create", json=EVENT_PAYLOAD, headers=admin_headers)
        event_id = create.json()["id"]
        resp = client.get(f"/events/{event_id}", headers=student_headers)
        assert resp.status_code == 404

    def test_get_nonexistent_event_returns_404(self, client, admin_headers):
        resp = client.get("/events/99999", headers=admin_headers)
        assert resp.status_code == 404


# ── update event ───────────────────────────────────────────────────────────────

class TestUpdateEvent:
    def test_admin_can_update_event(self, client, admin_headers):
        create = client.post("/events/create", json=EVENT_PAYLOAD, headers=admin_headers)
        event_id = create.json()["id"]
        resp = client.patch(
            f"/events/{event_id}",
            json={"title": "Updated Title", "max_participants": 50},
            headers=admin_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["title"] == "Updated Title"
        assert resp.json()["max_participants"] == 50

    def test_student_cannot_update_event(self, client, admin_headers, student_headers):
        create = client.post("/events/create", json=EVENT_PAYLOAD, headers=admin_headers)
        event_id = create.json()["id"]
        resp = client.patch(
            f"/events/{event_id}",
            json={"title": "Hack"},
            headers=student_headers,
        )
        assert resp.status_code == 403


# ── delete event ───────────────────────────────────────────────────────────────

class TestDeleteEvent:
    def test_admin_can_delete_event(self, client, admin_headers):
        create = client.post("/events/create", json=EVENT_PAYLOAD, headers=admin_headers)
        event_id = create.json()["id"]
        resp = client.delete(f"/events/{event_id}", headers=admin_headers)
        assert resp.status_code == 204
        # confirm gone
        assert client.get(f"/events/{event_id}", headers=admin_headers).status_code == 404

    def test_student_cannot_delete_event(self, client, admin_headers, student_headers):
        create = client.post("/events/create", json=EVENT_PAYLOAD, headers=admin_headers)
        event_id = create.json()["id"]
        resp = client.delete(f"/events/{event_id}", headers=student_headers)
        assert resp.status_code == 403


# ── publish event ──────────────────────────────────────────────────────────────

class TestPublishEvent:
    def test_admin_can_publish_event(self, client, admin_headers):
        create = client.post("/events/create", json=EVENT_PAYLOAD, headers=admin_headers)
        event_id = create.json()["id"]
        resp = client.post(f"/events/{event_id}/publish", headers=admin_headers)
        assert resp.status_code == 200
        assert resp.json()["status"] in ("published", "registration_open")

    def test_student_cannot_publish_event(self, client, admin_headers, student_headers):
        create = client.post("/events/create", json=EVENT_PAYLOAD, headers=admin_headers)
        event_id = create.json()["id"]
        resp = client.post(f"/events/{event_id}/publish", headers=student_headers)
        assert resp.status_code == 403
