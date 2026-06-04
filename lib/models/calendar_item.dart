enum CalendarItemType {
  classItem,
  event,
  quiz,
  workshop,
  counselling,
  reminder;

  static CalendarItemType fromString(String value) => switch (value) {
    'class' => CalendarItemType.classItem,
    'quiz' => CalendarItemType.quiz,
    'workshop' => CalendarItemType.workshop,
    'counselling' => CalendarItemType.counselling,
    'reminder' => CalendarItemType.reminder,
    _ => CalendarItemType.event,
  };
}

class CalendarItem {
  const CalendarItem({
    required this.id,
    required this.sourceId,
    required this.type,
    required this.title,
    required this.startsAt,
    this.subtitle,
    this.endsAt,
    this.status,
    this.actionUrl,
    this.colorHex,
    this.isDone = false,
  });

  final String id;
  final int sourceId;
  final CalendarItemType type;
  final String title;
  final String? subtitle;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? status;
  final String? actionUrl;
  final String? colorHex;
  final bool isDone;

  bool get hasActionUrl => actionUrl != null && actionUrl!.isNotEmpty;
  bool get isReminder => type == CalendarItemType.reminder;

  factory CalendarItem.fromJson(Map<String, dynamic> json) => CalendarItem(
    id: json['id'] as String,
    sourceId: json['source_id'] as int,
    type: CalendarItemType.fromString(json['item_type'] as String? ?? 'event'),
    title: json['title'] as String,
    subtitle: json['subtitle'] as String?,
    startsAt: DateTime.parse(json['starts_at'] as String),
    endsAt: json['ends_at'] == null
        ? null
        : DateTime.tryParse(json['ends_at'] as String),
    status: json['status'] as String?,
    actionUrl: json['action_url'] as String?,
    colorHex: json['color_hex'] as String?,
    isDone: json['is_done'] as bool? ?? false,
  );
}

class CalendarReminder {
  const CalendarReminder({
    required this.id,
    required this.userId,
    required this.title,
    required this.scheduledAt,
    required this.isDone,
    required this.isActive,
  });

  final int id;
  final int userId;
  final String title;
  final DateTime scheduledAt;
  final bool isDone;
  final bool isActive;

  factory CalendarReminder.fromJson(Map<String, dynamic> json) =>
      CalendarReminder(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        title: json['title'] as String,
        scheduledAt: DateTime.parse(json['scheduled_at'] as String),
        isDone: json['is_done'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
      );
}
