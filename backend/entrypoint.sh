#!/bin/sh
set -e

echo "==> Waiting for database to be ready..."
# Retry loop — PostgreSQL might take a few seconds to start
for i in $(seq 1 30); do
    python -c "
import sys
from sqlalchemy import create_engine, text
import os
url = os.environ.get('DATABASE_URL', '')
if not url:
    print('No DATABASE_URL set, skipping check')
    sys.exit(0)
try:
    e = create_engine(url)
    with e.connect() as c:
        c.execute(text('SELECT 1'))
    print('Database is ready')
    sys.exit(0)
except Exception as ex:
    print(f'Not ready yet: {ex}')
    sys.exit(1)
" && break
    echo "Attempt $i/30 failed — retrying in 2s..."
    sleep 2
done

echo "==> Running database migrations..."
# Migration 001 is an empty baseline that assumes the schema was bootstrapped
# by Base.metadata.create_all(). On a fresh database (no users table) we must
# create the schema first and stamp head; otherwise the incremental
# migrations reference tables that don't exist yet.
DB_STATE=$(python -c "
from sqlalchemy import inspect
from app.database import engine
print('fresh' if not inspect(engine).has_table('users') else 'existing')
")
if [ "$DB_STATE" = "fresh" ]; then
    echo "==> Fresh database detected — creating full schema and stamping baseline..."
    python -c "
from app.database import Base, engine
import app.models  # noqa: F401 — registers all ORM models
Base.metadata.create_all(bind=engine)
print('Schema created.')
"
    alembic stamp head
else
    alembic upgrade head
fi

echo "==> Starting CareSkill API..."
# Railway injects $PORT at runtime and routes to whatever port the process binds —
# a hardcoded port here would silently break the platform's health checks.
exec uvicorn app.main:app \
    --host 0.0.0.0 \
    --port "${PORT:-8000}" \
    --workers "${WEB_CONCURRENCY:-1}" \
    --proxy-headers \
    --forwarded-allow-ips='*'
