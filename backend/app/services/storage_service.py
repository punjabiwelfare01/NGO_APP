"""
Remote file storage on Hostinger shared hosting via SFTP.

Uploads are streamed to a local temp file first, then transferred with
sftp.put() (which streams from disk in chunks) so large videos never need to
sit fully in memory at once. Only metadata and the resulting public URL are
ever persisted in Postgres (see models/file_asset.py) — never file binaries.
"""
from __future__ import annotations

import logging
import posixpath
import time
import uuid
from dataclasses import dataclass

import paramiko

from ..config import settings
from ..models.file_asset import FileAssetType

logger = logging.getLogger(__name__)

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
VIDEO_EXTENSIONS = {".mp4", ".mov", ".avi", ".mkv"}
DOCUMENT_EXTENSIONS = {".pdf"}

MAX_IMAGE_SIZE = 10 * 1024 * 1024      # 10 MB
MAX_DOCUMENT_SIZE = 20 * 1024 * 1024   # 20 MB
MAX_VIDEO_SIZE = 500 * 1024 * 1024     # 500 MB

_ALLOWED_MIME_TYPES = {
    ".jpg": {"image/jpeg"},
    ".jpeg": {"image/jpeg"},
    ".png": {"image/png"},
    ".webp": {"image/webp"},
    ".pdf": {"application/pdf"},
    ".mp4": {"video/mp4"},
    ".mov": {"video/quicktime"},
    ".avi": {"video/x-msvideo", "video/avi", "video/msvideo"},
    ".mkv": {"video/x-matroska"},
}

_REMOTE_SUBDIR = {
    FileAssetType.image: "images",
    FileAssetType.video: "videos",
    FileAssetType.document: "documents",
}

_CONNECT_ATTEMPTS = 3
_RETRY_BACKOFF_SECONDS = 1.5


class StorageValidationError(ValueError):
    """Raised for bad input: disallowed extension/MIME, oversized file, etc."""


class StorageError(Exception):
    """Raised when the remote SFTP operation fails after all retries."""


@dataclass
class StoredFile:
    filename: str
    original_filename: str
    file_type: FileAssetType
    mime_type: str
    size: int
    remote_path: str
    public_url: str


def generate_unique_filename(original_filename: str) -> str:
    ext = posixpath.splitext(original_filename or "")[1].lower()
    return f"{uuid.uuid4().hex}{ext}"


def validate_extension(filename: str, allowed_extensions: set[str]) -> str:
    ext = posixpath.splitext(filename or "")[1].lower()
    if ext not in allowed_extensions:
        raise StorageValidationError(
            f"File type '{ext or '(none)'}' is not allowed. Allowed: {sorted(allowed_extensions)}"
        )
    return ext


def validate_mime_type(content_type: str | None, ext: str) -> str:
    allowed = _ALLOWED_MIME_TYPES.get(ext, set())
    mime = (content_type or "").split(";")[0].strip().lower()
    if mime not in allowed:
        raise StorageValidationError(f"MIME type '{mime or '(none)'}' does not match extension '{ext}'.")
    return mime


def validate_size(size: int, max_size: int) -> None:
    if size <= 0:
        raise StorageValidationError("Uploaded file is empty.")
    if size > max_size:
        raise StorageValidationError(
            f"File size {size} bytes exceeds the maximum of {max_size} bytes."
        )


def get_public_url(subdir: str, filename: str) -> str:
    base = settings.hostinger_public_base_url.rstrip("/")
    return f"{base}/{subdir}/{filename}"


def _connect() -> tuple[paramiko.Transport, paramiko.SFTPClient]:
    last_error: Exception | None = None
    for attempt in range(1, _CONNECT_ATTEMPTS + 1):
        try:
            transport = paramiko.Transport((settings.hostinger_host, settings.hostinger_port))
            transport.connect(username=settings.hostinger_username, password=settings.hostinger_password)
            sftp = paramiko.SFTPClient.from_transport(transport)
            return transport, sftp
        except (paramiko.SSHException, OSError, EOFError) as exc:
            last_error = exc
            logger.warning("SFTP connect attempt %s/%s failed: %s", attempt, _CONNECT_ATTEMPTS, exc)
            if attempt < _CONNECT_ATTEMPTS:
                time.sleep(_RETRY_BACKOFF_SECONDS * attempt)
    raise StorageError(f"Could not connect to Hostinger SFTP: {last_error}")


