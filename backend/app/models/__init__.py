# Import all models so SQLAlchemy registers them before create_all()
from .user import User, UserRole
from .auth import BlacklistedToken
from .course import SkillCategory, Course, UserCourseProgress, Lesson, UserLessonProgress, LearningResource
from .wellness import CounsellingAvailability, CounsellingSession
from .counselling import MentorProfile, CounsellingNotification, CounsellorWeeklyAvailability
from .badge import Badge, UserBadge
from .event import Event, EventParticipant, EventQuiz, EventSelection, EventSlot, EventType, EventStatus, SelectionMethod, QuizMapping
from .quiz import Quiz, Question, QuizAttempt, DailyChallenge, QuizDifficulty
from .safety import SafetyAwarenessQuestion, UserSafetyAnswer
from .emergency import EmergencyContact
from .notification import AdminNotification
from .calendar import StudentReminder
from .creator_post import CreatorPost
from .volunteer import VolunteerActivity, ActivityApplication, ActivityAssignment, WorkSubmission, DailyLog, ImpactStory
from .donation import Donation, StipendConfig, StipendRecord, NGOPaymentDetails
from .certificate import Certificate
from .impact import ImpactPost, ImpactPostMedia, ImpactPostReaction
from .platform import (
    Notification, NotificationPreference, UserSetting, NGOProfileSetting,
    BankSetting, RolePermissionSetting, AppSetting, AdminAuditLog,
    Announcement, PasswordResetToken, ReminderJob, EventReportFile,
    SchoolCounsellorRequest, CounsellorSessionReport,
)
from .school_partner import SchoolPartnerProfile
from .file_asset import FileAsset, FileAssetType
