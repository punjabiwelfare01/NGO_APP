import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../../../widgets/app_card.dart';

class WellnessActionCard extends StatelessWidget {
  const WellnessActionCard({
    required this.icon,
    required this.title,
    required this.color,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        color: color.withValues(alpha: color == AppColors.lavender ? 1 : 0.24),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.ink, size: 28),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
