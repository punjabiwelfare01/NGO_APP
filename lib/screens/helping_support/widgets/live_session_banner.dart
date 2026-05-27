import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/api_models.dart';
import '../../../widgets/app_card.dart';

class LiveSessionBanner extends StatelessWidget {
  const LiveSessionBanner({required this.session, super.key});

  final ApiCounsellingSession session;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.secondary.withValues(alpha: 0.18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.videocam_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Session Ready to Join',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'With ${session.counsellorName} · ${session.formattedTime}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Join: ${session.meetingUrl}')),
              );
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Join'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
