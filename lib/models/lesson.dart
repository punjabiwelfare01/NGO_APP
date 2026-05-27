class Lesson {
  const Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.contentType,
    required this.order,
    required this.isPublished,
    required this.completed,
    this.description,
    this.contentUrl,
    this.contentText,
    this.durationMinutes,
  });

  final int id;
  final int courseId;
  final String title;
  final String? description;
  final String contentType; // 'text' | 'video'
  final String? contentUrl;
  final String? contentText;
  final int order;
  final int? durationMinutes;
  final bool isPublished;
  final bool completed;

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'] as int,
        courseId: j['course_id'] as int,
        title: j['title'] as String,
        description: j['description'] as String?,
        contentType: (j['content_type'] as String?) ?? 'text',
        contentUrl: j['content_url'] as String?,
        contentText: j['content_text'] as String?,
        order: (j['order'] as int?) ?? 0,
        durationMinutes: j['duration_minutes'] as int?,
        isPublished: (j['is_published'] as bool?) ?? true,
        completed: (j['completed'] as bool?) ?? false,
      );

  Lesson copyWith({bool? completed}) => Lesson(
        id: id,
        courseId: courseId,
        title: title,
        description: description,
        contentType: contentType,
        contentUrl: contentUrl,
        contentText: contentText,
        order: order,
        durationMinutes: durationMinutes,
        isPublished: isPublished,
        completed: completed ?? this.completed,
      );

  String get durationLabel {
    if (durationMinutes == null) return '';
    if (durationMinutes! < 60) return '${durationMinutes}m';
    final h = durationMinutes! ~/ 60;
    final m = durationMinutes! % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
