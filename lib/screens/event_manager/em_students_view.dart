import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/colors.dart';
import '../../core/config.dart';
import '../../models/event_manager_models.dart';
import '../../viewmodels/event_manager_viewmodel.dart';
import '../../widgets/app_card.dart';
import 'em_activity_tracking_screen.dart';

class EMStudentsView extends StatefulWidget {
  const EMStudentsView({required this.vm, this.tabNotifier, super.key});
  final EventManagerViewModel vm;
  final ValueNotifier<int>? tabNotifier;

  @override
  State<EMStudentsView> createState() => _EMStudentsViewState();
}

class _EMStudentsViewState extends State<EMStudentsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    widget.tabNotifier?.addListener(_onExternalTabChange);
  }

  void _onExternalTabChange() {
    final idx = widget.tabNotifier!.value;
    if (_tabs.index != idx) _tabs.animateTo(idx);
  }

  @override
  void dispose() {
    widget.tabNotifier?.removeListener(_onExternalTabChange);
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final applied = widget.vm.appliedStudents;
        final assigned = widget.vm.assignedStudents;
        final submitted = widget.vm.pendingSubmissions;

        return Column(
          children: [
            _Header(
              appliedCount: applied.length,
              assignedCount: assigned.length,
              submittedCount: submitted.length,
            ),
            TabBar(
              controller: _tabs,
              labelColor: const Color(0xFF1565C0),
              unselectedLabelColor: AppColors.muted,
              indicatorColor: const Color(0xFF1565C0),
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Applications'),
                      if (applied.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _CountBadge(count: applied.length,
                            color: const Color(0xFF1565C0)),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Assigned'),
                      if (assigned.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _CountBadge(count: assigned.length,
                            color: const Color(0xFFE65100)),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Submissions'),
                      if (submitted.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _CountBadge(count: submitted.length,
                            color: const Color(0xFFF57F17)),
                      ],
                    ],
                  ),
                ),
                const Tab(
                  child: Text('Work Log'),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _ApplicationsTab(
                      assignments: applied, vm: widget.vm),
                  _AssignedTab(
                      assignments: assigned, vm: widget.vm),
                  _SubmissionsTab(
                      assignments: submitted, vm: widget.vm),
                  _WorkLogTab(
                      assignments: widget.vm.assignments),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.appliedCount,
    required this.assignedCount,
    required this.submittedCount,
  });
  final int appliedCount;
  final int assignedCount;
  final int submittedCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Students',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$appliedCount applied · $assignedCount assigned · $submittedCount submitted',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

// ─── Applications Tab ─────────────────────────────────────────────────────────

class _ApplicationsTab extends StatelessWidget {
  const _ApplicationsTab(
      {required this.assignments, required this.vm});
  final List<EMStudentAssignment> assignments;
  final EventManagerViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
      return const _EmptyTab(
        icon: Icons.inbox_rounded,
        message: 'No new applications',
        sub: 'Students who apply for activities will appear here',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      itemCount: assignments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) =>
          _ApplicationCard(assignment: assignments[i], vm: vm),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.assignment, required this.vm});
  final EMStudentAssignment assignment;
  final EventManagerViewModel vm;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StudentRow(student: assignment.student,
              status: assignment.status),
          const SizedBox(height: 10),
          _EventActivityRow(
              event: assignment.event, activity: assignment.activity),
          const SizedBox(height: 6),
          _AppliedOn(date: assignment.appliedAt),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => vm.updateAssignmentStatus(
                    assignment.id,
                    AssignmentStatus.rejected,
                    notes: 'Application not selected for this activity.',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.softRed,
                    side: BorderSide(
                        color: AppColors.softRed.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Reject',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => vm.updateAssignmentStatus(
                    assignment.id,
                    AssignmentStatus.shortlisted,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6A1B9A),
                    side: const BorderSide(color: Color(0xFF6A1B9A)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Shortlist',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => _showAssignDialog(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Assign',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context) {
    final instrCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assigning ${assignment.student.name} to "${assignment.activity.title}"',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Instructions (optional)',
              style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: instrCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Please arrive by 8:30 AM...',
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              vm.updateAssignmentStatus(
                assignment.id,
                AssignmentStatus.assigned,
                instructions: instrCtrl.text.trim().isEmpty
                    ? null
                    : instrCtrl.text.trim(),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${assignment.student.name} assigned successfully'),
                  backgroundColor: const Color(0xFF1565C0),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0)),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }
}

