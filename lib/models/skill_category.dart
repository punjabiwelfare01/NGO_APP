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
  SkillCategory(
    'Communication Skill',
    Icons.record_voice_over_rounded,
    Color(0xFFFFE7C8),
  ),
  SkillCategory('Digital Literacy', Icons.devices_rounded, Color(0xFFDDF1FF)),
  SkillCategory('Career Guidance', Icons.explore_rounded, Color(0xFFE9E2FF)),
  SkillCategory('Safety Awareness', Icons.shield_rounded, Color(0xFFE0F8E8)),
  SkillCategory(
    'Financial Literacy',
    Icons.account_balance_wallet_rounded,
    Color(0xFFFFF3D0),
  ),
];
