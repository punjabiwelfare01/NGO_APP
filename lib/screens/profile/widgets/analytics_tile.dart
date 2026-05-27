import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../../../widgets/app_card.dart';

class AnalyticsTile extends StatelessWidget {
  const AnalyticsTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    super.key,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: color.withValues(alpha: 0.18),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.ink),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
