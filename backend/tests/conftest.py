"""
Shared pytest fixtures for the CareSkill backend test suite.

Every test function gets a fresh in-memory SQLite database so tests are
fully isolated and never touch the production careskill.db file.
"""

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database import Base, get_db
from app.main import app
from app.crud.auth_crud import register_user
from app.models.user import UserRole
from app.schemas.auth import RegisterRequest

TEST_DB_URL = "sqlite:///:memory:"

# StaticPool forces SQLAlchemy to reuse a single connection so all fixtures
# and the TestClient HTTP requests share the same in-memory database.
_engine = create_engine(
    TEST_DB_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
_TestSession = sessionmaker(autocommit=False, autoflush=False, bind=_engine)


# ── database fixture ───────────────────────────────────────────────────────────

@pytest.fixture()
def db():
    """Fresh in-memory DB per test."""
    Base.metadata.create_all(bind=_engine)
    session = _TestSession()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=_engine)


# ── HTTP client fixture ────────────────────────────────────────────────────────

@pytest.fixture()
def client(db):
    """FastAPI TestClient wired to the isolated test DB."""
    def _override_db():
        try:
            yield db
        finally:
            pass

    app.dependency_overrides[get_db] = _override_db
    with TestClient(app, raise_server_exceptions=True) as c:
        yield c
    app.dependency_overrides.clear()


# ── user helpers ───────────────────────────────────────────────────────────────

def _create_user(db, email: str, role: UserRole, name: str, age: int = 22):
    return register_user(db, RegisterRequest(
        name=name,
        email=email,
        password="testpass123",
        age=age,
        role=role,
    ))


@pytest.fixture()
def super_admin_user(db):
    return _create_user(db, "superadmin@test.local", UserRole.super_admin, "Super Admin", age=40)


@pytest.fixture()
def admin_user(db):
    return _create_user(db, "admin@test.local", UserRole.admin, "Admin User", age=35)


@pytest.fixture()
def student_user(db):
    return _create_user(db, "student@test.local", UserRole.student, "Student User", age=18)


@pytest.fixture()
def mentor_user(db):
    return _create_user(db, "mentor@test.local", UserRole.mentor, "Mentor User", age=30)


@pytest.fixture()
def content_creator_user(db):
    return _create_user(db, "cc@test.local", UserRole.content_creator, "Content Creator", age=28)


@pytest.fixture()
def school_partner_user(db):
    return _create_user(db, "school@test.local", UserRole.school_partner, "School Partner", age=40)


@pytest.fixture()
def event_manager_user(db):
    return _create_user(db, "em@test.local", UserRole.event_manager, "Event Manager", age=32)


# ── auth header fixtures ───────────────────────────────────────────────────────

def _get_token(client, email: str) -> str:
    resp = client.post("/auth/login", json={"email": email, "password": "testpass123"})
    assert resp.status_code == 200, f"Login failed for {email}: {resp.text}"
    return resp.json()["access_token"]


@pytest.fixture()
def super_admin_headers(client, super_admin_user):
    return {"Authorization": f"Bearer {_get_token(client, 'superadmin@test.local')}"}


@pytest.fixture()
def admin_headers(client, admin_user):
    return {"Authorization": f"Bearer {_get_token(client, 'admin@test.local')}"}


@pytest.fixture()
def student_headers(client, student_user):
    return {"Authorization": f"Bearer {_get_token(client, 'student@test.local')}"}


@pytest.fixture()
def mentor_headers(client, mentor_user):
    return {"Authorization": f"Bearer {_get_token(client, 'mentor@test.local')}"}


@pytest.fixture()
def cc_headers(client, content_creator_user):
    return {"Authorization": f"Bearer {_get_token(client, 'cc@test.local')}"}


@pytest.fixture()
def school_partner_headers(client, school_partner_user):
    return {"Authorization": f"Bearer {_get_token(client, 'school@test.local')}"}


@pytest.fixture()
def event_manager_headers(client, event_manager_user):
    return {"Authorization": f"Bearer {_get_token(client, 'em@test.local')}"}


# ── shared payloads ────────────────────────────────────────────────────────────

EVENT_PAYLOAD = {
    "title": "Test Competition",
    "event_type": "competition",
    "theme_color": "#41A7F5",
    "selection_method": "lucky_draw",
    "required_challenges": 0,
    "counselling_enabled": False,
    "certificate_enabled": True,
    "scholarship_enabled": False,
    "mentorship_enabled": False,
    "auto_publish": False,
    "auto_close": False,
    "auto_result_publish": False,
    "auto_notification": True,
    "push_notification": True,
    "in_app_notification": True,
    "email_notification": False,
    "registration_start": "2030-06-01T09:00:00",
    "registration_end": "2030-06-10T17:00:00",
    "event_start": "2030-06-15T10:00:00",
    "event_end": "2030-06-15T18:00:00",
}

SAFETY_QUESTION_PAYLOAD = {
    "question_text": "What should you do if someone touches you inappropriately?",
    "option_a": "Stay quiet",
    "option_b": "Tell a trusted adult immediately",
    "option_c": "Blame yourself",
    "correct_option": "b",
    "explanation": "Always tell a trusted adult so they can help keep you safe.",
    "category": "personal_safety",
    "is_active": True,
}
