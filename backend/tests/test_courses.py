"""Free Courses feature: skill categories, course CRUD, lessons, and a
student's progress tracking."""

CATEGORY_PAYLOAD = {"title": "Digital Skills", "icon_name": "computer", "color_hex": "#41A7F5"}
COURSE_PAYLOAD = {
    "title": "Intro to Spreadsheets", "duration": "2 hours", "level": "beginner",
    "icon_name": "table_chart", "color_hex": "#41A7F5",
}


class TestCategories:
    def test_admin_can_create_category(self, client, admin_headers):
        resp = client.post("/categories", json=CATEGORY_PAYLOAD, headers=admin_headers)
        assert resp.status_code == 201, resp.text

    def test_content_creator_cannot_create_category(self, client, cc_headers):
        resp = client.post("/categories", json=CATEGORY_PAYLOAD, headers=cc_headers)
        assert resp.status_code == 403

    def test_anyone_can_list_categories(self, client, admin_headers, student_headers):
        client.post("/categories", json=CATEGORY_PAYLOAD, headers=admin_headers)
        resp = client.get("/categories", headers=student_headers)
        assert resp.status_code == 200
        assert len(resp.json()) == 1

    def test_admin_can_delete_category(self, client, admin_headers):
        created = client.post("/categories", json=CATEGORY_PAYLOAD, headers=admin_headers).json()
        resp = client.delete(f"/categories/{created['id']}", headers=admin_headers)
        assert resp.status_code == 204


class TestCourses:
    def test_content_creator_can_create_course(self, client, cc_headers):
        resp = client.post("/courses", json=COURSE_PAYLOAD, headers=cc_headers)
        assert resp.status_code == 201, resp.text

    def test_mentor_can_create_course(self, client, mentor_headers):
        resp = client.post("/courses", json=COURSE_PAYLOAD, headers=mentor_headers)
        assert resp.status_code == 201

    def test_student_cannot_create_course(self, client, student_headers):
        resp = client.post("/courses", json=COURSE_PAYLOAD, headers=student_headers)
        assert resp.status_code == 403

    def test_get_and_update_course(self, client, cc_headers):
        created = client.post("/courses", json=COURSE_PAYLOAD, headers=cc_headers).json()
        got = client.get(f"/courses/{created['id']}")
        assert got.status_code == 200

        updated = client.patch(
            f"/courses/{created['id']}", json={"title": "Advanced Spreadsheets"}, headers=cc_headers,
        )
        assert updated.status_code == 200
        assert updated.json()["title"] == "Advanced Spreadsheets"

    def test_delete_course(self, client, cc_headers):
        created = client.post("/courses", json=COURSE_PAYLOAD, headers=cc_headers).json()
        resp = client.delete(f"/courses/{created['id']}", headers=cc_headers)
        assert resp.status_code == 204
        assert client.get(f"/courses/{created['id']}").status_code == 404


class TestLessons:
    def _create_course(self, client, cc_headers):
        return client.post("/courses", json=COURSE_PAYLOAD, headers=cc_headers).json()

    def test_create_and_list_lessons(self, client, cc_headers):
        course = self._create_course(client, cc_headers)
        created = client.post(
            f"/courses/{course['id']}/lessons",
            json={"title": "Getting Started", "content_type": "text", "content_text": "Welcome!"},
            headers=cc_headers,
        )
        assert created.status_code == 201, created.text

        listing = client.get(f"/courses/{course['id']}/lessons", headers=cc_headers)
        assert listing.status_code == 200
        assert len(listing.json()) == 1

    def test_student_can_mark_lesson_complete(self, client, cc_headers, student_headers):
        course = self._create_course(client, cc_headers)
        lesson = client.post(
            f"/courses/{course['id']}/lessons",
            json={"title": "Getting Started"},
            headers=cc_headers,
        ).json()
        resp = client.patch(f"/lessons/{lesson['id']}/complete", headers=student_headers)
        assert resp.status_code == 204


class TestUserProgress:
    def test_student_can_update_own_progress(self, client, cc_headers, student_headers, student_user):
        course = client.post("/courses", json=COURSE_PAYLOAD, headers=cc_headers).json()
        resp = client.put(
            f"/users/{student_user.id}/courses/{course['id']}/progress",
            json={"progress": 0.5},
            headers=student_headers,
        )
        assert resp.status_code == 200, resp.text
        assert resp.json()["progress"] == 0.5

    def test_student_cannot_update_someone_elses_progress(self, client, cc_headers, student_headers, mentor_user):
        course = client.post("/courses", json=COURSE_PAYLOAD, headers=cc_headers).json()
        resp = client.put(
            f"/users/{mentor_user.id}/courses/{course['id']}/progress",
            json={"progress": 0.5},
            headers=student_headers,
        )
        assert resp.status_code == 403
