import 'package:flutter/material.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum CounsellorCategory {
  retiredArmyOfficer(
    'Retired Army Officer Counsellor',
    Icons.military_tech_rounded,
    Color(0xFF1565C0),
    'Defence / NDA Guidance',
  ),
  retiredAirForceOfficer(
    'Retired Air Force Officer Counsellor',
    Icons.flight_rounded,
    Color(0xFF0277BD),
    'Defence / NDA Guidance',
  ),
  defenceCareerMentor(
    'Defence Career Guidance Mentor',
    Icons.shield_rounded,
    Color(0xFF1B5E20),
    'Career Guidance',
  ),
  governmentOfficerMentor(
    'Government Officer Mentor',
    Icons.account_balance_rounded,
    Color(0xFF4527A0),
    'Government Mentor',
  ),
  educationCounsellor(
    'Education Counsellor',
    Icons.school_rounded,
    Color(0xFF00695C),
    'Career Guidance',
  ),
  careerGuidanceCounsellor(
    'Career Guidance Counsellor',
    Icons.trending_up_rounded,
    Color(0xFF2E7D32),
    'Career Guidance',
  ),
  mentalWellnessCounsellor(
    'Mental Wellness Counsellor',
    Icons.favorite_rounded,
    Color(0xFFC62828),
    'Mental Wellness',
  ),
  cyberSafetySpeaker(
    'Cyber Safety Awareness Speaker',
    Icons.security_rounded,
    Color(0xFF0288D1),
    'Cyber Safety',
  ),
  antiDrugSpeaker(
    'Anti-Drug Awareness Speaker',
    Icons.health_and_safety_rounded,
    Color(0xFFE65100),
    'Anti-Drug Awareness',
  ),
  womenSafetySpeaker(
    'Women Safety Awareness Speaker',
    Icons.woman_rounded,
    Color(0xFF880E4F),
    'Women Safety',
  );

  const CounsellorCategory(this.label, this.icon, this.color, this.filterTag);
  final String label;
  final IconData icon;
  final Color color;
  final String filterTag;

  static CounsellorCategory? fromLabel(String label) {
    for (final v in values) {
      if (v.label == label) return v;
    }
    return null;
  }
}

enum SessionMode {
  online('Online', Icons.videocam_rounded, Color(0xFF1565C0)),
  offline('Offline', Icons.location_on_rounded, Color(0xFF2E7D32)),
  both('Online & Offline', Icons.swap_horiz_rounded, Color(0xFF6A1B9A));

  const SessionMode(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;

  static SessionMode fromString(String s) =>
      values.firstWhere((v) => v.name == s, orElse: () => SessionMode.both);
}

enum VerificationStatus {
  pending('Pending Verification', Color(0xFFF57F17), Icons.pending_rounded),
  verified('Verified', Color(0xFF2E7D32), Icons.verified_rounded),
  rejected('Rejected', Color(0xFFC62828), Icons.cancel_rounded);

