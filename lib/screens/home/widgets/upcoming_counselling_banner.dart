import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/api_models.dart';
import '../../../models/event_models.dart';
import '../../../widgets/app_card.dart';

class UpcomingCounsellingBanner extends StatelessWidget {
  const UpcomingCounsellingBanner({
    this.upcomingEvent,
    this.liveSession,
    this.onEventTap,
    this.onJoinTap,
    super.key,
  });

  final EventModel? upcomingEvent;
  final ApiCounsellingSession? liveSession;
  final VoidCallback? onEventTap;
  final VoidCallback? onJoinTap;

  @override
  Widget build(BuildContext context) {
    // Live session with join link takes priority
    if (liveSession != null && liveSession!.hasMeetingLink) {
      return _LiveBanner(session: liveSession!, onJoin: onJoinTap);
    }
    // Open counselling event
    if (upcomingEvent != null) {
      return _EventBanner(event: upcomingEvent!, onTap: onEventTap);
    }
    return const SizedBox.shrink();
  }
}

class _LiveBanner extends StatelessWidget {
  const _LiveBanner({required this.session, this.onJoin});

  final ApiCounsellingSession session;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.secondary.withValues(alpha: 0.18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Session Ready',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'With ${session.counsellorName} · ${session.formattedTime}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onJoin,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.ink,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Join Now'),
          ),
        ],
      ),
    );
  }
}

class _EventBanner extends StatelessWidget {
  const _EventBanner({required this.event, this.onTap});

  final EventModel event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isLive = event.status == EventStatus.live;
    final color = isLive ? AppColors.accent : AppColors.primary;
    final label = isLive ? 'Live Now' : 'Open';

    return AppCard(
      color: color.withValues(alpha: 0.1),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              isLive ? Icons.radio_button_on_rounded : Icons.event_available_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Counselling session — tap to book',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(isLive ? 'View' : 'Book'),
          ),
        ],
      ),
    );
  }
}
