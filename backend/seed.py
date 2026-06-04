"""
Seed the database with initial data.
Drops all tables and recreates them on every run (use only in development).

    cd backend
    python seed.py
"""
from datetime import date, datetime, timedelta

from passlib.context import CryptContext

from app.database import Base, SessionLocal, engine
from app.models import (  # noqa: F401
    Badge, BlacklistedToken, Course, CounsellingAvailability, CounsellingSession,
    Lesson, LearningResource,
    SkillCategory, User, UserBadge, UserCourseProgress,
    DailyChallenge, Question, Quiz, QuizDifficulty,
)
from app.models.user import UserRole

_pwd = CryptContext(schemes=["bcrypt"], deprecated="auto")


def _hash(plain: str) -> str:
    return _pwd.hash(plain)


# ── reset ──────────────────────────────────────────────────────────────────────

print("Dropping and recreating all tables...")
Base.metadata.drop_all(bind=engine)
Base.metadata.create_all(bind=engine)

db = SessionLocal()


# ── seed helpers ───────────────────────────────────────────────────────────────

def seed_categories() -> list[SkillCategory]:
    data = [
        SkillCategory(title="Communication Skill", icon_name="record_voice_over_rounded",      color_hex="#FFE7C8"),
        SkillCategory(title="Digital Literacy",    icon_name="devices_rounded",                color_hex="#DDF1FF"),
        SkillCategory(title="Career Guidance",     icon_name="explore_rounded",                color_hex="#E9E2FF"),
        SkillCategory(title="Safety Awareness",    icon_name="shield_rounded",                 color_hex="#E0F8E8"),
        SkillCategory(title="Financial Literacy",  icon_name="account_balance_wallet_rounded", color_hex="#FFF3D0"),
    ]
    db.add_all(data)
    db.commit()
    for d in data:
        db.refresh(d)
    return data


def seed_courses(categories: list[SkillCategory]) -> list[Course]:
    cat = {c.title: c.id for c in categories}
    data = [
        Course(
            title="Coding Basics for Kids",
            duration="2h 30m",
            level="Beginner",
            icon_name="code_rounded",
            color_hex="#DDF1FF",
            category_id=cat["Digital Literacy"],
        ),
        Course(
            title="Speak with Confidence",
            duration="1h 45m",
            level="Beginner",
            icon_name="campaign_rounded",
            color_hex="#FFE7C8",
            category_id=cat["Communication Skill"],
        ),
        Course(
            title="Internet Safety Heroes",
            duration="3h",
            level="Intermediate",
            icon_name="security_rounded",
            color_hex="#E0F8E8",
            category_id=cat["Safety Awareness"],
        ),
    ]
    db.add_all(data)
    db.commit()
    for d in data:
        db.refresh(d)
    return data


def seed_lessons(courses: list[Course]) -> list[Lesson]:
    course_by_title = {c.title: c for c in courses}
    lessons = [
        Lesson(
            course_id=course_by_title["Coding Basics for Kids"].id,
            title="What is Coding?",
            description="A friendly introduction to how instructions become apps and websites.",
            content_type="mixed",
            content_url="https://www.youtube.com/watch?v=rfscVS0vtbw",
            content_text=(
                "Coding means writing clear instructions for a computer. "
                "In this lesson, students learn what programs are, how logic works, "
                "and why small steps make problem solving easier."
            ),
            order=0,
            duration_minutes=14,
            is_published=True,
        ),
        Lesson(
            course_id=course_by_title["Coding Basics for Kids"].id,
            title="Build Your First Web Page",
            description="Create a simple page with headings, text, and a button.",
            content_type="mixed",
            content_url="https://www.youtube.com/watch?v=916GWv2Qs08",
            content_text=(
                "HTML gives structure to a web page. Try writing a heading, a paragraph, "
                "and one button. Keep names simple and test each change."
            ),
            order=1,
            duration_minutes=18,
            is_published=True,
        ),
        Lesson(
            course_id=course_by_title["Speak with Confidence"].id,
            title="Speak Clearly in Class",
            description="Practice voice, posture, and short answers.",
            content_type="mixed",
            content_url="https://www.youtube.com/watch?v=tShavGuo0_E",
            content_text=(
                "Good communication starts with breathing, listening, and speaking one idea "
                "at a time. Use a calm voice and look at the person you are speaking to."
            ),
            order=0,
            duration_minutes=12,
            is_published=True,
        ),
        Lesson(
            course_id=course_by_title["Internet Safety Heroes"].id,
            title="Strong Passwords and Safe Links",
            description="Learn how to identify suspicious links and protect accounts.",
            content_type="mixed",
            content_url="https://www.youtube.com/watch?v=HxySrSbSY7o",
            content_text=(
                "Never share passwords. Use long passwords with words, numbers, and symbols. "
                "If a link feels urgent or strange, stop and ask a trusted adult."
            ),
            order=0,
            duration_minutes=16,
            is_published=True,
        ),
    ]
    db.add_all(lessons)
    db.commit()
    for lesson in lessons:
        db.refresh(lesson)

    resources = []
    for lesson in lessons:
        resources.extend([
            LearningResource(
                lesson_id=lesson.id,
                type="pdf",
                title=f"{lesson.title} Notes.pdf",
                file_url=f"https://example.com/careskill/{lesson.id}-notes.pdf",
                text_content=None,
            ),
            LearningResource(
                lesson_id=lesson.id,
                type="note",
                title="Quick Revision Notes",
                file_url=None,
                text_content=lesson.content_text,
            ),
        ])
    resources.append(
        LearningResource(
            lesson_id=lessons[1].id,
            type="zip",
            title="Practice Web Page Files.zip",
            file_url="https://example.com/careskill/practice-web-page.zip",
            text_content=None,
        )
    )
    db.add_all(resources)
    db.commit()
    return lessons


