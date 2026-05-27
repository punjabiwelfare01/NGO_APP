from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import relationship

from ..database import Base


class SafetyAwarenessQuestion(Base):
    __tablename__ = "safety_awareness_questions"

    id = Column(Integer, primary_key=True, index=True)
    question_text = Column(String, nullable=False)
    option_a = Column(String, nullable=False)
    option_b = Column(String, nullable=False)
    option_c = Column(String, nullable=False)
    # 'a' | 'b' | 'c'
    correct_option = Column(String, nullable=False)
    explanation = Column(String, nullable=False)
    category = Column(String, nullable=False, default="general")
    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

    answers = relationship("UserSafetyAnswer", back_populates="question", cascade="all, delete-orphan")


class UserSafetyAnswer(Base):
    __tablename__ = "user_safety_answers"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    question_id = Column(Integer, ForeignKey("safety_awareness_questions.id"), nullable=False)
    # 'a' | 'b' | 'c'
    chosen_option = Column(String, nullable=False)
    is_correct = Column(Boolean, nullable=False)
    answered_at = Column(DateTime, server_default=func.now())

    question = relationship("SafetyAwarenessQuestion", back_populates="answers")
    user = relationship("User")
