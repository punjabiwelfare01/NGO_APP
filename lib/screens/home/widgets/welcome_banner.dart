import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../../../widgets/app_card.dart';

class WelcomeBanner extends StatelessWidget {
  const WelcomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.primary,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Learn - Grow - Stay Safe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your friendly NGO learning space for skills, counselling, and safer choices.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Continue'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
      width: 104,
      height: 126,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            top: 20,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD5A6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.face_rounded, color: AppColors.ink),
            ),
          ),
          Positioned(
            bottom: 16,
            child: Container(
              width: 74,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white),
            ),
          ),
          Positioned(
            right: 10,
            top: 8,
            child: _BubbleDot(color: AppColors.secondary),
          ),
          Positioned(
            left: 4,
            bottom: 24,
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
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
