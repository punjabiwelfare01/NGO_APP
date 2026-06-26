from pathlib import Path
import secrets


ROOT = Path(__file__).resolve().parents[2] / "uploads"


def storage_dir(kind: str) -> Path:
    safe = "".join(ch for ch in kind if ch.isalnum() or ch in ("-", "_"))
    path = ROOT / safe
    path.mkdir(parents=True, exist_ok=True)
    return path


def save_bytes(kind: str, content: bytes, suffix: str) -> str:
    name = f"{secrets.token_urlsafe(18)}{suffix}"
    path = storage_dir(kind) / name
    path.write_bytes(content)
    return str(path)


def save_upload(kind: str, file_name: str, content: bytes) -> str:
    suffix = Path(file_name).suffix.lower()
    return save_bytes(kind, content, suffix or ".bin")


def resolve_stored_file(path: str | None, kind: str) -> Path | None:
    if not path:
        return None
    candidate = Path(path).resolve()
    root = storage_dir(kind).resolve()
    if candidate.is_file() and root in candidate.parents:
        return candidate
    return None
