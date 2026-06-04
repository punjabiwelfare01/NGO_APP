import logging
import uuid
from datetime import datetime
from pathlib import Path

from google.auth.exceptions import GoogleAuthError
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import Flow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

from .config import settings

logger = logging.getLogger(__name__)

# Calendar scope — creates events (and Meet links) in the authorised account's calendar.
_SCOPES = ["https://www.googleapis.com/auth/calendar.events"]

_BACKEND_DIR = Path(__file__).parent.parent
# Tokens are stored in backend/google_token.json
_TOKEN_FILE = _BACKEND_DIR / "google_token.json"


def _find_client_secret_file() -> Path | None:
    """Return the first client_secret_*.json found in the backend directory."""
    matches = list(_BACKEND_DIR.glob("client_secret_*.json"))
    return matches[0] if matches else None


def _client_config() -> dict:
    # Prefer the downloaded client_secret JSON file if present.
    secret_file = _find_client_secret_file()
    if secret_file:
        import json
        raw = json.loads(secret_file.read_text())
        key = list(raw.keys())[0]          # "web" or "installed"
        data = raw[key]
        return {
            key: {
                "client_id":     data["client_id"],
                "client_secret": data["client_secret"],
                "redirect_uris": data.get("redirect_uris") or [settings.google_redirect_uri],
                "auth_uri":      data.get("auth_uri", "https://accounts.google.com/o/oauth2/auth"),
                "token_uri":     data.get("token_uri", "https://oauth2.googleapis.com/token"),
            }
        }
    # Fallback: build config from .env variables.
    return {
        "web": {
            "client_id":     settings.google_client_id,
            "client_secret": settings.google_client_secret,
            "redirect_uris": [settings.google_redirect_uri],
            "auth_uri":      "https://accounts.google.com/o/oauth2/auth",
            "token_uri":     "https://oauth2.googleapis.com/token",
        }
    }


def is_calendar_authorized() -> bool:
    return _get_credentials() is not None


def _effective_redirect_uri() -> str:
    # If the admin explicitly set GOOGLE_REDIRECT_URI in .env, honour it.
    # Otherwise build it from PUBLIC_URL so ngrok tunnels work automatically.
    if settings.google_redirect_uri != "http://localhost:8000/auth/google/callback":
        return settings.google_redirect_uri
    return f"{settings.public_url.rstrip('/')}/auth/google/callback"


def get_authorization_url() -> tuple[str, str]:
    """Return (auth_url, state) for the one-time OAuth2 consent page."""
    flow = Flow.from_client_config(_client_config(), scopes=_SCOPES)
    flow.redirect_uri = _effective_redirect_uri()
    url, state = flow.authorization_url(
        access_type="offline",
        include_granted_scopes="true",
        prompt="consent",
    )
    return url, state


def exchange_code_for_tokens(code: str, state: str) -> None:
    """Exchange the OAuth2 authorization code for tokens and save them."""
    flow = Flow.from_client_config(_client_config(), scopes=_SCOPES, state=state)
    flow.redirect_uri = _effective_redirect_uri()
    flow.fetch_token(code=code)
    _save_credentials(flow.credentials)
    logger.info("Google Calendar tokens saved to %s", _TOKEN_FILE)


def _save_credentials(creds: Credentials) -> None:
    _TOKEN_FILE.write_text(creds.to_json())


def _get_credentials() -> Credentials | None:
    if not _TOKEN_FILE.exists():
        return None
    try:
        creds = Credentials.from_authorized_user_file(str(_TOKEN_FILE), _SCOPES)
    except Exception:
        return None
    if creds and creds.expired and creds.refresh_token:
        try:
            creds.refresh(Request())
            _save_credentials(creds)
        except GoogleAuthError as exc:
            logger.warning("Could not refresh Google token: %s", exc)
            return None
    return creds if (creds and creds.valid) else None


def create_meet_link(
    title: str,
    starts_at: datetime,
    ends_at: datetime,
    description: str = "",
) -> str | None:
    """
    Create a Google Calendar event with a Meet conference.
    Returns the video join URL, or None if Calendar is not yet authorized
    or if the API call fails (caller should proceed without a link).
    """
    creds = _get_credentials()
    if not creds:
        logger.warning(
            "Google Calendar not authorized. "
            "Visit GET /auth/google/calendar/authorize to set up."
        )
        return None

    try:
        service = build("calendar", "v3", credentials=creds)
        event = {
            "summary": title,
            "description": description,
            "start": {"dateTime": starts_at.isoformat(), "timeZone": "UTC"},
            "end": {"dateTime": ends_at.isoformat(), "timeZone": "UTC"},
            "conferenceData": {
                "createRequest": {
                    "requestId": str(uuid.uuid4()),
                    "conferenceSolutionKey": {"type": "hangoutsMeet"},
                }
            },
        }
        created = (
            service.events()
            .insert(calendarId="primary", body=event, conferenceDataVersion=1)
            .execute()
        )
        for ep in created.get("conferenceData", {}).get("entryPoints", []):
            if ep.get("entryPointType") == "video":
                link = ep.get("uri")
                logger.info("Google Meet link created: %s", link)
                return link
        logger.warning("Event created but no Meet entry point found: %s", created.get("id"))
        return None
    except HttpError as exc:
        logger.error("Google Calendar API error: %s", exc)
        return None
