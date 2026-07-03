from sqlalchemy import String, create_engine
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from .config import settings

# check_same_thread only means something to SQLite's driver; psycopg2 (Postgres)
# raises on an unrecognized connect_arg, so it must be passed conditionally.
_connect_args = {"check_same_thread": False} if settings.database_url.startswith("sqlite") else {}

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
