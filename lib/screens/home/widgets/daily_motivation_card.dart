import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../../../widgets/app_card.dart';

class DailyMotivationCard extends StatelessWidget {
  const DailyMotivationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      color: AppColors.mint,
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: AppColors.ink),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Small efforts create big social impact.',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
