"""
Tests for /auth/* endpoints.

Covers: register, login, logout, token revocation, and role-gating.
"""

import asyncio

import pytest
from fastapi import HTTPException

from app.config import settings
from app.routers import auth
from app.routers.auth import GoogleLoginRequest


class _GoogleTokenInfoResponse:
    def __init__(self, status_code=200, payload=None):
        self.status_code = status_code
        self._payload = payload or {}

    def json(self):
        return self._payload


class _GoogleTokenInfoClient:
    response = _GoogleTokenInfoResponse()

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc, traceback):
        return False

    async def get(self, *args, **kwargs):
        return self.response


# ── registration ───────────────────────────────────────────────────────────────

class TestRegister:
    def test_register_student_success(self, client):
        resp = client.post("/auth/register", json={
            "name": "New Student",
            "email": "new@test.local",
            "password": "secure123",
            "age": 16,
            "role": "student",
        })
        assert resp.status_code == 201
        data = resp.json()
        assert data["user"]["email"] == "new@test.local"
        assert data["user"]["role"] == "student"
        assert data["user"]["access_status"] == "pending"
        assert "hashed_password" not in data["user"]

    def test_counsellor_request_stays_pending_until_admin_assigns_mentor(
        self, client, admin_headers
    ):
        registered = client.post("/auth/register", json={
            "name": "Manoj Singh",
            "email": "manoj.counsellor@test.local",
            "password": "secure123",
            "role": "admin",
            "requested_role": "mentor",
            "class_name": "Indian army commander",
            "school_name": "Graduate",
            "location": "Delhi Cantt",
        })
        assert registered.status_code == 201, registered.text
        user = registered.json()["user"]
        assert user["role"] == "student"
        assert user["requested_role"] == "mentor"
        assert user["access_status"] == "pending"

        pending = client.get("/admin/users/pending", headers=admin_headers)
        assert pending.status_code == 200
        assert user["id"] in [item["id"] for item in pending.json()]

        summary = client.get("/admin/dashboard/summary", headers=admin_headers)
        assert summary.status_code == 200
        assert summary.json()["pending_counsellor_count"] == 1

        approved = client.patch(
            f"/admin/users/{user['id']}/approve",
            headers=admin_headers,
            json={"role": "mentor", "verification_note": "Verified counsellor"},
        )
        assert approved.status_code == 200, approved.text
        assert approved.json()["role"] == "mentor"
        assert approved.json()["access_status"] == "approved"

        signed_in = client.post("/auth/login", json={
            "email": "manoj.counsellor@test.local",
            "password": "secure123",
        })
        assert signed_in.status_code == 200
        assert signed_in.json()["role"] == "mentor"
        assert signed_in.json()["access_status"] == "approved"

        pending_after = client.get("/admin/users/pending", headers=admin_headers)
        assert user["id"] not in [item["id"] for item in pending_after.json()]

    def test_register_duplicate_email(self, client, student_user):
        resp = client.post("/auth/register", json={
            "name": "Duplicate",
            "email": "student@test.local",
            "password": "pass123",
            "age": 18,
        })
        assert resp.status_code == 409

    def test_register_missing_required_field(self, client):
        resp = client.post("/auth/register", json={
            "email": "missing@test.local",
            "password": "pass123",
        })
        assert resp.status_code == 422


# ── login ──────────────────────────────────────────────────────────────────────

class TestLogin:
    def test_login_valid_credentials(self, client, admin_user):
        resp = client.post("/auth/login", json={
            "email": "admin@test.local",
            "password": "testpass123",
        })
        assert resp.status_code == 200
        data = resp.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
        assert data["role"] == "admin"
        assert data["name"] == "Admin User"

    def test_login_wrong_password(self, client, student_user):
        resp = client.post("/auth/login", json={
            "email": "student@test.local",
            "password": "wrongpassword",
        })
        assert resp.status_code == 401

    def test_login_unknown_email(self, client):
        resp = client.post("/auth/login", json={
            "email": "nobody@test.local",
            "password": "pass123",
        })
        assert resp.status_code == 401

    def test_login_returns_user_id(self, client, student_user):
        resp = client.post("/auth/login", json={
            "email": "student@test.local",
            "password": "testpass123",
        })
        assert resp.status_code == 200
        assert resp.json()["user_id"] == student_user.id


# ── Google sign-in ─────────────────────────────────────────────────────────────

class TestGoogleLogin:
    def test_google_login_creates_user_and_returns_token(self, db, monkeypatch):
        monkeypatch.setattr(settings, "google_client_id", "web-client-id")
        monkeypatch.setattr(auth.httpx, "AsyncClient", _GoogleTokenInfoClient)
        _GoogleTokenInfoClient.response = _GoogleTokenInfoResponse(payload={
            "email": "google@test.local",
            "name": "Google User",
            "email_verified": "true",
            "aud": "web-client-id",
        })

        data = asyncio.run(
            auth.google_login(GoogleLoginRequest(id_token="valid-google-token"), db)
        )

        assert data.role == "student"
        assert data.name == "Google User"
        assert data.access_token

    def test_google_login_rejects_wrong_audience(self, db, monkeypatch):
        monkeypatch.setattr(settings, "google_client_id", "web-client-id")
        monkeypatch.setattr(auth.httpx, "AsyncClient", _GoogleTokenInfoClient)
        _GoogleTokenInfoClient.response = _GoogleTokenInfoResponse(payload={
            "email": "google@test.local",
            "name": "Google User",
            "email_verified": "true",
            "aud": "other-client-id",
        })

        with pytest.raises(HTTPException) as exc:
            asyncio.run(
                auth.google_login(GoogleLoginRequest(id_token="wrong-audience-token"), db)
            )
        assert exc.value.status_code == 401

    def test_google_login_rejects_unverified_email(self, db, monkeypatch):
        monkeypatch.setattr(settings, "google_client_id", "web-client-id")
        monkeypatch.setattr(auth.httpx, "AsyncClient", _GoogleTokenInfoClient)
        _GoogleTokenInfoClient.response = _GoogleTokenInfoResponse(payload={
            "email": "google@test.local",
            "name": "Google User",
            "email_verified": "false",
            "aud": "web-client-id",
        })

        with pytest.raises(HTTPException) as exc:
            asyncio.run(
                auth.google_login(GoogleLoginRequest(id_token="unverified-email-token"), db)
            )
        assert exc.value.status_code == 401


