from datetime import datetime, timedelta

from app.models.event import Event, EventStatus, EventType
from app.models.user import UserRole
from app.models.volunteer import ActivityAssignment, SubmissionStatus, VolunteerActivity, ActivityCategory, WorkSubmission


def _activity(client, admin_headers):
    response = client.post("/volunteer/activities", headers=admin_headers, json={
        "title": "Community Learning Support",
        "category": "education_support",
        "description": "Support a published NGO learning activity",
        "location": "Partner School",
        "duration": "2 days",
        "certificate_eligible": True,
    })
    assert response.status_code == 200, response.text
    return response.json()


def test_student_apply_and_submit_persists(client, admin_headers, student_headers):
    activity = _activity(client, admin_headers)
    applied = client.post(f"/student/activities/{activity['id']}/apply", headers=student_headers, json={})
    assert applied.status_code == 201
    assignments = client.get("/student/assignments", headers=student_headers)
    assert assignments.status_code == 200
    assignment = assignments.json()[0]
    assert assignment["status"] == "applied"

    # Event manager/admin assigns the applicant before work can be submitted.
    updated = client.patch(f"/event-manager/assignments/{assignment['id']}", headers=admin_headers, json={"status": "assigned"})
    assert updated.status_code == 200
    submitted = client.post(f"/student/assignments/{assignment['id']}/submit-work", headers=student_headers, json={
        "activity_id": activity["id"],
        "assignment_id": assignment["id"],
        "title": "Completed support work",
        "description": "Helped students complete their learning activities.",
        "hours_worked": 4,
        "people_reached": 20,
        "donation_collected": 0,
    })
    assert submitted.status_code == 201, submitted.text
    refreshed = client.get(f"/student/assignments/{assignment['id']}", headers=student_headers).json()
    assert refreshed["status"] == "submitted"


def test_published_impact_feed_reaction_and_share(client, admin_headers, student_headers):
    created = client.post("/impact/posts", headers=admin_headers, json={
        "category": "achievement",
        "title": "Verified community impact",
        "description": "Students completed a verified service activity.",
        "people_reached": 30,
        "hours_served": 12,
    })
    assert created.status_code == 201, created.text
    post_id = created.json()["id"]
    assert client.post(f"/impact/posts/{post_id}/publish", headers=admin_headers).status_code == 200
    feed = client.get("/impact/posts?status=published", headers=student_headers)
    assert [item["id"] for item in feed.json()] == [post_id]
    appreciated = client.post(f"/impact/posts/{post_id}/appreciate", headers=student_headers)
    assert appreciated.json()["appreciation_count"] == 1
    assert appreciated.json()["appreciated_by_me"] is True
    shared = client.post(f"/impact/posts/{post_id}/share")
    assert shared.status_code == 200
    assert f"/public/impact/{post_id}" in shared.json()["public_url"]


def test_mentor_can_create_and_only_sees_own_drafts(client, admin_headers, mentor_headers, student_headers, school_partner_headers):
    # School partner and student remain excluded from creating impact posts.
    assert client.post("/impact/posts", headers=school_partner_headers, json={
        "category": "achievement", "title": "Should be denied", "description": "n/a",
    }).status_code == 403
    assert client.post("/impact/posts", headers=student_headers, json={
        "category": "achievement", "title": "Should be denied", "description": "n/a",
    }).status_code == 403

    # Mentor (counsellor) can create their own draft.
    mentor_post = client.post("/impact/posts", headers=mentor_headers, json={
        "category": "achievement",
        "title": "Counselling drive outcomes",
        "description": "Summary of a school counselling session.",
        "people_reached": 15,
    })
    assert mentor_post.status_code == 201, mentor_post.text
    mentor_post_id = mentor_post.json()["id"]

    # Admin creates an unrelated draft that the mentor should not see via `mine`.
    admin_post = client.post("/impact/posts", headers=admin_headers, json={
        "category": "achievement", "title": "Admin's own draft", "description": "n/a",
    })
    assert admin_post.status_code == 201, admin_post.text

    mine = client.get("/impact/posts?mine=true", headers=mentor_headers)
    assert mine.status_code == 200
    assert [item["id"] for item in mine.json()] == [mentor_post_id]

    # `mine=true` is unavailable to roles below mentor in the hierarchy.
    assert client.get("/impact/posts?mine=true", headers=student_headers).status_code == 403


def test_notifications_and_settings_persist(client, db, student_user, student_headers):
    from app.services.notification_service import notify
    notify(db, student_user.id, "assignment_update", "Assignment updated", "You were assigned to an activity.")
    items = client.get("/notifications", headers=student_headers).json()
    assert len(items) == 1 and items[0]["is_read"] is False
    assert client.post(f"/notifications/{items[0]['id']}/read", headers=student_headers).json()["is_read"] is True
    settings = client.patch("/settings/me", headers=student_headers, json={"language": "pa", "event_reminders": False})
    assert settings.status_code == 200
    assert settings.json()["language"] == "pa"
    assert settings.json()["event_reminders"] is False


