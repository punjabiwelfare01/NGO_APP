import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/colors.dart';
import '../../../models/api_models.dart';
import '../../../models/counselling_models.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({
    required this.session,
    required this.mentor,
    super.key,
  });

  final ApiCounsellingSession session;
  final MentorProfile mentor;

  String get _formattedTime {
    final d = session.scheduledAt;
    final now = DateTime.now();
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    final isToday =
        d.year == now.year && d.month == now.month && d.day == now.day;
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = isToday
        ? 'Today'
        : '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
    return '$day at $h:$m $ampm';
  }

  Future<void> _openMeetLink(BuildContext context) async {
    final url = Uri.parse(session.meetingUrl!);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open meeting link.')),
        );
      }
    }
  }

  Future<void> _copyMeetLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: session.meetingUrl!));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting link copied!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              // Success icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.secondary,
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your session with ${mentor.displayName} is scheduled.',
                style: const TextStyle(color: AppColors.muted, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Details card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.lavender.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.person_rounded,
                      label: 'Mentor',
                      value: mentor.displayName,
                    ),
                    const Divider(height: 20),
                    _DetailRow(
                      icon: Icons.schedule_rounded,
                      label: 'Date & Time',
                      value: _formattedTime,
                    ),
                    const Divider(height: 20),
                    _DetailRow(
                      icon: Icons.label_rounded,
                      label: 'Topic',
                      value: session.topic,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Meet link section
              if (session.hasMeetingLink) ...[
                _MeetLinkCard(
                  onJoin: () => _openMeetLink(context),
                  onCopy: () => _copyMeetLink(context),
                ),
                const SizedBox(height: 12),
              ] else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.25)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppColors.accent, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'The Meet link will appear here once your mentor adds it.',
                          style:
                              TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Back to Home',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('View Mentor',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeetLinkCard extends StatelessWidget {
  const _MeetLinkCard({required this.onJoin, required this.onCopy});

  final VoidCallback onJoin;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.videocam_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Meeting Ready',
                    style: TextStyle(
                        color: AppColors.ink, fontWeight: FontWeight.w800)),
                Text('Tap to join when it\'s time',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.muted),
            tooltip: 'Copy link',
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
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            Text(value,
                style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
      ],
    );
  }
}
