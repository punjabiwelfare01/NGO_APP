class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.actionUrl,
    this.createdAt,
  });
  final int id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final String? actionUrl;
  final DateTime? createdAt;
  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as int,
        type: json['type'] as String? ?? 'general',
        title: json['title'] as String,
        message: json['message'] as String,
        isRead: json['is_read'] as bool? ?? false,
        actionUrl: json['action_url'] as String?,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.tryParse(json['created_at'] as String),
      );
}

class ProfileReport {
  const ProfileReport({
    required this.id,
    required this.type,
    required this.title,
    required this.status,
    required this.summary,
    required this.details,
    this.createdAt,
  });
  final String id;
  final String type;
  final String title;
  final String status;
  final String summary;
  final Map<String, dynamic> details;
  final DateTime? createdAt;
  factory ProfileReport.fromJson(Map<String, dynamic> json) => ProfileReport(
    id: json['id'] as String,
    type: json['type'] as String,
    title: json['title'] as String,
    status: json['status'] as String,
    summary: json['summary'] as String,
    details: (json['details'] as Map<String, dynamic>?) ?? const {},
    createdAt: json['created_at'] == null
        ? null
        : DateTime.tryParse(json['created_at'] as String),
  );
}

class UserSettings {
  const UserSettings({
    required this.language,
    required this.profileVisibility,
    required this.showImpactName,
    required this.inAppEnabled,
    required this.emailEnabled,
    required this.eventReminders,
    required this.counsellingReminders,
    required this.assignmentUpdates,
    required this.impactUpdates,
  });
  final String language;
  final String profileVisibility;
  final bool showImpactName;
  final bool inAppEnabled;
  final bool emailEnabled;
  final bool eventReminders;
  final bool counsellingReminders;
  final bool assignmentUpdates;
  final bool impactUpdates;
  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
    language: json['language'] as String? ?? 'en',
    profileVisibility: json['profile_visibility'] as String? ?? 'ngo_members',
    showImpactName: json['show_impact_name'] as bool? ?? true,
    inAppEnabled: json['in_app_enabled'] as bool? ?? true,
    emailEnabled: json['email_enabled'] as bool? ?? true,
    eventReminders: json['event_reminders'] as bool? ?? true,
    counsellingReminders: json['counselling_reminders'] as bool? ?? true,
    assignmentUpdates: json['assignment_updates'] as bool? ?? true,
    impactUpdates: json['impact_updates'] as bool? ?? true,
  );
}
