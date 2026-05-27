import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../../../widgets/app_card.dart';

class CounsellingHistoryCard extends StatelessWidget {
  const CounsellingHistoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Last counselling session: confidence building with Dr. Meera.',
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
