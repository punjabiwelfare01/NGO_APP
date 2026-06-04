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
        title: j['title'] as String,
        duration: j['duration'] as String,
        level: j['level'] as String,
        iconName: j['icon_name'] as String,
        colorHex: j['color_hex'] as String,
        icon: IconMapper.fromName(j['icon_name'] as String),
        color: IconMapper.colorFromHex(j['color_hex'] as String),
        progress: progress,
        categoryId: j['category_id'] as int?,
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
}

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
