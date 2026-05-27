import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../../../widgets/app_card.dart';

class ParentPreviewPanel extends StatelessWidget {
  const ParentPreviewPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Row(
        children: [
          Icon(Icons.family_restroom_rounded, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Parent view: progress, counselling history, and learning time.',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
