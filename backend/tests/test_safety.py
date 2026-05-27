"""
Tests for /safety-awareness/* endpoints.

Covers: admin CRUD, student daily question flow, answer submission, XP reward.
"""

import pytest
from tests.conftest import SAFETY_QUESTION_PAYLOAD


# ── admin: create questions ────────────────────────────────────────────────────

class TestAdminCRUD:
    def test_admin_can_create_question(self, client, admin_headers):
        resp = client.post("/safety-awareness/", json=SAFETY_QUESTION_PAYLOAD, headers=admin_headers)
        assert resp.status_code == 201
        data = resp.json()
        assert data["question_text"] == SAFETY_QUESTION_PAYLOAD["question_text"]
        assert data["category"] == "personal_safety"
        assert "correct_option" in data  # admin sees correct answer

    def test_student_cannot_create_question(self, client, student_headers):
        resp = client.post("/safety-awareness/", json=SAFETY_QUESTION_PAYLOAD, headers=student_headers)
        assert resp.status_code == 403

    def test_admin_can_list_all_questions(self, client, admin_headers):
        client.post("/safety-awareness/", json=SAFETY_QUESTION_PAYLOAD, headers=admin_headers)
        resp = client.get("/safety-awareness/", headers=admin_headers)
        assert resp.status_code == 200
        assert len(resp.json()) >= 1

    def test_admin_can_update_question(self, client, admin_headers):
        create = client.post("/safety-awareness/", json=SAFETY_QUESTION_PAYLOAD, headers=admin_headers)
        qid = create.json()["id"]
        resp = client.patch(
            f"/safety-awareness/{qid}",
            json={"question_text": "Updated question text"},
            headers=admin_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["question_text"] == "Updated question text"

    def test_admin_can_delete_question(self, client, admin_headers):
        create = client.post("/safety-awareness/", json=SAFETY_QUESTION_PAYLOAD, headers=admin_headers)
        qid = create.json()["id"]
        resp = client.delete(f"/safety-awareness/{qid}", headers=admin_headers)
        assert resp.status_code == 204


# ── student: daily question ────────────────────────────────────────────────────

class TestDailyQuestion:
    def _seed_question(self, client, admin_headers):
        resp = client.post("/safety-awareness/", json=SAFETY_QUESTION_PAYLOAD, headers=admin_headers)
        assert resp.status_code == 201
        return resp.json()["id"]

    def test_student_gets_daily_question(self, client, admin_headers, student_headers):
        self._seed_question(client, admin_headers)
        resp = client.get("/safety-awareness/daily", headers=student_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert "question_text" in data
        assert "option_a" in data
        assert "option_b" in data
        assert "option_c" in data
        # correct_option must NOT be exposed to students
        assert "correct_option" not in data

    def test_no_question_returns_null(self, client, student_headers):
        resp = client.get("/safety-awareness/daily", headers=student_headers)
        # No active questions seeded → endpoint returns 200 with null body
        assert resp.status_code == 200
        assert resp.json() is None

    def test_unauthenticated_cannot_get_daily(self, client, admin_headers):
        self._seed_question(client, admin_headers)
        resp = client.get("/safety-awareness/daily")
        assert resp.status_code == 401


# ── student: answer submission ─────────────────────────────────────────────────

class TestSubmitAnswer:
    def _seed_and_get_id(self, client, admin_headers, student_headers):
        client.post("/safety-awareness/", json=SAFETY_QUESTION_PAYLOAD, headers=admin_headers)
        q = client.get("/safety-awareness/daily", headers=student_headers)
        return q.json()["id"]

    def test_correct_answer_returns_correct_true(self, client, admin_headers, student_headers):
        qid = self._seed_and_get_id(client, admin_headers, student_headers)
        resp = client.post(
            f"/safety-awareness/{qid}/answer",
            json={"chosen_option": "b"},
            headers=student_headers,
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["correct"] is True
        assert data["correct_option"] == "b"
        assert data["xp_earned"] > 0

    def test_wrong_answer_returns_correct_false(self, client, admin_headers, student_headers):
        qid = self._seed_and_get_id(client, admin_headers, student_headers)
        resp = client.post(
            f"/safety-awareness/{qid}/answer",
            json={"chosen_option": "a"},
            headers=student_headers,
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["correct"] is False
        assert data["xp_earned"] == 0

    def test_answer_reveals_explanation(self, client, admin_headers, student_headers):
        qid = self._seed_and_get_id(client, admin_headers, student_headers)
        resp = client.post(
            f"/safety-awareness/{qid}/answer",
            json={"chosen_option": "b"},
            headers=student_headers,
        )
        assert resp.json()["explanation"] == SAFETY_QUESTION_PAYLOAD["explanation"]

    def test_unauthenticated_cannot_submit(self, client, admin_headers, student_headers):
        qid = self._seed_and_get_id(client, admin_headers, student_headers)
        resp = client.post(f"/safety-awareness/{qid}/answer", json={"chosen_option": "b"})
        assert resp.status_code == 401


# ── student: stats ─────────────────────────────────────────────────────────────

class TestStats:
    def test_stats_initially_zero(self, client, student_headers):
        resp = client.get("/safety-awareness/my-stats", headers=student_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["total_answered"] == 0
        assert data["correct"] == 0

    def test_stats_update_after_answer(self, client, admin_headers, student_headers):
        client.post("/safety-awareness/", json=SAFETY_QUESTION_PAYLOAD, headers=admin_headers)
        q = client.get("/safety-awareness/daily", headers=student_headers)
        qid = q.json()["id"]
        client.post(f"/safety-awareness/{qid}/answer", json={"chosen_option": "b"}, headers=student_headers)

        stats = client.get("/safety-awareness/my-stats", headers=student_headers)
        data = stats.json()
        assert data["total_answered"] == 1
        assert data["correct"] == 1