def seed_badges() -> list[Badge]:
    data = [
        Badge(icon_name="code_rounded",              label="Coding Starter", category="skill"),
        Badge(icon_name="shield_rounded",            label="Cyber Safe",     category="safety"),
        Badge(icon_name="record_voice_over_rounded", label="Speaker",        category="skill"),
        Badge(icon_name="brush_rounded",             label="Creative Mind",  category="skill"),
        Badge(icon_name="military_tech_rounded",     label="Quiz Champion",  category="achievement"),
        Badge(icon_name="star_rounded",              label="Top Learner",    category="achievement"),
    ]
    db.add_all(data)
    db.commit()
    for d in data:
        db.refresh(d)
    return data


def seed_quizzes(admin: User) -> list[Quiz]:
    quizzes = [
        Quiz(
            title="Cyber Safety Starter",
            description="Practice smart choices for passwords, messages, and links.",
            category="Cyber Safety",
            difficulty=QuizDifficulty.easy,
            xp_reward=80,
            time_limit_seconds=240,
            created_by=admin.id,
            questions=[
                Question(
                    text="What should you do if a stranger asks for your home address online?",
                    options=[
                        "Share it if they seem friendly",
                        "Ask a trusted adult before replying",
                        "Send it in a private message",
                        "Post it only for a few minutes",
                    ],
                    correct_index=1,
                    explanation="Personal details should stay private, and a trusted adult can help you decide what is safe.",
                    points=10,
                    order_index=0,
                ),
                Question(
                    text="Which password is the safest choice?",
                    options=[
                        "aarav123",
                        "password",
                        "BlueTiger!47Cloud",
                        "myname",
                    ],
                    correct_index=2,
                    explanation="Strong passwords mix words, numbers, and symbols so they are harder to guess.",
                    points=10,
                    order_index=1,
                ),
                Question(
                    text="A link says you won a free phone and asks you to log in. What is the best next step?",
                    options=[
                        "Click quickly before it expires",
                        "Share it with friends",
                        "Close it and report or ask an adult",
                        "Enter a fake password",
                    ],
                    correct_index=2,
                    explanation="Prize links can be phishing attempts. Stop, check, and ask for help.",
                    points=10,
                    order_index=2,
                ),
            ],
        ),
        Quiz(
            title="Kind Communication",
            description="Choose thoughtful responses in everyday conversations.",
            category="Communication",
            difficulty=QuizDifficulty.medium,
            xp_reward=100,
            time_limit_seconds=300,
            created_by=admin.id,
            questions=[
                Question(
                    text="A teammate makes a mistake in your project. What helps most?",
                    options=[
                        "Blame them in front of everyone",
                        "Ignore the problem",
                        "Explain the issue kindly and offer help",
                        "Quit the team",
                    ],
                    correct_index=2,
                    explanation="Kind, clear feedback helps the team solve the problem together.",
                    points=10,
                    order_index=0,
                ),
                Question(
                    text="What does active listening mean?",
                    options=[
                        "Planning your reply while someone talks",
                        "Interrupting with your own story",
                        "Paying attention and checking you understood",
                        "Only listening to friends",
                    ],
                    correct_index=2,
                    explanation="Active listening means focusing on the speaker and confirming the meaning.",
                    points=10,
                    order_index=1,
                ),
            ],
        ),
    ]
    db.add_all(quizzes)
    db.commit()
    for quiz in quizzes:
        db.refresh(quiz)

    db.add(DailyChallenge(
        quiz_id=quizzes[0].id,
        challenge_date=date.today().isoformat(),
    ))
    db.commit()
    return quizzes


