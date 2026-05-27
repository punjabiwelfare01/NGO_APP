// API response models — plain Dart classes with fromJson factories.
// These map 1-to-1 with the FastAPI schemas in backend/app/schemas/.

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.age,
    required this.level,
    required this.xp,
    this.parentEmail,
  });

  final int id;
  final String name;
  final int age;
  final int level;
  final int xp;
  final String? parentEmail;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'] as int,
    name: j['name'] as String,
    age: j['age'] as int,
    level: j['level'] as int,
    xp: j['xp'] as int,
    parentEmail: j['parent_email'] as String?,
  );
}

class UserStats {
  const UserStats({
    required this.userId,
    required this.weeklyLearningHours,
    required this.skillGrowthPercent,
    required this.quizRank,
  });

  final int userId;
  final double weeklyLearningHours;
  final int skillGrowthPercent;
  final int quizRank;

  factory UserStats.fromJson(Map<String, dynamic> j) => UserStats(
    userId: j['user_id'] as int,
    weeklyLearningHours: (j['weekly_learning_hours'] as num).toDouble(),
    skillGrowthPercent: j['skill_growth_percent'] as int,
    quizRank: j['quiz_rank'] as int,
  );
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.xp,
    required this.level,
  });

  final int rank;
  final int userId;
  final String name;
  final int xp;
  final int level;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
    rank: j['rank'] as int,
    userId: j['user_id'] as int,
    name: j['name'] as String,
    xp: j['xp'] as int,
    level: j['level'] as int,
  );
}

class ApiCounsellingSession {
  const ApiCounsellingSession({
    required this.id,
    required this.counsellorName,
    required this.topic,
    required this.scheduledAt,
    required this.status,
    this.slotId,
    this.mentorId,
    this.endsAt,
    this.meetingUrl,
    this.notes,
  });

  final int id;
  final int? slotId;
  final int? mentorId;
  final String counsellorName;
  final String topic;
  final DateTime scheduledAt;
  final DateTime? endsAt;
  final String status; // upcoming | completed | cancelled
  final String? meetingUrl;
  final String? notes;

  bool get isUpcoming => status == 'upcoming';
  bool get hasMeetingLink => meetingUrl != null && meetingUrl!.isNotEmpty;

  /// Returns a human-readable time like "Today, 5:00 PM" or "23/6, 3:30 PM".
  String get formattedTime {
    final now = DateTime.now();
    final isToday =
        scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
    final h = scheduledAt.hour % 12 == 0 ? 12 : scheduledAt.hour % 12;
    final m = scheduledAt.minute.toString().padLeft(2, '0');
    final ampm = scheduledAt.hour < 12 ? 'AM' : 'PM';
    final day = isToday ? 'Today' : '${scheduledAt.day}/${scheduledAt.month}';
    return '$day, $h:$m $ampm';
  }

  factory ApiCounsellingSession.fromJson(Map<String, dynamic> j) =>
      ApiCounsellingSession(
        id: j['id'] as int,
        slotId: j['slot_id'] as int?,
        mentorId: j['mentor_id'] as int?,
        counsellorName: j['counsellor_name'] as String,
        topic: j['topic'] as String,
        scheduledAt: DateTime.parse(j['scheduled_at'] as String),
        endsAt: j['ends_at'] != null
            ? DateTime.tryParse(j['ends_at'] as String)
            : null,
        status: j['status'] as String,
        meetingUrl: j['meeting_url'] as String?,
        notes: j['notes'] as String?,
      );
}

class ApiCounsellingSlot {
  const ApiCounsellingSlot({
    required this.id,
    required this.mentorId,
    required this.mentorName,
    required this.startsAt,
    required this.endsAt,
    required this.capacity,
    required this.bookedCount,
    required this.availableCount,
    required this.isActive,
    required this.isAvailable,
    this.topic,
    this.meetingUrl,
  });

  final int id;
  final int mentorId;
  final String mentorName;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? topic;
  final int capacity;
  final int bookedCount;
  final int availableCount;
  final String? meetingUrl;
  final bool isActive;
  final bool isAvailable;

  bool get hasMeetingLink => meetingUrl != null && meetingUrl!.isNotEmpty;

  String get formattedTime {
    final h = startsAt.hour % 12 == 0 ? 12 : startsAt.hour % 12;
    final m = startsAt.minute.toString().padLeft(2, '0');
    final ampm = startsAt.hour < 12 ? 'AM' : 'PM';
    return '${startsAt.day}/${startsAt.month}, $h:$m $ampm';
  }

  factory ApiCounsellingSlot.fromJson(Map<String, dynamic> j) =>
      ApiCounsellingSlot(
        id: j['id'] as int,
        mentorId: j['mentor_id'] as int,
        mentorName: j['mentor_name'] as String,
        startsAt: DateTime.parse(j['starts_at'] as String),
        endsAt: DateTime.parse(j['ends_at'] as String),
        topic: j['topic'] as String?,
        capacity: j['capacity'] as int,
        bookedCount: j['booked_count'] as int,
        availableCount: j['available_count'] as int,
        meetingUrl: j['meeting_url'] as String?,
        isActive: j['is_active'] as bool,
        isAvailable: j['is_available'] as bool,
      );
}

class ApiBadge {
  const ApiBadge({
    required this.id,
    required this.iconName,
    required this.label,
    required this.category,
  });

  final int id;
  final String iconName;
  final String label;
  final String category;

  factory ApiBadge.fromJson(Map<String, dynamic> j) => ApiBadge(
    id: j['id'] as int,
    iconName: j['icon_name'] as String,
    label: j['label'] as String,
    category: j['category'] as String,
  );
}

class UserBadge {
  const UserBadge({
    required this.id,
    required this.badgeId,
    required this.earnedAt,
    required this.badge,
  });

  final int id;
  final int badgeId;
  final DateTime earnedAt;
  final ApiBadge badge;

  factory UserBadge.fromJson(Map<String, dynamic> j) => UserBadge(
    id: j['id'] as int,
    badgeId: j['badge_id'] as int,
    earnedAt: DateTime.parse(j['earned_at'] as String),
    badge: ApiBadge.fromJson(j['badge'] as Map<String, dynamic>),
  );
}
