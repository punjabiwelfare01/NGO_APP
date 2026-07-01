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
alembic upgrade head

echo "==> Starting CareSkill API..."
# Railway injects $PORT at runtime and routes to whatever port the process binds —
# a hardcoded port here would silently break the platform's health checks.
exec uvicorn app.main:app \
    --host 0.0.0.0 \
    --port "${PORT:-8000}" \
    --workers "${WEB_CONCURRENCY:-1}" \
    --proxy-headers \
    --forwarded-allow-ips='*'