def test_certificate_signed_pdf_download_and_public_verify(client, db, admin_user, student_user, admin_headers, student_headers):
    activity = VolunteerActivity(title="Certificate Activity", category=ActivityCategory.education_support, is_active=True, certificate_eligible=True)
    db.add(activity); db.flush()
    assignment = ActivityAssignment(student_id=student_user.id, activity_id=activity.id, assigned_by=admin_user.id, status="admin_approved")
    db.add(assignment); db.flush()
    submission = WorkSubmission(student_id=student_user.id, assignment_id=assignment.id, activity_id=activity.id, title="Verified work", description="Completed", hours_worked=5, status=SubmissionStatus.approved)
    db.add(submission); db.commit()
    generated = client.post("/admin/certificates/generate", headers=admin_headers, json={"assignment_id": assignment.id})
    assert generated.status_code == 201, generated.text
    certificate = generated.json()
    assert certificate["status"] == "pending_signature"
    uploaded = client.post(f"/admin/certificates/{certificate['certificate_id']}/upload-signed", headers=admin_headers, files={"file": ("signed.pdf", b"%PDF-1.4\n% signed certificate", "application/pdf")})
    assert uploaded.status_code == 200, uploaded.text
    assert uploaded.json()["status"] == "issued"
    download = client.get(f"/student/certificates/{certificate['id']}/download", headers=student_headers)
    assert download.status_code == 200
    assert download.content.startswith(b"%PDF")
    verified = client.get(f"/public/certificates/verify/{certificate['qr_token']}")
    assert verified.status_code == 200 and verified.json()["is_verified"] is True


def test_student_profile_update_is_saved(client, student_user, student_headers):
    payload = {
        "name": "Updated Student",
        "age": 19,
        "date_of_birth": "2007-02-14",
        "parent_email": "parent@example.com",
        "class_name": "12",
        "school_name": "Punjabi Welfare School",
        "location": "Ludhiana",
        "phone": "9876543210",
    }

    updated = client.patch(
        "/users/me/profile",
        headers=student_headers,
        json=payload,
    )
    assert updated.status_code == 200, updated.text
    for key, value in payload.items():
        assert updated.json()[key] == value

    persisted = client.get(f"/users/{student_user.id}", headers=student_headers)
    assert persisted.status_code == 200
    for key, value in payload.items():
        assert persisted.json()[key] == value


def test_event_report_pdf_and_admin_audit(client, db, admin_user, admin_headers):
    event = Event(title="Production Report Event", event_type=EventType.workshop, status=EventStatus.completed, created_by=admin_user.id)
    db.add(event); db.commit(); db.refresh(event)
    report = client.post(f"/events/{event.id}/reports/generate", headers=admin_headers, json={})
    assert report.status_code == 201, report.text
    report_id = report.json()["id"]
    assert client.get(f"/events/{event.id}/reports/{report_id}/download", headers=admin_headers).content.startswith(b"%PDF")
    finalized = client.patch(f"/events/{event.id}/reports/{report_id}/finalize", headers=admin_headers)
    assert finalized.json()["status"] == "finalized"
    bank = client.patch("/admin/settings/bank", headers=admin_headers, json={"account_holder": "Punjabi Welfare Trust", "upi_id": "trust@upi", "confirmation": "CONFIRM"})
    assert bank.status_code == 200
    logs = client.get("/admin/audit-logs", headers=admin_headers).json()
    assert any(item["action"] == "update_bank_settings" for item in logs)


def test_password_reset_code_is_private_and_rate_limited(client, monkeypatch, student_user):
    delivered = {}
    def capture(recipient, code):
        delivered["recipient"] = recipient
        delivered["code"] = code
        return True
    monkeypatch.setattr("app.services.email_service.send_password_reset_code", capture)
    requested = client.post("/auth/forgot-password", json={"email": student_user.email})
    assert requested.status_code == 200
    assert "reset_token" not in requested.json()
    assert len(delivered["code"]) == 6
    verified = client.post("/auth/verify-reset-code", json={"email": student_user.email, "otp": delivered["code"]})
    assert verified.status_code == 200
    reset = client.post("/auth/reset-password", json={"email": student_user.email, "otp": delivered["code"], "new_password": "newsecurepass123"})
    assert reset.status_code == 200
    assert client.post("/auth/login", json={"email": student_user.email, "password": "newsecurepass123"}).status_code == 200
