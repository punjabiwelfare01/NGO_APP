import 'package:flutter/material.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum EventStatus {
  draft,
  published,
  registrationOpen,
  ongoing,
  completed,
  archived;

  String get label => switch (this) {
        draft            => 'Draft',
        published        => 'Published',
        registrationOpen => 'Registration Open',
        ongoing          => 'Ongoing',
        completed        => 'Completed',
        archived         => 'Archived',
      };

  String get apiValue => switch (this) {
        draft            => 'draft',
        published        => 'published',
        registrationOpen => 'registration_open',
        ongoing          => 'ongoing',
        completed        => 'completed',
        archived         => 'archived',
      };

  Color get color => switch (this) {
        draft            => const Color(0xFF757575),
        published        => const Color(0xFF1565C0),
        registrationOpen => const Color(0xFF2E7D32),
        ongoing          => const Color(0xFFE65100),
        completed        => const Color(0xFF4CAF50),
        archived         => const Color(0xFF9E9E9E),
      };

  IconData get icon => switch (this) {
        draft            => Icons.edit_outlined,
        published        => Icons.public_rounded,
        registrationOpen => Icons.app_registration_rounded,
        ongoing          => Icons.play_circle_rounded,
        completed        => Icons.check_circle_rounded,
        archived         => Icons.archive_rounded,
      };

  static EventStatus fromString(String v) => EventStatus.values.firstWhere(
        (e) => e.apiValue == v || e.name == v,
        orElse: () => EventStatus.draft,
      );
}

enum EventCategory {
  quizEvent,
  workshop,
  awarenessCampaign,
  competition,
  talentHunt,
  scholarshipDrive,
  counsellingDrive,
  cyberSecurity,
  stationeryDrive,
  donationDrive,
  schoolPartnership,
  communityOutreach;

  String get label => switch (this) {
        quizEvent         => 'Quiz Event',
        workshop          => 'Workshop',
        awarenessCampaign => 'Awareness Campaign',
        competition       => 'Competition',
        talentHunt        => 'Talent Hunt',
        scholarshipDrive  => 'Scholarship Drive',
        counsellingDrive  => 'Counselling Drive',
        cyberSecurity     => 'Cyber Security',
        stationeryDrive   => 'Stationery Drive',
        donationDrive     => 'Donation Drive',
        schoolPartnership => 'School Partnership',
        communityOutreach => 'Community Outreach',
      };

  IconData get icon => switch (this) {
        quizEvent         => Icons.quiz_rounded,
        workshop          => Icons.build_circle_rounded,
        awarenessCampaign => Icons.campaign_rounded,
        competition       => Icons.emoji_events_rounded,
        talentHunt        => Icons.star_rounded,
        scholarshipDrive  => Icons.school_rounded,
        counsellingDrive  => Icons.support_agent_rounded,
        cyberSecurity     => Icons.security_rounded,
        stationeryDrive   => Icons.book_rounded,
        donationDrive     => Icons.favorite_rounded,
        schoolPartnership => Icons.handshake_rounded,
        communityOutreach => Icons.people_rounded,
      };

  static EventCategory fromString(String v) => EventCategory.values.firstWhere(
        (e) => e.name == v || e.label.toLowerCase() == v.toLowerCase(),
        orElse: () => EventCategory.workshop,
      );
}

enum ActivityRole {
  registrationDesk,
  awarenessSpeaker,
  stationeryDistribution,
  donationCollection,
  photographyMedia,
  reportWriting,
  schoolCoordination,
  volunteerSupport;

  String get label => switch (this) {
        registrationDesk       => 'Registration Desk',
        awarenessSpeaker       => 'Awareness Speaker Support',
        stationeryDistribution => 'Stationery Distribution Team',
        donationCollection     => 'Donation Collection Team',
        photographyMedia       => 'Photography / Media Team',
        reportWriting          => 'Report Writing Team',
        schoolCoordination     => 'School Coordination Team',
        volunteerSupport       => 'Volunteer Support Team',
      };

