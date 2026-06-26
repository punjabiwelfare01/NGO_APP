// ignore_for_file: constant_identifier_names

enum ActivityCategory {
  education_support,
  awareness_programs,
  school_partner,
  donation_drives,
  event_organization,
  digital_branding,
  documentation;

  String get displayName => switch (this) {
    education_support => 'Education Support',
    awareness_programs => 'Awareness Programs',
    school_partner => 'School Partner',
    donation_drives => 'Donation Drives',
    event_organization => 'Event Organization',
    digital_branding => 'Digital & Branding',
    documentation => 'Documentation',
  };

  static ActivityCategory fromString(String v) =>
      ActivityCategory.values.firstWhere(
        (e) => e.name == v,
        orElse: () => ActivityCategory.education_support,
      );
}

enum SubmissionStatus {
  submitted,
  under_review,
  approved,
  rejected;

  String get displayName => switch (this) {
    submitted => 'Submitted',
    under_review => 'Under Review',
    approved => 'Approved',
    rejected => 'Rejected',
  };

  static SubmissionStatus fromString(String v) => SubmissionStatus.values
      .firstWhere((e) => e.name == v, orElse: () => SubmissionStatus.submitted);
}

class VolunteerActivity {
  final int id;
  final int? eventId;
  final String title;
  final ActivityCategory category;
  final String? subdivision;
  final String? description;
  final String? expectedWork;
  final String? proofRequired;
  final double rewardHours;
  final bool isActive;
  final String? location;
  final String? duration;
  final DateTime? applicationDeadline;
  final int? maxStudents;
  final bool certificateEligible;
  final double? stipendAmount;
  final String? applicationStatus;
  final int? assignmentId;

  const VolunteerActivity({
    required this.id,
    this.eventId,
    required this.title,
    required this.category,
    this.subdivision,
    this.description,
    this.expectedWork,
    this.proofRequired,
    required this.rewardHours,
    required this.isActive,
    this.location,
    this.duration,
    this.applicationDeadline,
    this.maxStudents,
    this.certificateEligible = true,
    this.stipendAmount,
    this.applicationStatus,
    this.assignmentId,
  });

