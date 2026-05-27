import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/api_models.dart';
import '../../../widgets/app_card.dart';

class ProfileHeroCard extends StatelessWidget {
  const ProfileHeroCard({this.user, super.key});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'Loading…';
    final subtitle = user != null
        ? 'Age ${user!.age} · Level ${user!.level} Learner'
        : '';
    final xpLabel = user != null ? '${user!.xp} XP' : '';

    return AppCard(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.face_rounded, color: Colors.white, size: 42),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(color: AppColors.muted)),
                ],
                if (xpLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    xpLabel,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.workspace_premium_rounded, color: AppColors.accent),
        ],
      ),
    );
  }
}
