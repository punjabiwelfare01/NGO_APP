"""Add file_assets table for Hostinger SFTP-backed storage metadata.

Revision ID: 010
Revises: 009
Create Date: 2026-07-01
"""
from typing import Sequence, Union

from alembic import op

revision: str = "010"
down_revision: Union[str, None] = "009"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    from app.models.file_asset import FileAsset

    FileAsset.__table__.create(bind=bind, checkfirst=True)


def downgrade() -> None:
    op.drop_table("file_assets")
