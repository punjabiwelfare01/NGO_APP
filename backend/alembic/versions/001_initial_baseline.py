"""Initial baseline — stamps existing database as up to date.

Run once on a database that was created by SQLAlchemy's create_all():
    cd backend
    alembic stamp head

After stamping, use `alembic revision --autogenerate -m "description"` for
all future schema changes instead of editing dev_migrations.py.

Revision ID: 001
Revises:
Create Date: 2025-01-01 00:00:00.000000
"""
from typing import Sequence, Union

revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Intentionally empty — the database schema was bootstrapped by
    # SQLAlchemy's Base.metadata.create_all() and dev_migrations.py.
    # This revision simply marks the existing state as the Alembic baseline.
    pass


def downgrade() -> None:
    pass
