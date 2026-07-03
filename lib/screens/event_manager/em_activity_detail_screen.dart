import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/event_manager_models.dart';
import '../../repositories/event_manager_repository.dart';
import 'em_assign_students_screen.dart';
import 'em_edit_activity_screen.dart';

class EMActivityDetailScreen extends StatefulWidget {
  const EMActivityDetailScreen({
    required this.activityId,
    required this.activityTitle,
    super.key,
  });

  final int activityId;
  final String activityTitle;

  @override
  State<EMActivityDetailScreen> createState() => _EMActivityDetailScreenState();
}

class _EMActivityDetailScreenState extends State<EMActivityDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  EMActivityTracking? _tracking;
  List<EMActivityStudent> _students = [];
  List<EMActivityWorkLog> _workLogs = [];

  bool _loadingTracking = true;
  bool _loadingStudents = false;
  bool _loadingLogs = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTracking();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 1:
        if (_students.isEmpty) _loadStudents();
      case 2:
        if (_workLogs.isEmpty) _loadWorkLogs();
      default:
        break;
    }
  }

  Future<void> _loadTracking() async {
    setState(() {
      _loadingTracking = true;
      _error = null;
    });
    try {
      final t = await EventManagerRepository.getActivityTracking(widget.activityId);
      setState(() => _tracking = t);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingTracking = false);
    }
  }

  Future<void> _loadStudents() async {
    setState(() => _loadingStudents = true);
    try {
      final s = await EventManagerRepository.getActivityStudents(widget.activityId);
      setState(() => _students = s);
    } catch (_) {}
    setState(() => _loadingStudents = false);
  }

  Future<void> _loadWorkLogs() async {
    setState(() => _loadingLogs = true);
    try {
      final l = await EventManagerRepository.getActivityWorkLogs(widget.activityId);
      setState(() => _workLogs = l);
    } catch (_) {}
    setState(() => _loadingLogs = false);
  }

  Future<void> _reviewSubmission(int submissionId, String status) async {
    String? notes;
    if (status == 'rejected' || status == 'needs_correction') {
      notes = await _askNotes(context);
      if (notes == null) return;
    }
    await EventManagerRepository.reviewSubmission(
      submissionId,
      status: status,
      reviewerNotes: notes,
    );
    await _loadWorkLogs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission ${status.replaceAll('_', ' ')}')),
      );
    }
  }

  Future<String?> _askNotes(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Remarks'),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.7),
          child: SingleChildScrollView(
            child: TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Reason for rejection / correction needed...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Submit')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.activityTitle,
            overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _loadTracking();
              if (_tabController.index == 1) _loadStudents();
              if (_tabController.index == 2) _loadWorkLogs();
            },
          ),
          if (_tracking != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit Activity',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EMEditActivityScreen(
                    activity: EMActivity.fromJson({
                      'id': widget.activityId,
                      'title': _tracking!.title,
                      'category': 'event_organization',
                      'description': _tracking!.description,
                      'location': _tracking!.location,
                      'reward_hours': _tracking!.rewardHours,
                      'certificate_eligible': _tracking!.certificateEligible,
                      'expected_work': _tracking!.expectedWork,
                    }),
                    onSaved: _loadTracking,
                  ),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.info_outline_rounded, size: 18), text: 'Overview'),
            Tab(icon: Icon(Icons.people_outline_rounded, size: 18), text: 'Students'),
            Tab(icon: Icon(Icons.assignment_outlined, size: 18), text: 'Work Logs'),
            Tab(icon: Icon(Icons.workspace_premium_outlined, size: 18), text: 'Certs'),
          ],
        ),
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) => _tabController.index == 1
            ? FloatingActionButton.extended(
                onPressed: _openAssignStudents,
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Assign Students'),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              )
            : const SizedBox.shrink(),
      ),
      body: _loadingTracking
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _loadTracking)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _OverviewTab(tracking: _tracking!),
                    _StudentsTab(
                      students: _students,
                      loading: _loadingStudents,
                      onRefresh: _loadStudents,
                      tracking: _tracking!,
                    ),
                    _WorkLogsTab(
                      logs: _workLogs,
                      loading: _loadingLogs,
                      onRefresh: _loadWorkLogs,
                      onReview: _reviewSubmission,
                    ),
                    _CertificatesTab(tracking: _tracking!),
                  ],
                ),
    );
  }

  Future<void> _openAssignStudents() async {
    final assignedIds = {
      ..._students.map((s) => s.studentId),
      ..._tracking?.students.map((s) => s.student.id) ?? [],
    };
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EMAssignStudentsScreen(
          activityId: widget.activityId,
          activityTitle: widget.activityTitle,
          alreadyAssignedIds: assignedIds,
        ),
      ),
    );
    if (result == true) _loadStudents();
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.tracking});
  final EMActivityTracking tracking;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(
            icon: Icons.analytics_rounded, title: 'Activity Summary'),
        const SizedBox(height: 10),
        _StatsGrid(stats: tracking.stats),
        const SizedBox(height: 20),
        _SectionHeader(icon: Icons.info_outline_rounded, title: 'Details'),
        const SizedBox(height: 10),
        _InfoCard(children: [
          _infoRow(Icons.title_rounded, 'Title', tracking.title),
          if (tracking.description != null)
            _infoRow(Icons.description_outlined, 'Description',
                tracking.description!),
          if (tracking.location != null)
            _infoRow(Icons.place_rounded, 'Location', tracking.location!),
          if (tracking.expectedWork != null)
            _infoRow(Icons.work_outline_rounded, 'Expected Work',
                tracking.expectedWork!),
          _infoRow(Icons.access_time_rounded, 'Reward Hours',
              '${tracking.rewardHours?.toStringAsFixed(1) ?? 0} hours'),
          _infoRow(
              Icons.workspace_premium_outlined,
              'Certificate Eligible',
              tracking.certificateEligible ? 'Yes' : 'No'),
        ]),
      ],
    );
  }

  static Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.muted),
            const SizedBox(width: 10),
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final EMTrackingStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: [
        _statTile(Icons.people_rounded, '${stats.totalAssigned}',
            'Total Assigned', const Color(0xFF1565C0)),
        _statTile(Icons.upload_file_rounded, '${stats.submitted}',
            'Submitted', const Color(0xFFF57F17)),
        _statTile(Icons.check_circle_rounded, '${stats.approved}',
            'Approved', const Color(0xFF2E7D32)),
        _statTile(Icons.hourglass_top_rounded, '${stats.pending}',
            'Pending', const Color(0xFFC62828)),
      ],
    );
  }

  static Widget _statTile(
          IconData icon, String val, String label, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(val,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ],
        ),
      );
}

