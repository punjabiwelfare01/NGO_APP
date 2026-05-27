import enum

from sqlalchemy import Boolean, Column, DateTime, Enum as SAEnum, Float, ForeignKey, Integer, String, Text, func
from sqlalchemy.types import JSON
from sqlalchemy.orm import relationship

from ..database import Base


class QuizDifficulty(str, enum.Enum):
    easy   = "easy"
    medium = "medium"
    hard   = "hard"


class Quiz(Base):
    __tablename__ = "quizzes"

    id                 = Column(Integer, primary_key=True, index=True)
    title              = Column(String, nullable=False)
    description        = Column(Text, nullable=True)
    category           = Column(String, nullable=True)
    difficulty         = Column(SAEnum(QuizDifficulty), default=QuizDifficulty.medium, nullable=False)
    xp_reward          = Column(Integer, default=100, nullable=False)
    time_limit_seconds = Column(Integer, default=300, nullable=False)
    is_active          = Column(Boolean, default=True, nullable=False)
    created_by         = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at         = Column(DateTime, server_default=func.now())

    questions = relationship(
        "Question", back_populates="quiz",
        cascade="all, delete-orphan",
        order_by="Question.order_index",
    )
    attempts = relationship("QuizAttempt", back_populates="quiz", cascade="all, delete-orphan")
    creator  = relationship("User", foreign_keys=[created_by])

    @property
    def question_count(self) -> int:
        return len(self.questions)


class Question(Base):
    __tablename__ = "questions"

    id            = Column(Integer, primary_key=True, index=True)
    quiz_id       = Column(Integer, ForeignKey("quizzes.id"), nullable=False)
    text          = Column(Text, nullable=False)
    options       = Column(JSON, nullable=False)    # list[str] — exactly 4 items
    correct_index = Column(Integer, nullable=False)  # 0-3
    explanation   = Column(Text, nullable=True)
    points        = Column(Integer, default=10, nullable=False)
    order_index   = Column(Integer, default=0, nullable=False)

    quiz = relationship("Quiz", back_populates="questions")


class QuizAttempt(Base):
    __tablename__ = "quiz_attempts"

    id                 = Column(Integer, primary_key=True, index=True)
    user_id            = Column(Integer, ForeignKey("users.id"), nullable=False)
    quiz_id            = Column(Integer, ForeignKey("quizzes.id"), nullable=False)
    answers            = Column(JSON, nullable=False)   # list[int] — selected index (-1 = skipped)
    score              = Column(Float, default=0.0, nullable=False)   # percentage 0-100
    correct_count      = Column(Integer, default=0, nullable=False)
    total_questions    = Column(Integer, default=0, nullable=False)
    xp_earned          = Column(Integer, default=0, nullable=False)
    time_taken_seconds = Column(Integer, nullable=True)
    completed_at       = Column(DateTime, server_default=func.now())

    user = relationship("User", foreign_keys=[user_id])
    quiz = relationship("Quiz", back_populates="attempts")


class DailyChallenge(Base):
    __tablename__ = "daily_challenges"

    id             = Column(Integer, primary_key=True, index=True)
    quiz_id        = Column(Integer, ForeignKey("quizzes.id"), nullable=False)
    challenge_date = Column(String, unique=True, nullable=False, index=True)  # YYYY-MM-DD

    quiz = relationship("Quiz")
