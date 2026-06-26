// ignore_for_file: constant_identifier_names

enum CertificateType {
  volunteer,
  internship,
  donation_drive,
  event_organizer,
  appreciation,
  school_awareness,
  event_participation,
  counselling_support,
  course_completion,
  social_work,
  event_manager,
  donation_collection;

  String get displayName => switch (this) {
    volunteer           => 'Volunteer Participation Certificate',
    internship          => 'Internship Completion Certificate',
    donation_drive      => 'Donation Drive Certificate',
    event_organizer     => 'Event Organizer Certificate',
    appreciation        => 'Appreciation Certificate',
    school_awareness    => 'School Awareness Certificate',
    event_participation => 'Event Participation Certificate',
    counselling_support => 'Counselling Support Certificate',
    course_completion   => 'Course Completion Certificate',
    social_work         => 'Social Work Appreciation Certificate',
    event_manager       => 'Event Manager Contribution Certificate',
    donation_collection => 'Donation Collection Appreciation Certificate',
  };

  String get templateTitle => switch (this) {
    volunteer           => 'Certificate of Volunteer Service',
    internship          => 'Certificate of Internship Completion',
    donation_drive      => 'Certificate of Appreciation',
    event_organizer     => 'Certificate of Event Contribution',
    appreciation        => 'Certificate of Appreciation',
    school_awareness    => 'Certificate of Participation',
    event_participation => 'Certificate of Participation',
    counselling_support => 'Certificate of Counselling Support',
    course_completion   => 'Certificate of Course Completion',
    social_work         => 'Certificate of Social Impact Contribution',
    event_manager       => 'Certificate of Event Management Contribution',
    donation_collection => 'Certificate of Donation Collection Appreciation',
  };

  static CertificateType fromString(String v) => CertificateType.values
      .firstWhere((e) => e.name == v, orElse: () => CertificateType.volunteer);
}

enum CertificateStatus {
  draft,
  pending_signature,
  pending,
  approved,
  rejected,
  generated,
  signed,
  issued,
  revoked;

  String get displayName => switch (this) {
    draft             => 'Draft',
    pending_signature => 'Pending Signature',
    pending           => 'Pending Approval',
    approved          => 'Approved — Ready to Generate',
    rejected          => 'Rejected',
    generated         => 'Generated',
    signed            => 'Signed',
    issued            => 'Issued & Verified',
    revoked           => 'Revoked',
  };

  bool get canGeneratePdf =>
      this == approved || this == issued || this == generated;

  bool get isActive => this != rejected && this != revoked;

  static CertificateStatus fromString(String v) => CertificateStatus.values
      .firstWhere((e) => e.name == v, orElse: () => CertificateStatus.pending);
}

class Certificate {
  final int id;
  final String certificateId;
  final int studentId;
  final String? studentName;
  final int? eventId;
  final int? activityId;
  final int? assignmentId;
  final CertificateType certificateType;
  final String activityName;
  final String? duration;
  final String? signatoryName;
  final String? signatoryTitle;
  final DateTime? issueDate;
  final String? certificateFile;
  final CertificateStatus status;
  final bool isVerified;
  final String? qrToken;
  final String? rejectionReason;
  final DateTime? createdAt;

  const Certificate({
    required this.id,
    required this.certificateId,
    required this.studentId,
    this.studentName,
    this.eventId,
    this.activityId,
    this.assignmentId,
    required this.certificateType,
    required this.activityName,
    this.duration,
    this.signatoryName,
    this.signatoryTitle,
    this.issueDate,
    this.certificateFile,
    required this.status,
    required this.isVerified,
    this.qrToken,
    this.rejectionReason,
    this.createdAt,
  });

  factory Certificate.fromJson(Map<String, dynamic> j) => Certificate(
    id: j['id'] as int,
    certificateId: j['certificate_id'] as String,
    studentId: j['student_id'] as int,
    studentName: j['student_name'] as String?,
    eventId: j['event_id'] as int?,
    activityId: j['activity_id'] as int?,
    assignmentId: j['assignment_id'] as int?,
    certificateType: CertificateType.fromString(
      j['certificate_type'] as String,
    ),
    activityName: j['activity_name'] as String,
    duration: j['duration'] as String?,
    signatoryName: j['signatory_name'] as String?,
    signatoryTitle: j['signatory_title'] as String?,
    issueDate: j['issue_date'] == null
        ? null
        : DateTime.tryParse(j['issue_date'] as String),
    certificateFile: j['certificate_file'] as String?,
    status: CertificateStatus.fromString(j['status'] as String),
    isVerified: j['is_verified'] as bool? ?? false,
    qrToken: j['qr_token'] as String?,
    rejectionReason: j['rejection_reason'] as String?,
    createdAt: j['created_at'] == null
        ? null
        : DateTime.tryParse(j['created_at'] as String),
  );
}
