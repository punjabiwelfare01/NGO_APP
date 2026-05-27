from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import relationship

from ..database import Base


class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id         = Column(Integer, primary_key=True, index=True)
    # Room is identified by sorted(mentor_user_id, student_user_id).
    # We store both to allow efficient queries from either side.
    mentor_id  = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    student_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    sender_id  = Column(Integer, ForeignKey("users.id"), nullable=False)
    content    = Column(Text, nullable=False)
    created_at = Column(DateTime, server_default=func.now(), index=True)

    mentor  = relationship("User", foreign_keys=[mentor_id])
    student = relationship("User", foreign_keys=[student_id])
    sender  = relationship("User", foreign_keys=[sender_id])
