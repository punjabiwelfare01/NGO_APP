import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/colors.dart';
import '../../../models/api_models.dart';
import '../../../widgets/app_card.dart';

class CounsellingSessionCard extends StatelessWidget {
  const CounsellingSessionCard({
    required this.upcomingSessions,
    required this.availableSlots,
    required this.onViewAll,
    required this.onBook,
    super.key,
  });

  final List<ApiCounsellingSession> upcomingSessions;
  final List<ApiCounsellingSlot> availableSlots;
  final VoidCallback onViewAll;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.lavender.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: AppColors.ink,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Counselling Sessions',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // My booked sessions (upcoming)
          if (upcomingSessions.isNotEmpty) ...[
            const _SectionLabel(label: 'My Booked Sessions'),
            ...upcomingSessions.take(2).map(
                  (s) => _BookedSessionRow(session: s),
                ),
            const SizedBox(height: 10),
          ],

          // Available slots preview
          if (availableSlots.isNotEmpty) ...[
            const _SectionLabel(label: 'Available Sessions'),
            ...availableSlots.take(2).map(
                  (slot) => _AvailableSlotRow(slot: slot, onBook: onBook),
                ),
          ] else if (upcomingSessions.isEmpty) ...[
            // Nothing at all
            const _EmptyState(),
          ],

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onViewAll,
              icon: const Icon(Icons.calendar_month_rounded, size: 16),
              label: const Text('Browse All Sessions'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _BookedSessionRow extends StatelessWidget {
  const _BookedSessionRow({required this.session});

  final ApiCounsellingSession session;

  @override
  Widget build(BuildContext context) {
    final hasLink = session.hasMeetingLink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event_available_rounded,
                color: AppColors.secondary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.topic,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${session.counsellorName} · ${session.formattedTime}',
                  style:
                      const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (hasLink)
            _JoinLinkButton(url: session.meetingUrl!)
          else
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Upcoming',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvailableSlotRow extends StatelessWidget {
  const _AvailableSlotRow({required this.slot, required this.onBook});

  final ApiCounsellingSlot slot;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.topic ?? slot.mentorName,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${slot.mentorName} · ${slot.formattedTime}',
                  style:
                      const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onBook,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Book', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _JoinLinkButton extends StatelessWidget {
  const _JoinLinkButton({required this.url});

  final String url;

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Join link copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _copyLink(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_rounded,
                size: 13, color: AppColors.secondary),
            SizedBox(width: 4),
            Text(
              'Copy Link',
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'No upcoming counselling sessions. Tap "Browse All Sessions" to find and book one.',
        style: TextStyle(color: AppColors.muted, fontSize: 13),
      ),
    );
  }
}
