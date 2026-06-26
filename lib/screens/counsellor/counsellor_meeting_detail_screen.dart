import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/colors.dart';
import '../../models/counsellor_models.dart';
import '../../models/counsellor_session_models.dart';
import '../../viewmodels/counsellor_home_viewmodel.dart';

class CounsellorMeetingDetailScreen extends StatefulWidget {
  const CounsellorMeetingDetailScreen({
    required this.request,
    required this.vm,
    super.key,
  });

  final SchoolBookingRequest request;
  final CounsellorHomeViewModel vm;

  @override
  State<CounsellorMeetingDetailScreen> createState() =>
      _CounsellorMeetingDetailScreenState();
}

class _CounsellorMeetingDetailScreenState
    extends State<CounsellorMeetingDetailScreen> {
  late SchoolBookingRequest _req;

  @override
  void initState() {
    super.initState();
    _req = widget.request;
    widget.vm.addListener(_onVmChange);
  }

  @override
  void dispose() {
    widget.vm.removeListener(_onVmChange);
    super.dispose();
  }

  void _onVmChange() {
    final updated = widget.vm.requestById(_req.id);
    if (updated != null && mounted) setState(() => _req = updated);
  }

  @override
  Widget build(BuildContext context) {
    final d = _req.effectiveDate;
    final t = _req.effectiveTime;
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    final dateStr =
        '${_dayName(d.weekday)}, ${d.day} ${_monthName(d.month)} ${d.year}';
    final timeStr = '$h:$m $period';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _Header(req: _req),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Session details
                _DetailSection(
                  title: 'Session Details',
                  icon: Icons.info_outline_rounded,
                  children: [
                    _DetailRow('Topic', _req.topic),
                    _DetailRow('Program', _req.program),
                    _DetailRow('Class Group', _req.classGroup),
                    _DetailRow('Expected Students', '${_req.expectedStudents}'),
                    _DetailRow('Language', _req.language),
                    _DetailRow('Date', dateStr),
                    _DetailRow('Time', timeStr),
                    _DetailRow(
                      'Mode',
                      _req.mode == SessionMode.online
                          ? 'Online (Video Call)'
                          : 'Offline (In-Person)',
                    ),
                    if (_req.specialRequirements.isNotEmpty)
                      _DetailRow(
                        'Special Requirements',
                        _req.specialRequirements,
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Contact — gated behind acceptance
                if (_req.contactVisible) ...[
                  _DetailSection(
                    title: 'School Contact',
                    icon: Icons.contact_phone_rounded,
                    iconColor: const Color(0xFF2E7D32),
                    children: [
                      _DetailRow('Coordinator', _req.coordinatorName),
                      _DetailRow('School', _req.schoolName),
                      _DetailRow('Address', _req.schoolAddress),
                      _DetailRow('Phone', _req.coordinatorPhone),
                      _DetailRow('Email', _req.coordinatorEmail),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ContactButton(
                          icon: Icons.call_rounded,
                          label: 'Call Coordinator',
                          color: const Color(0xFF2E7D32),
                          onTap: () => _launch('tel:${_req.coordinatorPhone}'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ContactButton(
                          icon: Icons.email_outlined,
                          label: 'Send Email',
                          color: const Color(0xFF1565C0),
                          onTap: () =>
                              _launch('mailto:${_req.coordinatorEmail}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  _ContactLockedCard(),
                  const SizedBox(height: 16),
                ],

                // Meeting link / location
                _DetailSection(
                  title: _req.mode == SessionMode.online
                      ? 'Meeting Link'
                      : 'Session Location',
                  icon: _req.mode == SessionMode.online
                      ? Icons.videocam_rounded
                      : Icons.location_on_rounded,
                  iconColor: const Color(0xFF6A1B9A),
                  children: [
                    if (_req.mode == SessionMode.online) ...[
                      _DetailRow(
                        'Link',
                        _req.meetingLink ?? 'Link will be shared after confirmation',
                      ),
                    ] else ...[
                      _DetailRow('Location', _req.offlineLocation.isNotEmpty
                          ? _req.offlineLocation
                          : _req.schoolAddress),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                if (_req.mode == SessionMode.online && _req.meetingLink != null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          _launch('https://${_req.meetingLink}'),
                      icon: const Icon(Icons.videocam_rounded, size: 18),
                      label: const Text('Join Online Meeting'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6A1B9A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                else if (_req.mode == SessionMode.offline)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final addr = Uri.encodeComponent(
                          _req.offlineLocation.isNotEmpty
                              ? _req.offlineLocation
                              : _req.schoolAddress,
                        );
                        _launch('https://maps.google.com?q=$addr');
                      },
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Open in Maps'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6A1B9A),
                        side: const BorderSide(color: Color(0xFF6A1B9A)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Assigned Event Manager
                if (_req.assignedEventManager != null) ...[
                  _DetailSection(
                    title: 'Assigned Event Manager',
                    icon: Icons.manage_accounts_rounded,
                    iconColor: const Color(0xFFF57F17),
                    children: [
                      _DetailRow('Name', _req.assignedEventManager!),
                      if (_req.assignedEventManagerPhone != null)
                        _DetailRow('Phone', _req.assignedEventManagerPhone!),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Preparation notes
                if (_req.preparationNotes != null &&
                    _req.preparationNotes!.isNotEmpty) ...[
                  _DetailSection(
                    title: 'Preparation Notes',
                    icon: Icons.notes_rounded,
                    iconColor: const Color(0xFF00695C),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _req.preparationNotes!,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.ink,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Reminders
                _RemindersSection(vm: widget.vm, requestId: _req.id),
                const SizedBox(height: 16),

                // Feedback (if completed)
                if (_req.feedbackRating != null) ...[
                  _FeedbackSection(req: _req),
                  const SizedBox(height: 16),
                ],
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomActions(
        req: _req,
        vm: widget.vm,
        onCompleted: () {
          setState(() {
            _req = _req.copyWith(
              status: SchoolRequestStatus.completed,
              completedAt: DateTime.now(),
            );
          });
        },
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.req});
  final SchoolBookingRequest req;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: const Color(0xFF0A1F44),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1F44), Color(0xFF1565C0)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _StatusChip(status: req.status),
              const SizedBox(height: 8),
              Text(
                req.schoolName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 4),
              Text(
                req.topic,
                style: const TextStyle(
                  color: Color(0xFFB3C8E8),
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
      title: Text(
        'Meeting Details',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Detail Section ───────────────────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.children,
    this.iconColor,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.ink,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Contact Buttons ──────────────────────────────────────────────────────────

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactLockedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF57F17).withValues(alpha: 0.35),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: Color(0xFFF57F17), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'School contact details will be visible after you accept this request or after Event Manager confirms the booking.',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFFE65100),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reminders ────────────────────────────────────────────────────────────────

class _RemindersSection extends StatelessWidget {
  const _RemindersSection({required this.vm, required this.requestId});
  final CounsellorHomeViewModel vm;
  final int requestId;

  @override
  Widget build(BuildContext context) {
    final reminders = vm.upcomingReminders
        .where((r) => r.requestId == requestId)
        .toList();

    if (reminders.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                color: Color(0xFFF57F17),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Scheduled Reminders',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...reminders.map(
            (r) => _ReminderBadge(
              type: r.type,
              scheduledFor: r.scheduledFor,
              isDismissed: r.isDismissed,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderBadge extends StatelessWidget {
  const _ReminderBadge({
    required this.type,
    required this.scheduledFor,
    required this.isDismissed,
  });

  final ReminderType type;
  final DateTime scheduledFor;
  final bool isDismissed;

  @override
  Widget build(BuildContext context) {
    final color = type == ReminderType.minutes15
        ? const Color(0xFFC62828)
        : type == ReminderType.hours2
            ? const Color(0xFFF57F17)
            : const Color(0xFF1565C0);
    final h = scheduledFor.hour;
    final m = scheduledFor.minute.toString().padLeft(2, '0');
    final period = h < 12 ? 'AM' : 'PM';
    final hour = h % 12 == 0 ? 12 : h % 12;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDismissed ? AppColors.muted : color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              type.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDismissed ? AppColors.muted : AppColors.ink,
                decoration:
                    isDismissed ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            '${scheduledFor.day}/${scheduledFor.month} $hour:$m $period',
            style: TextStyle(
              fontSize: 11.5,
              color: isDismissed ? AppColors.muted : color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feedback ─────────────────────────────────────────────────────────────────

class _FeedbackSection extends StatelessWidget {
  const _FeedbackSection({required this.req});
  final SchoolBookingRequest req;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00695C).withValues(alpha: 0.25),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 18),
              SizedBox(width: 8),
              Text(
                'School Feedback',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF004D40),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              final rating = req.feedbackRating ?? 0;
              return Icon(
                i < rating.floor()
                    ? Icons.star_rounded
                    : i < rating
                        ? Icons.star_half_rounded
                        : Icons.star_outline_rounded,
                color: const Color(0xFFFFB300),
                size: 20,
              );
            }),
          ),
          if (req.feedbackComment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"${req.feedbackComment}"',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF004D40),
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Bottom Actions ───────────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.req,
    required this.vm,
    required this.onCompleted,
  });

  final SchoolBookingRequest req;
  final CounsellorHomeViewModel vm;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    if (req.status == SchoolRequestStatus.newRequest) {
      return Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDeclineSheet(context),
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Decline'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC62828),
                  side: const BorderSide(color: Color(0xFFC62828)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () {
                  vm.acceptRequest(req.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Request from ${req.schoolName} accepted!'),
                      backgroundColor: const Color(0xFF2E7D32),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text('Accept Request'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (req.status == SchoolRequestStatus.scheduled ||
        req.status == SchoolRequestStatus.confirmed) {
      return Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              vm.markCompleted(req.id);
              onCompleted();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session marked as completed!'),
                  backgroundColor: Color(0xFF00695C),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.task_alt_rounded, size: 18),
            label: const Text(
              'Mark Session as Completed',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00695C),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showDeclineSheet(BuildContext context) {
    DeclineReason? selected;
    final noteController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final bottom = MediaQuery.of(sheetCtx).viewInsets.bottom;
          return Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Decline Request',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Color(0xFF17324D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please select a reason for declining.',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                RadioGroup<DeclineReason>(
                  groupValue: selected,
                  onChanged: (v) => setSheetState(() => selected = v),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: DeclineReason.values.map(
                      (r) => RadioListTile<DeclineReason>(
                        value: r,
                        title: Text(
                          r.label,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        activeColor: const Color(0xFFC62828),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    hintText: 'Additional note (optional)',
                    hintStyle:
                        TextStyle(fontSize: 13, color: AppColors.muted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: selected == null
                            ? null
                            : () {
                                vm.declineRequest(
                                  req.id,
                                  selected!,
                                  note: noteController.text,
                                );
                                Navigator.pop(sheetCtx);
                                Navigator.pop(context);
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Status Chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final SchoolRequestStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: status.color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _dayName(int weekday) {
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  return days[weekday - 1];
}

String _monthName(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return months[month - 1];
}
