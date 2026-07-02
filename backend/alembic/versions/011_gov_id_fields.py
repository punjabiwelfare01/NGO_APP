"""Add gov_id_type and gov_id_doc_url fields to users table.

Revision ID: 011
Revises: 010
Create Date: 2026-07-03
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "011"
down_revision: Union[str, None] = "010"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    existing_cols = {c["name"] for c in inspector.get_columns("users")}

    with op.batch_alter_table("users") as batch_op:
        if "gov_id_type" not in existing_cols:
            batch_op.add_column(sa.Column("gov_id_type", sa.String(), nullable=True))
        if "gov_id_doc_url" not in existing_cols:
            batch_op.add_column(sa.Column("gov_id_doc_url", sa.String(), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("users") as batch_op:
        batch_op.drop_column("gov_id_doc_url")
        batch_op.drop_column("gov_id_type")