// ─── Assigned Tab ─────────────────────────────────────────────────────────────

class _AssignedTab extends StatelessWidget {
  const _AssignedTab({required this.assignments, required this.vm});
  final List<EMStudentAssignment> assignments;
  final EventManagerViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
      return const _EmptyTab(
        icon: Icons.assignment_turned_in_rounded,
        message: 'No assigned students yet',
        sub: 'Assign students from the Applications tab',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      itemCount: assignments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) =>
          _AssignedCard(assignment: assignments[i], vm: vm),
    );
  }
}

class _AssignedCard extends StatelessWidget {
  const _AssignedCard({required this.assignment, required this.vm});
  final EMStudentAssignment assignment;
  final EventManagerViewModel vm;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StudentRow(
              student: assignment.student, status: assignment.status),
          const SizedBox(height: 10),
          _EventActivityRow(
              event: assignment.event, activity: assignment.activity),
          if (assignment.instructions != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFF1565C0), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      assignment.instructions!,
                      style: const TextStyle(
                        color: Color(0xFF1565C0),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showMarkAttendance(context),
                  icon: const Icon(Icons.how_to_reg_rounded, size: 14),
                  label: const Text('Attendance',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showSendInstructions(context),
                  icon: const Icon(Icons.send_rounded, size: 14),
                  label: const Text('Instructions',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMarkAttendance(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark Attendance'),
        content: Text(
            'Mark ${assignment.student.name} as present for "${assignment.event.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Attendance marked for ${assignment.student.name}'),
                  backgroundColor: const Color(0xFF2E7D32),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32)),
            child: const Text('Mark Present'),
          ),
        ],
      ),
    );
  }

  void _showSendInstructions(BuildContext context) {
    final ctrl = TextEditingController(
        text: assignment.instructions ?? '');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Instructions'),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Type instructions for this volunteer...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              vm.updateAssignmentStatus(
                assignment.id,
                assignment.status,
                instructions: ctrl.text.trim(),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Instructions sent'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0)),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

// ─── Submissions Tab ──────────────────────────────────────────────────────────

class _SubmissionsTab extends StatelessWidget {
  const _SubmissionsTab(
      {required this.assignments, required this.vm});
  final List<EMStudentAssignment> assignments;
  final EventManagerViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
      return const _EmptyTab(
        icon: Icons.upload_file_rounded,
        message: 'No submissions yet',
        sub: 'When students submit their work it will appear here',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      itemCount: assignments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) =>
          _SubmissionCard(assignment: assignments[i], vm: vm),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({required this.assignment, required this.vm});
  final EMStudentAssignment assignment;
  final EventManagerViewModel vm;

  @override
  Widget build(BuildContext context) {
    final sub = assignment.submission;
    if (sub == null) {
      return AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StudentRow(student: assignment.student, status: assignment.status),
            const SizedBox(height: 10),
            _EventActivityRow(event: assignment.event, activity: assignment.activity),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Submission data unavailable — please refresh.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StudentRow(
              student: assignment.student, status: assignment.status),
          const SizedBox(height: 10),
          _EventActivityRow(
              event: assignment.event, activity: assignment.activity),
          const SizedBox(height: 12),
          // Submission details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFF57F17).withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.workTitle,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sub.description,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _SubMeta(
                        icon: Icons.access_time_rounded,
                        value: '${sub.hoursWorked}h worked'),
                    _SubMeta(
                        icon: Icons.people_rounded,
                        value: '${sub.peopleReached} reached'),
                    if (sub.donationCollected != null &&
                        sub.donationCollected! > 0)
                      _SubMeta(
                          icon: Icons.payments_rounded,
                          value:
                              '₹${sub.donationCollected!.toStringAsFixed(0)} collected'),
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
                // ── Proof files ───────────────────────────────────────────
                if (sub.photoUrls.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.attach_file_rounded,
                          size: 12, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text(
                        '${sub.photoUrls.length} proof file${sub.photoUrls.length > 1 ? 's' : ''} attached',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _ProofFilesGrid(urls: sub.photoUrls),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Reviewer notes field
          _ReviewNotesField(assignment: assignment, vm: vm),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _reject(context),
                  icon: const Icon(Icons.close_rounded, size: 14),
                  label: const Text('Reject',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.softRed,
                    side: BorderSide(
                        color: AppColors.softRed.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _requestResubmit(context),
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('Re-submit',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6A1B9A),
                    side: const BorderSide(color: Color(0xFF6A1B9A)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _approve(context),
                  icon: const Icon(Icons.check_rounded, size: 14),
                  label: const Text('Approve',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _approve(BuildContext context) {
    vm.updateAssignmentStatus(
      assignment.id,
      AssignmentStatus.approved,
      notes: 'Great work! Submission approved.',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${assignment.student.name}\'s work approved!'),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Create Impact Post',
          textColor: Colors.white,
          onPressed: () => _convertToPost(context),
        ),
      ),
    );
  }

  void _reject(BuildContext context) {
    vm.updateAssignmentStatus(
      assignment.id,
      AssignmentStatus.rejected,
      notes: 'Submission rejected. Please improve and resubmit.',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Submission rejected'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _requestResubmit(BuildContext context) {
    vm.updateAssignmentStatus(
      assignment.id,
      AssignmentStatus.assigned,
      notes:
          'Please provide more detail and resubmit your work.',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Student notified to resubmit'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _convertToPost(BuildContext context) async {
    await vm.convertToImpactPost(assignment);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft impact post created — go to Impact tab'),
        backgroundColor: Color(0xFF6A1B9A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ReviewNotesField extends StatefulWidget {
  const _ReviewNotesField(
      {required this.assignment, required this.vm});
  final EMStudentAssignment assignment;
  final EventManagerViewModel vm;

  @override
  State<_ReviewNotesField> createState() => _ReviewNotesFieldState();
}

class _ReviewNotesFieldState extends State<_ReviewNotesField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.assignment.reviewerNotes ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _ctrl,
      maxLines: 2,
      onChanged: (v) => widget.vm.updateAssignmentStatus(
        widget.assignment.id,
        widget.assignment.status,
        notes: v,
      ),
      decoration: InputDecoration(
        hintText: 'Reviewer notes (visible to student)...',
        hintStyle: TextStyle(
            color: AppColors.muted.withValues(alpha: 0.6), fontSize: 12),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _SubMeta extends StatelessWidget {
  const _SubMeta({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFF57F17), size: 13),
        const SizedBox(width: 4),
        Text(
          value,
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

// ─── Proof files grid ─────────────────────────────────────────────────────────

class _ProofFilesGrid extends StatelessWidget {
  const _ProofFilesGrid({required this.urls});
  final List<String> urls;

  static final _imageExts = {'.jpg', '.jpeg', '.png', '.webp'};

  bool _isImage(String url) {
    final ext = url.toLowerCase().split('.').last;
    return _imageExts.contains('.$ext');
  }

  String _fullUrl(String path) {
    if (path.startsWith('http')) return path;
    return '${AppConfig.apiBaseUrl}$path';
  }

  String _label(String url) {
    final name = url.split('/').last;
    return name.length > 28 ? '${name.substring(0, 25)}…' : name;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = urls.where(_isImage).toList();
    final otherUrls = urls.where((u) => !_isImage(u)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageUrls.isNotEmpty)
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imageUrls.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(_fullUrl(imageUrls[i])),
                  mode: LaunchMode.externalApplication,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _fullUrl(imageUrls[i]),
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 90,
                      height: 90,
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
        if (otherUrls.isNotEmpty) ...[
          if (imageUrls.isNotEmpty) const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: otherUrls
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

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _StudentRow extends StatelessWidget {
  const _StudentRow(
      {required this.student, required this.status});
  final EMStudent student;
  final AssignmentStatus status;

  static const _colors = [
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFFE65100),
    Color(0xFF6A1B9A),
    Color(0xFF00695C),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[student.id % _colors.length];
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Text(
            student.initials,
            style: TextStyle(
              color: color,
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
                '${student.hoursServed}h · ${student.activitiesCompleted} activities',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _StatusChip(status: status),
      ],
    );
  }
}

class _EventActivityRow extends StatelessWidget {
  const _EventActivityRow(
      {required this.event, required this.activity});
  final NGOEvent event;
  final EventActivity activity;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(activity.role.icon,
            color: AppColors.muted, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${activity.role.label} · ${event.title}',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _AppliedOn extends StatelessWidget {
  const _AppliedOn({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(date);
    final label = diff.inHours < 1
        ? 'Just now'
        : diff.inHours < 24
            ? '${diff.inHours}h ago'
            : '${diff.inDays}d ago';

    return Row(
      children: [
        const Icon(Icons.access_time_rounded,
            color: AppColors.muted, size: 12),
        const SizedBox(width: 4),
        Text(
          'Applied $label',
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final AssignmentStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.color});
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab(
      {required this.icon, required this.message, required this.sub});
  final IconData icon;
  final String message;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: AppColors.muted.withValues(alpha: 0.35), size: 52),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              sub,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Work Log Tab ─────────────────────────────────────────────────────────────

class _WorkLogTab extends StatelessWidget {
  const _WorkLogTab({required this.assignments});
  final List<EMStudentAssignment> assignments;

  @override
  Widget build(BuildContext context) {
    // Group assignments by activity id
    final Map<int, List<EMStudentAssignment>> byActivity = {};
    for (final a in assignments) {
      byActivity.putIfAbsent(a.activity.id, () => []).add(a);
    }

    if (byActivity.isEmpty) {
      return const _EmptyTab(
        icon: Icons.bar_chart_rounded,
        message: 'No activities yet',
        sub: 'Assigned activities will appear here for tracking',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      itemCount: byActivity.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final activityId = byActivity.keys.elementAt(i);
        final group = byActivity[activityId]!;
        final activity = group.first.activity;

        final totalAssigned = group.length;
        final submitted = group
            .where((a) =>
                a.status == AssignmentStatus.workSubmitted ||
                a.status == AssignmentStatus.verified ||
                a.status == AssignmentStatus.approved ||
                a.status == AssignmentStatus.certificateEligible)
            .length;
        final pending = group
            .where((a) =>
                a.status == AssignmentStatus.assigned ||
                a.status == AssignmentStatus.shortlisted)
            .length;

        return AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activity.title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _WorkLogChip(
                    label: '$totalAssigned assigned',
                    color: const Color(0xFF1565C0),
                    icon: Icons.people_rounded,
                  ),
                  _WorkLogChip(
                    label: '$submitted submitted',
                    color: const Color(0xFF2E7D32),
                    icon: Icons.upload_file_rounded,
                  ),
                  _WorkLogChip(
                    label: '$pending pending',
                    color: const Color(0xFF757575),
                    icon: Icons.hourglass_empty_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => EMActivityTrackingScreen(
                          activityId: activityId,
                          activityTitle: activity.title,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.track_changes_rounded, size: 16),
                  label: const Text(
                    'Track Students →',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkLogChip extends StatelessWidget {
  const _WorkLogChip({
    required this.label,
    required this.color,
    required this.icon,
  });
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
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
