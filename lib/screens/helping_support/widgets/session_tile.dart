import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/api_models.dart';

class SessionTile extends StatelessWidget {
  const SessionTile({required this.session, this.onTap, super.key});

  final ApiCounsellingSession session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isUpcoming = session.isUpcoming;
    final statusColor = switch (session.status) {
      'upcoming' => AppColors.primary,
      'completed' => AppColors.secondary,
      _ => AppColors.muted,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: statusColor.withValues(alpha: 0.15),
              child: Icon(
                isUpcoming
                    ? Icons.schedule_rounded
                    : Icons.check_circle_rounded,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.topic,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${session.counsellorName} · ${session.formattedTime}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (session.hasMeetingLink && isUpcoming)
              const Icon(Icons.videocam_rounded, color: AppColors.secondary, size: 20),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                session.status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
