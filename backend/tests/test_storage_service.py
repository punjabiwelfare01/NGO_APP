"""
Unit tests for app.services.storage_service.

These never touch a real SFTP server: upload_local_file is monkeypatched
wherever the orchestration functions (upload_image/video/document) would
otherwise open a network connection.
"""

import pytest

from app.services import storage_service
from app.models.file_asset import FileAssetType


@pytest.fixture(autouse=True)
def _public_base_url(monkeypatch):
    monkeypatch.setattr(storage_service.settings, "hostinger_public_base_url", "https://example.com/uploads")
    monkeypatch.setattr(storage_service.settings, "hostinger_upload_root", "/public_html/uploads")


# ── validate_extension ──────────────────────────────────────────────────────────

def test_validate_extension_accepts_allowed():
    assert storage_service.validate_extension("photo.JPG", storage_service.IMAGE_EXTENSIONS) == ".jpg"


def test_validate_extension_rejects_disallowed():
    with pytest.raises(storage_service.StorageValidationError):
        storage_service.validate_extension("malware.exe", storage_service.IMAGE_EXTENSIONS)


def test_validate_extension_rejects_missing_extension():
    with pytest.raises(storage_service.StorageValidationError):
        storage_service.validate_extension("noextension", storage_service.IMAGE_EXTENSIONS)


# ── validate_mime_type ──────────────────────────────────────────────────────────

def test_validate_mime_type_accepts_matching():
    assert storage_service.validate_mime_type("image/png", ".png") == "image/png"


def test_validate_mime_type_rejects_mismatch():
    with pytest.raises(storage_service.StorageValidationError):
        storage_service.validate_mime_type("application/octet-stream", ".png")


def test_validate_mime_type_rejects_none():
    with pytest.raises(storage_service.StorageValidationError):
        storage_service.validate_mime_type(None, ".pdf")


# ── validate_size ───────────────────────────────────────────────────────────────

def test_validate_size_rejects_empty():
    with pytest.raises(storage_service.StorageValidationError):
        storage_service.validate_size(0, storage_service.MAX_IMAGE_SIZE)


def test_validate_size_rejects_oversized():
    with pytest.raises(storage_service.StorageValidationError):
        storage_service.validate_size(storage_service.MAX_IMAGE_SIZE + 1, storage_service.MAX_IMAGE_SIZE)


def test_validate_size_accepts_within_limit():
    storage_service.validate_size(1024, storage_service.MAX_IMAGE_SIZE)


# ── generate_unique_filename ────────────────────────────────────────────────────

def test_generate_unique_filename_preserves_extension():
    name = storage_service.generate_unique_filename("My Photo.PNG")
    assert name.endswith(".png")


def test_generate_unique_filename_is_unique():
    a = storage_service.generate_unique_filename("a.png")
    b = storage_service.generate_unique_filename("a.png")
    assert a != b


# ── get_public_url ──────────────────────────────────────────────────────────────

def test_get_public_url_joins_cleanly():
    url = storage_service.get_public_url("images", "abc123.png")
    assert url == "https://example.com/uploads/images/abc123.png"


# ── upload_image/video/document orchestration ───────────────────────────────────

def test_upload_image_success(monkeypatch):
    calls = {}

    def fake_upload_local_file(local_path, subdir, filename):
        calls["args"] = (local_path, subdir, filename)
        return f"/public_html/uploads/{subdir}/{filename}"

    monkeypatch.setattr(storage_service, "upload_local_file", fake_upload_local_file)

    result = storage_service.upload_image("/tmp/whatever.jpg", 2048, "photo.jpg", "image/jpeg")

    assert result.file_type == FileAssetType.image
    assert result.mime_type == "image/jpeg"
    assert result.size == 2048
    assert result.filename.endswith(".jpg")
    assert result.public_url == f"https://example.com/uploads/images/{result.filename}"
    assert calls["args"] == ("/tmp/whatever.jpg", "images", result.filename)


def test_upload_video_rejects_bad_extension_without_network_call(monkeypatch):
    def fail_upload_local_file(*args, **kwargs):
        raise AssertionError("upload_local_file should not be called for a validation failure")

    monkeypatch.setattr(storage_service, "upload_local_file", fail_upload_local_file)

    with pytest.raises(storage_service.StorageValidationError):
        storage_service.upload_video("/tmp/clip.exe", 1024, "clip.exe", "video/mp4")


def test_upload_document_rejects_oversized_without_network_call(monkeypatch):
    def fail_upload_local_file(*args, **kwargs):
        raise AssertionError("upload_local_file should not be called for a validation failure")

    monkeypatch.setattr(storage_service, "upload_local_file", fail_upload_local_file)

    with pytest.raises(storage_service.StorageValidationError):
        storage_service.upload_document(
            "/tmp/doc.pdf", storage_service.MAX_DOCUMENT_SIZE + 1, "doc.pdf", "application/pdf"
        )


def test_upload_local_file_refuses_to_overwrite(monkeypatch):
    class FakeSFTP:
        def stat(self, path):
            return object()  # exists

        def mkdir(self, path):
            raise AssertionError("should not need to create an existing dir")

    def fake_with_sftp(func):
        return func(FakeSFTP())

    monkeypatch.setattr(storage_service, "_with_sftp", fake_with_sftp)

    with pytest.raises(storage_service.StorageError):
        storage_service.upload_local_file("/tmp/a.jpg", "images", "a.jpg")
