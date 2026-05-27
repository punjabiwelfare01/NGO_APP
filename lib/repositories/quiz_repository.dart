import '../app_state.dart';
import '../models/quiz_models.dart';
import 'api_client.dart';

class QuizRepository {
  const QuizRepository._();

  static Future<List<QuizSummary>> getQuizzes({
    String? category,
    bool includeInactive = false,
  }) async {
    final params = <String, String>{
      if (category != null && category.isNotEmpty) 'category': category,
      if (includeInactive) 'include_inactive': 'true',
    };
    final query = params.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
    final path = query.isEmpty ? '/quizzes/' : '/quizzes/?$query';
    final list = await ApiClient.get(path) as List<dynamic>;
    return list
        .map((j) => QuizSummary.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<QuizModel> getQuiz(int quizId) async {
    final json =
        await ApiClient.get('/quizzes/$quizId') as Map<String, dynamic>;
    return QuizModel.fromJson(json);
  }

  static Future<DailyChallengeModel?> getDailyChallenge() async {
    try {
      final json =
          await ApiClient.get('/daily-challenge/today') as Map<String, dynamic>;
      return DailyChallengeModel.fromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  static Future<AttemptResult> submitAttempt(
    int quizId, {
    required List<int> answers,
    int? timeTakenSeconds,
  }) async {
    final json =
        await ApiClient.post('/quizzes/$quizId/attempt', {
              'answers': answers,
              'time_taken_seconds': timeTakenSeconds,
            })
            as Map<String, dynamic>;
    return AttemptResult.fromJson(json);
  }

  static Future<List<AttemptResult>> getMyHistory({int limit = 20}) async {
    final list =
        await ApiClient.get(
              '/quizzes/users/${AppState.userId}/history?limit=$limit',
            )
            as List<dynamic>;
    return list
        .map((j) => AttemptResult.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<QuizSummary> createQuiz({
    required String title,
    required String description,
    required String category,
    required String difficulty,
    required int xpReward,
    required int timeLimitSeconds,
  }) async {
    final json =
        await ApiClient.post('/quizzes/', {
              'title': title,
              'description': description,
              'category': category,
              'difficulty': difficulty,
              'xp_reward': xpReward,
              'time_limit_seconds': timeLimitSeconds,
            })
            as Map<String, dynamic>;
    return QuizSummary.fromJson(json);
  }

  static Future<QuestionModel> addQuestion({
    required int quizId,
    required String text,
    required List<String> options,
    required int correctIndex,
    required String explanation,
    required int points,
    required int orderIndex,
  }) async {
    final json =
        await ApiClient.post('/quizzes/$quizId/questions', {
              'text': text,
              'options': options,
              'correct_index': correctIndex,
              'explanation': explanation,
              'points': points,
              'order_index': orderIndex,
            })
            as Map<String, dynamic>;
    return QuestionModel.fromJson(json);
  }

  static Future<void> setDailyChallenge({
    required int quizId,
    required DateTime date,
  }) async {
    await ApiClient.post('/quizzes/daily', {
      'quiz_id': quizId,
      'challenge_date': date.toIso8601String().split('T').first,
    });
  }

  static Future<void> linkQuizToEvent({
    required int eventId,
    required int quizId,
  }) async {
    await ApiClient.post('/quiz-manager/link-event', {
      'event_id': eventId,
      'quiz_id': quizId,
    });
  }
}
