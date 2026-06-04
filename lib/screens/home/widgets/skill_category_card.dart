import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../../../models/skill_category.dart';
import '../../../widgets/app_card.dart';

class SkillCategoryCard extends StatelessWidget {
  const SkillCategoryCard({required this.item, this.onTap, super.key});

  final SkillCategory item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AppCard(
            color: item.color,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(item.icon, size: 30, color: AppColors.ink),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.ink.withValues(alpha: 0.55),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
