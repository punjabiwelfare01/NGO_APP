# ── Stage 1: dependencies ─────────────────────────────────────────────────────
FROM python:3.12-slim AS deps

RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ── Stage 2: runtime ──────────────────────────────────────────────────────────
FROM python:3.12-slim

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

# Create persistent directories (mounted as volumes in production)
RUN mkdir -p uploads videos_uploaded logs \
    && chmod +x entrypoint.sh

# Run as non-root user for security
RUN useradd -m -u 1000 appuser \
    && chown -R appuser:appuser /app
USER appuser

# Documents the default port for local/docker-compose use; Railway ignores this
# and instead routes to whatever port the process binds via $PORT at runtime.
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f "http://localhost:${PORT:-8000}/health" || exit 1

ENTRYPOINT ["./entrypoint.sh"]
