"""
Tests for /upload/image, /upload/video, /upload/document, GET/DELETE /upload/{id}.

storage_service's network-touching functions (upload_image/video/document and
delete_file) are monkeypatched module-wide so these tests never open a real
SFTP connection.
"""

import io

import pytest

from app.models.file_asset import FileAsset, FileAssetType
from app.routers import file_upload
from app.services.storage_service import StorageError, StorageValidationError, StoredFile


def _fake_stored_file(file_type=FileAssetType.image, size=1234):
    return StoredFile(
        filename="generated-name.jpg",
        original_filename="photo.jpg",
        file_type=file_type,
        mime_type="image/jpeg",
        size=size,
        remote_path="/public_html/uploads/images/generated-name.jpg",
        public_url="https://example.com/uploads/images/generated-name.jpg",
    )


def _make_asset(db, uploader_id, **overrides):
    defaults = dict(
        filename="abc.jpg",
        original_filename="photo.jpg",
        file_type=FileAssetType.image,
        mime_type="image/jpeg",
        size=1234,
        remote_path="/public_html/uploads/images/abc.jpg",
        public_url="https://example.com/uploads/images/abc.jpg",
        uploaded_by=uploader_id,
    )
    defaults.update(overrides)
    asset = FileAsset(**defaults)
    db.add(asset)
    db.commit()
    db.refresh(asset)
    return asset


# ── POST /upload/image ──────────────────────────────────────────────────────────

class TestUploadImage:
    def test_upload_success_persists_metadata(self, client, db, student_user, student_headers, monkeypatch):
        monkeypatch.setattr(file_upload.storage_service, "upload_image", lambda *a, **k: _fake_stored_file())

        resp = client.post(
            "/upload/image",
            files={"file": ("photo.jpg", io.BytesIO(b"fake-bytes"), "image/jpeg")},
            headers=student_headers,
        )

        assert resp.status_code == 200, resp.text
        body = resp.json()
        assert body["filename"] == "generated-name.jpg"
        assert body["url"] == "https://example.com/uploads/images/generated-name.jpg"
        assert body["size"] == 1234

        asset = db.query(FileAsset).filter(FileAsset.id == body["id"]).first()
        assert asset is not None
        assert asset.uploaded_by == student_user.id

    def test_upload_rejects_unauthenticated(self, client):
        resp = client.post("/upload/image", files={"file": ("photo.jpg", io.BytesIO(b"x"), "image/jpeg")})
        assert resp.status_code == 401

    def test_upload_returns_400_on_validation_error(self, client, student_headers, monkeypatch):
        def raise_validation(*a, **k):
            raise StorageValidationError("File type '.exe' is not allowed.")

        monkeypatch.setattr(file_upload.storage_service, "upload_image", raise_validation)

        resp = client.post(
            "/upload/image",
            files={"file": ("virus.exe", io.BytesIO(b"x"), "image/jpeg")},
            headers=student_headers,
        )
        assert resp.status_code == 400

    def test_upload_returns_502_on_storage_error(self, client, student_headers, monkeypatch):
        def raise_storage_error(*a, **k):
            raise StorageError("Could not connect to Hostinger SFTP")

        monkeypatch.setattr(file_upload.storage_service, "upload_image", raise_storage_error)

        resp = client.post(
            "/upload/image",
            files={"file": ("photo.jpg", io.BytesIO(b"x"), "image/jpeg")},
            headers=student_headers,
        )
        assert resp.status_code == 502

    def test_db_failure_rolls_back_remote_upload(self, client, db, student_headers, monkeypatch):
        deleted = {}

        monkeypatch.setattr(file_upload.storage_service, "upload_image", lambda *a, **k: _fake_stored_file())
        monkeypatch.setattr(
            file_upload.storage_service, "delete_file",
            lambda remote_path: deleted.setdefault("path", remote_path),
        )

        def failing_create(*a, **k):
            raise RuntimeError("db is down")

        monkeypatch.setattr(file_upload.file_asset_crud, "create_file_asset", failing_create)

        resp = client.post(
            "/upload/image",
            files={"file": ("photo.jpg", io.BytesIO(b"x"), "image/jpeg")},
            headers=student_headers,
        )

        assert resp.status_code == 500
        assert deleted["path"] == "/public_html/uploads/images/generated-name.jpg"


# ── POST /upload/video, /upload/document ────────────────────────────────────────

def test_upload_video_success(client, student_headers, monkeypatch):
    stored = _fake_stored_file(file_type=FileAssetType.video, size=999)
    monkeypatch.setattr(file_upload.storage_service, "upload_video", lambda *a, **k: stored)

    resp = client.post(
        "/upload/video",
        files={"file": ("clip.mp4", io.BytesIO(b"video-bytes"), "video/mp4")},
        headers=student_headers,
    )
    assert resp.status_code == 200
    assert resp.json()["size"] == 999


def test_upload_document_success(client, student_headers, monkeypatch):
    stored = _fake_stored_file(file_type=FileAssetType.document, size=555)
    monkeypatch.setattr(file_upload.storage_service, "upload_document", lambda *a, **k: stored)

    resp = client.post(
        "/upload/document",
        files={"file": ("resume.pdf", io.BytesIO(b"pdf-bytes"), "application/pdf")},
        headers=student_headers,
    )
    assert resp.status_code == 200
    assert resp.json()["size"] == 555


# ── GET /upload/{id} ─────────────────────────────────────────────────────────────

class TestGetFile:
    def test_get_existing_file(self, client, db, student_user, student_headers):
        asset = _make_asset(db, student_user.id)
        resp = client.get(f"/upload/{asset.id}", headers=student_headers)
        assert resp.status_code == 200
        body = resp.json()
        assert body["id"] == asset.id
        assert body["public_url"] == asset.public_url

    def test_get_missing_file_404(self, client, student_headers):
        resp = client.get("/upload/999999", headers=student_headers)
        assert resp.status_code == 404


# ── DELETE /upload/{id} ──────────────────────────────────────────────────────────

class TestDeleteFile:
    def test_owner_can_delete(self, client, db, student_user, student_headers, monkeypatch):
        monkeypatch.setattr(file_upload.storage_service, "delete_file", lambda remote_path: True)
        asset = _make_asset(db, student_user.id)

        resp = client.delete(f"/upload/{asset.id}", headers=student_headers)
        assert resp.status_code == 200
        assert db.query(FileAsset).filter(FileAsset.id == asset.id).first() is None

    def test_non_owner_non_admin_forbidden(self, client, db, admin_user, mentor_headers, monkeypatch):
        monkeypatch.setattr(file_upload.storage_service, "delete_file", lambda remote_path: True)
        asset = _make_asset(db, admin_user.id)

        resp = client.delete(f"/upload/{asset.id}", headers=mentor_headers)
        assert resp.status_code == 403
        assert db.query(FileAsset).filter(FileAsset.id == asset.id).first() is not None

    def test_admin_can_delete_others_file(self, client, db, student_user, admin_headers, monkeypatch):
        monkeypatch.setattr(file_upload.storage_service, "delete_file", lambda remote_path: True)
        asset = _make_asset(db, student_user.id)

        resp = client.delete(f"/upload/{asset.id}", headers=admin_headers)
        assert resp.status_code == 200

    def test_delete_missing_file_404(self, client, student_headers):
        resp = client.delete("/upload/999999", headers=student_headers)
        assert resp.status_code == 404
