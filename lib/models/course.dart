import 'package:flutter/material.dart';
import '../utils/icon_mapper.dart';

class Course {
  const Course({
    required this.title,
    required this.duration,
    required this.level,
    required this.progress,
    required this.icon,
    required this.color,
    required this.iconName,
    required this.colorHex,
    this.id = 0,
    this.categoryId,
    this.courseType = CourseType.skill,
    this.classLevel,
    this.subject,
    this.skillCategory,
    this.recommendedClassMin,
    this.recommendedClassMax,
    this.isPublished = true,
    this.lessonCount = 0,
    this.learnItems,
    this.skillTags,
    this.courseDescription,
    this.offerPrice,
    this.originalPrice,
    this.offerLabel,
  });

  final int id;
  final String title;
  final String duration;
  final String level;
  final double progress;
  final IconData icon;
  final Color color;
  final String iconName;
  final String colorHex;
  final int? categoryId;
  final String courseType;
  final String? classLevel;
  final String? subject;
  final String? skillCategory;
  final int? recommendedClassMin;
  final int? recommendedClassMax;
  final bool isPublished;
  final int lessonCount;

  // Admin-editable sales/preview card fields
  final List<String>? learnItems;
  final List<String>? skillTags;
  final String? courseDescription;
  final int? offerPrice;
  final int? originalPrice;
  final String? offerLabel;

  Course copyWith({
    List<String>? learnItems,
    List<String>? skillTags,
    String? courseDescription,
    int? offerPrice,
    int? originalPrice,
    String? offerLabel,
  }) => Course(
    id: id,
    title: title,
    duration: duration,
    level: level,
    progress: progress,
    icon: icon,
    color: color,
    iconName: iconName,
    colorHex: colorHex,
    categoryId: categoryId,
    courseType: courseType,
    classLevel: classLevel,
    subject: subject,
    skillCategory: skillCategory,
    recommendedClassMin: recommendedClassMin,
    recommendedClassMax: recommendedClassMax,
    isPublished: isPublished,
    lessonCount: lessonCount,
    learnItems: learnItems ?? this.learnItems,
    skillTags: skillTags ?? this.skillTags,
    courseDescription: courseDescription ?? this.courseDescription,
    offerPrice: offerPrice ?? this.offerPrice,
    originalPrice: originalPrice ?? this.originalPrice,
    offerLabel: offerLabel ?? this.offerLabel,
  );

