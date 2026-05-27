import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../../../widgets/app_card.dart';

class CourseDetailPreview extends StatelessWidget {
  const CourseDetailPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      color: AppColors.lavender,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Detail',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              CourseTab(label: 'Videos', icon: Icons.play_circle_rounded),
              CourseTab(label: 'Notes', icon: Icons.notes_rounded),
              CourseTab(label: 'Quiz', icon: Icons.quiz_rounded),
              CourseTab(
                label: 'Certificate',
                icon: Icons.workspace_premium_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CourseTab extends StatelessWidget {
  const CourseTab({required this.label, required this.icon, super.key});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.ink),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
