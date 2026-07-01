import 'package:flutter/material.dart';

import 'counsellor_models.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum SchoolRequestStatus {
  newRequest('New Request', Color(0xFF1565C0), Icons.fiber_new_rounded),
  accepted('Accepted', Color(0xFF2E7D32), Icons.check_circle_rounded),
  rescheduled('Rescheduled', Color(0xFF6A1B9A), Icons.schedule_rounded),
  declined('Declined', Color(0xFFC62828), Icons.cancel_rounded),
  pendingConfirmation(
    'Pending Confirmation',
    Color(0xFFF57F17),
    Icons.pending_rounded,
  ),
  confirmed('Confirmed', Color(0xFF1565C0), Icons.verified_rounded),
  scheduled(
    'Meeting Scheduled',
    Color(0xFF2E7D32),
    Icons.event_available_rounded,
  ),
  completed('Completed', Color(0xFF00695C), Icons.task_alt_rounded),
  cancelled('Cancelled', Color(0xFF6F7E8D), Icons.event_busy_rounded);

  const SchoolRequestStatus(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;

  static SchoolRequestStatus fromString(String value) => values.firstWhere(
    (item) =>
        item.name == value ||
        (item == SchoolRequestStatus.newRequest && value == 'new_request') ||
        (item == SchoolRequestStatus.pendingConfirmation &&
            value == 'pending_confirmation'),
    orElse: () => SchoolRequestStatus.newRequest,
  );
}

enum DeclineReason {
  notAvailable('Not available on the requested date'),
  topicOutsideExpertise('Topic is outside my area of expertise'),
  locationTooFar('Offline location is too far to travel'),
  schedulingConflict('Scheduling conflict with another commitment'),
  other('Other reason');

  const DeclineReason(this.label);
  final String label;
}

enum ReminderType {
  hours24('24 hours before meeting'),
  hours2('2 hours before meeting'),
  minutes15('15 minutes before meeting');

  const ReminderType(this.label);
  final String label;
}

// ─── School Booking Request ───────────────────────────────────────────────────

class SchoolBookingRequest {
  const SchoolBookingRequest({
    required this.id,
    this.counsellorUserId,
    required this.schoolName,
    required this.coordinatorName,
    required this.coordinatorPhone,
    required this.coordinatorEmail,
    required this.schoolAddress,
    required this.program,
    required this.topic,
    required this.classGroup,
    required this.expectedStudents,
    required this.language,
    required this.preferredDate,
    required this.preferredTime,
    required this.mode,
    required this.status,
    required this.requestedAt,
    this.counsellorName = 'TBD',
    this.offlineLocation = '',
    this.meetingLink,
    this.assignedEventManager,
    this.assignedEventManagerPhone,
    this.preparationNotes = '',
    this.specialRequirements = '',
    this.suggestedDate,
    this.suggestedTime,
    this.declineReason,
    this.declineNote = '',
    this.acceptedAt,
    this.confirmedAt,
    this.completedAt,
    this.feedbackRating,
    this.feedbackComment = '',
  });

  final int id;
  final int? counsellorUserId;

  final String counsellorName;

  // School contact — phone/email hidden before acceptance (see contactVisible)
  final String schoolName;
  final String coordinatorName;
  final String coordinatorPhone;
  final String coordinatorEmail;
  final String schoolAddress;

  // Request details
  final String program;
  final String topic;
  final String classGroup;
  final int expectedStudents;
  final String language;
  final String specialRequirements;

  // Scheduling
  final DateTime preferredDate;
  final TimeOfDay preferredTime;
  final SessionMode mode;
  final String offlineLocation;
  final String? meetingLink;

  // Post-acceptance details set by EM
  final String? assignedEventManager;
  final String? assignedEventManagerPhone;
  final String? preparationNotes;

  // Counsellor reschedule suggestion
  final DateTime? suggestedDate;
  final TimeOfDay? suggestedTime;

  // Status and decline
  final SchoolRequestStatus status;
  final DeclineReason? declineReason;
  final String declineNote;

  // Timestamps
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;

  // Feedback (set after completion)
  final double? feedbackRating;
  final String feedbackComment;

