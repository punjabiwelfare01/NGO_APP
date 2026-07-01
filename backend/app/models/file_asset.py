import enum

from sqlalchemy import BigInteger, Column, DateTime, Enum as SAEnum, ForeignKey, Integer, String, func

from ..database import Base


class FileAssetType(str, enum.Enum):
    image    = "image"
    video    = "video"
    document = "document"


class FileAsset(Base):
    __tablename__ = "file_assets"

    id                = Column(Integer, primary_key=True, index=True)
    filename          = Column(String, nullable=False)             # UUID-based stored filename
    original_filename = Column(String, nullable=False)
    file_type         = Column(SAEnum(FileAssetType), nullable=False)
    mime_type         = Column(String, nullable=False)
    size              = Column(BigInteger, nullable=False)         # bytes
    remote_path       = Column(String, nullable=False, unique=True)  # absolute path on Hostinger
    public_url        = Column(String, nullable=False)
    uploaded_at       = Column(DateTime, server_default=func.now())
    uploaded_by       = Column(Integer, ForeignKey("users.id"), nullable=False)
