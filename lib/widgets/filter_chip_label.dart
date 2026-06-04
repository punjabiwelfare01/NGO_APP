import 'package:flutter/material.dart';
import '../core/colors.dart';

class FilterChipLabel extends StatelessWidget {
  const FilterChipLabel({
    required this.label,
    this.selected = false,
    this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (onTap != null) {
      return FilterChip(
        label: Text(label),
        selected: selected,
        avatar: selected ? const Icon(Icons.check_rounded, size: 18) : null,
        onSelected: (_) => onTap?.call(),
        backgroundColor: Colors.white,
        selectedColor: AppColors.mint,
        side: BorderSide(
          color: selected ? AppColors.secondary : Colors.transparent,
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      );
    }
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
