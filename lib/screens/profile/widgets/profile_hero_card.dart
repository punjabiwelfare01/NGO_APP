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
    final age = user?.age;
    final className = user?.className;
    final school = user?.schoolName;
    final location = user?.location;

    final schoolLine = [
      if (className != null) 'Class $className',
      if (school != null) school,
      if (location != null) location,
    ].join(' • ');

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                if (schoolLine.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    schoolLine,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (user != null && age != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Age $age',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
