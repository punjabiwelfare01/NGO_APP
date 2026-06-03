"""
Tests for Google Meet / Google Calendar integration.

Coverage:
  Unit  — google_calendar.py: is_calendar_authorized, create_meet_link,
           get_authorization_url, exchange_code_for_tokens
  API   — GET  /auth/google/calendar/status
          GET  /auth/google/calendar/authorize
          POST /users/{id}/wellness/counselling/availability
            ↳ auto-generates Meet link when Calendar is authorized
            ↳ skips Meet link when Calendar is NOT authorized
            ↳ keeps manual URL when caller already provided one
          POST /users/{id}/wellness/counselling/availability/{slot_id}/book
            ↳ booked session inherits the Meet link from the slot
"""

from __future__ import annotations

import json
import tempfile
from datetime import datetime, timedelta
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

# ---------------------------------------------------------------------------
# Helpers shared across tests
# ---------------------------------------------------------------------------

FUTURE = datetime.utcnow() + timedelta(days=3)
STARTS = FUTURE.replace(microsecond=0).isoformat()
ENDS = (FUTURE + timedelta(hours=1)).replace(microsecond=0).isoformat()
FAKE_MEET_URL = "https://meet.google.com/abc-defg-hij"

SLOT_PAYLOAD = {
    "starts_at": STARTS,
    "ends_at": ENDS,
    "topic": "Career Guidance",
    "capacity": 2,
}


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture()
def mentor_id(mentor_user):
    return mentor_user.id


@pytest.fixture()
def student_id(student_user):
    return student_user.id


# ---------------------------------------------------------------------------
# Helper: build a minimal fake credential object saved to a temp token file
# ---------------------------------------------------------------------------

def _fake_token_file(tmp_path: Path) -> Path:
    token_data = {
        "token": "fake-access-token",
        "refresh_token": "fake-refresh-token",
        "token_uri": "https://oauth2.googleapis.com/token",
        "client_id": "fake-client-id.apps.googleusercontent.com",
        "client_secret": "fake-secret",
        "scopes": ["https://www.googleapis.com/auth/calendar.events"],
        "expiry": (datetime.utcnow() + timedelta(hours=1)).isoformat() + "Z",
    }
    path = tmp_path / "google_token.json"
    path.write_text(json.dumps(token_data))
    return path


# ===========================================================================
# UNIT — google_calendar module
# ===========================================================================

class TestIsCalendarAuthorized:
    def test_returns_false_when_no_token_file(self, tmp_path):
        missing = tmp_path / "nonexistent_token.json"
        with patch("app.google_calendar._TOKEN_FILE", missing):
            from app.google_calendar import is_calendar_authorized
            assert is_calendar_authorized() is False

    def test_returns_true_when_valid_credentials_exist(self, tmp_path):
        token_file = _fake_token_file(tmp_path)
        mock_creds = MagicMock()
        mock_creds.valid = True
        mock_creds.expired = False

        with patch("app.google_calendar._TOKEN_FILE", token_file), \
             patch("app.google_calendar.Credentials.from_authorized_user_file",
                   return_value=mock_creds):
            from app.google_calendar import is_calendar_authorized
            assert is_calendar_authorized() is True

    def test_returns_false_when_token_file_is_corrupted(self, tmp_path):
        bad_file = tmp_path / "google_token.json"
        bad_file.write_text("not-valid-json{{{")
        with patch("app.google_calendar._TOKEN_FILE", bad_file):
            from app.google_calendar import is_calendar_authorized
            assert is_calendar_authorized() is False