  factory VolunteerActivity.fromJson(Map<String, dynamic> j) =>
      VolunteerActivity(
        id: j['id'] as int,
        eventId: j['event_id'] as int?,
        title: j['title'] as String,
        category: ActivityCategory.fromString(j['category'] as String),
        subdivision: j['subdivision'] as String?,
        description: j['description'] as String?,
        expectedWork: j['expected_work'] as String?,
        proofRequired: j['proof_required'] as String?,
        rewardHours: (j['reward_hours'] as num).toDouble(),
        isActive: j['is_active'] as bool? ?? true,
        location: j['location'] as String?,
        duration: j['duration'] as String?,
        applicationDeadline: j['application_deadline'] == null
            ? null
            : DateTime.tryParse(j['application_deadline'] as String),
        maxStudents: j['max_students'] as int?,
        certificateEligible: j['certificate_eligible'] as bool? ?? true,
        stipendAmount: (j['stipend_amount'] as num?)?.toDouble(),
        applicationStatus: j['application_status'] as String?,
        assignmentId: j['assignment_id'] as int?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is VolunteerActivity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class ActivityAssignment {
  final int id;
  final int studentId;
  final int activityId;
  final int? assignedBy;
  final String? location;
  final DateTime? scheduledDate;
  final String status;
  final String? notes;
  final VolunteerActivity? activity;

  const ActivityAssignment({
    required this.id,
    required this.studentId,
    required this.activityId,
    this.assignedBy,
    this.location,
    this.scheduledDate,
    required this.status,
    this.notes,
    this.activity,
  });

  factory ActivityAssignment.fromJson(Map<String, dynamic> j) =>
      ActivityAssignment(
        id: j['id'] as int,
        studentId: j['student_id'] as int,
        activityId: j['activity_id'] as int,
        assignedBy: j['assigned_by'] as int?,
        location: j['location'] as String?,
        scheduledDate: j['scheduled_date'] == null
            ? null
            : DateTime.parse(j['scheduled_date'] as String),
        status: j['status'] as String? ?? 'assigned',
        notes: j['notes'] as String?,
        activity: j['activity'] == null
            ? null
            : VolunteerActivity.fromJson(j['activity'] as Map<String, dynamic>),
      );
}

class WorkSubmission {
  final int id;
  final int studentId;
  final int? assignmentId;
  final int activityId;
  final String title;
  final String description;
  final double hoursWorked;
  final int peopleReached;
  final double donationCollected;
  final String? transactionId;
  final String? proofFiles;
  final SubmissionStatus status;
  final String? remarks;
  final String? reviewerNotes;
  final DateTime? createdAt;
  final VolunteerActivity? activity;

  const WorkSubmission({
    required this.id,
    required this.studentId,
    this.assignmentId,
    required this.activityId,
    required this.title,
    required this.description,
    required this.hoursWorked,
    required this.peopleReached,
    required this.donationCollected,
    this.transactionId,
    this.proofFiles,
    required this.status,
    this.remarks,
    this.reviewerNotes,
    this.createdAt,
    this.activity,
  });

  factory WorkSubmission.fromJson(Map<String, dynamic> j) => WorkSubmission(
    id: j['id'] as int,
    studentId: j['student_id'] as int,
    assignmentId: j['assignment_id'] as int?,
    activityId: j['activity_id'] as int,
    title: j['title'] as String,
    description: j['description'] as String,
    hoursWorked: (j['hours_worked'] as num).toDouble(),
    peopleReached: j['people_reached'] as int? ?? 0,
    donationCollected: (j['donation_collected'] as num).toDouble(),
    transactionId: j['transaction_id'] as String?,
    proofFiles: j['proof_files'] as String?,
    status: SubmissionStatus.fromString(j['status'] as String),
    remarks: j['remarks'] as String?,
    reviewerNotes: j['reviewer_notes'] as String?,
    createdAt: j['created_at'] == null
        ? null
        : DateTime.tryParse(j['created_at'] as String),
    activity: j['activity'] == null
        ? null
        : VolunteerActivity.fromJson(j['activity'] as Map<String, dynamic>),
  );
}

class DailyLog {
  final int id;
  final int studentId;
  final int? submissionId;
  final DateTime date;
  final String? title;
  final String? content;
  final String? reflection;
  final String? mediaFiles;
  final bool isPublic;
  final String status;
  final DateTime? createdAt;

  const DailyLog({
    required this.id,
    required this.studentId,
    this.submissionId,
    required this.date,
    this.title,
    this.content,
    this.reflection,
    this.mediaFiles,
    required this.isPublic,
    required this.status,
    this.createdAt,
  });

  factory DailyLog.fromJson(Map<String, dynamic> j) => DailyLog(
    id: j['id'] as int,
    studentId: j['student_id'] as int,
    submissionId: j['submission_id'] as int?,
    date: DateTime.parse(j['date'] as String),
    title: j['title'] as String?,
    content: j['content'] as String?,
    reflection: j['reflection'] as String?,
    mediaFiles: j['media_files'] as String?,
    isPublic: j['is_public'] as bool? ?? false,
    status: j['status'] as String? ?? 'draft',
    createdAt: j['created_at'] == null
        ? null
        : DateTime.tryParse(j['created_at'] as String),
  );
}

class ImpactStory {
  final int id;
  final int studentId;
  final String title;
  final String? story;
  final String? category;
  final String? impactNumbers;
  final String? photoUrl;
  final bool isFeatured;
  final bool isPublic;

  const ImpactStory({
    required this.id,
    required this.studentId,
    required this.title,
    this.story,
    this.category,
    this.impactNumbers,
    this.photoUrl,
    required this.isFeatured,
    required this.isPublic,
  });

  factory ImpactStory.fromJson(Map<String, dynamic> j) => ImpactStory(
    id: j['id'] as int,
    studentId: j['student_id'] as int,
    title: j['title'] as String,
    story: j['story'] as String?,
    category: j['category'] as String?,
    impactNumbers: j['impact_numbers'] as String?,
    photoUrl: j['photo_url'] as String?,
    isFeatured: j['is_featured'] as bool? ?? false,
    isPublic: j['is_public'] as bool? ?? false,
  );
}

class VolunteerStats {
  final double totalHours;
  final int activitiesCompleted;
  final double donationRaised;
  final int certificatesEarned;
  final int pendingApprovals;
  final String volunteerRank;

  const VolunteerStats({
    required this.totalHours,
    required this.activitiesCompleted,
    required this.donationRaised,
    required this.certificatesEarned,
    required this.pendingApprovals,
    required this.volunteerRank,
  });

  factory VolunteerStats.fromJson(Map<String, dynamic> j) => VolunteerStats(
    totalHours: (j['total_hours'] as num).toDouble(),
    activitiesCompleted: j['activities_completed'] as int,
    donationRaised: (j['donation_raised'] as num).toDouble(),
    certificatesEarned: j['certificates_earned'] as int,
    pendingApprovals: j['pending_approvals'] as int,
    volunteerRank: j['volunteer_rank'] as String? ?? 'Bronze',
  );

  static VolunteerStats get empty => const VolunteerStats(
    totalHours: 0,
    activitiesCompleted: 0,
    donationRaised: 0,
    certificatesEarned: 0,
    pendingApprovals: 0,
    volunteerRank: 'Bronze',
  );
}
