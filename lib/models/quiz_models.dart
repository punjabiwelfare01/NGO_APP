class QuestionModel {
  const QuestionModel({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.points,
    required this.orderIndex,
  });

  final int id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
  final int points;
  final int orderIndex;

  factory QuestionModel.fromJson(Map<String, dynamic> j) => QuestionModel(
    id: j['id'] as int,
    text: j['text'] as String,
    options: (j['options'] as List).cast<String>(),
    correctIndex: j['correct_index'] as int,
    explanation: j['explanation'] as String?,
    points: j['points'] as int,
    orderIndex: j['order_index'] as int,
  );
}

class QuizModel {
  const QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.xpReward,
    required this.timeLimitSeconds,
    required this.questions,
  });

  final int id;
  final String title;
  final String? description;
  final String? category;
  final String difficulty;
  final int xpReward;
  final int timeLimitSeconds;
  final List<QuestionModel> questions;

  factory QuizModel.fromJson(Map<String, dynamic> j) => QuizModel(
    id: j['id'] as int,
    title: j['title'] as String,
    description: j['description'] as String?,
    category: j['category'] as String?,
    difficulty: j['difficulty'] as String,
    xpReward: j['xp_reward'] as int,
    timeLimitSeconds: j['time_limit_seconds'] as int,
    questions: (j['questions'] as List? ?? [])
        .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
        .toList(),
  );
}

class QuizSummary {
  const QuizSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.xpReward,
    required this.timeLimitSeconds,
    required this.questionCount,
    required this.isActive,
  });

  final int id;
  final String title;
  final String? description;
  final String? category;
  final String difficulty;
  final int xpReward;
  final int timeLimitSeconds;
  final int questionCount;
  final bool isActive;

  QuizSummary copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    String? difficulty,
    int? xpReward,
    int? timeLimitSeconds,
    int? questionCount,
    bool? isActive,
  }) => QuizSummary(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    category: category ?? this.category,
    difficulty: difficulty ?? this.difficulty,
    xpReward: xpReward ?? this.xpReward,
    timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
    questionCount: questionCount ?? this.questionCount,
    isActive: isActive ?? this.isActive,
  );

  factory QuizSummary.fromJson(Map<String, dynamic> j) => QuizSummary(
    id: j['id'] as int,
    title: j['title'] as String,
    description: j['description'] as String?,
    category: j['category'] as String?,
    difficulty: j['difficulty'] as String,
    xpReward: j['xp_reward'] as int,
    timeLimitSeconds: j['time_limit_seconds'] as int,
    questionCount: j['question_count'] as int? ?? 0,
    isActive: j['is_active'] as bool? ?? true,
  );
}

class DailyChallengeModel {
  const DailyChallengeModel({
    required this.challengeDate,
    this.quiz,
    required this.completed,
    this.id,
    this.title,
    this.difficulty,
    this.xpReward,
    this.participantsCount,
    this.timeRemainingSeconds,
    this.quizId,
  });

  final String challengeDate;
  final QuizModel? quiz;
  final bool completed;
  final int? id;
  final String? title;
  final String? difficulty;
  final int? xpReward;
  final int? participantsCount;
  final int? timeRemainingSeconds;
  final int? quizId;

  factory DailyChallengeModel.fromJson(Map<String, dynamic> j) {
    final hasQuiz = j.containsKey('quiz') && j['quiz'] != null;
    final parsedQuiz = hasQuiz ? QuizModel.fromJson(j['quiz'] as Map<String, dynamic>) : null;
    
    return DailyChallengeModel(
      challengeDate: j['challenge_date'] as String? ?? DateTime.now().toIso8601String().split('T').first,
      quiz: parsedQuiz,
      completed: j['completed'] as bool? ?? false,
      id: j['id'] as int?,
      title: j['title'] as String? ?? parsedQuiz?.title,
      difficulty: j['difficulty'] as String? ?? parsedQuiz?.difficulty,
      xpReward: j['xp_reward'] as int? ?? parsedQuiz?.xpReward,
      participantsCount: j['participants_count'] as int? ?? 0,
      timeRemainingSeconds: j['time_remaining_seconds'] as int?,
      quizId: j['quiz_id'] as int? ?? parsedQuiz?.id,
    );
  }
}

class AnswerResult {
  const AnswerResult({
    required this.questionId,
    required this.questionText,
    required this.selectedIndex,
    required this.correctIndex,
    required this.isCorrect,
    required this.explanation,
  });

  final int questionId;
  final String questionText;
  final int selectedIndex;
  final int correctIndex;
  final bool isCorrect;
  final String? explanation;

  factory AnswerResult.fromJson(Map<String, dynamic> j) => AnswerResult(
    questionId: j['question_id'] as int,
    questionText: j['question_text'] as String,
    selectedIndex: j['selected_index'] as int,
    correctIndex: j['correct_index'] as int,
    isCorrect: j['is_correct'] as bool,
    explanation: j['explanation'] as String?,
  );
}

class AttemptResult {
  const AttemptResult({
    required this.id,
    required this.quizId,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.xpEarned,
    required this.timeTakenSeconds,
    required this.answerResults,
  });

  final int id;
  final int quizId;
  final double score;
  final int correctCount;
  final int totalQuestions;
  final int xpEarned;
  final int? timeTakenSeconds;
  final List<AnswerResult> answerResults;

  factory AttemptResult.fromJson(Map<String, dynamic> j) => AttemptResult(
    id: j['id'] as int,
    quizId: j['quiz_id'] as int,
    score: (j['score'] as num).toDouble(),
    correctCount: j['correct_count'] as int,
    totalQuestions: j['total_questions'] as int,
    xpEarned: j['xp_earned'] as int,
    timeTakenSeconds: j['time_taken_seconds'] as int?,
    answerResults: (j['answer_results'] as List)
        .map((a) => AnswerResult.fromJson(a as Map<String, dynamic>))
        .toList(),
  );
}
