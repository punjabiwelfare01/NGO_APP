"""Add secondary_role field to users table (multi-role support).

Revision ID: 012
Revises: 011
Create Date: 2026-07-03
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "012"
down_revision: Union[str, None] = "011"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    existing_cols = {c["name"] for c in inspector.get_columns("users")}

    # Adding one nullable column doesn't require SQLite's batch/table-rebuild
    # mode (that's only needed for column drops/renames/type changes).
    if "secondary_role" not in existing_cols:
        op.add_column("users", sa.Column("secondary_role", sa.String(), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "secondary_role")
