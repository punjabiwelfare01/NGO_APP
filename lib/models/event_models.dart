import 'package:flutter/material.dart';

enum EventType {
  quiz,
  talentHunt,
  dailyChallenge,
  counsellingDrive,
  scholarship,
  awarenessCampaign,
  workshop,
  competition,
  cyberSecurity;

  static EventType fromString(String value) => switch (value) {
    'quiz' => EventType.quiz,
    'talent_hunt' => EventType.talentHunt,
    'daily_challenge' => EventType.dailyChallenge,
    'counselling_drive' => EventType.counsellingDrive,
    'scholarship' => EventType.scholarship,
    'awareness_campaign' => EventType.awarenessCampaign,
    'workshop' => EventType.workshop,
    'competition' => EventType.competition,
    'cyber_security' => EventType.cyberSecurity,
    _ => EventType.quiz,
  };

  String get displayName => switch (this) {
    EventType.quiz => 'Quiz',
    EventType.talentHunt => 'Talent Hunt',
    EventType.dailyChallenge => 'Daily Challenge',
    EventType.counsellingDrive => 'Counselling Drive',
    EventType.scholarship => 'Scholarship',
    EventType.awarenessCampaign => 'Awareness Campaign',
    EventType.workshop => 'Workshop',
    EventType.competition => 'Competition',
    EventType.cyberSecurity => 'Cyber Security',
  };

  String get apiValue => switch (this) {
    EventType.quiz => 'quiz',
    EventType.talentHunt => 'talent_hunt',
    EventType.dailyChallenge => 'daily_challenge',
    EventType.counsellingDrive => 'counselling_drive',
    EventType.scholarship => 'scholarship',
    EventType.awarenessCampaign => 'awareness_campaign',
    EventType.workshop => 'workshop',
    EventType.competition => 'competition',
    EventType.cyberSecurity => 'cyber_security',
  };
}

enum EventStatus {
  draft,
  pendingReview,
  published,
  registrationOpen,
  live,
  evaluation,
  selection,
  completed,
  archived;

  static EventStatus fromString(String value) => switch (value) {
    'draft' => EventStatus.draft,
    'pending_review' => EventStatus.pendingReview,
    'published' => EventStatus.published,
    'registration_open' => EventStatus.registrationOpen,
    'live' => EventStatus.live,
    'evaluation' => EventStatus.evaluation,
    'selection' => EventStatus.selection,
    'completed' => EventStatus.completed,
    'archived' => EventStatus.archived,
    _ => EventStatus.draft,
  };

  String get displayName => switch (this) {
    EventStatus.draft => 'Draft',
    EventStatus.pendingReview => 'Pending Review',
    EventStatus.published => 'Published',
    EventStatus.registrationOpen => 'Registration Open',
    EventStatus.live => 'Live',
    EventStatus.evaluation => 'Evaluation',
    EventStatus.selection => 'Selection',
    EventStatus.completed => 'Completed',
    EventStatus.archived => 'Archived',
  };

  String get apiValue => switch (this) {
    EventStatus.draft => 'draft',
    EventStatus.pendingReview => 'pending_review',
    EventStatus.published => 'published',
    EventStatus.registrationOpen => 'registration_open',
    EventStatus.live => 'live',
    EventStatus.evaluation => 'evaluation',
    EventStatus.selection => 'selection',
    EventStatus.completed => 'completed',
    EventStatus.archived => 'archived',
  };

  bool get canRegister =>
      this == EventStatus.published || this == EventStatus.registrationOpen;
}

enum SelectionMethod {
  luckyDraw,
  manual,
  hybrid,
  scoreBased;

  static SelectionMethod fromString(String value) => switch (value) {
    'lucky_draw' => SelectionMethod.luckyDraw,
    'manual' => SelectionMethod.manual,
    'hybrid' => SelectionMethod.hybrid,
    'score_based' => SelectionMethod.scoreBased,
    _ => SelectionMethod.luckyDraw,
  };

  String get displayName => switch (this) {
    SelectionMethod.luckyDraw => 'Lucky Draw',
    SelectionMethod.manual => 'Manual',
    SelectionMethod.hybrid => 'Hybrid',
    SelectionMethod.scoreBased => 'Score Based',
  };

  String get apiValue => switch (this) {
    SelectionMethod.luckyDraw => 'lucky_draw',
    SelectionMethod.manual => 'manual',
    SelectionMethod.hybrid => 'hybrid',
    SelectionMethod.scoreBased => 'score_based',
  };
}

