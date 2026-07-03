# ── Stage 1: dependencies ─────────────────────────────────────────────────────
FROM python:3.12-slim AS deps

# gcc + libpq-dev cover any package that falls back to a source build
# (psycopg2, cryptography, bcrypt normally install as prebuilt wheels).
# pymysql (MySQL/MariaDB driver) is pure Python — no system libs needed.
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ── Stage 2: runtime ──────────────────────────────────────────────────────────
FROM python:3.12-slim

# Don't buffer stdout/stderr — logs appear in Railway immediately, not in bursts
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Runtime system libs only (no gcc needed at runtime)
RUN apt-get update && apt-get install -y \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy installed packages from deps stage
COPY --from=deps /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=deps /usr/local/bin /usr/local/bin

# Copy application code
COPY app/        ./app/
COPY alembic/    ./alembic/
COPY alembic.ini .
COPY entrypoint.sh .

# Local-fallback upload dirs — only used when HOSTINGER_HOST is not configured;
# in production files go to Hostinger over SFTP and these stay empty.
RUN mkdir -p uploads/gov_ids uploads/images uploads/videos uploads/documents \
             uploads/certificates uploads/event_reports uploads/counsellor_docs \
             videos_uploaded logs \
    && chmod +x entrypoint.sh

# Run as non-root user for security
RUN useradd -m -u 1000 appuser \
    && chown -R appuser:appuser /app
USER appuser

# Documents the default port for local/docker-compose use; Railway ignores this
# and instead routes to whatever port the process binds via $PORT at runtime.
EXPOSE 8000

# Local/docker-compose health check; Railway uses healthcheckPath from railway.toml
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f "http://localhost:${PORT:-8000}/health" || exit 1

# entrypoint.sh: waits for the database, bootstraps/migrates the schema,
# then starts uvicorn (app.main:app on $PORT, default 8000).
ENTRYPOINT ["./entrypoint.sh"]