  factory SchoolBookingRequest.fromJson(Map<String, dynamic> json) {
    TimeOfDay time(String prefix) => TimeOfDay(
      hour: json['${prefix}_hour'] as int? ?? 9,
      minute: json['${prefix}_minute'] as int? ?? 0,
    );
    DateTime? optionalDate(String key) =>
        json[key] == null ? null : DateTime.tryParse(json[key] as String);
    return SchoolBookingRequest(
      id: json['id'] as int,
      counsellorUserId: json['counsellor_user_id'] as int?,
      counsellorName: json['counsellor_name'] as String? ?? 'TBD',
      schoolName: json['school_name'] as String,
      coordinatorName: json['coordinator_name'] as String,
      coordinatorPhone: json['coordinator_phone'] as String? ?? '',
      coordinatorEmail: json['coordinator_email'] as String? ?? '',
      schoolAddress: json['school_address'] as String? ?? '',
      program: json['program'] as String? ?? 'School counselling',
      topic: json['topic'] as String,
      classGroup: json['class_group'] as String? ?? '',
      expectedStudents: json['expected_students'] as int? ?? 0,
      language: json['language'] as String? ?? '',
      specialRequirements: json['special_requirements'] as String? ?? '',
      preferredDate: DateTime.parse(json['preferred_date'] as String),
      preferredTime: time('preferred'),
      mode: SessionMode.fromString(json['mode'] as String? ?? 'offline'),
      offlineLocation: json['offline_location'] as String? ?? '',
      meetingLink: json['meeting_link'] as String?,
      assignedEventManager: json['assigned_event_manager'] as String?,
      assignedEventManagerPhone:
          json['assigned_event_manager_phone'] as String?,
      preparationNotes: json['preparation_notes'] as String? ?? '',
      suggestedDate: optionalDate('suggested_date'),
      suggestedTime: json['suggested_hour'] == null ? null : time('suggested'),
      status: SchoolRequestStatus.fromString(
        json['status'] as String? ?? 'new_request',
      ),
      declineNote: json['decline_note'] as String? ?? '',
      requestedAt: json['requested_at'] != null
          ? DateTime.parse(json['requested_at'] as String)
          : DateTime.now(),
      acceptedAt: optionalDate('accepted_at'),
      confirmedAt: optionalDate('confirmed_at'),
      completedAt: optionalDate('completed_at'),
    );
  }

  /// Phone/email become visible only after counsellor accepts or EM confirms.
  bool get contactVisible =>
      status == SchoolRequestStatus.accepted ||
      status == SchoolRequestStatus.pendingConfirmation ||
      status == SchoolRequestStatus.confirmed ||
      status == SchoolRequestStatus.scheduled ||
      status == SchoolRequestStatus.completed;

  bool get isUpcoming =>
      status == SchoolRequestStatus.accepted ||
      status == SchoolRequestStatus.pendingConfirmation ||
      status == SchoolRequestStatus.confirmed ||
      status == SchoolRequestStatus.scheduled;

  bool get isActive =>
      status == SchoolRequestStatus.newRequest ||
      status == SchoolRequestStatus.accepted ||
      status == SchoolRequestStatus.rescheduled ||
      status == SchoolRequestStatus.pendingConfirmation;

  bool get isToday {
    final d = effectiveDate;
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  DateTime get effectiveDate => suggestedDate ?? preferredDate;
  TimeOfDay get effectiveTime => suggestedTime ?? preferredTime;

  String get effectiveModeDetail {
    if (mode == SessionMode.online) return meetingLink ?? 'Link TBD';
    return offlineLocation.isNotEmpty ? offlineLocation : schoolAddress;
  }

  SchoolBookingRequest copyWith({
    String? counsellorName,
    SchoolRequestStatus? status,
    DateTime? suggestedDate,
    TimeOfDay? suggestedTime,
    DeclineReason? declineReason,
    String? declineNote,
    DateTime? acceptedAt,
    DateTime? confirmedAt,
    DateTime? completedAt,
    String? meetingLink,
    String? assignedEventManager,
    String? assignedEventManagerPhone,
    String? preparationNotes,
    double? feedbackRating,
    String? feedbackComment,
  }) => SchoolBookingRequest(
    id: id,
    counsellorUserId: counsellorUserId,
    counsellorName: counsellorName ?? this.counsellorName,
    schoolName: schoolName,
    coordinatorName: coordinatorName,
    coordinatorPhone: coordinatorPhone,
    coordinatorEmail: coordinatorEmail,
    schoolAddress: schoolAddress,
    program: program,
    topic: topic,
    classGroup: classGroup,
    expectedStudents: expectedStudents,
    language: language,
    specialRequirements: specialRequirements,
    preferredDate: preferredDate,
    preferredTime: preferredTime,
    mode: mode,
    offlineLocation: offlineLocation,
    meetingLink: meetingLink ?? this.meetingLink,
    assignedEventManager: assignedEventManager ?? this.assignedEventManager,
    assignedEventManagerPhone:
        assignedEventManagerPhone ?? this.assignedEventManagerPhone,
    preparationNotes: preparationNotes ?? this.preparationNotes,
    suggestedDate: suggestedDate ?? this.suggestedDate,
    suggestedTime: suggestedTime ?? this.suggestedTime,
    declineReason: declineReason ?? this.declineReason,
    declineNote: declineNote ?? this.declineNote,
    status: status ?? this.status,
    requestedAt: requestedAt,
    acceptedAt: acceptedAt ?? this.acceptedAt,
    confirmedAt: confirmedAt ?? this.confirmedAt,
    completedAt: completedAt ?? this.completedAt,
    feedbackRating: feedbackRating ?? this.feedbackRating,
    feedbackComment: feedbackComment ?? this.feedbackComment,
  );
}

// ─── Meeting Reminder ─────────────────────────────────────────────────────────

class MeetingReminder {
  const MeetingReminder({
    required this.id,
    required this.requestId,
    required this.scheduledFor,
    required this.type,
    required this.schoolName,
    required this.mode,
    required this.coordinatorName,
    required this.meetingDate,
    this.locationOrLink,
    this.isSent = false,
    this.isDismissed = false,
  });