class TestCreateMeetLink:
    def _mock_calendar_service(self, meet_url: str) -> MagicMock:
        """Build a mock googleapiclient service that returns a Meet entry point."""
        mock_service = MagicMock()
        mock_event_result = {
            "id": "fake_event_id",
            "conferenceData": {
                "entryPoints": [
                    {"entryPointType": "video", "uri": meet_url},
                    {"entryPointType": "phone", "uri": "tel:+11234567890"},
                ]
            },
        }
        (
            mock_service.events.return_value
            .insert.return_value
            .execute.return_value
        ) = mock_event_result
        return mock_service

    def test_returns_meet_url_when_authorized(self, tmp_path):
        mock_creds = MagicMock()
        mock_creds.valid = True

        with patch("app.google_calendar._get_credentials", return_value=mock_creds), \
             patch("app.google_calendar.build",
                   return_value=self._mock_calendar_service(FAKE_MEET_URL)):
            from app.google_calendar import create_meet_link
            result = create_meet_link(
                title="CareSkill: Career Guidance",
                starts_at=FUTURE,
                ends_at=FUTURE + timedelta(hours=1),
                description="Test session",
            )
        assert result == FAKE_MEET_URL

    def test_returns_none_when_not_authorized(self):
        with patch("app.google_calendar._get_credentials", return_value=None):
            from app.google_calendar import create_meet_link
            result = create_meet_link(
                title="Test",
                starts_at=FUTURE,
                ends_at=FUTURE + timedelta(hours=1),
            )
        assert result is None

    def test_returns_none_on_google_api_error(self, tmp_path):
        from googleapiclient.errors import HttpError
        mock_creds = MagicMock()
        mock_creds.valid = True

        mock_service = MagicMock()
        (
            mock_service.events.return_value
            .insert.return_value
            .execute.side_effect
        ) = HttpError(resp=MagicMock(status=403), content=b"Forbidden")

        with patch("app.google_calendar._get_credentials", return_value=mock_creds), \
             patch("app.google_calendar.build", return_value=mock_service):
            from app.google_calendar import create_meet_link
            result = create_meet_link(
                title="Test",
                starts_at=FUTURE,
                ends_at=FUTURE + timedelta(hours=1),
            )
        assert result is None

    def test_returns_none_when_no_video_entry_point(self, tmp_path):
        """Calendar event created but no video entrypoint in response."""
        mock_creds = MagicMock()
        mock_creds.valid = True

        mock_service = MagicMock()
        (
            mock_service.events.return_value
            .insert.return_value
            .execute.return_value
        ) = {"id": "evt1", "conferenceData": {"entryPoints": []}}

        with patch("app.google_calendar._get_credentials", return_value=mock_creds), \
             patch("app.google_calendar.build", return_value=mock_service):
            from app.google_calendar import create_meet_link
            result = create_meet_link("T", FUTURE, FUTURE + timedelta(hours=1))
        assert result is None

    def test_event_contains_correct_title_and_times(self, tmp_path):
        """Verify the payload sent to the Calendar API has the right fields."""
        mock_creds = MagicMock()
        mock_creds.valid = True
        mock_service = self._mock_calendar_service(FAKE_MEET_URL)

        with patch("app.google_calendar._get_credentials", return_value=mock_creds), \
             patch("app.google_calendar.build", return_value=mock_service):
            from app.google_calendar import create_meet_link
            create_meet_link(
                title="CareSkill: Mental Wellness with Mentor User",
                starts_at=FUTURE,
                ends_at=FUTURE + timedelta(hours=1),
                description="NGO counselling session",
            )

        call_kwargs = mock_service.events().insert.call_args
        body = call_kwargs.kwargs.get("body") or call_kwargs[1].get("body") or call_kwargs[0][1]
        assert body["summary"] == "CareSkill: Mental Wellness with Mentor User"
        assert body["description"] == "NGO counselling session"
        assert body["conferenceData"]["createRequest"]["conferenceSolutionKey"]["type"] == "hangoutsMeet"


class TestGetAuthorizationUrl:
    def test_returns_url_and_state(self):
        mock_flow = MagicMock()
        mock_flow.authorization_url.return_value = ("https://accounts.google.com/auth?...", "random_state")
        mock_flow.redirect_uri = None

        with patch("app.google_calendar.Flow.from_client_config", return_value=mock_flow):
            from app.google_calendar import get_authorization_url
            url, state = get_authorization_url()

        assert url.startswith("https://")
        assert isinstance(state, str)

    def test_authorization_url_requests_offline_access(self):
        mock_flow = MagicMock()
        mock_flow.authorization_url.return_value = ("https://auth.url", "state123")
        mock_flow.redirect_uri = None

        with patch("app.google_calendar.Flow.from_client_config", return_value=mock_flow):
            from app.google_calendar import get_authorization_url
            get_authorization_url()

        mock_flow.authorization_url.assert_called_once_with(
            access_type="offline",
            include_granted_scopes="true",
            prompt="consent",
        )


