import '../models/course.dart';
import '../models/lesson.dart';
import '../models/skill_category.dart';
import 'api_client.dart';

class CourseRepository {
  const CourseRepository._();

  static Future<List<SkillCategory>> getCategories() async {
    final list = await ApiClient.get('/categories') as List<dynamic>;
    return list
        .map((j) => SkillCategory.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Course>> getCourses() async {
    final list = await ApiClient.get('/courses') as List<dynamic>;
    return list
        .map((j) => Course.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // Returns courses merged with the user's saved progress (0.0 if never started).
  static Future<List<Course>> getUserCourses(int userId) async {
    final list =
        await ApiClient.get('/users/$userId/courses') as List<dynamic>;
    if (list.isEmpty) return getCourses();
    return list
        .map((j) => Course.fromProgressJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<void> updateProgress(
      int userId, int courseId, double progress) async {
    await ApiClient.put(
      '/users/$userId/courses/$courseId/progress',
      {'progress': progress},
    );
  }

  // ── Lesson methods ────────────────────────────────────────────────────────

  static Future<List<Lesson>> getLessons(int courseId) async {
    final list =
        await ApiClient.get('/courses/$courseId/lessons') as List<dynamic>;
    return list
        .map((j) => Lesson.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<Lesson> createLesson(
    int courseId, {
    required String title,
    String? description,
    String contentType = 'text',
    String? contentUrl,
    String? contentText,
    int order = 0,
    int? durationMinutes,
    bool isPublished = true,
  }) async {
    final json = await ApiClient.post('/courses/$courseId/lessons', {
      'title': title,
      'description': description,
      'content_type': contentType,
      'content_url': contentUrl,
      'content_text': contentText,
      'order': order,
      'duration_minutes': durationMinutes,
      'is_published': isPublished,
    }) as Map<String, dynamic>;
    return Lesson.fromJson(json);
  }

  static Future<Lesson> updateLesson(
    int courseId,
    int lessonId,
    Map<String, dynamic> data,
  ) async {
    final json = await ApiClient.patch(
      '/courses/$courseId/lessons/$lessonId',
      data,
    ) as Map<String, dynamic>;
    return Lesson.fromJson(json);
  }

  static Future<void> deleteLesson(int courseId, int lessonId) async {
    await ApiClient.delete('/courses/$courseId/lessons/$lessonId');
  }

  static Future<void> markLessonComplete(int courseId, int lessonId) async {
    await ApiClient.post(
      '/courses/$courseId/lessons/$lessonId/complete',
      {},
    );
  }
}
