from sqlalchemy import inspect, text
from sqlalchemy.engine import Engine


def ensure_sqlite_schema(engine: Engine) -> None:
    if not engine.url.drivername.startswith("sqlite"):
        return

    inspector = inspect(engine)
    table_names = inspector.get_table_names()

    event_columns = (
        {column["name"] for column in inspector.get_columns("events")}
        if "events" in table_names
        else set()
    )
    event_additions = {
        "quiz_id": "INTEGER",
        "is_daily_challenge": "BOOLEAN NOT NULL DEFAULT 0",
        "start_date": "DATETIME",
        "end_date": "DATETIME",
    }

    with engine.begin() as connection:
        if "users" in table_names:
            user_columns = {
                column["name"]
                for column in inspector.get_columns("users")
            }
            user_additions = {
                "date_of_birth": "DATE",
                "reset_token": "VARCHAR",
                "reset_token_expires": "DATETIME",
                "photo_url": "VARCHAR",
            }
            for column, ddl_type in user_additions.items():
                if column not in user_columns:
                    connection.execute(
                        text(f"ALTER TABLE users ADD COLUMN {column} {ddl_type}")
                    )

            if {"access_status", "requested_role", "role"}.issubset(user_columns):
                # Normalize legacy pending values and repair accounts created by
                # the old bug as approved students despite requesting staff access.
                connection.execute(text("""
                    UPDATE users
                    SET access_status = 'pending'
                    WHERE access_status IN (
                        'pending_verification', 'pending_review', 'under_review'
                    )
                """))
                connection.execute(text("""
                    UPDATE users
                    SET access_status = 'pending'
                    WHERE access_status = 'approved'
                      AND role = 'student'
                      AND requested_role IS NOT NULL
                      AND requested_role NOT IN ('', 'student')
                """))

        if "student_reminders" not in table_names:
            connection.execute(text("""
                CREATE TABLE student_reminders (
                    id INTEGER NOT NULL,
                    user_id INTEGER NOT NULL,
                    title VARCHAR NOT NULL,
                    scheduled_at DATETIME NOT NULL,
                    is_done BOOLEAN NOT NULL DEFAULT 0,
                    is_active BOOLEAN NOT NULL DEFAULT 1,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (id),
                    FOREIGN KEY(user_id) REFERENCES users (id)
                )
            """))
            connection.execute(text("CREATE INDEX ix_student_reminders_id ON student_reminders (id)"))
            connection.execute(text("CREATE INDEX ix_student_reminders_user_id ON student_reminders (user_id)"))

        if "events" in table_names:
            for column, ddl_type in event_additions.items():
                if column not in event_columns:
                    connection.execute(
                        text(f"ALTER TABLE events ADD COLUMN {column} {ddl_type}")
                    )

        if "event_participants" in inspector.get_table_names():
            participant_columns = {
                column["name"]
                for column in inspector.get_columns("event_participants")
            }
            if "slot_id" not in participant_columns:
                connection.execute(
                    text("ALTER TABLE event_participants ADD COLUMN slot_id INTEGER")
                )

        if "event_slots" not in inspector.get_table_names():
            connection.execute(text("""
                CREATE TABLE event_slots (
                    id INTEGER NOT NULL,
                    event_id INTEGER NOT NULL,
                    title VARCHAR NOT NULL,
                    starts_at DATETIME NOT NULL,
                    ends_at DATETIME,
                    capacity INTEGER NOT NULL DEFAULT 1,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (id),
                    FOREIGN KEY(event_id) REFERENCES events (id)
                )
            """))
            connection.execute(
                text("CREATE INDEX ix_event_slots_id ON event_slots (id)")
            )

        if "lessons" not in inspector.get_table_names():
            connection.execute(text("""
                CREATE TABLE lessons (
                    id INTEGER NOT NULL,
                    course_id INTEGER NOT NULL,
                    title VARCHAR NOT NULL,
                    description VARCHAR,
                    content_type VARCHAR NOT NULL DEFAULT 'text',
                    content_url VARCHAR,
                    content_text TEXT,
                    "order" INTEGER NOT NULL DEFAULT 0,
                    duration_minutes INTEGER,
                    is_published BOOLEAN NOT NULL DEFAULT 1,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (id),
                    FOREIGN KEY(course_id) REFERENCES courses (id)
                )
            """))
            connection.execute(text("CREATE INDEX ix_lessons_id ON lessons (id)"))
            connection.execute(text("CREATE INDEX ix_lessons_course_id ON lessons (course_id)"))

        if "user_lesson_progress" not in inspector.get_table_names():
            connection.execute(text("""
                CREATE TABLE user_lesson_progress (
                    id INTEGER NOT NULL,
                    user_id INTEGER NOT NULL,
                    lesson_id INTEGER NOT NULL,
                    completed BOOLEAN NOT NULL DEFAULT 0,
                    completed_at DATETIME,
                    PRIMARY KEY (id),
                    FOREIGN KEY(user_id) REFERENCES users (id),
                    FOREIGN KEY(lesson_id) REFERENCES lessons (id)
                )
            """))
            connection.execute(text("CREATE INDEX ix_user_lesson_progress_id ON user_lesson_progress (id)"))

        if "safety_awareness_questions" not in inspector.get_table_names():
            connection.execute(text("""
                CREATE TABLE safety_awareness_questions (
                    id INTEGER NOT NULL,
                    question_text VARCHAR NOT NULL,
                    option_a VARCHAR NOT NULL,
                    option_b VARCHAR NOT NULL,
                    option_c VARCHAR NOT NULL,
                    correct_option VARCHAR NOT NULL,
                    explanation VARCHAR NOT NULL,
                    category VARCHAR NOT NULL DEFAULT 'general',
                    is_active BOOLEAN NOT NULL DEFAULT 1,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (id)
                )
            """))
            connection.execute(text("CREATE INDEX ix_safety_awareness_questions_id ON safety_awareness_questions (id)"))

        if "user_safety_answers" not in inspector.get_table_names():
            connection.execute(text("""
                CREATE TABLE user_safety_answers (
                    id INTEGER NOT NULL,
                    user_id INTEGER NOT NULL,
                    question_id INTEGER NOT NULL,
                    chosen_option VARCHAR NOT NULL,
                    is_correct BOOLEAN NOT NULL,
                    answered_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (id),
                    FOREIGN KEY(user_id) REFERENCES users (id),
                    FOREIGN KEY(question_id) REFERENCES safety_awareness_questions (id)
                )
            """))
            connection.execute(text("CREATE INDEX ix_user_safety_answers_id ON user_safety_answers (id)"))

        if "courses" in inspector.get_table_names():
            course_columns = {col["name"] for col in inspector.get_columns("courses")}
            course_additions = {
                "course_type": "VARCHAR NOT NULL DEFAULT 'skill'",
                "class_level": "VARCHAR",
                "subject": "VARCHAR",
                "skill_category": "VARCHAR",
                "recommended_class_min": "INTEGER",
                "recommended_class_max": "INTEGER",
                "is_published": "BOOLEAN NOT NULL DEFAULT 1",
                "learn_items": "TEXT",
                "skill_tags": "TEXT",
                "course_description": "TEXT",
                "offer_price": "INTEGER",
                "original_price": "INTEGER",
                "offer_label": "VARCHAR",
            }
            for column, ddl_type in course_additions.items():
                if column not in course_columns:
                    connection.execute(
                        text(f"ALTER TABLE courses ADD COLUMN {column} {ddl_type}")
                    )

        if "lessons" in inspector.get_table_names():
            lesson_columns = {col["name"] for col in inspector.get_columns("lessons")}
            lesson_additions = {
                "class_level": "VARCHAR",
                "subject": "VARCHAR",
                "chapter": "VARCHAR",
            }
            for column, ddl_type in lesson_additions.items():
                if column not in lesson_columns:
                    connection.execute(
                        text(f"ALTER TABLE lessons ADD COLUMN {column} {ddl_type}")
                    )

        if "counselling_sessions" in inspector.get_table_names():
            counselling_columns = {
                column["name"]
                for column in inspector.get_columns("counselling_sessions")
            }
            counselling_additions = {
                "slot_id": "INTEGER",
                "mentor_id": "INTEGER",
                "ends_at": "DATETIME",
                "meeting_url": "VARCHAR",
            }
            for column, ddl_type in counselling_additions.items():
                if column not in counselling_columns:
                    connection.execute(
                        text(f"ALTER TABLE counselling_sessions ADD COLUMN {column} {ddl_type}")
                    )

        if "counselling_availability" not in inspector.get_table_names():
            connection.execute(text("""
                CREATE TABLE counselling_availability (
                    id INTEGER NOT NULL,
                    mentor_id INTEGER NOT NULL,
                    mentor_name VARCHAR NOT NULL,
                    starts_at DATETIME NOT NULL,
                    ends_at DATETIME NOT NULL,
                    topic VARCHAR,
                    capacity INTEGER NOT NULL DEFAULT 1,
                    booked_count INTEGER NOT NULL DEFAULT 0,
                    meeting_url VARCHAR,
                    is_active BOOLEAN NOT NULL DEFAULT 1,
                    slot_duration_minutes INTEGER NOT NULL DEFAULT 45,
                    recurrence_type VARCHAR NOT NULL DEFAULT 'none',
                    recurrence_end_date DATETIME,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (id),
                    FOREIGN KEY(mentor_id) REFERENCES users (id)
                )
            """))
            connection.execute(text("CREATE INDEX ix_counselling_availability_id ON counselling_availability (id)"))
        else:
            # Add new columns to existing counselling_availability table
            avail_columns = {col["name"] for col in inspector.get_columns("counselling_availability")}
            avail_additions = {
                "slot_duration_minutes": "INTEGER NOT NULL DEFAULT 45",
                "recurrence_type": "VARCHAR NOT NULL DEFAULT 'none'",
                "recurrence_end_date": "DATETIME",
            }
            for column, ddl_type in avail_additions.items():
                if column not in avail_columns:
                    connection.execute(
                        text(f"ALTER TABLE counselling_availability ADD COLUMN {column} {ddl_type}")
                    )

        if "certificates" in inspector.get_table_names():
            certificate_columns = {col["name"] for col in inspector.get_columns("certificates")}
            certificate_additions = {
                "event_id": "INTEGER",
                "activity_id": "INTEGER",
                "assignment_id": "INTEGER",
                "submission_id": "INTEGER",
                "revoked_by": "INTEGER",
                "revoked_at": "DATETIME",
                "revoke_reason": "VARCHAR",
            }
            for column, ddl_type in certificate_additions.items():
                if column not in certificate_columns:
                    connection.execute(text(f"ALTER TABLE certificates ADD COLUMN {column} {ddl_type}"))

        # mentor_profiles table
        if "mentor_profiles" not in inspector.get_table_names():
            connection.execute(text("""
                CREATE TABLE mentor_profiles (
                    id INTEGER NOT NULL,
                    user_id INTEGER NOT NULL UNIQUE,
                    display_name VARCHAR NOT NULL,
                    bio TEXT,
                    expertise VARCHAR,
                    category VARCHAR,
                    profile_image_url VARCHAR,
                    is_active BOOLEAN NOT NULL DEFAULT 1,
                    rating REAL NOT NULL DEFAULT 0.0,
                    session_count INTEGER NOT NULL DEFAULT 0,
                    google_calendar_id VARCHAR,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (id),
                    FOREIGN KEY(user_id) REFERENCES users (id)
                )
            """))
            connection.execute(text("CREATE INDEX ix_mentor_profiles_id ON mentor_profiles (id)"))
            connection.execute(text("CREATE UNIQUE INDEX ix_mentor_profiles_user_id ON mentor_profiles (user_id)"))

        # counselling_notifications table
        if "counselling_notifications" not in inspector.get_table_names():
            connection.execute(text("""
                CREATE TABLE counselling_notifications (
                    id INTEGER NOT NULL,
                    user_id INTEGER NOT NULL,
                    type VARCHAR NOT NULL,
                    message TEXT NOT NULL,
                    booking_ref VARCHAR,
                    is_read BOOLEAN NOT NULL DEFAULT 0,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (id),
                    FOREIGN KEY(user_id) REFERENCES users (id)
                )
            """))
            connection.execute(text("CREATE INDEX ix_counselling_notifications_id ON counselling_notifications (id)"))

        # ── Volunteer Platform tables ─────────────────────────────────────────

        if "volunteer_activities" not in table_names:
            connection.execute(text("""
                CREATE TABLE volunteer_activities (
                    id INTEGER NOT NULL,
                    title VARCHAR NOT NULL,
                    category VARCHAR NOT NULL,
                    subdivision VARCHAR,
                    description VARCHAR,
                    expected_work VARCHAR,
                    proof_required VARCHAR,
                    reward_hours REAL NOT NULL DEFAULT 0.0,
                    is_active BOOLEAN NOT NULL DEFAULT 1,
                    created_by INTEGER,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (id),
                    FOREIGN KEY(created_by) REFERENCES users (id)
                )
            """))
            connection.execute(text("CREATE INDEX ix_volunteer_activities_id ON volunteer_activities (id)"))
        else:
            activity_columns = {col["name"] for col in inspector.get_columns("volunteer_activities")}
            activity_additions = {
                "event_id": "INTEGER",
                "location": "VARCHAR",
                "duration": "VARCHAR",
                "application_deadline": "DATETIME",
                "max_students": "INTEGER",
                "certificate_eligible": "BOOLEAN NOT NULL DEFAULT 1",
                "stipend_amount": "REAL",
            }
            for column, ddl_type in activity_additions.items():
                if column not in activity_columns:
                    connection.execute(text(f"ALTER TABLE volunteer_activities ADD COLUMN {column} {ddl_type}"))

        if "activity_assignments" not in table_names:
            connection.execute(text("""
                CREATE TABLE activity_assignments (
                    id INTEGER NOT NULL,
                    student_id INTEGER NOT NULL,
                    activity_id INTEGER NOT NULL,
                    assigned_by INTEGER,
                    location VARCHAR,
                    scheduled_date DATETIME,
                    status VARCHAR NOT NULL DEFAULT 'assigned',
                    notes VARCHAR,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (id),
                    FOREIGN KEY(student_id) REFERENCES users (id),
                    FOREIGN KEY(activity_id) REFERENCES volunteer_activities (id),
                    FOREIGN KEY(assigned_by) REFERENCES users (id)
                )
            """))
            connection.execute(text("CREATE INDEX ix_activity_assignments_id ON activity_assignments (id)"))

        if "work_submissions" not in table_names:
            connection.execute(text("""
                CREATE TABLE work_submissions (
                    id INTEGER NOT NULL,
                    student_id INTEGER NOT NULL,
                    assignment_id INTEGER,
                    activity_id INTEGER NOT NULL,
                    title VARCHAR NOT NULL,
                    description VARCHAR NOT NULL,
                    hours_worked REAL NOT NULL DEFAULT 0.0,
                    people_reached INTEGER NOT NULL DEFAULT 0,
                    donation_collected REAL NOT NULL DEFAULT 0.0,
                    transaction_id VARCHAR,
                    proof_files VARCHAR,
                    status VARCHAR NOT NULL DEFAULT 'submitted',
                    remarks VARCHAR,
                    reviewer_notes VARCHAR,
                    reviewed_by INTEGER,
                    reviewed_at DATETIME,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (id),
                    FOREIGN KEY(student_id) REFERENCES users (id),
                    FOREIGN KEY(activity_id) REFERENCES volunteer_activities (id),
                    FOREIGN KEY(assignment_id) REFERENCES activity_assignments (id),
                    FOREIGN KEY(reviewed_by) REFERENCES users (id)
                )
            """))
            connection.execute(text("CREATE INDEX ix_work_submissions_id ON work_submissions (id)"))

        if "daily_logs" not in table_names:
            connection.execute(text("""
                CREATE TABLE daily_logs (
                    id INTEGER NOT NULL,
                    student_id INTEGER NOT NULL,
                    submission_id INTEGER,
                    date DATE NOT NULL,
                    title VARCHAR,
                    content VARCHAR,
                    reflection VARCHAR,
                    media_files VARCHAR,
                    is_public BOOLEAN NOT NULL DEFAULT 0,
                    status VARCHAR NOT NULL DEFAULT 'draft',
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (id),
                    FOREIGN KEY(student_id) REFERENCES users (id),
                    FOREIGN KEY(submission_id) REFERENCES work_submissions (id)
                )
            """))
            connection.execute(text("CREATE INDEX ix_daily_logs_id ON daily_logs (id)"))

        if "impact_stories" not in table_names:
            connection.execute(text("""
                CREATE TABLE impact_stories (
                    id INTEGER NOT NULL,
                    student_id INTEGER NOT NULL,
                    title VARCHAR NOT NULL,
                    story VARCHAR,
                    category VARCHAR,
                    impact_numbers VARCHAR,
                    photo_url VARCHAR,
                    is_featured BOOLEAN NOT NULL DEFAULT 0,
                    is_public BOOLEAN NOT NULL DEFAULT 0,
                    created_by INTEGER,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (id),
                    FOREIGN KEY(student_id) REFERENCES users (id),
                    FOREIGN KEY(created_by) REFERENCES users (id)
                )
            """))
            connection.execute(text("CREATE INDEX ix_impact_stories_id ON impact_stories (id)"))

        if "donations" not in table_names:
            connection.execute(text("""
                CREATE TABLE donations (
                    id INTEGER NOT NULL,
                    donor_name VARCHAR,
                    donor_mobile VARCHAR,
                    donor_email VARCHAR,
                    donation_type VARCHAR NOT NULL,
                    category VARCHAR,
                    amount REAL NOT NULL DEFAULT 0.0,
                    items_desc VARCHAR,
                    purpose VARCHAR,
                    transaction_id VARCHAR,
                    proof_file VARCHAR,
                    referred_by INTEGER,
                    status VARCHAR NOT NULL DEFAULT 'pending',
                    receipt_number VARCHAR,
                    verified_by INTEGER,
                    verified_at DATETIME,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (id),
                    FOREIGN KEY(referred_by) REFERENCES users (id),
                    FOREIGN KEY(verified_by) REFERENCES users (id)
                )
            """))
            connection.execute(text("CREATE INDEX ix_donations_id ON donations (id)"))

        if "stipend_config" not in table_names:
            connection.execute(text("""
                CREATE TABLE stipend_config (
                    id INTEGER NOT NULL,
                    percentage REAL NOT NULL DEFAULT 20.0,
                    min_donation_threshold REAL NOT NULL DEFAULT 1000.0,
                    updated_by INTEGER,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (id),
                    FOREIGN KEY(updated_by) REFERENCES users (id)
                )
            """))
            connection.execute(text("CREATE INDEX ix_stipend_config_id ON stipend_config (id)"))
            # Seed default config
            connection.execute(text(
                "INSERT INTO stipend_config (percentage, min_donation_threshold) VALUES (20.0, 1000.0)"
            ))

        if "stipend_records" not in table_names:
            connection.execute(text("""
                CREATE TABLE stipend_records (
                    id INTEGER NOT NULL,
                    student_id INTEGER NOT NULL,
                    donation_id INTEGER NOT NULL,
                    percentage REAL NOT NULL,
                    stipend_amount REAL NOT NULL,
                    status VARCHAR NOT NULL DEFAULT 'pending',
                    approved_by INTEGER,
                    paid_at DATETIME,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (id),
                    FOREIGN KEY(student_id) REFERENCES users (id),
                    FOREIGN KEY(donation_id) REFERENCES donations (id),
                    FOREIGN KEY(approved_by) REFERENCES users (id)
                )
            """))
            connection.execute(text("CREATE INDEX ix_stipend_records_id ON stipend_records (id)"))

        if "ngo_payment_details" not in table_names:
            connection.execute(text("""
                CREATE TABLE ngo_payment_details (
                    id INTEGER NOT NULL,
                    upi_id VARCHAR,
                    qr_code_file VARCHAR,
                    bank_name VARCHAR,
                    account_number VARCHAR,
                    ifsc_code VARCHAR,
                    account_holder VARCHAR,
                    is_active BOOLEAN NOT NULL DEFAULT 1,
                    updated_by INTEGER,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (id),
                    FOREIGN KEY(updated_by) REFERENCES users (id)
                )
            """))
            connection.execute(text("CREATE INDEX ix_ngo_payment_details_id ON ngo_payment_details (id)"))
            # Seed placeholder NGO payment record
            connection.execute(text(
                "INSERT INTO ngo_payment_details (upi_id, bank_name, account_holder) "
                "VALUES ('punjabiwelfaretrust@upi', 'State Bank of India', 'Punjabi Welfare Trust')"
            ))

        if "certificates" not in table_names:
            connection.execute(text("""
                CREATE TABLE certificates (
                    id INTEGER NOT NULL,
                    certificate_id VARCHAR NOT NULL UNIQUE,
                    student_id INTEGER NOT NULL,
                    certificate_type VARCHAR NOT NULL,
                    activity_name VARCHAR NOT NULL,
                    duration VARCHAR,
                    signatory_name VARCHAR,
                    signatory_title VARCHAR,
                    issue_date DATE,
                    certificate_file VARCHAR,
                    status VARCHAR NOT NULL DEFAULT 'pending',
                    is_verified BOOLEAN NOT NULL DEFAULT 0,
                    qr_token VARCHAR,
                    issued_by INTEGER,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (id),
                    FOREIGN KEY(student_id) REFERENCES users (id),
                    FOREIGN KEY(issued_by) REFERENCES users (id)
                )
            """))
            connection.execute(text("CREATE INDEX ix_certificates_id ON certificates (id)"))
            connection.execute(text("CREATE UNIQUE INDEX ix_certificates_certificate_id ON certificates (certificate_id)"))
