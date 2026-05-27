import '../models/safety_awareness.dart';
import 'api_client.dart';

class SafetyAwarenessRepository {
  const SafetyAwarenessRepository._();

  // ── Student ────────────────────────────────────────────────────────────────

  static Future<SafetyQuestion?> getDailyQuestion() async {
    final json = await ApiClient.get('/safety-awareness/daily');
    if (json == null) return null;
    return SafetyQuestion.fromJson(json as Map<String, dynamic>);
  }

  static Future<AnswerResult> submitAnswer(int questionId, String choice) async {
    final json = await ApiClient.post(
      '/safety-awareness/$questionId/answer',
      {'chosen_option': choice},
    );
    return AnswerResult.fromJson(json as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>> getMyStats() async {
    final json = await ApiClient.get('/safety-awareness/my-stats');
    return json as Map<String, dynamic>;
  }

  // ── Admin ──────────────────────────────────────────────────────────────────

  static Future<List<SafetyQuestionAdmin>> getAllQuestions() async {
    final json = await ApiClient.get('/safety-awareness/');
    return (json as List)
        .map((e) => SafetyQuestionAdmin.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<SafetyQuestionAdmin> createQuestion({
    required String questionText,
    required String optionA,
    required String optionB,
    required String optionC,
    required String correctOption,
    required String explanation,
    required String category,
  }) async {
    final json = await ApiClient.post('/safety-awareness/', {
      'question_text': questionText,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'correct_option': correctOption,
      'explanation': explanation,
      'category': category,
    });
    return SafetyQuestionAdmin.fromJson(json as Map<String, dynamic>);
  }

  static Future<SafetyQuestionAdmin> updateQuestion(
    int id,
    Map<String, dynamic> fields,
  ) async {
    final json = await ApiClient.patch('/safety-awareness/$id', fields);
    return SafetyQuestionAdmin.fromJson(json as Map<String, dynamic>);
  }

  static Future<void> deleteQuestion(int id) async {
    await ApiClient.delete('/safety-awareness/$id');
  }
}
