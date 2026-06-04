# Import all models so SQLAlchemy registers them before create_all()
from .user import User, UserRole
from .auth import BlacklistedToken
from .course import SkillCategory, Course, UserCourseProgress, Lesson, UserLessonProgress, LearningResource
from .wellness import CounsellingAvailability, CounsellingSession
from .counselling import MentorProfile, CounsellingNotification
from .badge import Badge, UserBadge
from .event import Event, EventParticipant, EventQuiz, EventSelection, EventSlot, EventType, EventStatus, SelectionMethod, QuizMapping
from .quiz import Quiz, Question, QuizAttempt, DailyChallenge, QuizDifficulty
from .safety import SafetyAwarenessQuestion, UserSafetyAnswer
from .emergency import EmergencyContact
from .chat import ChatMessage
from .notification import AdminNotification
from .calendar import StudentReminder
from .creator_post import CreatorPost
