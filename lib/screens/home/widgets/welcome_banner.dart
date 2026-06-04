import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../../core/colors.dart';
import '../../../models/api_models.dart';
import '../../../widgets/app_card.dart';

class WelcomeBanner extends StatelessWidget {
  const WelcomeBanner({this.student, super.key});

  final AppUser? student;

  @override
  Widget build(BuildContext context) {
    final name = student?.name ?? AppState.studentName ?? 'Student';
    final firstName = name.split(' ').first;
    final className = student?.className;
    final school = student?.schoolName;
    final location = student?.location;

    final subtitle = [
      if (className != null) 'Class $className',
      if (school != null) school,
      if (location != null) location,
    ].join(' • ');

    return AppCard(
      color: AppColors.primary,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $firstName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const FriendlyIllustration(),
        ],
      ),
    );
  }
}

class FriendlyIllustration extends StatelessWidget {
  const FriendlyIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      height: 82,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            top: 12,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD5A6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.face_rounded, color: AppColors.ink),
            ),
          ),
          Positioned(
            bottom: 8,
            child: Container(
              width: 58,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
            ),
          ),
          Positioned(
            right: 6,
            top: 4,
            child: _BubbleDot(color: AppColors.secondary),
          ),
          Positioned(
            left: 2,
            bottom: 18,
            child: _BubbleDot(color: AppColors.mint),
          ),
        ],
      ),
    );
  }
}

class _BubbleDot extends StatelessWidget {
  const _BubbleDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