  const VerificationStatus(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

enum RequestStatus {
  pending('Pending Review', Color(0xFFF57F17)),
  reviewed('Under Review', Color(0xFF1565C0)),
  assigned('Counsellor Assigned', Color(0xFF6A1B9A)),
  confirmed('Confirmed', Color(0xFF2E7D32)),
  completed('Completed', Color(0xFF00695C)),
  cancelled('Cancelled', Color(0xFFC62828));

  const RequestStatus(this.label, this.color);
  final String label;
  final Color color;
}

// ─── Counsellor Profile ───────────────────────────────────────────────────────

class CounsellorProfile {
  const CounsellorProfile({
    required this.id,
    required this.ngoVerificationId,
    required this.name,
    required this.category,
    required this.designation,
    required this.serviceBackground,
    required this.shortBio,
    required this.qualifications,
    required this.expertiseAreas,
    required this.sessionTopics,
    required this.languages,
    required this.sessionMode,
    required this.availableSlots,
    required this.yearsOfExperience,
    required this.schoolSessionsCompleted,
    required this.studentsGuided,
    required this.recognitionProof,
    required this.verificationStatus,
    this.phone,
    this.location,
    this.photoUrl,
    this.isRetired = false,
    this.showRetiredStatus = false,
    this.isFeatured = false,
    this.isActive = true,
    this.appreciationDocuments = const [],
    this.availableThisWeek = false,
  });

  final int id;

  /// Privacy-safe internal NGO ID — e.g. PWT-COUN-2026-001. Never a government/army ID.
  final String ngoVerificationId;
  final String name;
  final String? photoUrl;
  final String? phone;
  final String? location;
  final CounsellorCategory category;
  final String designation;
  final String serviceBackground;
  final String shortBio;

  /// Only shown publicly when document is verified AND counsellor has given consent.
  final bool isRetired;
  final bool showRetiredStatus;
  final List<String> qualifications;
  final List<String> expertiseAreas;
  final List<String> sessionTopics;
  final List<String> languages;
  final SessionMode sessionMode;
  final List<String> availableSlots;
  final int yearsOfExperience;
  final int schoolSessionsCompleted;
  final int studentsGuided;

  /// Approved appreciation letters / recognition — safe for public display.
  final List<String> recognitionProof;
  final List<String> appreciationDocuments;
  final VerificationStatus verificationStatus;
  final bool isFeatured;
  final bool isActive;
  final bool availableThisWeek;

  bool get isVerified => verificationStatus == VerificationStatus.verified;

  CounsellorProfile copyWith({
    String? photoUrl,
    String? phone,
    String? location,
    CounsellorCategory? category,
    String? designation,
    String? serviceBackground,
    String? shortBio,
    List<String>? qualifications,
    List<String>? expertiseAreas,
    List<String>? sessionTopics,
    List<String>? languages,
    SessionMode? sessionMode,
    List<String>? availableSlots,
    VerificationStatus? verificationStatus,
    bool? isRetired,
    bool? showRetiredStatus,
    bool? isFeatured,
    bool? isActive,
    bool? availableThisWeek,
  }) => CounsellorProfile(
    id: id,
    ngoVerificationId: ngoVerificationId,
    name: name,
    photoUrl: photoUrl ?? this.photoUrl,
    phone: phone ?? this.phone,
    location: location ?? this.location,
    category: category ?? this.category,
    designation: designation ?? this.designation,
    serviceBackground: serviceBackground ?? this.serviceBackground,
    shortBio: shortBio ?? this.shortBio,
    qualifications: qualifications ?? this.qualifications,
    expertiseAreas: expertiseAreas ?? this.expertiseAreas,
    sessionTopics: sessionTopics ?? this.sessionTopics,
    languages: languages ?? this.languages,
    sessionMode: sessionMode ?? this.sessionMode,
    availableSlots: availableSlots ?? this.availableSlots,
    yearsOfExperience: yearsOfExperience,
    schoolSessionsCompleted: schoolSessionsCompleted,
    studentsGuided: studentsGuided,
    recognitionProof: recognitionProof,
    appreciationDocuments: appreciationDocuments,
    verificationStatus: verificationStatus ?? this.verificationStatus,
    isRetired: isRetired ?? this.isRetired,
    showRetiredStatus: showRetiredStatus ?? this.showRetiredStatus,
    isFeatured: isFeatured ?? this.isFeatured,
    isActive: isActive ?? this.isActive,
    availableThisWeek: availableThisWeek ?? this.availableThisWeek,
  );

  factory CounsellorProfile.fromMentorJson(Map<String, dynamic> json) {
    final userId = json['user_id'] as int;
    final categoryStr = json['category'] as String? ?? '';
    final category =
        CounsellorCategory.fromLabel(categoryStr) ??
        CounsellorCategory.educationCounsellor;
    final bio = json['bio'] as String? ?? '';
    final expertise = json['expertise'] as String? ?? '';
    final isActive = json['is_active'] as bool? ?? true;
    final sessionCount = json['session_count'] as int? ?? 0;

    // Extended fields returned from the enriched mentor endpoint
    final qualification = json['qualification'] as String? ?? '';
    final yoe = (json['years_of_experience'] as num?)?.toInt() ?? 0;
    final counsellingMode = json['counselling_mode'] as String? ?? 'both';
    final languagesKnown = json['languages_known'] as String? ?? '';
    final weeklyAvailability =
        (json['weekly_availability'] as List<dynamic>?)
            ?.cast<String>() ??
        const [];

    List<String> splitCsv(String raw) => raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final qualList = qualification.isNotEmpty ? splitCsv(qualification) : const <String>[];
    final expertiseList = expertise.isNotEmpty ? splitCsv(expertise) : const <String>[];
    final langList = languagesKnown.isNotEmpty ? splitCsv(languagesKnown) : const <String>[];

    return CounsellorProfile(
      id: userId,
      ngoVerificationId: 'PWT-COUN-$userId',
      name: json['display_name'] as String? ?? 'PWT Counsellor',
      photoUrl: json['profile_image_url'] as String?,
      phone: json['phone'] as String?,
      location: json['location'] as String?,
      category: category,
      designation: category.label,
      serviceBackground: bio,
      shortBio: bio,
      qualifications: qualList,
      expertiseAreas: expertiseList,
      sessionTopics: const [],
      languages: langList.isNotEmpty ? langList : const ['English'],
      sessionMode: SessionMode.fromString(counsellingMode),
      availableSlots: weeklyAvailability,
      yearsOfExperience: yoe,
      schoolSessionsCompleted: sessionCount,
      studentsGuided: sessionCount * 30,
      recognitionProof: const [],
      appreciationDocuments: const [],
      verificationStatus: isActive
          ? VerificationStatus.verified
          : VerificationStatus.pending,
      isActive: isActive,
      isFeatured: json['featured'] as bool? ?? false,
      isRetired: false,
      showRetiredStatus: false,
      availableThisWeek: weeklyAvailability.isNotEmpty,
    );
  }

  /// Public label — e.g. "Retired" only when doc verified + consent given.
  String get publicStatusLabel {
    if (!showRetiredStatus) return '';
    return isRetired ? 'Retired' : 'Serving';
  }

  String get initialsAvatar {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'C';
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final first = parts.first;
    return first.substring(0, first.length >= 2 ? 2 : 1).toUpperCase();
  }
}

// ─── Counselling Request ──────────────────────────────────────────────────────

class CounsellingRequest {
  const CounsellingRequest({
    required this.id,
    required this.counsellorId,
    required this.counsellorName,
    required this.counsellorCategory,
    required this.schoolName,
    required this.principalName,
    required this.schoolEmail,
    required this.topic,
    required this.preferredDate,
    required this.sessionMode,
    required this.studentCount,
    required this.gradeLevel,
    required this.status,
    required this.requestedAt,
    this.principalPhone = '',
    this.schoolAddress = '',
    this.specialRequirements = '',
    this.assignedVolunteers = const [],
    this.eventManagerNotes = '',
    this.confirmedAt,
  });

  final int id;
  final int counsellorId;
  final String counsellorName;
  final CounsellorCategory counsellorCategory;
  final String schoolName;
  final String principalName;
  final String principalPhone;
  final String schoolEmail;
  final String schoolAddress;
  final String topic;
  final DateTime preferredDate;
  final SessionMode sessionMode;
  final int studentCount;
  final String gradeLevel;
  final String specialRequirements;
  final RequestStatus status;
  final DateTime requestedAt;
  final List<String> assignedVolunteers;
  final String eventManagerNotes;
  final DateTime? confirmedAt;

  CounsellingRequest copyWith({
    RequestStatus? status,
    String? eventManagerNotes,
    List<String>? assignedVolunteers,
    DateTime? confirmedAt,
    int? counsellorId,
    String? counsellorName,
    CounsellorCategory? counsellorCategory,
    DateTime? preferredDate,
  }) => CounsellingRequest(
    id: id,
    counsellorId: counsellorId ?? this.counsellorId,
    counsellorName: counsellorName ?? this.counsellorName,
    counsellorCategory: counsellorCategory ?? this.counsellorCategory,
    schoolName: schoolName,
    principalName: principalName,
    principalPhone: principalPhone,
    schoolEmail: schoolEmail,
    schoolAddress: schoolAddress,
    topic: topic,
    preferredDate: preferredDate ?? this.preferredDate,
    sessionMode: sessionMode,
    studentCount: studentCount,
    gradeLevel: gradeLevel,
    specialRequirements: specialRequirements,
    status: status ?? this.status,
    requestedAt: requestedAt,
    assignedVolunteers: assignedVolunteers ?? this.assignedVolunteers,
    eventManagerNotes: eventManagerNotes ?? this.eventManagerNotes,
    confirmedAt: confirmedAt ?? this.confirmedAt,
  );
}

// ─── Filter State ─────────────────────────────────────────────────────────────

class CounsellorFilter {
  const CounsellorFilter({
    this.category,
    this.sessionMode,
    this.language,
    this.availableThisWeek = false,
    this.featuredOnly = false,
    this.searchQuery = '',
  });

  final CounsellorCategory? category;
  final SessionMode? sessionMode;
  final String? language;
  final bool availableThisWeek;
  final bool featuredOnly;
  final String searchQuery;

  CounsellorFilter copyWith({
    CounsellorCategory? category,
    bool clearCategory = false,
    SessionMode? sessionMode,
    bool clearMode = false,
    String? language,
    bool clearLanguage = false,
    bool? availableThisWeek,
    bool? featuredOnly,
    String? searchQuery,
  }) => CounsellorFilter(
    category: clearCategory ? null : (category ?? this.category),
    sessionMode: clearMode ? null : (sessionMode ?? this.sessionMode),
    language: clearLanguage ? null : (language ?? this.language),
    availableThisWeek: availableThisWeek ?? this.availableThisWeek,
    featuredOnly: featuredOnly ?? this.featuredOnly,
    searchQuery: searchQuery ?? this.searchQuery,
  );

  bool get hasActiveFilter =>
      category != null ||
      sessionMode != null ||
      language != null ||
      availableThisWeek ||
      featuredOnly ||
      searchQuery.isNotEmpty;
}
