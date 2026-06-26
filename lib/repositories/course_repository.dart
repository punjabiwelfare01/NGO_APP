import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/config.dart';
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

  static Future<List<Course>> getCourses({
    String? courseType,
    String? classLevel,
    String? subject,
    String? skillCategory,
  }) async {
    final path = _pathWithQuery('/courses', {
      'course_type': courseType,
      'class_level': classLevel,
      'subject': subject,
      'skill_category': skillCategory,
    });
    final list = await ApiClient.get(path) as List<dynamic>;
    return list.map((j) => Course.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<List<Course>> getRecommendedAcademic(String classLevel) async {
    final path = _pathWithQuery('/learn/recommended', {
      'class_level': classLevel,
    });
    final list = await ApiClient.get(path) as List<dynamic>;
    return list.map((j) => Course.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<List<Course>> getAcademicCourses({
    String? classLevel,
    String? subject,
  }) async {
    final path = _pathWithQuery('/learn/courses', {
      'class_level': classLevel,
      'subject': subject == 'All' ? null : subject,
    });
    final list = await ApiClient.get(path) as List<dynamic>;
    return list.map((j) => Course.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<List<Course>> getSkillCourses({String? category}) async {
    final path = _pathWithQuery('/learn/skills', {
      'category': category == 'All' ? null : category,
    });
    final list = await ApiClient.get(path) as List<dynamic>;
    return list.map((j) => Course.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<Course> createCourse({
    required String title,
    required String duration,
    required String level,
    required String iconName,
    required String colorHex,
    int? categoryId,
    String courseType = CourseType.skill,
    String? classLevel,
    String? subject,
    String? skillCategory,
    int? recommendedClassMin,
    int? recommendedClassMax,
    bool isPublished = true,
    String? courseDescription,
    List<String>? skillTags,
    List<String>? learnItems,
  }) async {
    final json =
        await ApiClient.post('/courses', {
              'title': title,
              'duration': duration,
              'level': level,
              'icon_name': iconName,
              'color_hex': colorHex,
              'category_id': categoryId,
              'course_type': courseType,
              'class_level': classLevel,
              'subject': subject,
              'skill_category': skillCategory,
              'recommended_class_min': recommendedClassMin,
              'recommended_class_max': recommendedClassMax,
              'is_published': isPublished,
              'course_description': courseDescription,
              'skill_tags': skillTags,
              'learn_items': learnItems,
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
    String courseType = CourseType.skill,
    String? classLevel,
    String? subject,
    String? skillCategory,
    int? recommendedClassMin,
    int? recommendedClassMax,
    bool isPublished = true,
    String? courseDescription,
    List<String>? skillTags,
    List<String>? learnItems,
  }) async {
    final json =
        await ApiClient.patch('/courses/$courseId', {
              'title': title,
              'duration': duration,
              'level': level,
              'icon_name': iconName,
              'color_hex': colorHex,
              'category_id': categoryId,
              'course_type': courseType,
              'class_level': classLevel,
              'subject': subject,
              'skill_category': skillCategory,
              'recommended_class_min': recommendedClassMin,
              'recommended_class_max': recommendedClassMax,
              'is_published': isPublished,
              'course_description': courseDescription,
              'skill_tags': skillTags,
              'learn_items': learnItems,
            })
            as Map<String, dynamic>;
    return Course.fromJson(json);
  }

  static Future<void> deleteCourse(int courseId) async {
    await ApiClient.delete('/courses/$courseId');
  }

  static Future<void> publishCourse(int courseId) async {
    await ApiClient.post('/courses/$courseId/publish', {});
  }

  static Future<void> unpublishCourse(int courseId) async {
    await ApiClient.post('/courses/$courseId/unpublish', {});
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
    String? classLevel,
    String? subject,
    String? chapter,
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
              'class_level': classLevel,
              'subject': subject,
              'chapter': chapter,
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

  /// Upload a video file securely.
  ///
  /// On non-web platforms (Android/iOS), pass [filePath] to stream the file
  /// directly from disk without loading it into memory — required for large
  /// videos. On web, pass [bytes] (FilePicker always provides bytes there).
  /// Returns the authenticated streaming URL (e.g. /video/stream/{uuid}.mp4).
  static Future<String> uploadVideo({
    List<int>? bytes,
    String? filePath,
    Stream<List<int>>? readStream,
    int fileSize = 0,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  }) async {
    final Map<String, dynamic> json;
    // Stream is preferred on every platform:
    //   Android/iOS — already-open fd, survives Android cache GC
    //   Web         — 1 MB chunks via FileReader, avoids flat Uint8List OOM
    // Path-only fallback is used on retry (stream already consumed).
    final bool hasStream = readStream != null && fileSize > 0;
    final bool hasPath = !kIsWeb && filePath != null;

    if (hasStream || hasPath) {
      json =
          await ApiClient.uploadFileWithProgress(
                '/upload',
                filePath: hasStream ? null : filePath,
                fileStream: hasStream ? readStream : null,
                fileStreamSize: hasStream ? fileSize : null,
                fileName: fileName,
                timeout: AppConfig.videoUploadTimeout,
                onProgress: onProgress,
              )
              as Map<String, dynamic>;
    } else {
      // Fallback: raw bytes (only triggered if caller explicitly passed bytes).
      assert(bytes != null, 'No stream, path, or bytes provided for upload');
      json =
          await ApiClient.postMultipart(
                '/upload',
                fields: const {},
                fileBytes: bytes!,
                fileName: fileName,
                timeout: AppConfig.videoUploadTimeout,
              )
              as Map<String, dynamic>;
    }
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

  static String _pathWithQuery(String path, Map<String, String?> query) {
    final entries = query.entries.where(
      (entry) => entry.value != null && entry.value!.trim().isNotEmpty,
    );
    if (entries.isEmpty) return path;
    final params = entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value!)}',
        )
        .join('&');
    return '$path?$params';
  }
}