// ── Students Tab ──────────────────────────────────────────────────────────────

class _StudentsTab extends StatelessWidget {
  const _StudentsTab({
    required this.students,
    required this.loading,
    required this.onRefresh,
    required this.tracking,
  });

  final List<EMActivityStudent> students;
  final bool loading;
  final Future<void> Function() onRefresh;
  final EMActivityTracking tracking;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    final displayList = students.isNotEmpty
        ? students
        : tracking.students
            .map((t) => EMActivityStudent(
                  assignmentId: t.assignmentId,
                  studentId: t.student.id,
                  name: t.student.name,
                  email: t.student.email,
                  phone: t.student.phone,
                  location: t.student.location,
                  assignmentStatus: t.assignmentStatus.name,
                  assignedAt: t.assignedAt,
                  workStatus: t.latestSubmission?.status,
                  hoursWorked: t.latestSubmission?.hoursWorked ?? 0,
                ))
            .toList();

    if (displayList.isEmpty) {
      return const _EmptyState(
        icon: Icons.people_outline_rounded,
        message: 'No students assigned yet',
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: displayList.length,
        separatorBuilder: (context, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) => _StudentCard(student: displayList[i]),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});
  final EMActivityStudent student;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(student.assignmentStatus);
    return Card(
      elevation: 0.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                student.initials,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.ink)),
                  Text(student.email,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _chip(student.assignmentStatus
                          .replaceAll('_', ' ')
                          .toUpperCase(), statusColor),
                      if (student.workStatus != null) ...[
                        const SizedBox(width: 6),
                        _chip(
                            'Work: ${student.workStatus!.replaceAll('_', ' ')}',
                            const Color(0xFF1565C0)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${student.hoursWorked.toStringAsFixed(1)}h',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 15)),
                const Text('hours',
                    style: TextStyle(color: AppColors.muted, fontSize: 11)),
                if (student.certificateStatus != null)
                  const Icon(Icons.workspace_premium_rounded,
                      color: Color(0xFF6A1B9A), size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700),
        ),
      );

  static Color _statusColor(String status) => switch (status) {
        'assigned' => const Color(0xFFE65100),
        'workSubmitted' || 'submitted' => const Color(0xFFF57F17),
        'verified' || 'event_manager_verified' => const Color(0xFF00695C),
        'approved' || 'admin_approved' => const Color(0xFF2E7D32),
        'certificateEligible' || 'certificate_generated' =>
          const Color(0xFF6A1B9A),
        'rejected' => const Color(0xFFC62828),
        _ => AppColors.muted,
      };
}

// ── Work Logs Tab ─────────────────────────────────────────────────────────────

class _WorkLogsTab extends StatelessWidget {
  const _WorkLogsTab({
    required this.logs,
    required this.loading,
    required this.onRefresh,
    required this.onReview,
  });

  final List<EMActivityWorkLog> logs;
  final bool loading;
  final Future<void> Function() onRefresh;
  final Future<void> Function(int submissionId, String status) onReview;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (logs.isEmpty) {
      return const _EmptyState(
        icon: Icons.assignment_outlined,
        message: 'No work logs yet',
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        separatorBuilder: (context, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) =>
            _WorkLogCard(log: logs[i], onReview: onReview),
      ),
    );
  }
}

