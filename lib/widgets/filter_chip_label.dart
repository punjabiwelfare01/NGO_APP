import 'package:flutter/material.dart';
import '../core/colors.dart';

class FilterChipLabel extends StatelessWidget {
  const FilterChipLabel({
    required this.label,
    this.selected = false,
    super.key,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      avatar: selected ? const Icon(Icons.check_rounded, size: 18) : null,
      backgroundColor: selected ? AppColors.mint : Colors.white,
      side: BorderSide(
        color: selected ? AppColors.secondary : Colors.transparent,
      ),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
    );
  }
}
