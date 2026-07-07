"""Impact posts feature (Wall of Impact): draft creation by a mentor,
admin-only publish/delete, and public reaction/share on published posts."""

POST_PAYLOAD = {
    "category": "achievement",
    "title": "Helping poor children",
    "description": "Provided clothes and books to 50 students.",
    "people_reached": 50,
}


class TestCreateAndListDrafts:
    def test_mentor_can_create_draft(self, client, mentor_headers):
        resp = client.post("/impact/posts", json=POST_PAYLOAD, headers=mentor_headers)
        assert resp.status_code == 201, resp.text
        assert resp.json()["status"] == "draft"

    def test_student_cannot_create_post(self, client, student_headers):
        resp = client.post("/impact/posts", json=POST_PAYLOAD, headers=student_headers)
        assert resp.status_code == 403

    def test_draft_not_visible_in_public_published_feed(self, client, mentor_headers):
        client.post("/impact/posts", json=POST_PAYLOAD, headers=mentor_headers)
        resp = client.get("/impact/posts")  # default status=published, no auth needed
        assert resp.status_code == 200
        assert resp.json() == []

    def test_mentor_sees_own_drafts_via_mine_filter(self, client, mentor_headers):
        client.post("/impact/posts", json=POST_PAYLOAD, headers=mentor_headers)
        resp = client.get("/impact/posts", params={"mine": True}, headers=mentor_headers)
        assert resp.status_code == 200
        assert len(resp.json()) == 1

    def test_student_cannot_use_mine_filter(self, client, student_headers):
        resp = client.get("/impact/posts", params={"mine": True}, headers=student_headers)
        assert resp.status_code == 403

    def test_non_privileged_role_cannot_view_non_published_status(self, client, mentor_headers, student_headers):
        client.post("/impact/posts", json=POST_PAYLOAD, headers=mentor_headers)
        resp = client.get("/impact/posts", params={"status": "draft"}, headers=student_headers)
        assert resp.status_code == 403


class TestPublishAndDelete:
    def test_admin_can_publish(self, client, mentor_headers, admin_headers):
        created = client.post("/impact/posts", json=POST_PAYLOAD, headers=mentor_headers).json()
        resp = client.post(f"/impact/posts/{created['id']}/publish", headers=admin_headers)
        assert resp.status_code == 200, resp.text
        assert resp.json()["status"] == "published"

        public_feed = client.get("/impact/posts").json()
        assert len(public_feed) == 1

    def test_mentor_cannot_publish(self, client, mentor_headers):
        created = client.post("/impact/posts", json=POST_PAYLOAD, headers=mentor_headers).json()
        resp = client.post(f"/impact/posts/{created['id']}/publish", headers=mentor_headers)
        assert resp.status_code == 403

    def test_admin_can_delete_draft(self, client, mentor_headers, admin_headers):
        created = client.post("/impact/posts", json=POST_PAYLOAD, headers=mentor_headers).json()
        resp = client.delete(f"/impact/posts/{created['id']}", headers=admin_headers)
        assert resp.status_code == 204

        mine = client.get("/impact/posts", params={"mine": True}, headers=mentor_headers).json()
        assert mine == []

    def test_mentor_cannot_delete(self, client, mentor_headers):
        created = client.post("/impact/posts", json=POST_PAYLOAD, headers=mentor_headers).json()
        resp = client.delete(f"/impact/posts/{created['id']}", headers=mentor_headers)
        assert resp.status_code == 403

    def test_mentor_can_edit_own_draft(self, client, mentor_headers):
        created = client.post("/impact/posts", json=POST_PAYLOAD, headers=mentor_headers).json()
        resp = client.patch(
            f"/impact/posts/{created['id']}",
            json={"title": "Updated title"},
            headers=mentor_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["title"] == "Updated title"


class TestAppreciateAndShare:
    def test_cannot_appreciate_unpublished_post(self, client, mentor_headers, student_headers):
        created = client.post("/impact/posts", json=POST_PAYLOAD, headers=mentor_headers).json()
        resp = client.post(f"/impact/posts/{created['id']}/appreciate", headers=student_headers)
        assert resp.status_code == 404

    def test_appreciate_published_post(self, client, mentor_headers, admin_headers, student_headers):
        created = client.post("/impact/posts", json=POST_PAYLOAD, headers=mentor_headers).json()
        client.post(f"/impact/posts/{created['id']}/publish", headers=admin_headers)

        resp = client.post(f"/impact/posts/{created['id']}/appreciate", headers=student_headers)
        assert resp.status_code == 200

    def test_share_published_post_increments_count(self, client, mentor_headers, admin_headers):
        created = client.post("/impact/posts", json=POST_PAYLOAD, headers=mentor_headers).json()
        client.post(f"/impact/posts/{created['id']}/publish", headers=admin_headers)

        resp = client.post(f"/impact/posts/{created['id']}/share")
        assert resp.status_code == 200
        assert resp.json()["share_count"] == 1


class TestMetrics:
    def test_metrics_endpoint(self, client, mentor_headers, admin_headers):
        created = client.post("/impact/posts", json=POST_PAYLOAD, headers=mentor_headers).json()
        client.post(f"/impact/posts/{created['id']}/publish", headers=admin_headers)
        resp = client.get("/impact/metrics")
        assert resp.status_code == 200
        assert resp.json()["posts"] >= 1
