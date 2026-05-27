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
    this.id = 0,
    this.lessonCount = 0,
  });

  final int id;
  final String title;
  final String duration;
  final String level;
  final double progress;
  final IconData icon;
  final Color color;
  final int lessonCount;

  // From GET /courses or GET /courses/{id}
  factory Course.fromJson(Map<String, dynamic> j, {double progress = 0.0}) =>
      Course(
        id: j['id'] as int,
        title: j['title'] as String,
        duration: j['duration'] as String,
        level: j['level'] as String,
        icon: IconMapper.fromName(j['icon_name'] as String),
        color: IconMapper.colorFromHex(j['color_hex'] as String),
        progress: progress,
        lessonCount: (j['lesson_count'] as int?) ?? 0,
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
  ),
  Course(
    title: 'Speak with Confidence',
    duration: '1h 45m',
    level: 'Beginner',
    progress: 0.34,
    icon: Icons.campaign_rounded,
    color: Color(0xFFFFE7C8),
  ),
  Course(
    title: 'Internet Safety Heroes',
    duration: '3h',
    level: 'Intermediate',
    progress: 0.82,
    icon: Icons.security_rounded,
    color: Color(0xFFE0F8E8),
  ),
];
