from sqlalchemy import String, create_engine
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from .config import settings

# check_same_thread only means something to SQLite's driver; psycopg2 (Postgres)
# raises on an unrecognized connect_arg, so it must be passed conditionally.
_connect_args = {"check_same_thread": False} if settings.database_url.startswith("sqlite") else {}

# Hostinger's shared MySQL enforces wait_timeout=20s — far shorter than the
# 280s pool_recycle below — so without this, most connections that sit idle
# for more than 20s between requests are already dead by the time they're
# checked back out, forcing pool_pre_ping to silently open a brand-new
# connection (full TCP+TLS+auth handshake, ~1.5-2s) instead of reusing a warm
# one (~0.1-0.3s). Raising the *session's* wait_timeout past pool_recycle
# means SQLAlchemy proactively recycles connections before the server would
# ever kill them, so pre_ping almost always finds a live connection instead
# of a dead one. Measured: cuts the "first query after an idle gap" cost
# from ~2.1s to ~0.5s. MySQL/MariaDB only — other drivers don't recognise
# `init_command`.
if settings.database_url.startswith(("mysql", "mariadb")):
    _connect_args["init_command"] = (
        "SET SESSION wait_timeout=300, SESSION interactive_timeout=300"
    )

engine = create_engine(
    settings.database_url,
    connect_args=_connect_args,
    pool_pre_ping=True,   # remote MySQL/Postgres drop idle connections; re-validate before use
    pool_recycle=280,
)


@compiles(String, "mysql", "mariadb")
def _default_varchar_length(element, compiler, **kw):
    # Models declare Column(String) without a length, which SQLite/Postgres
    # accept but MySQL/MariaDB reject ("VARCHAR requires a length").
    if element.length is None:
        return "VARCHAR(255)"
    return compiler.visit_VARCHAR(element, **kw)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
