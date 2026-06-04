"""
One-time Google Calendar OAuth2 setup script.

Run this ONCE to authorise the backend to create Google Meet links:

    cd backend
    .venv/bin/python setup_google_auth.py

What it does:
  1. Opens a browser tab asking you to sign into Google.
  2. You click "Allow".
  3. Saves backend/google_token.json — the server uses this from now on.
  4. All future counselling slots auto-get a real Google Meet link.

Requirements:
  - Add  http://localhost:8080  to your OAuth client's Authorized redirect URIs
    in Google Console → APIs & Services → Credentials → your Web client → Edit.
"""

import sys
from pathlib import Path

# ── locate the client secret JSON file ────────────────────────────────────────
_HERE = Path(__file__).parent
_TOKEN_FILE = _HERE / "google_token.json"
_SCOPES = ["https://www.googleapis.com/auth/calendar.events"]

def _find_client_secret() -> Path:
    matches = list(_HERE.glob("client_secret_*.json"))
    if matches:
        return matches[0]
    raise FileNotFoundError(
        "No client_secret_*.json found in backend/.\n"
        "Download it from Google Console → APIs & Services → Credentials → "
        "your OAuth client → Download JSON."
    )


def main() -> None:
    try:
        from google_auth_oauthlib.flow import InstalledAppFlow
        from googleapiclient.discovery import build
    except ImportError:
        print("ERROR: google packages not installed.")
        print("Run:  .venv/bin/pip install google-auth-oauthlib google-api-python-client")
        sys.exit(1)

    secret_file = _find_client_secret()
    print(f"Using credentials: {secret_file.name}")
    print()
    print("IMPORTANT: Make sure  http://localhost:8080  is listed as an")
    print("Authorized redirect URI in your Google Console OAuth client.")
    print("(APIs & Services → Credentials → your client → Edit → Add URI)")
    print()
    input("Press Enter when ready to open the browser...")

    flow = InstalledAppFlow.from_client_secrets_file(
        str(secret_file),
        scopes=_SCOPES,
    )

    # Opens browser automatically and starts a local server on port 8080
    # to catch the OAuth callback.
    creds = flow.run_local_server(
        port=8080,
        prompt="consent",
        access_type="offline",
        open_browser=True,
    )

    _TOKEN_FILE.write_text(creds.to_json())
    print()
    print(f"✓ Saved: {_TOKEN_FILE}")
    print()
    print("Google Calendar is now authorised.")
    print("Every new counselling slot will automatically get a Google Meet link.")

    # Quick sanity check — list next 3 calendar events
    try:
        from datetime import datetime, timezone
        service = build("calendar", "v3", credentials=creds)
        now = datetime.now(timezone.utc).isoformat()
        result = service.events().list(
            calendarId="primary",
            timeMin=now,
            maxResults=3,
            singleEvents=True,
            orderBy="startTime",
        ).execute()
        events = result.get("items", [])
        if events:
            print()
            print("Upcoming calendar events (sanity check):")
            for e in events:
                start = e["start"].get("dateTime", e["start"].get("date"))
                print(f"  - {e.get('summary','(no title)')}  [{start}]")
        else:
            print("(No upcoming events found — calendar access confirmed.)")
    except Exception as exc:
        print(f"Warning: could not list events: {exc}")


if __name__ == "__main__":
    main()