class EventModel {
  const EventModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    required this.eventType,
    this.quizId,
    required this.isDailyChallenge,
    required this.status,
    required this.createdBy,
    this.bannerUrl,
    this.thumbnailUrl,
    required this.themeColor,
    this.ageMin,
    this.ageMax,
    this.minQuizScore,
    required this.requiredChallenges,
    this.maxParticipants,
    required this.selectionMethod,
    this.maxSelections,
    required this.counsellingEnabled,
    required this.certificateEnabled,
    required this.scholarshipEnabled,
    required this.mentorshipEnabled,
    required this.autoPublish,
    required this.autoClose,
    required this.autoResultPublish,
    required this.autoNotification,
    required this.pushNotification,
    required this.inAppNotification,
    required this.emailNotification,
    this.registrationStart,
    this.registrationEnd,
    this.eventStart,
    this.eventEnd,
    this.startDate,
    this.endDate,
    this.resultDate,
    this.counsellingDate,
    this.createdAt,
    this.updatedAt,
    this.participantCount = 0,
  });

  final int id;
  final String title;
  final String? subtitle;
  final String? description;
  final EventType eventType;
  final int? quizId;
  final bool isDailyChallenge;
  final EventStatus status;
  final int createdBy;
  final String? bannerUrl;
  final String? thumbnailUrl;
  final String themeColor;
  final int? ageMin;
  final int? ageMax;
  final double? minQuizScore;
  final int requiredChallenges;
  final int? maxParticipants;
  final SelectionMethod selectionMethod;
  final int? maxSelections;
  final bool counsellingEnabled;
  final bool certificateEnabled;
  final bool scholarshipEnabled;
  final bool mentorshipEnabled;
  final bool autoPublish;
  final bool autoClose;
  final bool autoResultPublish;
  final bool autoNotification;
  final bool pushNotification;
  final bool inAppNotification;
  final bool emailNotification;
  final DateTime? registrationStart;
  final DateTime? registrationEnd;
  final DateTime? eventStart;
  final DateTime? eventEnd;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? resultDate;
  final DateTime? counsellingDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int participantCount;

  Color get themeColorValue =>
      Color(int.parse(themeColor.replaceFirst('#', '0xFF')));

  bool get canRegister =>
      status == EventStatus.published || status == EventStatus.registrationOpen;

  factory EventModel.fromJson(Map<String, dynamic> j) => EventModel(
    id: j['id'] as int,
    title: j['title'] as String,
    subtitle: j['subtitle'] as String?,
    description: j['description'] as String?,
    eventType: EventType.fromString(j['event_type'] as String? ?? 'quiz'),
    quizId: j['quiz_id'] as int?,
    isDailyChallenge: j['is_daily_challenge'] as bool? ?? false,
    status: EventStatus.fromString(j['status'] as String? ?? 'draft'),
    createdBy: j['created_by'] as int,
    bannerUrl: j['banner_url'] as String?,
    thumbnailUrl: j['thumbnail_url'] as String?,
    themeColor: j['theme_color'] as String? ?? '#41A7F5',
    ageMin: j['age_min'] as int?,
    ageMax: j['age_max'] as int?,
    minQuizScore: (j['min_quiz_score'] as num?)?.toDouble(),
    requiredChallenges: j['required_challenges'] as int? ?? 0,
    maxParticipants: j['max_participants'] as int?,
    selectionMethod: SelectionMethod.fromString(
      j['selection_method'] as String? ?? 'lucky_draw',
    ),
    maxSelections: j['max_selections'] as int?,
    counsellingEnabled: j['counselling_enabled'] as bool? ?? false,
    certificateEnabled: j['certificate_enabled'] as bool? ?? false,
    scholarshipEnabled: j['scholarship_enabled'] as bool? ?? false,
    mentorshipEnabled: j['mentorship_enabled'] as bool? ?? false,
    autoPublish: j['auto_publish'] as bool? ?? false,
    autoClose: j['auto_close'] as bool? ?? false,
    autoResultPublish: j['auto_result_publish'] as bool? ?? false,
    autoNotification: j['auto_notification'] as bool? ?? true,
    pushNotification: j['push_notification'] as bool? ?? true,
    inAppNotification: j['in_app_notification'] as bool? ?? true,
    emailNotification: j['email_notification'] as bool? ?? false,
    registrationStart: j['registration_start'] != null
        ? DateTime.tryParse(j['registration_start'] as String)
        : null,
    registrationEnd: j['registration_end'] != null
        ? DateTime.tryParse(j['registration_end'] as String)
        : null,
    eventStart: j['event_start'] != null
        ? DateTime.tryParse(j['event_start'] as String)
        : null,
    eventEnd: j['event_end'] != null
        ? DateTime.tryParse(j['event_end'] as String)
        : null,
    startDate: j['start_date'] != null
        ? DateTime.tryParse(j['start_date'] as String)
        : null,
    endDate: j['end_date'] != null
        ? DateTime.tryParse(j['end_date'] as String)
        : null,
    resultDate: j['result_date'] != null
        ? DateTime.tryParse(j['result_date'] as String)
        : null,
    counsellingDate: j['counselling_date'] != null
        ? DateTime.tryParse(j['counselling_date'] as String)
        : null,
    createdAt: j['created_at'] != null
        ? DateTime.tryParse(j['created_at'] as String)
        : null,
    updatedAt: j['updated_at'] != null
        ? DateTime.tryParse(j['updated_at'] as String)
        : null,
    participantCount: j['participant_count'] as int? ?? 0,
  );
}

class EventSlotModel {
  const EventSlotModel({
    required this.id,
    required this.eventId,
    required this.title,
    required this.startsAt,
    this.endsAt,
    required this.capacity,
    required this.bookedCount,
    required this.availableCount,
  });

  final int id;
  final int eventId;
  final String title;
  final DateTime startsAt;
  final DateTime? endsAt;
  final int capacity;
  final int bookedCount;
  final int availableCount;

  bool get isFull => availableCount <= 0;

  factory EventSlotModel.fromJson(Map<String, dynamic> j) => EventSlotModel(
    id: j['id'] as int,
    eventId: j['event_id'] as int,
    title: j['title'] as String,
    startsAt: DateTime.parse(j['starts_at'] as String),
    endsAt: j['ends_at'] != null
        ? DateTime.tryParse(j['ends_at'] as String)
        : null,
    capacity: j['capacity'] as int,
    bookedCount: j['booked_count'] as int? ?? 0,
    availableCount: j['available_count'] as int? ?? 0,
  );
}