  IconData get icon => switch (this) {
        registrationDesk       => Icons.how_to_reg_rounded,
        awarenessSpeaker       => Icons.campaign_rounded,
        stationeryDistribution => Icons.book_rounded,
        donationCollection     => Icons.payments_rounded,
        photographyMedia       => Icons.camera_alt_rounded,
        reportWriting          => Icons.description_rounded,
        schoolCoordination     => Icons.school_rounded,
        volunteerSupport       => Icons.people_rounded,
      };

  static ActivityRole fromString(String v) => ActivityRole.values.firstWhere(
        (e) => e.name == v,
        orElse: () => ActivityRole.volunteerSupport,
      );
}

enum AssignmentStatus {
  applied,
  shortlisted,
  assigned,
  workSubmitted,
  verified,
  approved,
  certificateEligible,
  rejected;

  String get label => switch (this) {
        applied             => 'Applied',
        shortlisted         => 'Shortlisted',
        assigned            => 'Assigned',
        workSubmitted       => 'Work Submitted',
        verified            => 'Verified',
        approved            => 'Approved',
        certificateEligible => 'Certificate Eligible',
        rejected            => 'Rejected',
      };

  Color get color => switch (this) {
        applied             => const Color(0xFF1565C0),
        shortlisted         => const Color(0xFF6A1B9A),
        assigned            => const Color(0xFFE65100),
        workSubmitted       => const Color(0xFFF57F17),
        verified            => const Color(0xFF00695C),
        approved            => const Color(0xFF2E7D32),
        certificateEligible => const Color(0xFF1B5E20),
        rejected            => const Color(0xFFC62828),
      };

  IconData get icon => switch (this) {
        applied             => Icons.send_rounded,
        shortlisted         => Icons.checklist_rounded,
        assigned            => Icons.assignment_turned_in_rounded,
        workSubmitted       => Icons.upload_file_rounded,
        verified            => Icons.verified_rounded,
        approved            => Icons.check_circle_rounded,
        certificateEligible => Icons.workspace_premium_rounded,
        rejected            => Icons.cancel_rounded,
      };

  static AssignmentStatus fromString(String v) =>
      AssignmentStatus.values.firstWhere(
        (e) => e.name == v,
        orElse: () => AssignmentStatus.applied,
      );
}

enum EMImpactPostType {
  certificateAwarded,
  volunteerAppreciation,
  donationDriveAchievement,
  stationeryDistribution,
  awarenessCamp,
  schoolPartnerProgram,
  volunteerOfMonth,
  guestOfficerAppreciation,
  eventSuccessReport;

  String get label => switch (this) {
        certificateAwarded       => 'Certificate Awarded',
        volunteerAppreciation    => 'Volunteer Appreciation',
        donationDriveAchievement => 'Donation Drive Achievement',
        stationeryDistribution   => 'Stationery Distribution',
        awarenessCamp            => 'Awareness Camp',
        schoolPartnerProgram     => 'School Partner Program',
        volunteerOfMonth         => 'Volunteer of the Month',
        guestOfficerAppreciation => 'Guest / Officer Appreciation',
        eventSuccessReport       => 'Event Success Report',
      };

  IconData get icon => switch (this) {
        certificateAwarded       => Icons.workspace_premium_rounded,
        volunteerAppreciation    => Icons.favorite_rounded,
        donationDriveAchievement => Icons.payments_rounded,
        stationeryDistribution   => Icons.book_rounded,
        awarenessCamp            => Icons.campaign_rounded,
        schoolPartnerProgram     => Icons.school_rounded,
        volunteerOfMonth         => Icons.star_rounded,
        guestOfficerAppreciation => Icons.military_tech_rounded,
        eventSuccessReport       => Icons.emoji_events_rounded,
      };

  Color get color => switch (this) {
        certificateAwarded       => const Color(0xFF1565C0),
        volunteerAppreciation    => const Color(0xFFC62828),
        donationDriveAchievement => const Color(0xFF2E7D32),
        stationeryDistribution   => const Color(0xFF4527A0),
        awarenessCamp            => const Color(0xFFE65100),
        schoolPartnerProgram     => const Color(0xFF00695C),
        volunteerOfMonth         => const Color(0xFFFF6F00),
        guestOfficerAppreciation => const Color(0xFF283593),
        eventSuccessReport       => const Color(0xFF1B5E20),
      };

