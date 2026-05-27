class MentorProfile {
  const MentorProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    this.bio,
    this.expertise,
    this.category,
    this.profileImageUrl,
    required this.isActive,
    required this.rating,
    required this.sessionCount,
  });

  final int id;
  final int userId;
  final String displayName;
  final String? bio;
  final String? expertise;
  final String? category;
  final String? profileImageUrl;
  final bool isActive;
  final double rating;
  final int sessionCount;

  factory MentorProfile.fromJson(Map<String, dynamic> j) => MentorProfile(
        id: j['id'] as int,
        userId: j['user_id'] as int,
        displayName: j['display_name'] as String,
        bio: j['bio'] as String?,
        expertise: j['expertise'] as String?,
        category: j['category'] as String?,
        profileImageUrl: j['profile_image_url'] as String?,
        isActive: j['is_active'] as bool? ?? true,
        rating: (j['rating'] as num?)?.toDouble() ?? 0.0,
        sessionCount: j['session_count'] as int? ?? 0,
      );
}

class CounsellingAnalytics {
  const CounsellingAnalytics({
    required this.totalMentors,
    required this.activeMentors,
    required this.totalBookings,
    required this.upcomingBookings,
    required this.completedSessions,
  });

  final int totalMentors;
  final int activeMentors;
  final int totalBookings;
  final int upcomingBookings;
  final int completedSessions;

  factory CounsellingAnalytics.fromJson(Map<String, dynamic> j) =>
      CounsellingAnalytics(
        totalMentors: j['total_mentors'] as int? ?? 0,
        activeMentors: j['active_mentors'] as int? ?? 0,
        totalBookings: j['total_bookings'] as int? ?? 0,
        upcomingBookings: j['upcoming_bookings'] as int? ?? 0,
        completedSessions: j['completed_sessions'] as int? ?? 0,
      );
}
