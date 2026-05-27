"""
Tests for /quizzes/* and quiz-attempt endpoints.

Covers: create quiz, add questions, list quizzes, submit attempt, leaderboard.
"""

import pytest

QUIZ_PAYLOAD = {
    "title": "CareSkill Safety Quiz",
    "description": "A quiz about personal safety",
    "category": "safety",
    "difficulty": "medium",
    "xp_reward": 100,
    "time_limit_seconds": 300,
}

QUESTION_PAYLOAD = {
    "text": "What is a trusted adult?",
    "options": [
        "Someone who listens and helps",   # index 0 — correct
        "Any adult you know",              # index 1
        "Someone who gives gifts",         # index 2
        "A stranger online",               # index 3
    ],
    "correct_index": 0,
    "explanation": "A trusted adult is someone who listens, believes you, and helps you stay safe.",
    "points": 10,
}


# ── quiz creation ──────────────────────────────────────────────────────────────

class TestCreateQuiz:
    def test_admin_can_create_quiz(self, client, admin_headers):
        resp = client.post("/quizzes/", json=QUIZ_PAYLOAD, headers=admin_headers)
        assert resp.status_code == 201
        data = resp.json()
        assert data["title"] == "CareSkill Safety Quiz"
        assert data["difficulty"] == "medium"
        assert "id" in data

    def test_student_cannot_create_quiz(self, client, student_headers):
        resp = client.post("/quizzes/", json=QUIZ_PAYLOAD, headers=student_headers)
        assert resp.status_code == 403

    def test_create_quiz_missing_title(self, client, admin_headers):
        resp = client.post("/quizzes/", json={k: v for k, v in QUIZ_PAYLOAD.items() if k != "title"}, headers=admin_headers)
        assert resp.status_code == 422


# ── questions ──────────────────────────────────────────────────────────────────

class TestQuestions:
    def _create_quiz(self, client, headers):
        resp = client.post("/quizzes/", json=QUIZ_PAYLOAD, headers=headers)
        return resp.json()["id"]

    def test_add_question_to_quiz(self, client, admin_headers):
        qid = self._create_quiz(client, admin_headers)
        resp = client.post(f"/quizzes/{qid}/questions", json=QUESTION_PAYLOAD, headers=admin_headers)
        assert resp.status_code == 201
        data = resp.json()
        assert data["text"] == QUESTION_PAYLOAD["text"]
        assert data["correct_index"] == 0

    def test_list_questions(self, client, admin_headers):
        qid = self._create_quiz(client, admin_headers)
        client.post(f"/quizzes/{qid}/questions", json=QUESTION_PAYLOAD, headers=admin_headers)
        resp = client.get(f"/quizzes/{qid}/questions", headers=admin_headers)
        assert resp.status_code == 200
        assert len(resp.json()) == 1

    def test_student_cannot_add_question(self, client, admin_headers, student_headers):
        qid = self._create_quiz(client, admin_headers)
        resp = client.post(f"/quizzes/{qid}/questions", json=QUESTION_PAYLOAD, headers=student_headers)
        assert resp.status_code == 403


# ── list quizzes ───────────────────────────────────────────────────────────────

class TestListQuizzes:
    def test_list_active_quizzes(self, client, admin_headers, student_headers):
        client.post("/quizzes/", json=QUIZ_PAYLOAD, headers=admin_headers)
        resp = client.get("/quizzes/", headers=student_headers)
        assert resp.status_code == 200
        assert isinstance(resp.json(), list)

    def test_get_quiz_by_id(self, client, admin_headers):
        create = client.post("/quizzes/", json=QUIZ_PAYLOAD, headers=admin_headers)
        quiz_id = create.json()["id"]
        resp = client.get(f"/quizzes/{quiz_id}", headers=admin_headers)
        assert resp.status_code == 200
        assert resp.json()["id"] == quiz_id

    def test_get_nonexistent_quiz(self, client, admin_headers):
        resp = client.get("/quizzes/99999", headers=admin_headers)
        assert resp.status_code == 404


# ── quiz attempts ──────────────────────────────────────────────────────────────

class TestQuizAttempts:
    def _setup_quiz_with_question(self, client, admin_headers):
        quiz = client.post("/quizzes/", json=QUIZ_PAYLOAD, headers=admin_headers).json()
        qid = quiz["id"]
        question = client.post(f"/quizzes/{qid}/questions", json=QUESTION_PAYLOAD, headers=admin_headers).json()
        return qid, question["id"]

    def test_student_can_submit_attempt(self, client, admin_headers, student_headers):
        quiz_id, _ = self._setup_quiz_with_question(client, admin_headers)
        resp = client.post(
            f"/quizzes/{quiz_id}/attempt",
            json={"answers": [0]},          # index 0 = first option (correct)
            headers=student_headers,
        )
        assert resp.status_code == 201
        data = resp.json()
        assert "score" in data
        assert "xp_earned" in data

    def test_correct_answer_scores_points(self, client, admin_headers, student_headers):
        quiz_id, _ = self._setup_quiz_with_question(client, admin_headers)
        resp = client.post(
            f"/quizzes/{quiz_id}/attempt",
            json={"answers": [0]},          # correct_index = 0
            headers=student_headers,
        )
        assert resp.status_code == 201
        assert resp.json()["score"] > 0

    def test_wrong_answer_scores_zero(self, client, admin_headers, student_headers):
        quiz_id, _ = self._setup_quiz_with_question(client, admin_headers)
        resp = client.post(
            f"/quizzes/{quiz_id}/attempt",
            json={"answers": [2]},          # index 2 = wrong option
            headers=student_headers,
        )
        assert resp.status_code == 201
        assert resp.json()["score"] == 0
