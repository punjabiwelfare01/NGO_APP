import '../models/course.dart';
import '../models/learning_resource.dart';
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

  static Future<SkillCategory> createCategory({
    required String title,
    required String iconName,
    required String colorHex,
  }) async {
    final json =
        await ApiClient.post('/categories', {
              'title': title,
              'icon_name': iconName,
              'color_hex': colorHex,
            })
            as Map<String, dynamic>;
    return SkillCategory.fromJson(json);
  }

  static Future<SkillCategory> updateCategory(
    int categoryId, {
    required String title,
    required String iconName,
    required String colorHex,
  }) async {
    final json =
        await ApiClient.patch('/categories/$categoryId', {
              'title': title,
              'icon_name': iconName,
              'color_hex': colorHex,
            })
            as Map<String, dynamic>;
    return SkillCategory.fromJson(json);
  }

  static Future<void> deleteCategory(int categoryId) async {
    await ApiClient.delete('/categories/$categoryId');
  }

  static Future<List<Course>> getCourses() async {
    final list = await ApiClient.get('/courses') as List<dynamic>;
    return list.map((j) => Course.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<Course> createCourse({
    required String title,
    required String duration,
    required String level,
    required String iconName,
    required String colorHex,
    int? categoryId,
  }) async {
    final json =
        await ApiClient.post('/courses', {
              'title': title,
              'duration': duration,
              'level': level,
              'icon_name': iconName,
              'color_hex': colorHex,
              'category_id': categoryId,
            })
            as Map<String, dynamic>;
    return Course.fromJson(json);
  }

  static Future<Course> updateCourse(
    int courseId, {
    required String title,
    required String duration,
    required String level,
    required String iconName,
    required String colorHex,
    int? categoryId,
  }) async {
    final json =
        await ApiClient.patch('/courses/$courseId', {
              'title': title,
              'duration': duration,
              'level': level,
              'icon_name': iconName,
              'color_hex': colorHex,
              'category_id': categoryId,
            })
            as Map<String, dynamic>;
    return Course.fromJson(json);
  }

  static Future<void> deleteCourse(int courseId) async {
    await ApiClient.delete('/courses/$courseId');
  }

  static Future<Course> updateCourseSalesInfo(
    int courseId, {
    List<String>? learnItems,
    List<String>? skillTags,
    String? courseDescription,
    int? offerPrice,
    int? originalPrice,
    String? offerLabel,
  }) async {
    final json =
        await ApiClient.patch('/courses/$courseId', {
              'learn_items': learnItems,
              'skill_tags': skillTags,
              'course_description': courseDescription,
              'offer_price': offerPrice,
              'original_price': originalPrice,
              'offer_label': offerLabel,
            })
            as Map<String, dynamic>;
    return Course.fromJson(json);
  }

  // Returns courses merged with the user's saved progress (0.0 if never started).
  static Future<List<Course>> getUserCourses(int userId) async {
    final list = await ApiClient.get('/users/$userId/courses') as List<dynamic>;
    if (list.isEmpty) return getCourses();
    return list
        .map((j) => Course.fromProgressJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<void> updateProgress(
    int userId,
    int courseId,
    double progress,
  ) async {
    await ApiClient.put('/users/$userId/courses/$courseId/progress', {
      'progress': progress,
    });
  }

  // ── Lesson methods ────────────────────────────────────────────────────────

  static Future<List<Lesson>> getLessons(int courseId) async {
    final list =
        await ApiClient.get('/courses/$courseId/lessons') as List<dynamic>;
    return list.map((j) => Lesson.fromJson(j as Map<String, dynamic>)).toList();
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
    final json =
        await ApiClient.post('/courses/$courseId/lessons', {
              'title': title,
              'description': description,
              'content_type': contentType,
              'content_url': contentUrl,
              'content_text': contentText,
              'order': order,
              'duration_minutes': durationMinutes,
              'is_published': isPublished,
            })
            as Map<String, dynamic>;
    return Lesson.fromJson(json);
  }

  static Future<Lesson> updateLesson(
    int courseId,
    int lessonId,
    Map<String, dynamic> data,
  ) async {
    final json =
        await ApiClient.patch('/courses/$courseId/lessons/$lessonId', data)
            as Map<String, dynamic>;
    return Lesson.fromJson(json);
  }

  static Future<void> deleteLesson(int courseId, int lessonId) async {
    await ApiClient.delete('/courses/$courseId/lessons/$lessonId');
  }

  static Future<void> markLessonComplete(int courseId, int lessonId) async {
    await ApiClient.post('/courses/$courseId/lessons/$lessonId/complete', {});
  }

  // ── Learning resource methods ─────────────────────────────────────────────

  static Future<String> uploadFile({
    required List<int> bytes,
    required String fileName,
  }) async {
    final json =
        await ApiClient.postMultipart(
              '/upload',
              fields: const {},
              fileBytes: bytes,
              fileName: fileName,
            )
            as Map<String, dynamic>;
    return json['url'] as String;
  }

  static Future<LearningResource> createResource(
    int courseId,
    int lessonId, {
    required String type,
    required String title,
    String? fileUrl,
    String? textContent,
  }) async {
    final json =
        await ApiClient.post('/courses/$courseId/lessons/$lessonId/resources', {
              'type': type,
              'title': title,
              'file_url': fileUrl,
              'text_content': textContent,
            })
            as Map<String, dynamic>;
    return LearningResource.fromJson(json);
  }

  static Future<List<LearningResource>> getResources(
    int courseId,
    int lessonId,
  ) async {
    final list =
        await ApiClient.get('/courses/$courseId/lessons/$lessonId/resources')
            as List<dynamic>;
    return list
        .map((j) => LearningResource.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<LearningResource> updateResource(
    int courseId,
    int lessonId,
    int resourceId, {
    String? type,
    String? title,
    String? fileUrl,
    String? textContent,
  }) async {
    final json =
        await ApiClient.patch(
              '/courses/$courseId/lessons/$lessonId/resources/$resourceId',
              {
                'type': type,
                'title': title,
                'file_url': fileUrl,
                'text_content': textContent,
              },
            )
            as Map<String, dynamic>;
    return LearningResource.fromJson(json);
  }

  static Future<void> deleteResource(
    int courseId,
    int lessonId,
    int resourceId,
  ) async {
    await ApiClient.delete(
      '/courses/$courseId/lessons/$lessonId/resources/$resourceId',
    );
  }
}