def _ensure_remote_dir(sftp: paramiko.SFTPClient, remote_dir: str) -> None:
    parts = [p for p in remote_dir.split("/") if p]
    path = ""
    for part in parts:
        path = f"{path}/{part}"
        try:
            sftp.stat(path)
        except FileNotFoundError:
            sftp.mkdir(path)


def _remote_exists(sftp: paramiko.SFTPClient, remote_path: str) -> bool:
    try:
        sftp.stat(remote_path)
        return True
    except FileNotFoundError:
        return False


def _with_sftp(func):
    """Run `func(sftp)` over a fresh connection, retrying once on transient failure."""
    last_error: Exception | None = None
    for attempt in range(1, _CONNECT_ATTEMPTS + 1):
        transport, sftp = None, None
        try:
            transport, sftp = _connect()
            return func(sftp)
        except (paramiko.SSHException, OSError, EOFError) as exc:
            last_error = exc
            logger.warning("SFTP operation attempt %s/%s failed: %s", attempt, _CONNECT_ATTEMPTS, exc)
            if attempt < _CONNECT_ATTEMPTS:
                time.sleep(_RETRY_BACKOFF_SECONDS * attempt)
        finally:
            if sftp is not None:
                sftp.close()
            if transport is not None:
                transport.close()
    raise StorageError(f"SFTP operation failed after {_CONNECT_ATTEMPTS} attempts: {last_error}")


def upload_local_file(local_path: str, subdir: str, filename: str) -> str:
    """Transfer the file at `local_path` to <upload_root>/<subdir>/<filename>.

    Uses sftp.put(), which reads and writes in chunks from disk — the file
    content is never fully loaded into memory. Never overwrites an existing
    remote file. Returns the remote path.
    """
    remote_dir = posixpath.join(settings.hostinger_upload_root, subdir)
    remote_path = posixpath.join(remote_dir, filename)

    def _do(sftp: paramiko.SFTPClient) -> str:
        _ensure_remote_dir(sftp, remote_dir)
        if _remote_exists(sftp, remote_path):
            raise StorageError(f"Refusing to overwrite existing remote file: {remote_path}")
        sftp.put(local_path, remote_path)
        return remote_path

    return _with_sftp(_do)


def delete_file(remote_path: str) -> bool:
    def _do(sftp: paramiko.SFTPClient) -> bool:
        try:
            sftp.remove(remote_path)
            return True
        except FileNotFoundError:
            return False

    return _with_sftp(_do)


def file_exists(remote_path: str) -> bool:
    return _with_sftp(lambda sftp: _remote_exists(sftp, remote_path))


def _upload(
    local_path: str,
    size: int,
    original_filename: str,
    content_type: str | None,
    file_type: FileAssetType,
    allowed_extensions: set[str],
    max_size: int,
) -> StoredFile:
    ext = validate_extension(original_filename, allowed_extensions)
    mime = validate_mime_type(content_type, ext)
    validate_size(size, max_size)

    filename = generate_unique_filename(original_filename)
    subdir = _REMOTE_SUBDIR[file_type]
    remote_path = upload_local_file(local_path, subdir, filename)
    public_url = get_public_url(subdir, filename)

    return StoredFile(
        filename=filename,
        original_filename=original_filename,
        file_type=file_type,
        mime_type=mime,
        size=size,
        remote_path=remote_path,
        public_url=public_url,
    )


def upload_image(local_path: str, size: int, original_filename: str, content_type: str | None) -> StoredFile:
    return _upload(
        local_path, size, original_filename, content_type, FileAssetType.image, IMAGE_EXTENSIONS, MAX_IMAGE_SIZE
    )


def upload_video(local_path: str, size: int, original_filename: str, content_type: str | None) -> StoredFile:
    return _upload(
        local_path, size, original_filename, content_type, FileAssetType.video, VIDEO_EXTENSIONS, MAX_VIDEO_SIZE
    )


def upload_document(local_path: str, size: int, original_filename: str, content_type: str | None) -> StoredFile:
    return _upload(
        local_path, size, original_filename, content_type,
        FileAssetType.document, DOCUMENT_EXTENSIONS, MAX_DOCUMENT_SIZE,
    )
