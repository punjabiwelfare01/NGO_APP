"""Add featured field to mentor_profiles table.

Revision ID: 014
Revises: 013
Create Date: 2026-07-06
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "014"
down_revision: Union[str, None] = "013"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    existing_cols = {c["name"] for c in inspector.get_columns("mentor_profiles")}

    if "featured" not in existing_cols:
        op.add_column(
            "mentor_profiles",
            sa.Column("featured", sa.Boolean(), nullable=False, server_default=sa.false()),
        )


def downgrade() -> None:
    op.drop_column("mentor_profiles", "featured")
