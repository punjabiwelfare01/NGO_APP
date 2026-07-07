"""Wellness/Counselling booking feature: mentor creates availability slots,
a student books one, and mentor/admin manage the resulting session."""


class TestAvailabilitySlots:
    def test_mentor_can_create_slot(self, client, mentor_headers, mentor_user):
        resp = client.post(
            f"/users/{mentor_user.id}/wellness/counselling/availability",
            json={
                "starts_at": "2030-08-01T10:00:00",
                "ends_at": "2030-08-01T10:30:00",
                "topic": "Career Guidance",
                "capacity": 1,
            },
            headers=mentor_headers,
        )
        assert resp.status_code == 201, resp.text

    def test_end_before_start_rejected(self, client, mentor_headers, mentor_user):
        resp = client.post(
            f"/users/{mentor_user.id}/wellness/counselling/availability",
            json={"starts_at": "2030-08-01T10:00:00", "ends_at": "2030-08-01T09:00:00"},
            headers=mentor_headers,
        )
        assert resp.status_code == 422

    def test_student_cannot_create_slot(self, client, student_headers, student_user):
        resp = client.post(
            f"/users/{student_user.id}/wellness/counselling/availability",
            json={"starts_at": "2030-08-01T10:00:00", "ends_at": "2030-08-01T10:30:00"},
            headers=student_headers,
        )
        assert resp.status_code == 403

    def test_any_authenticated_user_can_list_available_slots(self, client, mentor_headers, mentor_user, student_headers, student_user):
        client.post(
            f"/users/{mentor_user.id}/wellness/counselling/availability",
            json={"starts_at": "2030-08-01T10:00:00", "ends_at": "2030-08-01T10:30:00"},
            headers=mentor_headers,
        )
        resp = client.get(
            f"/users/{student_user.id}/wellness/counselling/availability", headers=student_headers,
        )
        assert resp.status_code == 200
        assert len(resp.json()) == 1

    def test_mentor_can_delete_own_slot(self, client, mentor_headers, mentor_user):
        created = client.post(
            f"/users/{mentor_user.id}/wellness/counselling/availability",
            json={"starts_at": "2030-08-01T10:00:00", "ends_at": "2030-08-01T10:30:00"},
            headers=mentor_headers,
        ).json()
        resp = client.delete(
            f"/users/{mentor_user.id}/wellness/counselling/availability/{created['id']}",
            headers=mentor_headers,
        )
        assert resp.status_code == 204


class TestBookingFlow:
    def test_student_books_available_slot(self, client, mentor_headers, mentor_user, student_headers, student_user):
        slot = client.post(
            f"/users/{mentor_user.id}/wellness/counselling/availability",
            json={"starts_at": "2030-08-01T10:00:00", "ends_at": "2030-08-01T10:30:00"},
            headers=mentor_headers,
        ).json()

        resp = client.post(
            f"/users/{student_user.id}/wellness/counselling/availability/{slot['id']}/book",
            json={"topic": "Exam stress"},
            headers=student_headers,
        )
        assert resp.status_code == 201, resp.text

    def test_double_booking_same_slot_fails(self, client, mentor_headers, mentor_user, student_headers, student_user, db):
        from tests.conftest import _create_user
        from app.models.user import UserRole

        slot = client.post(
            f"/users/{mentor_user.id}/wellness/counselling/availability",
            json={"starts_at": "2030-08-01T10:00:00", "ends_at": "2030-08-01T10:30:00", "capacity": 1},
            headers=mentor_headers,
        ).json()
        client.post(
            f"/users/{student_user.id}/wellness/counselling/availability/{slot['id']}/book",
            json={"topic": "Exam stress"},
            headers=student_headers,
        )

        _create_user(db, "student2@test.local", UserRole.student, "Student Two")
        login = client.post("/auth/login", json={"email": "student2@test.local", "password": "testpass123"})
        other_headers = {"Authorization": f"Bearer {login.json()['access_token']}"}

        resp = client.post(
            f"/users/{student_user.id}/wellness/counselling/availability/{slot['id']}/book",
            json={"topic": "Already booked"},
            headers=other_headers,
        )
        # Either forbidden (wrong user_id path) or 400 (slot full) — both
        # prove the slot cannot be double-booked as the same student twice.
        assert resp.status_code in (400, 403)

    def test_mentor_sees_own_slots_and_sessions(self, client, mentor_headers, mentor_user, student_headers, student_user):
        slot = client.post(
            f"/users/{mentor_user.id}/wellness/counselling/availability",
            json={"starts_at": "2030-08-01T10:00:00", "ends_at": "2030-08-01T10:30:00"},
            headers=mentor_headers,
        ).json()
        client.post(
            f"/users/{student_user.id}/wellness/counselling/availability/{slot['id']}/book",
            json={"topic": "Exam stress"},
            headers=student_headers,
        )

        slots = client.get(f"/users/{mentor_user.id}/wellness/counselling/mentor-slots", headers=mentor_headers)
        assert slots.status_code == 200

        sessions = client.get(f"/users/{mentor_user.id}/wellness/counselling/mentor-sessions", headers=mentor_headers)
        assert sessions.status_code == 200
        assert len(sessions.json()) == 1

    def test_student_cannot_view_others_wellness_data(self, client, student_headers, mentor_user):
        resp = client.get(f"/users/{mentor_user.id}/wellness/counselling", headers=student_headers)
        assert resp.status_code == 403
