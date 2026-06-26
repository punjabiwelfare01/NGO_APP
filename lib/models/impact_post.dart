class ImpactMedia {
  const ImpactMedia({
    required this.id,
    required this.type,
    required this.url,
    this.caption,
  });
  final int id;
  final String type;
  final String url;
  final String? caption;

  factory ImpactMedia.fromJson(Map<String, dynamic> json) => ImpactMedia(
    id: json['id'] as int,
    type: json['media_type'] as String? ?? 'image',
    url: json['url'] as String,
    caption: json['caption'] as String?,
  );
}

class ImpactPost {
  const ImpactPost({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.status,
    required this.peopleReached,
    required this.donationCollected,
    required this.hoursServed,
    required this.appreciationCount,
    required this.shareCount,
    required this.appreciatedByMe,
    required this.media,
    this.eventId,
    this.activityId,
    this.certificateId,
    this.studentNames,
    this.teamName,
    this.location,
    this.partnerName,
    this.approvedBy,
    this.publishedAt,
    this.publicUrl,
  });

  final int id;
  final String category;
  final String title;
  final String description;
  final String status;
  final int? eventId;
  final int? activityId;
  final int? certificateId;
  final String? studentNames;
  final String? teamName;
  final String? location;
  final String? partnerName;
  final int peopleReached;
  final double donationCollected;
  final double hoursServed;
  final int appreciationCount;
  final int shareCount;
  final int? approvedBy;
  final DateTime? publishedAt;
  final bool appreciatedByMe;
  final String? publicUrl;
  final List<ImpactMedia> media;

  factory ImpactPost.fromJson(Map<String, dynamic> json) => ImpactPost(
    id: json['id'] as int,
    category: json['category'] as String? ?? 'achievement',
    title: json['title'] as String,
    description: json['description'] as String,
    status: json['status'] as String? ?? 'published',
    eventId: json['event_id'] as int?,
    activityId: json['activity_id'] as int?,
    certificateId: json['certificate_id'] as int?,
    studentNames: json['student_names'] as String?,
    teamName: json['team_name'] as String?,
    location: json['location'] as String?,
    partnerName: json['partner_name'] as String?,
    peopleReached: json['people_reached'] as int? ?? 0,
    donationCollected: (json['donation_collected'] as num?)?.toDouble() ?? 0,
    hoursServed: (json['hours_served'] as num?)?.toDouble() ?? 0,
    appreciationCount: json['appreciation_count'] as int? ?? 0,
    shareCount: json['share_count'] as int? ?? 0,
    approvedBy: json['approved_by'] as int?,
    publishedAt: json['published_at'] == null
        ? null
        : DateTime.tryParse(json['published_at'] as String),
    appreciatedByMe: json['appreciated_by_me'] as bool? ?? false,
    publicUrl: json['public_url'] as String?,
    media: (json['media'] as List<dynamic>? ?? const [])
        .map((item) => ImpactMedia.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}

class ImpactMetrics {
  const ImpactMetrics({
    required this.posts,
    required this.peopleReached,
    required this.donationCollected,
    required this.hoursServed,
    required this.appreciations,
    required this.shares,
  });
  final int posts;
  final int peopleReached;
  final double donationCollected;
  final double hoursServed;
  final int appreciations;
  final int shares;

  factory ImpactMetrics.fromJson(Map<String, dynamic> json) => ImpactMetrics(
    posts: json['posts'] as int? ?? 0,
    peopleReached: json['people_reached'] as int? ?? 0,
    donationCollected: (json['donation_collected'] as num?)?.toDouble() ?? 0,
    hoursServed: (json['hours_served'] as num?)?.toDouble() ?? 0,
    appreciations: json['appreciations'] as int? ?? 0,
    shares: json['shares'] as int? ?? 0,
  );
}