  final int id;
  final int requestId;
  final DateTime scheduledFor;
  final ReminderType type;
  final String schoolName;
  final SessionMode mode;
  final String coordinatorName;
  final DateTime meetingDate;
  final String? locationOrLink;
  final bool isSent;
  final bool isDismissed;

  bool get isUpcoming =>
      !isSent && !isDismissed && scheduledFor.isAfter(DateTime.now());

  MeetingReminder copyWith({bool? isSent, bool? isDismissed}) =>
      MeetingReminder(
        id: id,
        requestId: requestId,
        scheduledFor: scheduledFor,
        type: type,
        schoolName: schoolName,
        mode: mode,
        coordinatorName: coordinatorName,
        meetingDate: meetingDate,
        locationOrLink: locationOrLink,
        isSent: isSent ?? this.isSent,
        isDismissed: isDismissed ?? this.isDismissed,
      );
}

// ─── Impact Report ────────────────────────────────────────────────────────────

class ImpactReport {
  const ImpactReport({
    required this.id,
    required this.requestId,
    required this.schoolName,
    required this.topic,
    required this.studentsCount,
    required this.sessionDate,
    required this.submittedAt,
    this.counsellorNotes = '',
    this.rating,
    this.schoolFeedback = '',
    this.isSubmitted = false,
  });

  final int id;
  final int requestId;
  final String schoolName;
  final String topic;
  final int studentsCount;
  final DateTime sessionDate;
  final DateTime submittedAt;
  final String counsellorNotes;
  final double? rating;
  final String schoolFeedback;
  final bool isSubmitted;
}

// ─── Counsellor Stats ─────────────────────────────────────────────────────────

class CounsellorStats {
  const CounsellorStats({
    required this.todayScheduled,
    required this.newRequests,
    required this.pendingConfirmation,
    required this.completedThisMonth,
    required this.avgRating,
    required this.totalStudentsGuided,
  });

  final int todayScheduled;
  final int newRequests;
  final int pendingConfirmation;
  final int completedThisMonth;
  final double avgRating;
  final int totalStudentsGuided;
}

// ─── Availability Slot ────────────────────────────────────────────────────────

class AvailabilitySlot {
  const AvailabilitySlot({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.mode,
    this.isBooked = false,
    this.isBlocked = false,
    this.isRepeating = false,
    this.bookedByName,
    this.repeatDayLabel,
  });

  final int id;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final SessionMode mode;
  final bool isBooked;
  final bool isBlocked;
  final bool isRepeating;
  final String? bookedByName;
  final String? repeatDayLabel;

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    final start = DateTime.parse(json['starts_at'] as String);
    final end = DateTime.parse(json['ends_at'] as String);
    return AvailabilitySlot(
      id: json['id'] as int,
      date: start,
      startTime: TimeOfDay.fromDateTime(start),
      endTime: TimeOfDay.fromDateTime(end),
      mode: (json['meeting_url'] as String?)?.isNotEmpty == true
          ? SessionMode.online
          : SessionMode.offline,
      isBooked: (json['booked_count'] as int? ?? 0) > 0,
      isBlocked: json['is_active'] == false,
      isRepeating: (json['recurrence_type'] as String? ?? 'none') != 'none',
    );
  }

  String get timeLabel {
    String fmt(TimeOfDay t) {
      final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final m = t.minute.toString().padLeft(2, '0');
      final p = t.period == DayPeriod.am ? 'AM' : 'PM';
      return '$h:$m $p';
    }

    return '${fmt(startTime)} – ${fmt(endTime)}';
  }

  Color get displayColor {
    if (isBlocked) return const Color(0xFFC62828);
    if (isBooked) return const Color(0xFF1565C0);
    return const Color(0xFF2E7D32);
  }

  String get displayLabel {
    if (isBlocked) return 'Blocked';
    if (isBooked) return bookedByName ?? 'Booked';
    return 'Available';
  }

  AvailabilitySlot copyWith({
    bool? isBlocked,
    bool? isRepeating,
    SessionMode? mode,
  }) => AvailabilitySlot(
    id: id,
    date: date,
    startTime: startTime,
    endTime: endTime,
    mode: mode ?? this.mode,
    isBooked: isBooked,
    isBlocked: isBlocked ?? this.isBlocked,
    isRepeating: isRepeating ?? this.isRepeating,
    bookedByName: bookedByName,
    repeatDayLabel: repeatDayLabel,
  );
}
