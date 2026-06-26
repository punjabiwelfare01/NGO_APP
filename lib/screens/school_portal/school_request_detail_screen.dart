import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/counsellor_session_models.dart';
import '../../viewmodels/counsellor_viewmodel.dart';

class SchoolRequestDetailScreen extends StatefulWidget {
  const SchoolRequestDetailScreen({
    required this.request,
    required this.vm,
    super.key,
  });

  final SchoolBookingRequest request;
  final CounsellorViewModel vm;

  @override
  State<SchoolRequestDetailScreen> createState() =>
      _SchoolRequestDetailScreenState();
}

class _SchoolRequestDetailScreenState
    extends State<SchoolRequestDetailScreen> {
  late SchoolBookingRequest _request;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
  }

  @override
  Widget build(BuildContext context) {
    final r = _request;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Request Detail'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _StatusBanner(request: r),
          const SizedBox(height: 16),
          _InfoCard(request: r),
          const SizedBox(height: 14),
          _ScheduleCard(request: r),
          if (r.status == SchoolRequestStatus.rescheduled &&
              r.suggestedDate != null) ...[
            const SizedBox(height: 14),
            _RescheduleCard(request: r),
          ],
          if (r.contactVisible && r.meetingLink != null) ...[
            const SizedBox(height: 14),
            _MeetingLinkCard(request: r),
          ],
          const SizedBox(height: 14),
          _Timeline(request: r),
          const SizedBox(height: 24),
          _ActionButtons(
            request: r,
            busy: _busy,
            onConfirmTime: _confirmTime,
            onCancel: _cancel,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _confirmTime() async {
    setState(() => _busy = true);
    try {
      final updated = await widget.vm.confirmTime(_request.id);
      if (!mounted) return;
      setState(() {
        _request = updated;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New session time confirmed.'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError('Could not confirm time: $e');
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text(
          'Are you sure you want to cancel this counselling request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.softRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final updated = await widget.vm.cancelSchoolRequest(_request.id);
      if (!mounted) return;
      setState(() {
        _request = updated;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request cancelled.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError('Could not cancel: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.softRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─── Status Banner ────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.request});
  final SchoolBookingRequest request;

  static const _messages = {
    SchoolRequestStatus.newRequest:
        'Your request has been submitted and is awaiting counsellor review.',
    SchoolRequestStatus.accepted:
        'The counsellor has accepted your request. The Event Manager will confirm final details shortly.',
    SchoolRequestStatus.rescheduled:
        'The counsellor has suggested a new date/time. Please confirm or cancel below.',
    SchoolRequestStatus.declined:
        'The counsellor was unable to accept this request.',
    SchoolRequestStatus.pendingConfirmation:
        'You confirmed the new time. Waiting for final event-manager confirmation.',
    SchoolRequestStatus.confirmed:
        'Your session is confirmed. Check the meeting link below.',
    SchoolRequestStatus.scheduled:
        'Your session is scheduled. See meeting details below.',
    SchoolRequestStatus.completed: 'This counselling session is complete.',
    SchoolRequestStatus.cancelled: 'This request has been cancelled.',
  };

  @override
  Widget build(BuildContext context) {
    final s = request.status;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: s.color.withValues(alpha: .25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(s.icon, color: s.color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.label,
                  style: TextStyle(
                    color: s.color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _messages[s] ?? '',
                  style: TextStyle(
                    color: s.color.withValues(alpha: .85),
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.request});
  final SchoolBookingRequest request;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Request Details',
      icon: Icons.info_outline_rounded,
      children: [
        _Row('Topic', request.topic),
        _Row('Counsellor', request.counsellorName),
        _Row('School', request.schoolName),
        _Row('Coordinator', request.coordinatorName),
        if (request.contactVisible && request.coordinatorEmail.isNotEmpty)
          _Row('Email', request.coordinatorEmail),
        if (request.contactVisible && request.coordinatorPhone.isNotEmpty)
          _Row('Phone', request.coordinatorPhone),
        _Row('Grade / Class', request.classGroup.isNotEmpty ? request.classGroup : '—'),
        _Row('Students', '${request.expectedStudents}'),
        _Row('Mode', request.mode.label),
        if (request.specialRequirements.isNotEmpty)
          _Row('Requirements', request.specialRequirements),
      ],
    );
  }
}

// ─── Schedule Card ────────────────────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.request});
  final SchoolBookingRequest request;

  static String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    final d = request.preferredDate;
    return _Card(
      title: 'Preferred Schedule',
      icon: Icons.calendar_month_rounded,
      children: [
        _Row(
          'Date',
          '${d.day}/${d.month}/${d.year}',
        ),
        _Row('Time', _fmt(request.preferredTime)),
      ],
    );
  }
}

// ─── Reschedule Card ──────────────────────────────────────────────────────────

class _RescheduleCard extends StatelessWidget {
  const _RescheduleCard({required this.request});
  final SchoolBookingRequest request;

  static String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    final d = request.suggestedDate!;
    final t = request.suggestedTime;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: .25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule_rounded, color: Color(0xFF6A1B9A), size: 18),
              SizedBox(width: 8),
              Text(
                'Counsellor Suggested New Time',
                style: TextStyle(
                  color: Color(0xFF6A1B9A),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Row('New Date', '${d.day}/${d.month}/${d.year}',
              color: const Color(0xFF4A148C)),
          if (t != null)
            _Row('New Time', _fmt(t), color: const Color(0xFF4A148C)),
        ],
      ),
    );
  }
}

// ─── Meeting Link Card ────────────────────────────────────────────────────────

class _MeetingLinkCard extends StatelessWidget {
  const _MeetingLinkCard({required this.request});
  final SchoolBookingRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: .25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.videocam_rounded, color: Color(0xFF2E7D32), size: 18),
              SizedBox(width: 8),
              Text(
                'Meeting Link',
                style: TextStyle(
                  color: Color(0xFF1B5E20),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            request.meetingLink!,
            style: const TextStyle(
              color: Color(0xFF1565C0),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timeline ─────────────────────────────────────────────────────────────────

class _Timeline extends StatelessWidget {
  const _Timeline({required this.request});
  final SchoolBookingRequest request;

  @override
  Widget build(BuildContext context) {
    final events = <({String label, DateTime time})>[];
    events.add((label: 'Submitted', time: request.requestedAt));
    if (request.acceptedAt != null) {
      events.add((label: 'Accepted by Counsellor', time: request.acceptedAt!));
    }
    if (request.confirmedAt != null) {
      events.add((label: 'Confirmed', time: request.confirmedAt!));
    }
    if (request.completedAt != null) {
      events.add((label: 'Completed', time: request.completedAt!));
    }

    if (events.length <= 1) return const SizedBox.shrink();

    return _Card(
      title: 'Timeline',
      icon: Icons.timeline_rounded,
      children: [
        for (final e in events)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.circle,
                  size: 8,
                  color: Color(0xFF1565C0),
                ),
                const SizedBox(width: 10),
                Text(
                  e.label,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${e.time.day}/${e.time.month}/${e.time.year}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.request,
    required this.busy,
    required this.onConfirmTime,
    required this.onCancel,
  });

  final SchoolBookingRequest request;
  final bool busy;
  final VoidCallback onConfirmTime;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final s = request.status;
    final canConfirm = s == SchoolRequestStatus.rescheduled;
    final canCancel = s == SchoolRequestStatus.newRequest ||
        s == SchoolRequestStatus.accepted ||
        s == SchoolRequestStatus.rescheduled ||
        s == SchoolRequestStatus.pendingConfirmation;

    if (!canConfirm && !canCancel) return const SizedBox.shrink();

    return Column(
      children: [
        if (canConfirm)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : onConfirmTime,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text(
                'Confirm New Time',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        if (canConfirm) const SizedBox(height: 10),
        if (canCancel)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onCancel,
              icon: const Icon(Icons.cancel_rounded, size: 18),
              label: const Text(
                'Cancel Request',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.softRed,
                side: BorderSide(color: AppColors.softRed.withValues(alpha: .6)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.ink, size: 17),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
