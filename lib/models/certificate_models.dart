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
  downloaded,
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
    downloaded        => 'Downloaded',
    revoked           => 'Revoked',
  };

  bool get canGeneratePdf =>
      this == approved || this == issued || this == generated || this == downloaded;

  bool get canDownload =>
      this == generated || this == issued || this == downloaded;

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
  // Extended detail fields
  final String? studentIdNumber;
  final String? studentRole;
  final String? eventName;
  final String? programName;
  final String? workDescription;
  final double? serviceHours;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? signatoryName;
  final String? signatoryTitle;
  final String? signatureUrl;
  final String? logoUrl;
  final String? remarks;
  final String? impactStorySummary;
  final int? impactStoryId;
  // Status/verification fields
  final DateTime? issueDate;
  final String? certificateFile;
  final String? pdfUrl;
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
    this.studentIdNumber,
    this.studentRole,
    this.eventName,
    this.programName,
    this.workDescription,
    this.serviceHours,
    this.startDate,
    this.endDate,
    this.signatoryName,
    this.signatoryTitle,
    this.signatureUrl,
    this.logoUrl,
    this.remarks,
    this.impactStorySummary,
    this.impactStoryId,
    this.issueDate,
    this.certificateFile,
    this.pdfUrl,
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
    certificateType: CertificateType.fromString(j['certificate_type'] as String),
    activityName: j['activity_name'] as String,
    duration: j['duration'] as String?,
    studentIdNumber: j['student_id_number'] as String?,
    studentRole: j['student_role'] as String?,
    eventName: j['event_name'] as String?,
    programName: j['program_name'] as String?,
    workDescription: j['work_description'] as String?,
    serviceHours: (j['service_hours'] as num?)?.toDouble(),
    startDate: j['start_date'] == null ? null : DateTime.tryParse(j['start_date'] as String),
    endDate: j['end_date'] == null ? null : DateTime.tryParse(j['end_date'] as String),
    signatoryName: j['signatory_name'] as String?,
    signatoryTitle: j['signatory_title'] as String?,
    signatureUrl: j['signature_url'] as String?,
    logoUrl: j['logo_url'] as String?,
    remarks: j['remarks'] as String?,
    impactStorySummary: j['impact_story_summary'] as String?,
    impactStoryId: j['impact_story_id'] as int?,
    issueDate: j['issue_date'] == null
        ? null
        : DateTime.tryParse(j['issue_date'] as String),
    certificateFile: j['certificate_file'] as String?,
    pdfUrl: j['pdf_url'] as String?,
    status: CertificateStatus.fromString(j['status'] as String),
    isVerified: j['is_verified'] as bool? ?? false,
    qrToken: j['qr_token'] as String?,
    rejectionReason: j['rejection_reason'] as String?,
    createdAt: j['created_at'] == null
        ? null
        : DateTime.tryParse(j['created_at'] as String),
  );

  Certificate copyWith({
    String? studentIdNumber,
    String? studentRole,
    String? eventName,
    String? programName,
    String? workDescription,
    double? serviceHours,
    DateTime? startDate,
    DateTime? endDate,
    String? signatoryName,
    String? signatoryTitle,
    String? signatureUrl,
    String? logoUrl,
    String? remarks,
    String? impactStorySummary,
    DateTime? issueDate,
    CertificateType? certificateType,
    String? activityName,
    String? duration,
  }) => Certificate(
    id: id,
    certificateId: certificateId,
    studentId: studentId,
    studentName: studentName,
    eventId: eventId,
    activityId: activityId,
    assignmentId: assignmentId,
    certificateType: certificateType ?? this.certificateType,
    activityName: activityName ?? this.activityName,
    duration: duration ?? this.duration,
    studentIdNumber: studentIdNumber ?? this.studentIdNumber,
    studentRole: studentRole ?? this.studentRole,
    eventName: eventName ?? this.eventName,
    programName: programName ?? this.programName,
    workDescription: workDescription ?? this.workDescription,
    serviceHours: serviceHours ?? this.serviceHours,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    signatoryName: signatoryName ?? this.signatoryName,
    signatoryTitle: signatoryTitle ?? this.signatoryTitle,
    signatureUrl: signatureUrl ?? this.signatureUrl,
    logoUrl: logoUrl ?? this.logoUrl,
    remarks: remarks ?? this.remarks,
    impactStorySummary: impactStorySummary ?? this.impactStorySummary,
    impactStoryId: impactStoryId,
    issueDate: issueDate ?? this.issueDate,
    certificateFile: certificateFile,
    pdfUrl: pdfUrl,
    status: status,
    isVerified: isVerified,
    qrToken: qrToken,
    rejectionReason: rejectionReason,
    createdAt: createdAt,
  );
}