  static EMImpactPostType fromString(String v) =>
      EMImpactPostType.values.firstWhere(
        (e) => e.name == v,
        orElse: () => EMImpactPostType.eventSuccessReport,
      );
}

// ─── Models ───────────────────────────────────────────────────────────────────

class EventManagerStats {
  final int todayEvents;
  final int activeActivities;
  final int pendingSubmissions;
  final int studentsAssigned;
  final int pendingImpactPosts;
  final int totalEventsThisMonth;

  const EventManagerStats({
    this.todayEvents = 0,
    this.activeActivities = 0,
    this.pendingSubmissions = 0,
    this.studentsAssigned = 0,
    this.pendingImpactPosts = 0,
    this.totalEventsThisMonth = 0,
  });

  static const empty = EventManagerStats();

  factory EventManagerStats.fromJson(Map<String, dynamic> j) =>
      EventManagerStats(
        todayEvents: j['today_events'] as int? ?? 0,
        activeActivities: j['active_activities'] as int? ?? 0,
        pendingSubmissions: j['pending_submissions'] as int? ?? 0,
        studentsAssigned: j['students_assigned'] as int? ?? 0,
        pendingImpactPosts: j['pending_impact_posts'] as int? ?? 0,
        totalEventsThisMonth: j['total_events_this_month'] as int? ?? 0,
      );
}

class NGOEvent {
  final int id;
  final String title;
  final EventCategory category;
  final EventStatus status;
  final DateTime date;
  final String location;
  final String? partnerSchool;
  final String description;
  final String? bannerImageUrl;
  final int maxVolunteers;
  final String? studentEligibility;
  final String? expectedWork;
  final String? proofRequired;
  final bool certificateEligible;
  final bool donationEligible;
  final double? stipendAmount;
  final List<EventActivity> activities;
  final DateTime createdAt;

