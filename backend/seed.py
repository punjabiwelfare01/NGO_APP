"""
Seed the database with initial data.

Normal run — only inserts missing demo users / content, never touches existing data:
    cd backend
    python seed.py

Full reset (drops ALL tables, wipes every row, then re-seeds from scratch):
    cd backend
    python seed.py --reset
"""
import sys
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

_RESET = "--reset" in sys.argv


def _hash(plain: str) -> str:
    return _pwd.hash(plain)


# ── database setup ─────────────────────────────────────────────────────────────

if _RESET:
    print("--reset flag detected: dropping and recreating all tables...")
    Base.metadata.drop_all(bind=engine)

Base.metadata.create_all(bind=engine)

db = SessionLocal()


# ── seed helpers ───────────────────────────────────────────────────────────────

def _user_exists(email: str) -> bool:
    return db.query(User).filter(User.email == email).first() is not None


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
    free_course_examples = [
        ("NDA Exam Full Course", "NDA", "military_tech_rounded", "#DDEEFF", "24 hours", "Intermediate"),
        ("NDA Mathematics", "NDA", "calculate_rounded", "#E3F2FD", "12 hours", "Intermediate"),
        ("NDA English", "NDA", "language_rounded", "#FFF0D8", "8 hours", "Beginner"),
        ("NDA General Ability Test", "NDA", "quiz_rounded", "#E8E1FF", "10 hours", "Intermediate"),
        ("Defence Career Guidance", "Career Guidance", "shield_rounded", "#E8F5E9", "4 hours", "Beginner"),
        ("Spoken English for Students", "Spoken English", "record_voice_over_rounded", "#FFF0D8", "8 hours", "Beginner"),
        ("Basic Computer Skills", "Computer Basics", "computer_rounded", "#DDF5FF", "6 hours", "Beginner"),
        ("Career Guidance Program", "Career Guidance", "trending_up_rounded", "#E0F8E8", "5 hours", "Beginner"),
        ("Cyber Safety Awareness", "Awareness", "security_rounded", "#E0F8E8", "3 hours", "Beginner"),
        ("Women Safety Awareness", "Awareness", "health_and_safety_rounded", "#FCE4EC", "3 hours", "Beginner"),
        ("Anti-Drug Awareness", "Awareness", "campaign_rounded", "#FFF3E0", "2 hours", "Beginner"),
        ("Personality Development", "Career Guidance", "psychology_rounded", "#E8E1FF", "6 hours", "Beginner"),
        ("NGO Volunteer Training", "Volunteer Training", "volunteer_activism_rounded", "#E8F5E9", "5 hours", "Beginner"),
        ("Donation Ethics & Reporting", "Volunteer Training", "receipt_long_rounded", "#FFF8E1", "3 hours", "Beginner"),
    ]
    data = [
        Course(
            title=title,
            duration=duration,
            level=level,
            icon_name=icon,
            color_hex=color,
            course_type="skill",
            skill_category=category,
            is_published=True,
            course_description=f"Free {title.lower()} videos, notes, guidance, and practice by Punjabi Welfare Trust.",
            skill_tags=[
                "creator:NGO Team",
                "audience:Students",
                "language:Hindi / English",
                "notes",
                "quiz",
            ],
        )
        for title, category, icon, color, duration, level in free_course_examples
    ] + [
        Course(
            title="Coding Basics for Kids",
            duration="2h 30m",
            level="Beginner",
            icon_name="code_rounded",
            color_hex="#DDF1FF",
            category_id=cat["Digital Literacy"],
            course_type="skill",
            skill_category="Programming",
            recommended_class_min=6,
            recommended_class_max=12,
            course_description="Start coding with friendly videos, notes, and practice tasks.",
        ),
        Course(
            title="Speak with Confidence",
            duration="1h 45m",
            level="Beginner",
            icon_name="campaign_rounded",
            color_hex="#FFE7C8",
            category_id=cat["Communication Skill"],
            course_type="skill",
            skill_category="Communication Skills",
            recommended_class_min=6,
            recommended_class_max=12,
            course_description="Build public speaking habits for class, interviews, and daily life.",
        ),
        Course(
            title="Internet Safety Heroes",
            duration="3h",
            level="Intermediate",
            icon_name="security_rounded",
            color_hex="#E0F8E8",
            category_id=cat["Safety Awareness"],
            course_type="skill",
            skill_category="Cyber Security",
            recommended_class_min=6,
            recommended_class_max=12,
            course_description="Learn password safety, phishing awareness, and smart internet choices.",
        ),
        Course(
            title="Class 8 Science: Light and Reflection",
            duration="45m",
            level="Beginner",
            icon_name="psychology_rounded",
            color_hex="#F5E0FF",
            course_type="academic",
            class_level="8",
            subject="Science",
            course_description="Understand light, reflection, mirrors, and simple ray diagrams.",
        ),
        Course(
            title="Class 8 Mathematics: Linear Equations",
            duration="50m",
            level="Beginner",
            icon_name="grid_view_rounded",
            color_hex="#D0EDFF",
            course_type="academic",
            class_level="8",
            subject="Mathematics",
            course_description="Practice solving one-variable equations with step-by-step notes.",
        ),
        Course(
            title="Class 8 English: Writing Clear Paragraphs",
            duration="35m",
            level="Beginner",
            icon_name="language_rounded",
            color_hex="#FFE7C8",
            course_type="academic",
            class_level="8",
            subject="English",
            course_description="Learn topic sentences, supporting details, and revision habits.",
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
        Lesson(
            course_id=course_by_title["Class 8 Science: Light and Reflection"].id,
            title="Reflection from Plane Mirrors",
            description="Watch how light reflects and use notes to revise laws of reflection.",
            content_type="mixed",
            content_url="https://www.youtube.com/watch?v=vt-SG7Pn8UU",
            content_text=(
                "Light travels in straight lines. When it hits a smooth surface, it reflects. "
                "The angle of incidence is equal to the angle of reflection."
            ),
            class_level="8",
            subject="Science",
            order=0,
            duration_minutes=25,
            is_published=True,
        ),
        Lesson(
            course_id=course_by_title["Class 8 Mathematics: Linear Equations"].id,
            title="Solving Equations Step by Step",
            description="Use balance method examples to solve simple linear equations.",
            content_type="mixed",
            content_url="https://www.youtube.com/watch?v=NybHckSEQBI",
            content_text=(
                "A linear equation has a variable with power one. Keep both sides balanced "
                "when adding, subtracting, multiplying, or dividing."
            ),
            class_level="8",
            subject="Mathematics",
            order=0,
            duration_minutes=28,
            is_published=True,
        ),
        Lesson(
            course_id=course_by_title["Class 8 English: Writing Clear Paragraphs"].id,
            title="Topic Sentences and Supporting Details",
            description="Learn how to write one clear paragraph with examples.",
            content_type="mixed",
            content_url="https://www.youtube.com/watch?v=0IFDuhdB2Hk",
            content_text=(
                "A strong paragraph begins with one main idea. Supporting details explain, "
                "prove, or describe that idea. End with a closing sentence."
            ),
            class_level="8",
            subject="English",
            order=0,
            duration_minutes=20,
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


def seed_users() -> tuple:
    created = []
    skipped = []

    demo_users = [
        {
            "email": "aarav@careskill.demo",
            "fields": dict(
                name="Aarav Sharma",
                hashed_password=_hash("careskill123"),
                age=12, level=4, xp=2480,
                role=UserRole.student,
                parent_email="parent@example.com",
                class_name="Class 8",
            ),
        },
        {
            "email": "superadmin@careskill.demo",
            "fields": dict(
                name="Super Admin",
                hashed_password=_hash("superadmin123"),
                age=40, level=1, xp=0,
                role=UserRole.super_admin,
                access_status="approved",
            ),
        },
        {
            "email": "admin@careskill.demo",
            "fields": dict(
                name="Admin User",
                hashed_password=_hash("admin123"),
                age=30, level=1, xp=0,
                role=UserRole.admin,
                access_status="approved",
            ),
        },
        {
            "email": "eventmanager@careskill.demo",
            "fields": dict(
                name="Event Manager",
                hashed_password=_hash("eventmanager123"),
                age=32, level=1, xp=0,
                role=UserRole.event_manager,
                access_status="approved",
            ),
        },
        {
            "email": "meera@careskill.demo",
            "fields": dict(
                name="Dr. Meera",
                hashed_password=_hash("mentor123"),
                age=35, level=1, xp=0,
                role=UserRole.mentor,
                access_status="approved",
            ),
        },
        {
            "email": "creator@careskill.demo",
            "fields": dict(
                name="Content Creator",
                hashed_password=_hash("creator123"),
                age=28, level=1, xp=0,
                role=UserRole.content_creator,
                access_status="approved",
            ),
        },
        {
            "email": "school@careskill.demo",
            "fields": dict(
                name="School Partner",
                hashed_password=_hash("school123"),
                age=35, level=1, xp=0,
                role=UserRole.school_partner,
                school_name="Delhi Public School",
                location="New Delhi",
                access_status="approved",
            ),
        },
    ]

    user_objects: dict[str, User] = {}
    for entry in demo_users:
        email = entry["email"]
        existing = db.query(User).filter(User.email == email).first()
        if existing:
            skipped.append(email)
            user_objects[email] = existing
        else:
            u = User(email=email, **entry["fields"])
            db.add(u)
            db.flush()
            created.append(email)
            user_objects[email] = u

    db.commit()
    for u in user_objects.values():
        db.refresh(u)

    return (
        user_objects["aarav@careskill.demo"],
        user_objects["superadmin@careskill.demo"],
        user_objects["admin@careskill.demo"],
        user_objects["meera@careskill.demo"],
        user_objects["creator@careskill.demo"],
        user_objects["school@careskill.demo"],
        user_objects["eventmanager@careskill.demo"],
        created,
        skipped,
    )


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
    print("Seeding database..." + (" (full reset mode)" if _RESET else " (safe mode — existing data preserved)"))

    if _RESET:
        cats    = seed_categories();  print(f"  {len(cats)} skill categories")
        crs     = seed_courses(cats); print(f"  {len(crs)} courses")
        lessons = seed_lessons(crs);  print(f"  {len(lessons)} demo lessons")
        bdgs    = seed_badges();      print(f"  {len(bdgs)} badges")
    else:
        cats = db.query(SkillCategory).all()
        crs  = db.query(Course).all()
        bdgs = db.query(Badge).all()
        print(f"  Skipping courses/categories/badges (already exist, use --reset to recreate)")

    student, super_admin, admin, mentor, content_creator, school_partner, event_manager, created, skipped = seed_users()

    if created:
        print(f"  Created {len(created)} demo user(s): {', '.join(created)}")
    if skipped:
        print(f"  Skipped {len(skipped)} already-existing user(s): {', '.join(skipped)}")

    if _RESET and crs and bdgs:
        qzs = seed_quizzes(admin); print(f"  {len(qzs)} quizzes + daily challenge")
        seed_demo_activity(student, mentor, crs, bdgs)
        print("  Demo activity seeded")

    db.close()
    print("\nDone. Database ready.")
    print("\nDemo credentials:")
    print(f"  Super Admin      →  superadmin@careskill.demo    /  superadmin123")
    print(f"  Admin            →  admin@careskill.demo         /  admin123")
    print(f"  Event Manager    →  eventmanager@careskill.demo  /  eventmanager123")
    print(f"  Mentor           →  meera@careskill.demo         /  mentor123")
    print(f"  Content Creator  →  creator@careskill.demo       /  creator123")
    print(f"  School Partner   →  school@careskill.demo        /  school123")
    print(f"  Student          →  aarav@careskill.demo         /  careskill123")
