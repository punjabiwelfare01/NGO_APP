class SafetyQuestion {
  const SafetyQuestion({
    required this.id,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.explanation,
    required this.category,
  });

  final int id;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String explanation;
  final String category;

  String optionLabel(String key) => switch (key) {
    'a' => optionA,
    'b' => optionB,
    _ => optionC,
  };

  factory SafetyQuestion.fromJson(Map<String, dynamic> j) => SafetyQuestion(
    id: j['id'] as int,
    questionText: j['question_text'] as String,
    optionA: j['option_a'] as String,
    optionB: j['option_b'] as String,
    optionC: j['option_c'] as String,
    explanation: j['explanation'] as String,
    category: j['category'] as String? ?? 'general',
  );
}

// Admin-only full model (includes correct_option + is_active)
class SafetyQuestionAdmin extends SafetyQuestion {
  const SafetyQuestionAdmin({
    required super.id,
    required super.questionText,
    required super.optionA,
    required super.optionB,
    required super.optionC,
    required super.explanation,
    required super.category,
    required this.correctOption,
    required this.isActive,
  });

  final String correctOption;
  final bool isActive;

  factory SafetyQuestionAdmin.fromJson(Map<String, dynamic> j) =>
      SafetyQuestionAdmin(
        id: j['id'] as int,
        questionText: j['question_text'] as String,
        optionA: j['option_a'] as String,
        optionB: j['option_b'] as String,
        optionC: j['option_c'] as String,
        explanation: j['explanation'] as String,
        category: j['category'] as String? ?? 'general',
        correctOption: j['correct_option'] as String,
        isActive: j['is_active'] as bool? ?? true,
      );
}

class AnswerResult {
  const AnswerResult({
    required this.correct,
    required this.correctOption,
    required this.explanation,
    required this.xpEarned,
  });

  final bool correct;
  final String correctOption;
  final String explanation;
  final int xpEarned;

  factory AnswerResult.fromJson(Map<String, dynamic> j) => AnswerResult(
    correct: j['correct'] as bool,
    correctOption: j['correct_option'] as String,
    explanation: j['explanation'] as String,
    xpEarned: j['xp_earned'] as int? ?? 0,
  );
}
