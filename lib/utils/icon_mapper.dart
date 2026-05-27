import 'package:flutter/material.dart';

class IconMapper {
  const IconMapper._();

  static IconData fromName(String name) =>
      _icons[name] ?? Icons.help_outline_rounded;

  static Color colorFromHex(String hex) =>
      Color(int.parse(hex.replaceFirst('#', '0xFF')));

  static const _icons = <String, IconData>{
    'code_rounded': Icons.code_rounded,
    'shield_rounded': Icons.shield_rounded,
    'record_voice_over_rounded': Icons.record_voice_over_rounded,
    'palette_rounded': Icons.palette_rounded,
    'music_note_rounded': Icons.music_note_rounded,
    'language_rounded': Icons.language_rounded,
    'campaign_rounded': Icons.campaign_rounded,
    'security_rounded': Icons.security_rounded,
    'bolt_rounded': Icons.bolt_rounded,
    'grid_view_rounded': Icons.grid_view_rounded,
    'extension_rounded': Icons.extension_rounded,
    'explore_rounded': Icons.explore_rounded,
    'alt_route_rounded': Icons.alt_route_rounded,
    'psychology_rounded': Icons.psychology_rounded,
    'military_tech_rounded': Icons.military_tech_rounded,
    'star_rounded': Icons.star_rounded,
    'brush_rounded': Icons.brush_rounded,
    'workspace_premium_rounded': Icons.workspace_premium_rounded,
  };
}
