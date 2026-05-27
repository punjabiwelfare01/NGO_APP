import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../../../widgets/app_card.dart';

class ProtectionLessonCard extends StatelessWidget {
  const ProtectionLessonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.mint,
      child: Row(
        children: [
          const Icon(
            Icons.volunteer_activism_rounded,
            color: AppColors.ink,
            size: 34,
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Mindset protection lessons use stories, choices, and gentle guidance.',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }
}
