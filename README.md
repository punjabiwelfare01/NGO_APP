# CareSkill — NGO Learning Platform

A full-stack app for an NGO running youth skill courses, event-based volunteering, mentorship/counselling, and certificate issuance.

- **Frontend**: Flutter (Android)
- **Backend**: FastAPI (Python), SQLAlchemy 2, Alembic migrations
- **Database**: SQLite for local dev, PostgreSQL in production
- **File storage**: Images/videos/documents uploaded via the `/upload/*` endpoints are stored on Hostinger over SFTP; only metadata + public URL live in the database
- **Deployment**: Dockerfile + `railway.toml` for Railway

---

## Project layout

```
lib/            Flutter app source
backend/        FastAPI backend
  app/          routers, models, schemas, crud, services
  alembic/      database migrations
  tests/        pytest suite
  Dockerfile    production container build
  railway.toml  Railway build/deploy config
```

---

## Running the backend locally

```bash
cd backend
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt

cp .env.example .env   # fill in the values you need (see below)

.venv/bin/uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The API is now at `http://localhost:8000`, with interactive docs at `http://localhost:8000/docs`.

Tables are created automatically on startup against the local SQLite file (`careskill.db`). To run the test suite:

```bash
.venv/bin/python -m pytest tests/ -q
```

### Environment variables

See `backend/.env.example` for the full list. At minimum for local dev you'll want `SECRET_KEY`. Google OAuth, Auth0, SMTP, and Hostinger SFTP storage are all optional locally — those features simply won't work until configured, everything else runs fine without them.

---

## Running the Flutter app

```bash
flutter pub get
flutter run
```

On an Android emulator, `localhost` refers to the emulator itself, not your machine — point the app at `http://10.0.2.2:8000` instead. See `lib/core/config.dart` for the base URL setting.

---

## Deployment

The backend deploys to Railway via the Dockerfile in `backend/`. Set the Railway service's **Root Directory** to `backend`, attach a PostgreSQL database, and configure the environment variables listed in `backend/.env.example` (`DATABASE_URL` is auto-injected by Railway's Postgres addon). `entrypoint.sh` runs `alembic upgrade head` before starting the server.
