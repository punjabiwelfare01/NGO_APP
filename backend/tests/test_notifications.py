"""Notifications feature: a real workflow action (admin broadcasting an
announcement) generates a per-user notification, and the recipient can
list/read it."""


def _broadcast(client, admin_headers):
    resp = client.post("/admin/announcements", json={
        "title": "Platform Update", "message": "New feature rolled out.",
    }, headers=admin_headers)
    assert resp.status_code == 201, resp.text


class TestNotifications:
    def test_announcement_generates_a_notification_for_active_users(self, client, admin_headers, student_headers):
        _broadcast(client, admin_headers)
        resp = client.get("/notifications", headers=student_headers)
        assert resp.status_code == 200
        assert len(resp.json()) >= 1
        assert any("Platform Update" in n["title"] for n in resp.json())

    def test_unread_only_filter(self, client, admin_headers, student_headers):
        _broadcast(client, admin_headers)
        all_notifications = client.get("/notifications", headers=student_headers).json()
        unread = client.get("/notifications", params={"unread_only": True}, headers=student_headers).json()
        assert len(unread) == len(all_notifications)
        assert len(unread) >= 1
        assert all(not n["is_read"] for n in unread)

    def test_mark_single_notification_read(self, client, admin_headers, student_headers):
        _broadcast(client, admin_headers)
        notification = client.get("/notifications", headers=student_headers).json()[0]

        resp = client.post(f"/notifications/{notification['id']}/read", headers=student_headers)
        assert resp.status_code == 200
        assert resp.json()["is_read"] is True

        unread = client.get("/notifications", params={"unread_only": True}, headers=student_headers).json()
        assert len(unread) == 0

    def test_cannot_read_someone_elses_notification(self, client, admin_headers, student_headers, mentor_headers):
        _broadcast(client, admin_headers)
        notification = client.get("/notifications", headers=student_headers).json()[0]

        resp = client.post(f"/notifications/{notification['id']}/read", headers=mentor_headers)
        assert resp.status_code == 404

    def test_mark_all_read(self, client, admin_headers, student_headers):
        _broadcast(client, admin_headers)
        resp = client.post("/notifications/read-all", headers=student_headers)
        assert resp.status_code == 200
        assert resp.json()["updated"] >= 1

        unread = client.get("/notifications", params={"unread_only": True}, headers=student_headers).json()
        assert unread == []
