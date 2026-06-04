import 'creator_content.dart';

enum CreatorPostType {
  learningPost('learning_post', 'Learning Post'),
  ngoEventPost('ngo_event_post', 'NGO Event Post'),
  announcement('announcement', 'Announcement'),
  awarenessPost('awareness_post', 'Awareness Post'),
  motivationPost('motivation_post', 'Motivation Post');

  const CreatorPostType(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

enum CreatorPostVisibility {
  allStudents('all_students', 'All Students'),
  specificCourseStudents(
    'specific_course_students',
    'Specific Course Students',
  ),
  eventRegisteredStudents(
    'event_registered_students',
    'Event Registered Students',
  ),
  mentorsOnly('mentors_only', 'Mentors Only'),
  publicFeed('public_feed', 'Public Feed');

  const CreatorPostVisibility(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

enum CreatorPostStatus {
  draft('draft', 'Draft'),
  pendingReview('pending_review', 'Submit for Review'),
  published('published', 'Published');

  const CreatorPostStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

const creatorPostCategories = [
  'Communication Skill',
  'Digital Literacy',
  'Career Guidance',
  'Safety Awareness',
  'Financial Literacy',
  'Counselling',
  'NGO Activity',
  'Event Update',
];

class CreatorPostDraft {
  const CreatorPostDraft({
    required this.postType,
    required this.title,
    required this.description,
    required this.category,
    required this.visibility,
    required this.status,
    this.imageUrl,
    this.attachedCourseId,
    this.attachedEventId,
    this.attachedQuizId,
  });

  final CreatorPostType postType;
  final String title;
  final String description;
  final String category;
  final CreatorPostVisibility visibility;
  final CreatorPostStatus status;
  final String? imageUrl;
  final int? attachedCourseId;
  final int? attachedEventId;
  final int? attachedQuizId;

  Map<String, dynamic> toJson() => {
    'post_type': postType.apiValue,
    'title': title,
    'description': description,
    'category': category,
    'visibility': visibility.apiValue,
    'status': status.apiValue,
    'image_url': imageUrl,
    'attached_course_id': attachedCourseId,
    'attached_event_id': attachedEventId,
    'attached_quiz_id': attachedQuizId,
  };
}

typedef CreatorPostItem = CreatorContentItem;
