import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../../../models/skill_category.dart';
import '../../../widgets/app_card.dart';

class SkillCategoryCard extends StatelessWidget {
  const SkillCategoryCard({required this.item, super.key});

  final SkillCategory item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      child: AppCard(
        color: item.color,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.icon, size: 30, color: AppColors.ink),
            const Spacer(),
            Text(
              item.title,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