class _WorkLogCard extends StatelessWidget {
  const _WorkLogCard({required this.log, required this.onReview});
  final EMActivityWorkLog log;
  final Future<void> Function(int submissionId, String status) onReview;

  static const _statusColors = <String, Color>{
    'submitted': Color(0xFFF57F17),
    'under_review': Color(0xFF1565C0),
    'approved': Color(0xFF2E7D32),
    'rejected': Color(0xFFC62828),
    'needs_correction': Color(0xFFE65100),
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[log.status] ?? AppColors.muted;
    final isPending =
        log.status == 'submitted' || log.status == 'under_review';

    return Card(
      elevation: 0.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.studentName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink)),
                      Text(log.title,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    log.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(log.description,
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                _meta(Icons.access_time_rounded,
                    '${log.hoursWorked.toStringAsFixed(1)}h'),
                const SizedBox(width: 14),
                _meta(Icons.people_rounded, '${log.peopleReached} reached'),
                if (log.donationCollected > 0) ...[
                  const SizedBox(width: 14),
                  _meta(Icons.payments_rounded,
                      '₹${log.donationCollected.toStringAsFixed(0)}'),
                ],
                if (log.proofFiles.isNotEmpty) ...[
                  const SizedBox(width: 14),
                  _meta(Icons.attach_file_rounded,
                      '${log.proofFiles.length} files'),
                ],
              ],
            ),
            if (log.reviewerNotes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.comment_outlined,
                        size: 14, color: Color(0xFFE65100)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        log.reviewerNotes!,
                        style: const TextStyle(
                            color: Color(0xFFE65100), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          onReview(log.submissionId, 'approved'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          onReview(log.submissionId, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFC62828),
                        side: const BorderSide(color: Color(0xFFC62828)),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () =>
                        onReview(log.submissionId, 'needs_correction'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE65100),
                      side: const BorderSide(color: Color(0xFFE65100)),
                    ),
                    child: const Text('Fix', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _meta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.muted),
          const SizedBox(width: 3),
          Text(text,
              style:
                  const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      );
}

// ── Certificates Tab ──────────────────────────────────────────────────────────

class _CertificatesTab extends StatelessWidget {
  const _CertificatesTab({required this.tracking});
  final EMActivityTracking tracking;

  @override
  Widget build(BuildContext context) {
    final eligible = tracking.students
        .where((s) =>
            s.assignmentStatus == AssignmentStatus.approved ||
            s.assignmentStatus == AssignmentStatus.certificateEligible)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(
            icon: Icons.workspace_premium_rounded,
            title: 'Certificate Eligibility'),
        const SizedBox(height: 10),
        _InfoCard(children: [
          _row(Icons.how_to_reg_rounded, 'Total Assigned',
              '${tracking.stats.totalAssigned}'),
          _row(Icons.check_circle_rounded, 'Approved Students',
              '${tracking.stats.approved}'),
          _row(Icons.workspace_premium_rounded, 'Certificate Eligible',
              '${eligible.length}'),
          _row(Icons.verified_rounded, 'Activity Certificate',
              tracking.certificateEligible ? 'Enabled' : 'Disabled'),
        ]),
        const SizedBox(height: 20),
        if (eligible.isEmpty)
          const _EmptyState(
            icon: Icons.workspace_premium_outlined,
            message:
                'No students are certificate-eligible yet.\nApprove work submissions first.',
          )
        else ...[
          _SectionHeader(
              icon: Icons.people_rounded,
              title: 'Eligible Students (${eligible.length})'),
          const SizedBox(height: 10),
          ...eligible.map(
            (s) => ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    const Color(0xFF6A1B9A).withValues(alpha: 0.12),
                child: Text(
                  s.student.initials,
                  style: const TextStyle(
                      color: Color(0xFF6A1B9A),
                      fontWeight: FontWeight.w900),
                ),
              ),
              title: Text(s.student.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(s.student.email),
              trailing: s.assignmentStatus ==
                      AssignmentStatus.certificateEligible
                  ? const Icon(Icons.workspace_premium_rounded,
                      color: Color(0xFF6A1B9A))
                  : const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF2E7D32)),
            ),
          ),
        ],
      ],
    );
  }

  static Widget _row(IconData icon, String label, String val) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.muted),
            const SizedBox(width: 10),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600))),
            Text(val,
                style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      );
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 7),
          Text(
            title,
            style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 15),
          ),
        ],
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: children
              .expand((w) => [
                    w,
                    Divider(
                        height: 1,
                        color: AppColors.muted.withValues(alpha: 0.12))
                  ])
              .toList()
            ..removeLast(),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: AppColors.muted.withValues(alpha: 0.4)),
              const SizedBox(height: 14),
              Text(
                message,
                style: const TextStyle(color: AppColors.muted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.softRed, size: 40),
            const SizedBox(height: 12),
            Text(error,
                style: const TextStyle(color: AppColors.muted),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
                onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}