def seed_users() -> tuple[User, User, User, User, User]:
    # Demo student: Aarav Sharma
    student = User(
        name="Aarav Sharma",
        email="aarav@careskill.demo",
        hashed_password=_hash("careskill123"),
        age=12,
        level=4,
        xp=2480,
        role=UserRole.student,
        parent_email="parent@example.com",
    )
    # NGO super-admin (platform owner)
    super_admin = User(
        name="Super Admin",
        email="superadmin@careskill.demo",
        hashed_password=_hash("superadmin123"),
        age=40,
        level=1,
        xp=0,
        role=UserRole.super_admin,
    )
    # NGO admin account
    admin = User(
        name="Admin User",
        email="admin@careskill.demo",
        hashed_password=_hash("admin123"),
        age=30,
        level=1,
        xp=0,
        role=UserRole.admin,
    )
    # Demo mentor
    mentor = User(
        name="Dr. Meera",
        email="meera@careskill.demo",
        hashed_password=_hash("mentor123"),
        age=35,
        level=1,
        xp=0,
        role=UserRole.mentor,
    )
    # Demo content creator
    content_creator = User(
        name="Content Creator",
        email="creator@careskill.demo",
        hashed_password=_hash("creator123"),
        age=28,
        level=1,
        xp=0,
        role=UserRole.content_creator,
    )
    db.add_all([student, super_admin, admin, mentor, content_creator])
    db.commit()
    for u in [student, super_admin, admin, mentor, content_creator]:
        db.refresh(u)
    return student, super_admin, admin, mentor, content_creator


def seed_demo_activity(
    student: User,
    mentor: User,
    courses: list[Course],
    badges: list[Badge],
) -> None:
    # Course progress
    progress_values = [0.68, 0.34, 0.82]
    for course, prog in zip(courses, progress_values):
        db.add(UserCourseProgress(
            user_id=student.id, course_id=course.id,
            progress=prog, completed=prog >= 1.0,
        ))

    # Counselling availability + booked session (upcoming, created by mentor)
    slot = CounsellingAvailability(
        mentor_id=mentor.id,
        mentor_name=mentor.name,
        topic="Confidence Building",
        starts_at=datetime.now() + timedelta(hours=2),
        ends_at=datetime.now() + timedelta(hours=3),
        booked_count=1,
        meeting_url="https://meet.jit.si/CareSkill-Demo-Session",
    )
    db.add(slot)
    db.flush()
    db.add(CounsellingSession(
        user_id=student.id,
        slot_id=slot.id,
        mentor_id=mentor.id,
        counsellor_name=mentor.name,
        topic="Confidence Building",
        scheduled_at=slot.starts_at,
        ends_at=slot.ends_at,
        meeting_url=slot.meeting_url,
        status="upcoming",
    ))

    # Badges
    for badge in badges[:4]:
        db.add(UserBadge(user_id=student.id, badge_id=badge.id))

    db.commit()


# ── run ────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("Seeding database...")
    cats    = seed_categories();  print(f"  {len(cats)} skill categories")
    crs     = seed_courses(cats); print(f"  {len(crs)} courses")
    lessons = seed_lessons(crs);   print(f"  {len(lessons)} demo lessons")
    bdgs    = seed_badges();      print(f"  {len(bdgs)} badges")
    student, super_admin, admin, mentor, content_creator = seed_users()
    print(f"  Users: {student.name} (student), {super_admin.name} (super_admin), "
          f"{admin.name} (admin), {mentor.name} (mentor), {content_creator.name} (content_creator)")
    qzs     = seed_quizzes(admin); print(f"  {len(qzs)} quizzes + daily challenge")
    seed_demo_activity(student, mentor, crs, bdgs)
    print("  Demo activity seeded")
    db.close()
    print("\nDone. Database ready.")
    print("\nDemo credentials:")
    print(f"  Super Admin      →  superadmin@careskill.demo  /  superadmin123")
    print(f"  Admin            →  admin@careskill.demo       /  admin123")
    print(f"  Mentor           →  meera@careskill.demo       /  mentor123")
    print(f"  Content Creator  →  creator@careskill.demo     /  creator123")
    print(f"  Student          →  aarav@careskill.demo       /  careskill123")