  // From GET /courses or GET /courses/{id}
  factory Course.fromJson(Map<String, dynamic> j, {double progress = 0.0}) =>
      Course(
        id: j['id'] as int,
        title: _cleanCourseTitle(j['title'] as String),
        duration: j['duration'] as String,
        level: j['level'] as String,
        iconName: j['icon_name'] as String,
        colorHex: j['color_hex'] as String,
        icon: IconMapper.fromName(j['icon_name'] as String),
        color: IconMapper.colorFromHex(j['color_hex'] as String),
        progress: progress,
        categoryId: j['category_id'] as int?,
        courseType: (j['course_type'] as String?) ?? CourseType.skill,
        classLevel: j['class_level'] as String?,
        subject: j['subject'] as String?,
        skillCategory: j['skill_category'] as String?,
        recommendedClassMin: j['recommended_class_min'] as int?,
        recommendedClassMax: j['recommended_class_max'] as int?,
        isPublished: (j['is_published'] as bool?) ?? true,
        lessonCount: (j['lesson_count'] as int?) ?? 0,
        learnItems: (j['learn_items'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        skillTags: (j['skill_tags'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        courseDescription: j['course_description'] as String?,
        offerPrice: j['offer_price'] as int?,
        originalPrice: j['original_price'] as int?,
        offerLabel: j['offer_label'] as String?,
      );

  // From GET /users/{id}/courses — response includes nested course + progress
  factory Course.fromProgressJson(Map<String, dynamic> j) => Course.fromJson(
    j['course'] as Map<String, dynamic>,
    progress: (j['progress'] as num).toDouble(),
  );

  bool get isAcademic => courseType == CourseType.academic;
  bool get isSkill => !isAcademic;

  String get freeCategory {
    final text = '$title ${skillCategory ?? ''} ${skillTags?.join(' ') ?? ''}'
        .toLowerCase();
    if (text.contains('nda') || text.contains('defence')) return 'NDA';
    if (text.contains('government') ||
        text.contains('ssc') ||
        text.contains('upsc')) {
      return 'Government Exams';
    }
    if (text.contains('career') || text.contains('counsell')) {
      return 'Career Guidance';
    }
    if (text.contains('spoken english') || text.contains('english')) {
      return 'Spoken English';
    }
    if (text.contains('computer') || text.contains('digital')) {
      return 'Computer Basics';
    }
    if (text.contains('volunteer') || text.contains('donation')) {
      return 'Volunteer Training';
    }
    return 'Awareness';
  }

  String get createdBy => _tagValue('creator') ?? 'NGO Team';
  String get targetAudience => _tagValue('audience') ?? 'All students';
  String get language => _tagValue('language') ?? 'Hindi / English';
  String? get thumbnailUrl => _tagValue('thumbnail');
  bool get hasNotes =>
      skillTags?.any(
        (tag) => tag.toLowerCase() == 'notes' || tag.toLowerCase() == 'pdf',
      ) ??
      true;
  bool get hasQuiz =>
      skillTags?.any(
        (tag) =>
            tag.toLowerCase() == 'quiz' || tag.toLowerCase() == 'practice test',
      ) ??
      true;
  List<String> get subjects => (skillTags ?? const [])
      .where((tag) => tag.toLowerCase().startsWith('subject:'))
      .map((tag) => tag.substring(tag.indexOf(':') + 1).trim())
      .where((value) => value.isNotEmpty)
      .toList();

  String? _tagValue(String key) {
    final prefix = '${key.toLowerCase()}:';
    return (skillTags ?? const [])
        .where((tag) => tag.toLowerCase().startsWith(prefix))
        .map((tag) => tag.substring(tag.indexOf(':') + 1).trim())
        .where((value) => value.isNotEmpty)
        .firstOrNull;
  }

  String get audienceLabel {
    return freeCategory;
  }
}

String _cleanCourseTitle(String value) {
  final cleaned = value
      .replaceFirst(
        RegExp(r'^Class\s+(nan|\d+)\s*[:\-]?\s*', caseSensitive: false),
        '',
      )
      .trim();
  return cleaned.isEmpty ? 'Free Learning Course' : cleaned;
}

const freeCourseCategories = [
  'All',
  'NDA',
  'Government Exams',
  'Career Guidance',
  'Spoken English',
  'Computer Basics',
  'Awareness',
  'Volunteer Training',
];

class CourseType {
  const CourseType._();

  static const academic = 'academic';
  static const skill = 'skill';
}

const academicClasses = ['6', '7', '8', '9', '10', '11', '12'];

const classWiseAcademicSubjects = {
  '6': [
    'Mathematics',
    'Science',
    'English',
    'Hindi',
    'Social Science',
    'Computer',
    'Environmental Studies',
  ],
  '7': [
    'Mathematics',
    'Science',
    'English',
    'Hindi',
    'Social Science',
    'Computer',
    'Environmental Studies',
  ],
  '8': [
    'Mathematics',
    'Science',
    'English',
    'Hindi',
    'Social Science',
    'Computer',
  ],
  '9': [
    'Mathematics',
    'Science',
    'English',
    'Hindi',
    'Social Science',
    'Computer',
  ],
  '10': [
    'Mathematics',
    'Science',
    'English',
    'Hindi',
    'Social Science',
    'Computer',
  ],
  '11': [
    'English',
    'Physics',
    'Chemistry',
    'Mathematics',
    'Biology',
    'Computer Science',
    'Accountancy',
    'Economics',
    'Business Studies',
    'Political Science',
    'History',
    'Geography',
  ],
  '12': [
    'English',
    'Physics',
    'Chemistry',
    'Mathematics',
    'Biology',
    'Computer Science',
    'Accountancy',
    'Economics',
    'Business Studies',
    'Political Science',
    'History',
    'Geography',
  ],
};

List<String> academicSubjectsForClass(
  String classLevel, {
  bool includeAll = true,
}) {
  final subjects =
      classWiseAcademicSubjects[classLevel] ?? classWiseAcademicSubjects['8']!;
  return [if (includeAll) 'All', ...subjects];
}

const skillCourseCategories = [
  'All',
  'Video Editing',
  'Cyber Security',
  'Programming',
  'Python Programming',
  'Web Development',
  'App Development',
  'Animation Creation',
  'Graphic Design',
  'Digital Literacy',
  'Communication Skills',
  'Public Speaking',
  'Career Guidance',
  'Resume Building',
  'AI Basics',
  'Financial Literacy',
  'Internet Safety',
  'Computer Basics',
];

const courses = [
  Course(
    title: 'Coding Basics for Kids',
    duration: '2h 30m',
    level: 'Beginner',
    progress: 0.68,
    icon: Icons.code_rounded,
    color: Color(0xFFDDF1FF),
    iconName: 'code_rounded',
    colorHex: '#DDF1FF',
    categoryId: 0,
  ),
  Course(
    title: 'Speak with Confidence',
    duration: '1h 45m',
    level: 'Beginner',
    progress: 0.34,
    icon: Icons.campaign_rounded,
    color: Color(0xFFFFE7C8),
    iconName: 'campaign_rounded',
    colorHex: '#FFE7C8',
    categoryId: 0,
  ),
  Course(
    title: 'Internet Safety Heroes',
    duration: '3h',
    level: 'Intermediate',
    progress: 0.82,
    icon: Icons.security_rounded,
    color: Color(0xFFE0F8E8),
    iconName: 'security_rounded',
    colorHex: '#E0F8E8',
    categoryId: 0,
  ),
];
