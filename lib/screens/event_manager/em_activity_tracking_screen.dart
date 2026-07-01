import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/colors.dart';
import '../../core/config.dart';
import '../../models/event_manager_models.dart';
import '../../repositories/event_manager_repository.dart';
import '../../widgets/app_card.dart';

class EMActivityTrackingScreen extends StatefulWidget {
  const EMActivityTrackingScreen({
    required this.activityId,
    required this.activityTitle,
    super.key,
  });

  final int activityId;
  final String activityTitle;

  @override
  State<EMActivityTrackingScreen> createState() =>
      _EMActivityTrackingScreenState();
}

class _EMActivityTrackingScreenState extends State<EMActivityTrackingScreen> {
  EMActivityTracking? _tracking;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await EventManagerRepository.getActivityTracking(
          widget.activityId);
      if (mounted) setState(() => _tracking = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(color: AppColors.ink),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.activityTitle,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              'Student Work Log',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.ink),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: AppColors.softRed, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load tracking data',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
      );
    }

    final tracking = _tracking;
    if (tracking == null) {
      return const Center(child: Text('No data'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _StatsRow(stats: tracking.stats),
          const SizedBox(height: 20),
          if (tracking.students.isEmpty)
            _emptyState()
          else
            ...tracking.students.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StudentTrackCard(
                  studentTrack: s,
                  onRefresh: _load,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_outlined,
              color: AppColors.muted.withValues(alpha: 0.35),
              size: 52,
            ),
            const SizedBox(height: 14),
            const Text(
              'No students assigned yet',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Assign students to this activity to track their work',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final EMTrackingStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total',
            count: stats.totalAssigned,
            color: const Color(0xFF1565C0),
            icon: Icons.people_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Submitted',
            count: stats.submitted,
            color: const Color(0xFFF57F17),
            icon: Icons.upload_file_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Approved',
            count: stats.approved,
            color: const Color(0xFF2E7D32),
            icon: Icons.check_circle_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Pending',
            count: stats.pending,
            color: const Color(0xFF757575),
            icon: Icons.hourglass_empty_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.75),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Student Track Card ───────────────────────────────────────────────────────

class _StudentTrackCard extends StatelessWidget {
  const _StudentTrackCard({
    required this.studentTrack,
    required this.onRefresh,
  });

  final EMStudentTrack studentTrack;
  final VoidCallback onRefresh;

  static const _avatarColors = [
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFFE65100),
    Color(0xFF6A1B9A),
    Color(0xFF00695C),
  ];

  @override
  Widget build(BuildContext context) {
    final s = studentTrack;
    final student = s.student;
    final avatarColor = _avatarColors[student.id % _avatarColors.length];
    final initials = _initials(student.name);
    final sub = s.latestSubmission;
    final lastSubmitDate = sub?.submittedAt;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student header row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: avatarColor.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: avatarColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      student.email,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _AssignmentStatusChip(status: s.assignmentStatus),
            ],
          ),
          const SizedBox(height: 10),

          // Meta chips row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (lastSubmitDate != null)
                _MetaChip(
                  icon: Icons.calendar_today_rounded,
                  label: _formatDate(lastSubmitDate),
                  color: const Color(0xFF1565C0),
                ),
              _MetaChip(
                icon: Icons.attach_file_rounded,
                label:
                    '${sub?.proofFiles.length ?? 0} proof file${(sub?.proofFiles.length ?? 0) == 1 ? '' : 's'}',
                color: const Color(0xFFF57F17),
              ),
              _MetaChip(
                icon: Icons.edit_note_rounded,
                label:
                    '${s.dailyLogs.length} log${s.dailyLogs.length == 1 ? '' : 's'}',
                color: const Color(0xFF00695C),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Review Work button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: sub != null
                  ? () => _openWorkDetail(context)
                  : null,
              icon: const Icon(Icons.preview_rounded, size: 16),
              label: const Text(
                'Review Work',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                disabledBackgroundColor:
                    AppColors.muted.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (sub == null)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Center(
                child: Text(
                  'No submission yet',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _openWorkDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EMStudentWorkDetailSheet(
        studentTrack: studentTrack,
        onActionComplete: onRefresh,
      ),
    );
  }
}

class _AssignmentStatusChip extends StatelessWidget {
  const _AssignmentStatusChip({required this.status});
  final AssignmentStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.30)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Work Detail Bottom Sheet ─────────────────────────────────────────────────

class EMStudentWorkDetailSheet extends StatefulWidget {
  const EMStudentWorkDetailSheet({
    required this.studentTrack,
    required this.onActionComplete,
    super.key,
  });

  final EMStudentTrack studentTrack;
  final VoidCallback onActionComplete;

  @override
  State<EMStudentWorkDetailSheet> createState() =>
      _EMStudentWorkDetailSheetState();
}

class _EMStudentWorkDetailSheetState extends State<EMStudentWorkDetailSheet> {
  final TextEditingController _notesCtrl = TextEditingController();
  bool _submitting = false;
  bool _descExpanded = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _doReview(String status) async {
    setState(() => _submitting = true);
    try {
      final sub = widget.studentTrack.latestSubmission!;
      await EventManagerRepository.reviewSubmission(
        sub.id,
        status: status,
        reviewerNotes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      final label = switch (status) {
        'approved' => 'Work approved!',
        'needs_correction' => 'Student notified to correct and resubmit',
        'rejected' => 'Submission rejected',
        _ => 'Review submitted',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(label),
          backgroundColor: switch (status) {
            'approved' => const Color(0xFF2E7D32),
            'rejected' => AppColors.softRed,
            _ => const Color(0xFFE65100),
          },
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
      widget.onActionComplete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.softRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.studentTrack;
    final sub = track.latestSubmission;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.student.name,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          track.student.email,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _AssignmentStatusChip(status: track.assignmentStatus),
                ],
              ),
            ),
            const Divider(height: 1),
            // Scrollable body
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  if (sub == null)
                    _noSubmissionState()
                  else ...[
                    _submissionSection(sub),
                    const SizedBox(height: 20),
                  ],
                  if (track.dailyLogs.isNotEmpty) ...[
                    _dailyLogsSection(track.dailyLogs),
                    const SizedBox(height: 20),
                  ],
                  if (sub != null) ...[
                    _reviewSection(),
                    const SizedBox(height: 16),
                    _actionButtons(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noSubmissionState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.upload_file_rounded,
              color: AppColors.muted.withValues(alpha: 0.35), size: 48),
          const SizedBox(height: 12),
          const Text(
            'No submission yet',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'This student has not submitted their work',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _submissionSection(EMSubmissionTrack sub) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFFF57F17).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.upload_file_rounded,
                  color: Color(0xFFF57F17), size: 16),
              const SizedBox(width: 6),
              const Text(
                'Submission',
                style: TextStyle(
                  color: Color(0xFFF57F17),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              _SubmissionStatusChip(status: sub.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            sub.title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          // Expandable description
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Text(
              sub.description,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              maxLines: _descExpanded ? null : 3,
              overflow: _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
          ),
          if (sub.description.length > 120)
            GestureDetector(
              onTap: () => setState(() => _descExpanded = !_descExpanded),
              child: Text(
                _descExpanded ? 'Show less' : 'Read more',
                style: const TextStyle(
                  color: Color(0xFF1565C0),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 10),
          // Meta stats
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _SubMeta(
                  icon: Icons.access_time_rounded,
                  label: '${sub.hoursWorked}h worked'),
              _SubMeta(
                  icon: Icons.people_rounded,
                  label: '${sub.peopleReached} reached'),
              if (sub.donationCollected > 0)
                _SubMeta(
                    icon: Icons.payments_rounded,
                    label:
                        '₹${sub.donationCollected.toStringAsFixed(0)} collected'),
            ],
          ),
          if (sub.remarks != null && sub.remarks!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Remarks: ${sub.remarks}',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          // Proof files
          if (sub.proofFiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.attach_file_rounded,
                    size: 12, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(
                  '${sub.proofFiles.length} proof file${sub.proofFiles.length > 1 ? 's' : ''} attached',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ProofFilesGrid(files: sub.proofFiles),
          ],
        ],
      ),
    );
  }

  Widget _dailyLogsSection(List<EMDailyLogEntry> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.edit_note_rounded,
                color: Color(0xFF00695C), size: 16),
            const SizedBox(width: 6),
            Text(
              'Daily Logs (${logs.length})',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...logs.map((log) => _DailyLogItem(log: log)),
      ],
    );
  }

  Widget _reviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reviewer Feedback',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesCtrl,
          maxLines: 3,
          enabled: !_submitting,
          decoration: InputDecoration(
            hintText:
                'Add feedback for the student (optional)...',
            hintStyle: TextStyle(
                color: AppColors.muted.withValues(alpha: 0.6),
                fontSize: 12),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _actionButtons() {
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed:
                _submitting ? null : () => _doReview('approved'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Approve',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed:
                _submitting ? null : () => _doReview('needs_correction'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE65100),
              side: const BorderSide(color: Color(0xFFE65100)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Needs Correction',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed:
                _submitting ? null : () => _doReview('rejected'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.softRed,
              side: BorderSide(
                  color: AppColors.softRed.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Reject',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Daily Log Item ───────────────────────────────────────────────────────────

class _DailyLogItem extends StatefulWidget {
  const _DailyLogItem({required this.log});
  final EMDailyLogEntry log;

  @override
  State<_DailyLogItem> createState() => _DailyLogItemState();
}

class _DailyLogItemState extends State<_DailyLogItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF00695C).withValues(alpha: 0.20)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 12, color: Color(0xFF00695C)),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(log.date),
                      style: const TextStyle(
                        color: Color(0xFF00695C),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (log.mediaFiles.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_rounded,
                              size: 11, color: AppColors.muted),
                          const SizedBox(width: 3),
                          Text(
                            '${log.mediaFiles.length}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.muted,
                    ),
                  ],
                ),
                if (log.title != null && log.title!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    log.title!,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (_expanded) ...[
                  if (log.content != null && log.content!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      log.content!,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                  if (log.reflection != null &&
                      log.reflection!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Reflection: ${log.reflection}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── Submission Status Chip ───────────────────────────────────────────────────

class _SubmissionStatusChip extends StatelessWidget {
  const _SubmissionStatusChip({required this.status});
  final String status;

  static Color _color(String s) => switch (s) {
        'approved' => const Color(0xFF2E7D32),
        'rejected' => const Color(0xFFC62828),
        'needs_correction' => const Color(0xFFE65100),
        'under_review' => const Color(0xFF6A1B9A),
        _ => const Color(0xFFF57F17),
      };

  static String _label(String s) => switch (s) {
        'approved' => 'Approved',
        'rejected' => 'Rejected',
        'needs_correction' => 'Needs Correction',
        'under_review' => 'Under Review',
        'submitted' => 'Submitted',
        _ => s,
      };

  @override
  Widget build(BuildContext context) {
    final c = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.30)),
      ),
      child: Text(
        _label(status),
        style: TextStyle(
          color: c,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─── Sub-meta row item ────────────────────────────────────────────────────────

class _SubMeta extends StatelessWidget {
  const _SubMeta({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFFF57F17)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Proof Files Grid ─────────────────────────────────────────────────────────

class _ProofFilesGrid extends StatelessWidget {
  const _ProofFilesGrid({required this.files});
  final List<String> files;

  static final _imageExts = {'.jpg', '.jpeg', '.png', '.webp', '.gif'};

  bool _isImage(String url) {
    final ext = '.${url.toLowerCase().split('.').last}';
    return _imageExts.contains(ext);
  }

  String _fullUrl(String path) {
    if (path.startsWith('http')) return path;
    return '${AppConfig.apiBaseUrl}$path';
  }

  String _label(String url) {
    final name = url.split('/').last;
    return name.length > 24 ? '${name.substring(0, 21)}…' : name;
  }

  @override
  Widget build(BuildContext context) {
    final imageFiles = files.where(_isImage).toList();
    final otherFiles = files.where((f) => !_isImage(f)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageFiles.isNotEmpty)
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imageFiles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(_fullUrl(imageFiles[i])),
                  mode: LaunchMode.externalApplication,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _fullUrl(imageFiles[i]),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.muted.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.broken_image_rounded,
                          color: AppColors.muted),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (otherFiles.isNotEmpty) ...[
          if (imageFiles.isNotEmpty) const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: otherFiles
                .map(
                  (url) => InkWell(
                    onTap: () => launchUrl(
                      Uri.parse(_fullUrl(url)),
                      mode: LaunchMode.externalApplication,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.open_in_new_rounded,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 5),
                          Text(
                            _label(url),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
