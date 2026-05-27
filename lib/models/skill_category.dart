import 'package:flutter/material.dart';
import '../utils/icon_mapper.dart';

class SkillCategory {
  const SkillCategory(this.title, this.icon, this.color, {this.id = 0});

  final int id;
  final String title;
  final IconData icon;
  final Color color;

  factory SkillCategory.fromJson(Map<String, dynamic> j) => SkillCategory(
        j['title'] as String,
        IconMapper.fromName(j['icon_name'] as String),
        IconMapper.colorFromHex(j['color_hex'] as String),
        id: j['id'] as int,
      );
}

const skillCategories = [
  SkillCategory('Coding', Icons.code_rounded, Color(0xFFDDF1FF)),
  SkillCategory('Cyber Safety', Icons.shield_rounded, Color(0xFFE0F8E8)),
  SkillCategory(
    'Communication',
    Icons.record_voice_over_rounded,
    Color(0xFFFFE7C8),
  ),
  SkillCategory('Art', Icons.palette_rounded, Color(0xFFE9E2FF)),
  SkillCategory('Music', Icons.music_note_rounded, Color(0xFFFFDCDC)),
  SkillCategory('Languages', Icons.language_rounded, Color(0xFFDDF7F4)),
];