  const NGOEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.date,
    required this.location,
    this.partnerSchool,
    required this.description,
    this.bannerImageUrl,
    required this.maxVolunteers,
    this.studentEligibility,
    this.expectedWork,
    this.proofRequired,
    this.certificateEligible = true,
    this.donationEligible = false,
    this.stipendAmount,
    this.activities = const [],
    required this.createdAt,
  });

  factory NGOEvent.fromJson(Map<String, dynamic> j) => NGOEvent(
        id: j['id'] as int,
        title: j['title'] as String,
        category: EventCategory.fromString(j['category'] as String),
        status: EventStatus.fromString(j['status'] as String),
        date: DateTime.parse(j['date'] as String),
        location: j['location'] as String,
        partnerSchool: j['partner_school'] as String?,
        description: j['description'] as String,
        bannerImageUrl: j['banner_image_url'] as String?,
        maxVolunteers: j['max_volunteers'] as int? ?? 10,
        studentEligibility: j['student_eligibility'] as String?,
        expectedWork: j['expected_work'] as String?,
        proofRequired: j['proof_required'] as String?,
        certificateEligible: j['certificate_eligible'] as bool? ?? true,
        donationEligible: j['donation_eligible'] as bool? ?? false,
        stipendAmount: (j['stipend_amount'] as num?)?.toDouble(),
        activities: (j['activities'] as List<dynamic>?)
                ?.map((a) => EventActivity.fromJson(a as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class EventActivity {
  final int id;
  final int eventId;
  final String title;
  final ActivityRole role;
  final String? description;
  final int maxStudents;
  final int assignedCount;

  const EventActivity({
    required this.id,
    required this.eventId,
    required this.title,
    required this.role,
    this.description,
    required this.maxStudents,
    this.assignedCount = 0,
  });

  bool get isFull => assignedCount >= maxStudents;
  int get slotsLeft => maxStudents - assignedCount;

  factory EventActivity.fromJson(Map<String, dynamic> j) => EventActivity(
        id: j['id'] as int,
        eventId: j['event_id'] as int,
        title: j['title'] as String,
        role: ActivityRole.fromString(j['role'] as String),
        description: j['description'] as String?,
        maxStudents: j['max_students'] as int? ?? 5,
        assignedCount: j['assigned_count'] as int? ?? 0,
      );
}

class EMStudent {
  final int id;
  final String name;
  final String email;
  final String? location;
  final String? phone;
  final int hoursServed;
  final int activitiesCompleted;

  const EMStudent({
    required this.id,
    required this.name,
    required this.email,
    this.location,
    this.phone,
    this.hoursServed = 0,
    this.activitiesCompleted = 0,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory EMStudent.fromJson(Map<String, dynamic> j) => EMStudent(
        id: j['id'] as int,
        name: j['name'] as String,
        email: j['email'] as String,
        location: j['location'] as String?,
        phone: j['phone'] as String?,
        hoursServed: j['hours_served'] as int? ?? 0,
        activitiesCompleted: j['activities_completed'] as int? ?? 0,
      );
}

class EMStudentAssignment {
  final int id;
  final EMStudent student;
  final EventActivity activity;
  final NGOEvent event;
  final AssignmentStatus status;
  final DateTime appliedAt;
  final String? instructions;
  final String? reviewerNotes;
  final EMWorkSubmission? submission;

  const EMStudentAssignment({
    required this.id,
    required this.student,
    required this.activity,
    required this.event,
    required this.status,
    required this.appliedAt,
    this.instructions,
    this.reviewerNotes,
    this.submission,
  });

  EMStudentAssignment copyWith({
    AssignmentStatus? status,
    String? instructions,
    String? reviewerNotes,
    EMWorkSubmission? submission,
  }) =>
      EMStudentAssignment(
        id: id,
        student: student,
        activity: activity,
        event: event,
        status: status ?? this.status,
        appliedAt: appliedAt,
        instructions: instructions ?? this.instructions,
        reviewerNotes: reviewerNotes ?? this.reviewerNotes,
        submission: submission ?? this.submission,
      );

  factory EMStudentAssignment.fromJson(Map<String, dynamic> j) =>
      EMStudentAssignment(
        id: j['id'] as int,
        student: EMStudent.fromJson(j['student'] as Map<String, dynamic>),
        activity:
            EventActivity.fromJson(j['activity'] as Map<String, dynamic>),
        event: NGOEvent.fromJson(j['event'] as Map<String, dynamic>),
        status: AssignmentStatus.fromString(j['status'] as String),
        appliedAt: DateTime.parse(j['applied_at'] as String),
        instructions: j['instructions'] as String?,
        reviewerNotes: j['reviewer_notes'] as String?,
        submission: j['submission'] != null
            ? EMWorkSubmission.fromJson(
                j['submission'] as Map<String, dynamic>)
            : null,
      );
}

class EMWorkSubmission {
  final int id;
  final int assignmentId;
  final String workTitle;
  final String description;
  final double hoursWorked;
  final int peopleReached;
  final double? donationCollected;
  final String? transactionId;
  final String? remarks;
  final List<String> photoUrls;
  final DateTime submittedAt;

  const EMWorkSubmission({
    required this.id,
    required this.assignmentId,
    required this.workTitle,
    required this.description,
    required this.hoursWorked,
    required this.peopleReached,
    this.donationCollected,
    this.transactionId,
    this.remarks,
    this.photoUrls = const [],
    required this.submittedAt,
  });

  factory EMWorkSubmission.fromJson(Map<String, dynamic> j) =>
      EMWorkSubmission(
        id: j['id'] as int,
        assignmentId: j['assignment_id'] as int,
        workTitle: j['work_title'] as String,
        description: j['description'] as String,
        hoursWorked: (j['hours_worked'] as num).toDouble(),
        peopleReached: j['people_reached'] as int,
        donationCollected: (j['donation_collected'] as num?)?.toDouble(),
        transactionId: j['transaction_id'] as String?,
        remarks: j['remarks'] as String?,
        photoUrls: (j['photo_urls'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        submittedAt: DateTime.parse(j['submitted_at'] as String),
      );
}

class EMImpactPost {
  final int id;
  final EMImpactPostType type;
  final String title;
  final String? studentName;
  final String? teamName;
  final String eventName;
  final String location;
  final DateTime date;
  final String description;
  final String appreciationMessage;
  final int? studentsHelped;
  final double? hoursServed;
  final double? donationRaised;
  final List<String> photoUrls;
  final bool isPublished;
  final bool adminApproved;
  final String verifiedByName;

  const EMImpactPost({
    required this.id,
    required this.type,
    required this.title,
    this.studentName,
    this.teamName,
    required this.eventName,
    required this.location,
    required this.date,
    required this.description,
    required this.appreciationMessage,
    this.studentsHelped,
    this.hoursServed,
    this.donationRaised,
    this.photoUrls = const [],
    this.isPublished = false,
    this.adminApproved = false,
    required this.verifiedByName,
  });

  EMImpactPost copyWith({
    String? title,
    String? description,
    String? appreciationMessage,
    bool? isPublished,
    bool? adminApproved,
    EMImpactPostType? type,
  }) =>
      EMImpactPost(
        id: id,
        type: type ?? this.type,
        title: title ?? this.title,
        studentName: studentName,
        teamName: teamName,
        eventName: eventName,
        location: location,
        date: date,
        description: description ?? this.description,
        appreciationMessage: appreciationMessage ?? this.appreciationMessage,
        studentsHelped: studentsHelped,
        hoursServed: hoursServed,
        donationRaised: donationRaised,
        photoUrls: photoUrls,
        isPublished: isPublished ?? this.isPublished,
        adminApproved: adminApproved ?? this.adminApproved,
        verifiedByName: verifiedByName,
      );

  factory EMImpactPost.fromJson(Map<String, dynamic> j) => EMImpactPost(
        id: j['id'] as int,
        type: EMImpactPostType.fromString(j['type'] as String),
        title: j['title'] as String,
        studentName: j['student_name'] as String?,
        teamName: j['team_name'] as String?,
        eventName: j['event_name'] as String,
        location: j['location'] as String,
        date: DateTime.parse(j['date'] as String),
        description: j['description'] as String,
        appreciationMessage: j['appreciation_message'] as String,
        studentsHelped: j['students_helped'] as int?,
        hoursServed: (j['hours_served'] as num?)?.toDouble(),
        donationRaised: (j['donation_raised'] as num?)?.toDouble(),
        photoUrls: (j['photo_urls'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        isPublished: j['is_published'] as bool? ?? false,
        adminApproved: j['admin_approved'] as bool? ?? false,
        verifiedByName: j['verified_by_name'] as String? ?? '',
      );
}

class EventReport {
  final int id;
  final int eventId;
  final String eventName;
  final DateTime eventDate;
  final String location;
  final int volunteersParticipated;
  final int peopleReached;
  final double totalDonationCollected;
  final List<String> photoUrls;
  final String? partnerSchool;
  final String? guestOfficerName;
  final String summary;
  final String outcomes;
  final List<String> studentContributors;
  final DateTime generatedAt;

  const EventReport({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    required this.location,
    required this.volunteersParticipated,
    required this.peopleReached,
    required this.totalDonationCollected,
    required this.photoUrls,
    this.partnerSchool,
    this.guestOfficerName,
    required this.summary,
    required this.outcomes,
    required this.studentContributors,
    required this.generatedAt,
  });

  factory EventReport.fromJson(Map<String, dynamic> j) => EventReport(
        id: j['id'] as int,
        eventId: j['event_id'] as int,
        eventName: j['event_name'] as String,
        eventDate: DateTime.parse(j['event_date'] as String),
        location: j['location'] as String,
        volunteersParticipated: j['volunteers_participated'] as int,
        peopleReached: j['people_reached'] as int,
        totalDonationCollected:
            (j['total_donation_collected'] as num).toDouble(),
        photoUrls: (j['photo_urls'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        partnerSchool: j['partner_school'] as String?,
        guestOfficerName: j['guest_officer_name'] as String?,
        summary: j['summary'] as String,
        outcomes: j['outcomes'] as String,
        studentContributors: (j['student_contributors'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        generatedAt: DateTime.parse(j['generated_at'] as String),
      );
}