# ── protected routes ───────────────────────────────────────────────────────────

class TestAuth:
    def test_protected_route_no_token(self, client):
        resp = client.get("/users/me")
        assert resp.status_code == 401

    def test_protected_route_invalid_token(self, client):
        resp = client.get("/users/me", headers={"Authorization": "Bearer invalid.token.here"})
        assert resp.status_code == 401

    def test_protected_route_valid_token(self, client, student_headers):
        resp = client.get("/auth/me", headers=student_headers)
        assert resp.status_code == 200
        assert resp.json()["email"] == "student@test.local"

    def test_logout_and_token_revoked(self, client, student_user):
        login = client.post("/auth/login", json={
            "email": "student@test.local",
            "password": "testpass123",
        })
        token = login.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        logout = client.post("/auth/logout", headers=headers)
        assert logout.status_code == 204

        after = client.get("/auth/me", headers=headers)
        assert after.status_code == 401


# ── government ID upload ─────────────────────────────────────────────────────
#
# Regression coverage for a bug where the registration flow's government-ID
# upload silently failed for every user: the client always sent
# "application/octet-stream" (browsers/file pickers rarely set a real MIME
# type), and the endpoint rejected any content type outside an explicit
# {pdf, jpeg, png} allow-list — so uploads 400'd every time and the admin
# dashboard always showed "No government ID uploaded".

class TestGovIdUpload:
    def _use_local_storage(self, monkeypatch, tmp_path):
        # Force the endpoint's local-disk fallback instead of a real SFTP
        # upload, and keep the write inside a throwaway directory.
        monkeypatch.setattr(settings, "hostinger_host", "")
        monkeypatch.chdir(tmp_path)

    def test_upload_with_octet_stream_content_type_succeeds(
        self, client, db, student_user, student_headers, monkeypatch, tmp_path
    ):
        self._use_local_storage(monkeypatch, tmp_path)
        resp = client.post(
            "/auth/upload-gov-id",
            headers=student_headers,
            data={"id_type": "Aadhaar Card"},
            files={"file": ("id.pdf", b"%PDF-1.4 fake", "application/octet-stream")},
        )
        assert resp.status_code == 200, resp.text
        assert resp.json()["doc_url"]

        db.refresh(student_user)
        assert student_user.gov_id_type == "Aadhaar Card"
        assert student_user.gov_id_doc_url is not None

    def test_upload_with_no_content_type_succeeds(
        self, client, db, student_user, student_headers, monkeypatch, tmp_path
    ):
        self._use_local_storage(monkeypatch, tmp_path)
        resp = client.post(
            "/auth/upload-gov-id",
            headers=student_headers,
            data={"id_type": "Voter ID"},
            files={"file": ("id.jpg", b"\xff\xd8\xff fake-jpeg", "")},
        )
        assert resp.status_code == 200, resp.text
        db.refresh(student_user)
        assert student_user.gov_id_doc_url is not None

    def test_upload_rejects_disallowed_extension(
        self, client, student_headers, monkeypatch, tmp_path
    ):
        self._use_local_storage(monkeypatch, tmp_path)
        resp = client.post(
            "/auth/upload-gov-id",
            headers=student_headers,
            data={"id_type": "Aadhaar Card"},
            files={"file": ("id.exe", b"not an id", "application/octet-stream")},
        )
        assert resp.status_code == 400

    def test_uploaded_gov_id_visible_to_admin(
        self, client, db, student_user, student_headers, admin_headers, monkeypatch, tmp_path
    ):
        self._use_local_storage(monkeypatch, tmp_path)
        upload = client.post(
            "/auth/upload-gov-id",
            headers=student_headers,
            data={"id_type": "Aadhaar Card"},
            files={"file": ("id.png", b"\x89PNG fake", "application/octet-stream")},
        )
        assert upload.status_code == 200, upload.text

        detail = client.get(f"/admin/users/{student_user.id}", headers=admin_headers)
        assert detail.status_code == 200, detail.text
        body = detail.json()
        assert body["gov_id_doc_url"] is not None
        assert body["gov_id_type"] == "Aadhaar Card"


# ── role-based access ──────────────────────────────────────────────────────────

class TestRoleAccess:
    def test_student_cannot_create_event(self, client, student_headers):
        from tests.conftest import EVENT_PAYLOAD
        resp = client.post("/events/create", json=EVENT_PAYLOAD, headers=student_headers)
        assert resp.status_code == 403

    def test_admin_can_access_admin_route(self, client, admin_headers):
        resp = client.get("/events/", headers=admin_headers)
        assert resp.status_code == 200
