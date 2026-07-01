import os
from pathlib import Path

from dotenv import load_dotenv

# Load .env from the backend root (one directory above this file)
load_dotenv(Path(__file__).parent.parent / ".env")


class Settings:
    app_name: str = "CareSkill API"
    version: str = "1.0.0"
    debug: bool = os.getenv("DEBUG", "false").lower() == "true"
    database_url: str = os.getenv("DATABASE_URL", "sqlite:///./careskill.db")

    # XP thresholds per level  (level = xp // xp_per_level + 1)
    xp_per_level: int = 500

    # JWT — set SECRET_KEY env var in production; never use the default in prod
    secret_key: str = os.getenv("SECRET_KEY", "careskill-dev-secret-CHANGE-IN-PRODUCTION")
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60   # 1 hour for dev convenience
    refresh_token_expire_days: int = 7

    # Google Calendar / Meet — set these env vars to enable calendar sync
    google_client_id: str = os.getenv("GOOGLE_CLIENT_ID", "")
    google_client_secret: str = os.getenv("GOOGLE_CLIENT_SECRET", "")
    # GOOGLE_REDIRECT_URI can be overridden in .env with your ngrok URL, e.g.
    # GOOGLE_REDIRECT_URI=https://xxxx.ngrok-free.app/auth/google/callback
    google_redirect_uri: str = os.getenv(
        "GOOGLE_REDIRECT_URI", "http://localhost:8000/auth/google/callback"
    )
    # Public base URL — used to build absolute links (e.g. OAuth callbacks via ngrok).
    # Set PUBLIC_URL=https://xxxx.ngrok-free.app in .env when tunnelling.
    public_url: str = os.getenv("PUBLIC_URL", "http://localhost:8000")

    # Auth0 — set AUTH0_DOMAIN and AUTH0_CLIENT_ID in .env
    # Domain:    your Auth0 tenant, e.g. dev-abc123.us.auth0.com
    # Client ID: the Client ID of your Auth0 Native application
    auth0_domain: str = os.getenv("AUTH0_DOMAIN", "")
    auth0_client_id: str = os.getenv("AUTH0_CLIENT_ID", "")

    # Private password-reset delivery. Configure these in production.
    smtp_host: str = os.getenv("SMTP_HOST", "")
    smtp_port: int = int(os.getenv("SMTP_PORT", "587"))
    smtp_username: str = os.getenv("SMTP_USERNAME", "")
    smtp_password: str = os.getenv("SMTP_PASSWORD", "")
    smtp_from_email: str = os.getenv("SMTP_FROM_EMAIL", "")
    smtp_use_tls: bool = os.getenv("SMTP_USE_TLS", "true").lower() == "true"

    # Hostinger SFTP — remote storage for images/videos/documents.
    # Postgres only ever stores metadata + the public URL, never file bytes.
    hostinger_host: str = os.getenv("HOSTINGER_HOST", "")
    hostinger_port: int = int(os.getenv("HOSTINGER_PORT", "22"))
    hostinger_username: str = os.getenv("HOSTINGER_USERNAME", "")
    hostinger_password: str = os.getenv("HOSTINGER_PASSWORD", "")
    # Absolute remote path uploads are written under, e.g.
    # /home/u123456/domains/example.com/public_html/uploads
    hostinger_upload_root: str = os.getenv("HOSTINGER_UPLOAD_ROOT", "/public_html/uploads")
    # Public base URL that maps to hostinger_upload_root, e.g. https://cdn.example.com/uploads
    hostinger_public_base_url: str = os.getenv("HOSTINGER_PUBLIC_BASE_URL", "")


settings = Settings()
