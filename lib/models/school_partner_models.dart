class SchoolStats {
  const SchoolStats({
    required this.studentsCounselled,
    required this.counsellingSessions,
    required this.awarenessPrograms,
    required this.successStories,
  });

  final int studentsCounselled;
  final int counsellingSessions;
  final int awarenessPrograms;
  final int successStories;

  factory SchoolStats.fromJson(Map<String, dynamic> j) => SchoolStats(
        studentsCounselled: j['students_counselled'] as int? ?? 0,
        counsellingSessions: j['counselling_sessions'] as int? ?? 0,
        awarenessPrograms: j['awareness_programs'] as int? ?? 0,
        successStories: j['success_stories'] as int? ?? 0,
      );

  static const empty = SchoolStats(
    studentsCounselled: 0,
    counsellingSessions: 0,
    awarenessPrograms: 0,
    successStories: 0,
  );
}

class SchoolPartnerProfile {
  const SchoolPartnerProfile({
    required this.id,
    this.schoolName,
    this.schoolType,
    this.schoolBoard,
    this.registrationNumber,
    this.coordinatorName,
    this.coordinatorDesignation,
    this.phone,
    this.alternatePhone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pinCode,
    this.photoUrl,
    this.accessStatus,
    this.partnerId,
    this.verificationNote,
    this.joinedDate,
  });

  final int id;
  final String? schoolName;
  final String? schoolType;
  final String? schoolBoard;
  final String? registrationNumber;
  final String? coordinatorName;
  final String? coordinatorDesignation;
  final String? phone;
  final String? alternatePhone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pinCode;
  final String? photoUrl;
  final String? accessStatus;
  final String? partnerId;
  final String? verificationNote;
  final DateTime? joinedDate;

  factory SchoolPartnerProfile.fromJson(Map<String, dynamic> j) {
    return SchoolPartnerProfile(
      id: j['id'] as int? ?? 0,
      schoolName: j['school_name'] as String?,
      schoolType: j['school_type'] as String?,
      schoolBoard: j['school_board'] as String?,
      registrationNumber: j['registration_number'] as String?,
      coordinatorName: j['name'] as String?,
      coordinatorDesignation: j['coordinator_designation'] as String?,
      phone: j['phone'] as String?,
      alternatePhone: j['alternate_phone'] as String?,
      email: j['email'] as String?,
      address: j['address'] as String?,
      city: j['city'] as String?,
      state: j['state'] as String?,
      pinCode: j['pin_code'] as String?,
      photoUrl: j['photo_url'] as String?,
      accessStatus: j['access_status'] as String?,
      partnerId: j['partner_id'] as String?,
      verificationNote: j['verification_note'] as String?,
      joinedDate: j['joined_date'] != null
          ? DateTime.tryParse(j['joined_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      if (coordinatorName != null) 'name': coordinatorName,
      if (schoolName != null) 'school_name': schoolName,
      if (schoolType != null) 'school_type': schoolType,
      if (schoolBoard != null) 'school_board': schoolBoard,
      if (registrationNumber != null) 'registration_number': registrationNumber,
      if (coordinatorDesignation != null)
        'coordinator_designation': coordinatorDesignation,
      if (phone != null) 'phone': phone,
      if (alternatePhone != null) 'alternate_phone': alternatePhone,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (pinCode != null) 'pin_code': pinCode,
    };
  }

  SchoolPartnerProfile copyWith({
    String? schoolName,
    String? schoolType,
    String? schoolBoard,
    String? registrationNumber,
    String? coordinatorName,
    String? coordinatorDesignation,
    String? phone,
    String? alternatePhone,
    String? address,
    String? city,
    String? state,
    String? pinCode,
    String? photoUrl,
  }) {
    return SchoolPartnerProfile(
      id: id,
      schoolName: schoolName ?? this.schoolName,
      schoolType: schoolType ?? this.schoolType,
      schoolBoard: schoolBoard ?? this.schoolBoard,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      coordinatorName: coordinatorName ?? this.coordinatorName,
      coordinatorDesignation:
          coordinatorDesignation ?? this.coordinatorDesignation,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      email: email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      photoUrl: photoUrl ?? this.photoUrl,
      accessStatus: accessStatus,
      partnerId: partnerId,
      verificationNote: verificationNote,
      joinedDate: joinedDate,
    );
  }

  /// Initial letter(s) for the avatar fallback.
  String get initials {
    final n = schoolName ?? coordinatorName ?? 'S';
    final parts = n.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return n.substring(0, n.length >= 2 ? 2 : 1).toUpperCase();
  }
}
