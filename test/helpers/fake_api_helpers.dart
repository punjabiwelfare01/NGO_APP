/// Shared JSON payloads and helper builders used across unit and widget tests.
library;

// ── Event JSON ─────────────────────────────────────────────────────────────────

Map<String, dynamic> fakeEventJson({
  int id = 1,
  String title = 'Test Event',
  String eventType = 'competition',
  String status = 'draft',
  String selectionMethod = 'lucky_draw',
  String themeColor = '#41A7F5',
  bool isDailyChallenge = false,
  int createdBy = 2,
}) =>
    {
      'id': id,
      'title': title,
      'subtitle': null,
      'description': null,
      'event_type': eventType,
      'quiz_id': null,
      'is_daily_challenge': isDailyChallenge,
      'status': status,
      'created_by': createdBy,
      'banner_url': null,
      'thumbnail_url': null,
      'theme_color': themeColor,
      'age_min': null,
      'age_max': null,
      'min_quiz_score': null,
      'required_challenges': 0,
      'max_participants': null,
      'selection_method': selectionMethod,
      'max_selections': null,
      'counselling_enabled': false,
      'certificate_enabled': false,
      'scholarship_enabled': false,
      'mentorship_enabled': false,
      'auto_publish': false,
      'auto_close': false,
      'auto_result_publish': false,
      'auto_notification': true,
      'push_notification': true,
      'in_app_notification': true,
      'email_notification': false,
      'registration_start': null,
      'registration_end': null,
      'event_start': null,
      'event_end': null,
      'start_date': null,
      'end_date': null,
      'result_date': null,
      'counselling_date': null,
      'created_at': '2026-01-01T00:00:00',
      'updated_at': '2026-01-01T00:00:00',
      'participant_count': 0,
    };

// ── Safety Question JSON ───────────────────────────────────────────────────────

Map<String, dynamic> fakeSafetyQuestionJson({
  int id = 1,
  String questionText = 'What do you do when you feel unsafe?',
  String optionA = 'Run away',
  String optionB = 'Tell a trusted adult',
  String optionC = 'Stay quiet',
}) =>
    {
      'id': id,
      'question_text': questionText,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'category': 'general',
    };

Map<String, dynamic> fakeAnswerResultJson({
  bool correct = true,
  String correctOption = 'b',
  String explanation = 'Always tell a trusted adult.',
  int xpEarned = 5,
}) =>
    {
      'correct': correct,
      'correct_option': correctOption,
      'explanation': explanation,
      'xp_earned': xpEarned,
    };
