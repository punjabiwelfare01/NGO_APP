class CreatorContentResponse {
  const CreatorContentResponse({required this.items});

  final List<CreatorContentItem> items;

  factory CreatorContentResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return CreatorContentResponse(
      items: rawItems
          .map(
            (item) => CreatorContentItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class CreatorContentItem {
  const CreatorContentItem({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.views,
    this.completionRate,
    this.createdAt,
    this.updatedAt,
    this.category,
    this.subtitle,
    this.meta = const {},
  });

  final int id;
  final String title;
  final String type;
  final String status;
  final int views;
  final int? completionRate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? category;
  final String? subtitle;
  final Map<String, dynamic> meta;

  factory CreatorContentItem.fromJson(Map<String, dynamic> json) {
    return CreatorContentItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Untitled',
      type: json['type'] as String? ?? 'course',
      status: json['status'] as String? ?? 'draft',
      views: json['views'] as int? ?? 0,
      completionRate: json['completion_rate'] as int?,
      createdAt: _parseDate(json['created_at'] as String?),
      updatedAt: _parseDate(json['updated_at'] as String?),
      category: json['category'] as String?,
      subtitle: json['subtitle'] as String?,
      meta: (json['meta'] as Map<String, dynamic>?) ?? const {},
    );
  }

  String get statusLabel => switch (status) {
    'published' => 'Published',
    'pending_review' => 'Pending Review',
    'rejected' => 'Rejected',
    'completed' => 'Completed',
    'archived' => 'Archived',
    _ => 'Draft',
  };

  String get typeLabel => switch (type) {
    'course' => 'Course',
    'lesson' =>
      (meta['lesson_type'] as String?)?.trim().isNotEmpty == true
          ? _titleCase(meta['lesson_type'] as String)
          : 'Lesson',
    'quiz' => 'Quiz',
    'event' => 'Event Content',
    'post' =>
      (meta['post_type'] as String?)?.trim().isNotEmpty == true
          ? _titleCase(meta['post_type'] as String)
          : 'Post',
    _ => _titleCase(type),
  };

  String get metricLabel {
    if (type == 'quiz') return '$views attempts';
    if (type == 'event') return '$views registrations';
    return '$views views';
  }

  String get lastEditedLabel {
    final date = updatedAt ?? createdAt;
    if (date == null) return 'No update date';
    final now = DateTime.now();
    final days = now.difference(date).inDays;
    if (days == 0) return 'Updated today';
    if (days == 1) return 'Updated yesterday';
    return 'Updated $days days ago';
  }
}

DateTime? _parseDate(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}

String _titleCase(String value) {
  final words = value.replaceAll('_', ' ').split(' ');
  return words
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