# ===========================================================================
# API — /auth/google/calendar/status  &  /auth/google/calendar/authorize
# ===========================================================================

class TestCalendarStatusEndpoint:
    def test_returns_not_authorized_when_no_token(self, client, admin_headers):
        with patch("app.google_calendar._get_credentials", return_value=None):
            resp = client.get("/auth/google/calendar/status", headers=admin_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["authorized"] is False
        assert "authorize" in data["message"].lower()

    def test_returns_authorized_when_token_valid(self, client, admin_headers):
        mock_creds = MagicMock()
        mock_creds.valid = True
        with patch("app.google_calendar._get_credentials", return_value=mock_creds):
            resp = client.get("/auth/google/calendar/status", headers=admin_headers)
        assert resp.status_code == 200
        assert resp.json()["authorized"] is True

    def test_requires_admin_role(self, client, mentor_headers):
        resp = client.get("/auth/google/calendar/status", headers=mentor_headers)
        assert resp.status_code == 403

    def test_requires_authentication(self, client):
        resp = client.get("/auth/google/calendar/status")
        assert resp.status_code == 401


class TestCalendarAuthorizeEndpoint:
    def test_returns_authorization_url(self, client, admin_headers):
        fake_url = "https://accounts.google.com/o/oauth2/auth?response_type=code&..."
        with patch("app.google_calendar.Flow.from_client_config") as mock_flow_cls:
            mock_flow = MagicMock()
            mock_flow.authorization_url.return_value = (fake_url, "state_abc")
            mock_flow.redirect_uri = None
            mock_flow_cls.return_value = mock_flow

            resp = client.get("/auth/google/calendar/authorize", headers=admin_headers)

        assert resp.status_code == 200
        data = resp.json()
        assert "authorization_url" in data
        assert data["authorization_url"] == fake_url
        assert "instructions" in data

    def test_returns_503_when_credentials_not_configured(self, client, admin_headers):
        with patch("app.google_calendar.settings") as mock_settings:
            mock_settings.google_client_id = ""
            mock_settings.google_client_secret = ""
            mock_settings.google_redirect_uri = "http://localhost:8000/auth/google/callback"
            mock_settings.public_url = "http://localhost:8000"

            with patch("app.routers.auth.settings", mock_settings):
                resp = client.get("/auth/google/calendar/authorize", headers=admin_headers)

        assert resp.status_code == 503


# ===========================================================================
# API — Slot creation with auto Meet link
# ===========================================================================

class TestSlotCreationWithMeetLink:
    def test_auto_generates_meet_link_when_calendar_authorized(
        self, client, mentor_headers, mentor_id
    ):
        with patch("app.routers.wellness.create_meet_link", return_value=FAKE_MEET_URL):
            resp = client.post(
                f"/users/{mentor_id}/wellness/counselling/availability",
                json=SLOT_PAYLOAD,
                headers=mentor_headers,
            )

        assert resp.status_code == 201
        data = resp.json()
        assert data["meeting_url"] == FAKE_MEET_URL

    def test_creates_slot_without_url_when_calendar_not_authorized(
        self, client, mentor_headers, mentor_id
    ):
        with patch("app.routers.wellness.create_meet_link", return_value=None):
            resp = client.post(
                f"/users/{mentor_id}/wellness/counselling/availability",
                json=SLOT_PAYLOAD,
                headers=mentor_headers,
            )

        assert resp.status_code == 201
        data = resp.json()
        assert data["meeting_url"] is None

    def test_keeps_manual_url_without_calling_calendar_api(
        self, client, mentor_headers, mentor_id
    ):
        manual_url = "https://zoom.us/j/123456789"
        payload = {**SLOT_PAYLOAD, "meeting_url": manual_url}

        with patch("app.google_calendar.create_meet_link") as mock_create:
            resp = client.post(
                f"/users/{mentor_id}/wellness/counselling/availability",
                json=payload,
                headers=mentor_headers,
            )

        assert resp.status_code == 201
        assert resp.json()["meeting_url"] == manual_url
        mock_create.assert_not_called()

    def test_slot_fields_are_saved_correctly(
        self, client, mentor_headers, mentor_id
    ):
        with patch("app.routers.wellness.create_meet_link", return_value=FAKE_MEET_URL):
            resp = client.post(
                f"/users/{mentor_id}/wellness/counselling/availability",
                json=SLOT_PAYLOAD,
                headers=mentor_headers,
            )

        data = resp.json()
        assert data["topic"] == "Career Guidance"
        assert data["capacity"] == 2
        assert data["booked_count"] == 0
        assert data["available_count"] == 2
        assert data["is_active"] is True
        assert data["is_available"] is True

    def test_student_cannot_create_slot(
        self, client, student_headers, student_id
    ):
        resp = client.post(
            f"/users/{student_id}/wellness/counselling/availability",
            json=SLOT_PAYLOAD,
            headers=student_headers,
        )
        assert resp.status_code == 403

    def test_rejects_slot_when_ends_before_starts(
        self, client, mentor_headers, mentor_id
    ):
        bad_payload = {
            **SLOT_PAYLOAD,
            "starts_at": ENDS,    # reversed on purpose
            "ends_at": STARTS,
        }
        resp = client.post(
            f"/users/{mentor_id}/wellness/counselling/availability",
            json=bad_payload,
            headers=mentor_headers,
        )
        assert resp.status_code == 422


# ===========================================================================
# API — Booking a slot → session inherits Meet link
# ===========================================================================

class TestBookingInheritsMeetLink:
    def _create_slot(self, client, mentor_headers, mentor_id, meet_url=FAKE_MEET_URL):
        with patch("app.routers.wellness.create_meet_link", return_value=meet_url):
            resp = client.post(
                f"/users/{mentor_id}/wellness/counselling/availability",
                json=SLOT_PAYLOAD,
                headers=mentor_headers,
            )
        assert resp.status_code == 201
        return resp.json()["id"]

    def test_booked_session_has_meet_link(
        self, client, mentor_headers, student_headers, mentor_id, student_id
    ):
        slot_id = self._create_slot(client, mentor_headers, mentor_id)

        resp = client.post(
            f"/users/{student_id}/wellness/counselling/availability/{slot_id}/book",
            json={"topic": "I need career advice"},
            headers=student_headers,
        )
        assert resp.status_code == 201
        session = resp.json()
        assert session["meeting_url"] == FAKE_MEET_URL
        assert session["status"] == "upcoming"
        assert session["topic"] == "I need career advice"

    def test_booked_session_has_no_url_when_slot_had_none(
        self, client, mentor_headers, student_headers, mentor_id, student_id
    ):
        slot_id = self._create_slot(client, mentor_headers, mentor_id, meet_url=None)

        resp = client.post(
            f"/users/{student_id}/wellness/counselling/availability/{slot_id}/book",
            json={"topic": "General counselling"},
            headers=student_headers,
        )
        assert resp.status_code == 201
        assert resp.json()["meeting_url"] is None

    def test_slot_capacity_decrements_after_booking(
        self, client, mentor_headers, student_headers, mentor_id, student_id
    ):
        slot_id = self._create_slot(client, mentor_headers, mentor_id)

        client.post(
            f"/users/{student_id}/wellness/counselling/availability/{slot_id}/book",
            json={"topic": "Session 1"},
            headers=student_headers,
        )

        slots_resp = client.get(
            f"/users/{student_id}/wellness/counselling/availability",
            headers=student_headers,
        )
        slot = next((s for s in slots_resp.json() if s["id"] == slot_id), None)
        assert slot is not None
        assert slot["booked_count"] == 1
        assert slot["available_count"] == 1

    def test_cannot_book_nonexistent_slot(
        self, client, student_headers, student_id
    ):
        resp = client.post(
            f"/users/{student_id}/wellness/counselling/availability/99999/book",
            json={"topic": "Ghost session"},
            headers=student_headers,
        )
        assert resp.status_code == 400

    def test_session_appears_in_student_session_list(
        self, client, mentor_headers, student_headers, mentor_id, student_id
    ):
        slot_id = self._create_slot(client, mentor_headers, mentor_id)

        client.post(
            f"/users/{student_id}/wellness/counselling/availability/{slot_id}/book",
            json={"topic": "Career chat"},
            headers=student_headers,
        )

        list_resp = client.get(
            f"/users/{student_id}/wellness/counselling",
            headers=student_headers,
        )
        assert list_resp.status_code == 200
        sessions = list_resp.json()
        assert any(s["meeting_url"] == FAKE_MEET_URL for s in sessions)
