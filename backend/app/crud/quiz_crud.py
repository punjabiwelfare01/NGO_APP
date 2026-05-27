from datetime import date

from sqlalchemy.orm import Session

from ..models.quiz import DailyChallenge, Question, Quiz, QuizAttempt
from ..schemas.quiz import QuestionCreate, QuestionUpdate, QuizCreate, QuizUpdate


# ── quiz management ────────────────────────────────────────────────────────────

def create_quiz(db: Session, payload: QuizCreate, creator_id: int) -> Quiz:
    quiz = Quiz(**payload.model_dump(), created_by=creator_id)
    db.add(quiz)
    db.commit()
    db.refresh(quiz)
    return quiz


def get_quiz(db: Session, quiz_id: int) -> Quiz | None:
    return db.query(Quiz).filter(Quiz.id == quiz_id).first()


def list_quizzes(
    db: Session,
    category: str | None = None,
    include_inactive: bool = False,
) -> list[Quiz]:
    q = db.query(Quiz).filter(Quiz.is_active.is_(True))
    if include_inactive:
        q = db.query(Quiz)
    if category:
        q = q.filter(Quiz.category == category)
    return q.order_by(Quiz.created_at.desc()).all()


def update_quiz(db: Session, quiz_id: int, payload: QuizUpdate) -> Quiz | None:
    quiz = get_quiz(db, quiz_id)
    if not quiz:
        return None
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(quiz, key, value)
    db.commit()
    db.refresh(quiz)
    return quiz


def delete_quiz(db: Session, quiz_id: int) -> bool:
    quiz = get_quiz(db, quiz_id)
    if not quiz:
        return False
    db.delete(quiz)
    db.commit()
    return True


# ── questions ──────────────────────────────────────────────────────────────────

def add_question(db: Session, quiz_id: int, payload: QuestionCreate) -> Question | None:
    if not get_quiz(db, quiz_id):
        return None
    q = Question(quiz_id=quiz_id, **payload.model_dump())
    db.add(q)
    db.commit()
    db.refresh(q)
    return q


def list_questions(db: Session, quiz_id: int) -> list[Question] | None:
    if not get_quiz(db, quiz_id):
        return None
    return (
        db.query(Question)
        .filter(Question.quiz_id == quiz_id)
        .order_by(Question.order_index.asc())
        .all()
    )


def update_question(
    db: Session,
    quiz_id: int,
    question_id: int,
    payload: QuestionUpdate,
) -> Question | None:
    q = db.query(Question).filter(
        Question.id == question_id, Question.quiz_id == quiz_id
    ).first()
    if not q:
        return None
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(q, key, value)
    db.commit()
    db.refresh(q)
    return q


def delete_question(db: Session, quiz_id: int, question_id: int) -> bool:
    q = db.query(Question).filter(
        Question.id == question_id, Question.quiz_id == quiz_id
    ).first()
    if not q:
        return False
    db.delete(q)
    db.commit()
    return True


# ── attempts (play + grade) ────────────────────────────────────────────────────

def submit_attempt(
    db: Session,
    user_id: int,
    quiz_id: int,
    answers: list[int],
    time_taken: int | None,
) -> tuple[QuizAttempt, list[Question]] | None:
    quiz = get_quiz(db, quiz_id)
    if not quiz:
        return None

    questions   = sorted(quiz.questions, key=lambda q: q.order_index)
    total_pts   = sum(q.points for q in questions) or 1
    earned_pts  = sum(
        q.points
        for i, q in enumerate(questions)
        if i < len(answers) and answers[i] == q.correct_index
    )
    correct_cnt = sum(
        1
        for i, q in enumerate(questions)
        if i < len(answers) and answers[i] == q.correct_index
    )
    score     = round(earned_pts / total_pts * 100, 1)
    xp_earned = max(10, int(quiz.xp_reward * score / 100))

    attempt = QuizAttempt(
        user_id=user_id,
        quiz_id=quiz_id,
        answers=answers,
        score=score,
        correct_count=correct_cnt,
        total_questions=len(questions),
        xp_earned=xp_earned,
        time_taken_seconds=time_taken,
    )
    db.add(attempt)
    db.commit()
    db.refresh(attempt)

    from ..models.event import Event, EventParticipant, QuizMapping

    mapped_event_ids = [
        row.event_id
        for row in db.query(QuizMapping).filter(QuizMapping.quiz_id == quiz_id).all()
    ]
    events = db.query(Event).filter(
        (Event.quiz_id == quiz_id) | (Event.id.in_(mapped_event_ids))
    ).all()
    for event in events:
        participant = (
            db.query(EventParticipant)
            .filter(
                EventParticipant.event_id == event.id,
                EventParticipant.user_id == user_id,
            )
            .first()
        )
        if not participant:
            participant = EventParticipant(event_id=event.id, user_id=user_id)
            db.add(participant)
        participant.score = score
        participant.status = "completed"
    if events:
        db.commit()

    from .user_crud import add_xp
    add_xp(db, user_id, xp_earned)

    return attempt, questions


def get_user_attempts(db: Session, user_id: int, limit: int = 20) -> list[QuizAttempt]:
    return (
        db.query(QuizAttempt)
        .filter(QuizAttempt.user_id == user_id)
        .order_by(QuizAttempt.completed_at.desc())
        .limit(limit)
        .all()
    )


def has_completed_quiz(db: Session, user_id: int, quiz_id: int) -> bool:
    return (
        db.query(QuizAttempt)
        .filter(QuizAttempt.user_id == user_id, QuizAttempt.quiz_id == quiz_id)
        .first()
    ) is not None


# ── leaderboard ────────────────────────────────────────────────────────────────

def get_quiz_leaderboard(db: Session, quiz_id: int, limit: int = 10) -> list[dict]:
    attempts = (
        db.query(QuizAttempt)
        .filter(QuizAttempt.quiz_id == quiz_id)
        .order_by(QuizAttempt.score.desc(), QuizAttempt.time_taken_seconds.asc())
        .limit(limit)
        .all()
    )
    return [
        {
            "rank":         i + 1,
            "user_id":      a.user_id,
            "user_name":    a.user.name,
            "score":        a.score,
            "xp_earned":    a.xp_earned,
            "completed_at": a.completed_at,
        }
        for i, a in enumerate(attempts)
    ]


# ── daily challenge ────────────────────────────────────────────────────────────

def get_today_challenge(db: Session) -> DailyChallenge | None:
    today = date.today().isoformat()
    return db.query(DailyChallenge).filter(DailyChallenge.challenge_date == today).first()


def set_daily_challenge(db: Session, quiz_id: int, challenge_date: str) -> DailyChallenge:
    existing = (
        db.query(DailyChallenge)
        .filter(DailyChallenge.challenge_date == challenge_date)
        .first()
    )
    if existing:
        existing.quiz_id = quiz_id
        db.commit()
        db.refresh(existing)
        return existing
    dc = DailyChallenge(quiz_id=quiz_id, challenge_date=challenge_date)
    db.add(dc)
    db.commit()
    db.refresh(dc)
    return dc
