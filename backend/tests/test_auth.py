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
        assert data["email"] == "new@test.local"
        assert data["role"] == "student"
        assert "hashed_password" not in data

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


# ── role-based access ──────────────────────────────────────────────────────────

class TestRoleAccess:
    def test_student_cannot_create_event(self, client, student_headers):
        from tests.conftest import EVENT_PAYLOAD
        resp = client.post("/events/create", json=EVENT_PAYLOAD, headers=student_headers)
        assert resp.status_code == 403

    def test_admin_can_access_admin_route(self, client, admin_headers):
        resp = client.get("/events/", headers=admin_headers)
        assert resp.status_code == 200
