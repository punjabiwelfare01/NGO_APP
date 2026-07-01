import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/event_manager_models.dart';
import '../../viewmodels/event_manager_viewmodel.dart';
import 'em_activity_detail_screen.dart';
import 'em_assign_students_screen.dart';
import 'em_create_activity_screen.dart';
import 'em_edit_activity_screen.dart';

class EMActivitiesView extends StatefulWidget {
  const EMActivitiesView({required this.vm, super.key});
  final EventManagerViewModel vm;

  @override
  State<EMActivitiesView> createState() => _EMActivitiesViewState();
}

class _EMActivitiesViewState extends State<EMActivitiesView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String? _filterStatus;

  static const _tabs = ['All', 'Active', 'Draft', 'Completed', 'Cancelled'];
  static const _tabStatuses = [null, 'active', 'draft', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _filterStatus = _tabStatuses[_tabController.index]);
      }
    });
    widget.vm.loadActivities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<EMActivity> get _filtered {
    final all = widget.vm.activities;
    if (_filterStatus == null) return all;
    return all.where((a) => a.status.name == _filterStatus).toList();
  }

  Future<void> _openCreate(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EMCreateActivityScreen(vm: widget.vm),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) => Column(
        children: [
          _Header(vm: widget.vm, onCreateTap: () => _openCreate(context)),
          _StatsBar(activities: widget.vm.activities),
          _FilterTabBar(controller: _tabController, tabs: _tabs),
          Expanded(
            child: widget.vm.activitiesLoading
                ? const Center(child: CircularProgressIndicator())
                : widget.vm.activitiesError != null
                    ? _ErrorView(
                        error: widget.vm.activitiesError!,
                        onRetry: widget.vm.loadActivities,
                      )
                    : _filtered.isEmpty
                        ? _EmptyState(status: _filterStatus)
                        : RefreshIndicator(
                            onRefresh: widget.vm.loadActivities,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) => _ActivityCard(
                                activity: _filtered[i],
                                vm: widget.vm,
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.vm, required this.onCreateTap});
  final EventManagerViewModel vm;
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      color: Colors.white,
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Activities',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Manage activities you have created',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: vm.loadActivities,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Create',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Bar ─────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.activities});
  final List<EMActivity> activities;

  @override
  Widget build(BuildContext context) {
    final active = activities.where((a) => a.status == ActivityStatus.active).length;
    final pending = activities.fold(0, (sum, a) => sum + a.pendingApprovals);
    final certs = activities.fold(0, (sum, a) => sum + a.certificatesGenerated);
    final students = activities.fold(0, (sum, a) => sum + a.assignedStudents);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFF0F4FF),
      child: Row(
        children: [
          _stat('${activities.length}', 'Total', Icons.list_alt_rounded, const Color(0xFF1565C0)),
          _divider(),
          _stat('$active', 'Active', Icons.play_circle_outline_rounded, const Color(0xFF2E7D32)),
          _divider(),
          _stat('$students', 'Students', Icons.people_outline_rounded, const Color(0xFFE65100)),
          _divider(),
          _stat('$pending', 'Pending', Icons.hourglass_top_rounded, const Color(0xFFF57F17)),
          _divider(),
          _stat('$certs', 'Certs', Icons.workspace_premium_outlined, const Color(0xFF6A1B9A)),
        ],
      ),
    );
  }

  static Widget _stat(String val, String label, IconData icon, Color color) =>
      Expanded(
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              val,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  static Widget _divider() => Container(
        height: 36,
        width: 1,
        color: AppColors.muted.withValues(alpha: 0.2),
      );
}

// ── Tab Bar ───────────────────────────────────────────────────────────────────

class _FilterTabBar extends StatelessWidget {
  const _FilterTabBar({required this.controller, required this.tabs});
  final TabController controller;
  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.muted,
        indicatorColor: AppColors.primary,
        tabs: tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }
}

// ── Activity Card ─────────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.vm});
  final EMActivity activity;
  final EventManagerViewModel vm;

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final status = activity.status;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EMActivityDetailScreen(
              activityId: activity.id,
              activityTitle: activity.title,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row + status chip
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(status.icon, color: status.color, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _categoryLabel(activity.category),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        if (activity.eventName != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.event_rounded,
                                  size: 11, color: Color(0xFF1565C0)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  activity.eventName!,
                                  style: const TextStyle(
                                    color: Color(0xFF1565C0),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(Icons.link_off_rounded,
                                  size: 11, color: AppColors.muted),
                              SizedBox(width: 4),
                              Text(
                                'Standalone',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  _StatusChip(status: status),
                ],
              ),
              const SizedBox(height: 12),

              // Date + location
              Row(
                children: [
                  if (activity.startDate != null) ...[
                    const Icon(Icons.calendar_today_rounded,
                        size: 13, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      activity.endDate != null
                          ? '${_fmtDate(activity.startDate!)} – ${_fmtDate(activity.endDate!)}'
                          : _fmtDate(activity.startDate!),
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 11),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (activity.location != null) ...[
                    const Icon(Icons.place_rounded,
                        size: 13, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        activity.location!,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Stats row
              _StatsRow(activity: activity),
              const SizedBox(height: 12),

              // Action buttons
              _ActionButtons(activity: activity, vm: vm),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(String cat) => cat
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
      .join(' ');
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final ActivityStatus status;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: status.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 11, color: status.color),
            const SizedBox(width: 4),
            Text(
              status.label,
              style: TextStyle(
                color: status.color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.activity});
  final EMActivity activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _metric(Icons.people_rounded, '${activity.assignedStudents}',
              'Students', const Color(0xFF1565C0)),
          _divider(),
          _metric(Icons.check_circle_outline_rounded,
              '${activity.completedWorkLogs}', 'Done', const Color(0xFF2E7D32)),
          _divider(),
          _metric(Icons.hourglass_top_rounded,
              '${activity.pendingApprovals}', 'Pending', const Color(0xFFF57F17)),
          _divider(),
          _metric(Icons.workspace_premium_outlined,
              '${activity.certificatesGenerated}', 'Certs', const Color(0xFF6A1B9A)),
          _divider(),
          _metric(Icons.access_time_rounded,
              '${activity.rewardHours.toStringAsFixed(0)}h', 'Hours',
              const Color(0xFFE65100)),
        ],
      ),
    );
  }

  static Widget _metric(
          IconData icon, String val, String label, Color color) =>
      Expanded(
        child: Column(
          children: [
            Text(val,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 13)),
            Text(label,
                style:
                    const TextStyle(color: AppColors.muted, fontSize: 10)),
          ],
        ),
      );

  static Widget _divider() => Container(
      height: 24,
      width: 1,
      color: AppColors.muted.withValues(alpha: 0.2));
}

// ── Action Buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.activity, required this.vm});
  final EMActivity activity;
  final EventManagerViewModel vm;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _actionBtn(
            context,
            Icons.visibility_rounded,
            'View Details',
            AppColors.primary,
            () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => EMActivityDetailScreen(
                activityId: activity.id,
                activityTitle: activity.title,
              ),
            )),
          ),
          const SizedBox(width: 6),
          if (activity.status == ActivityStatus.active ||
              activity.status == ActivityStatus.draft)
            _actionBtn(
              context,
              Icons.person_add_rounded,
              'Assign Students',
              AppColors.primary,
              () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => EMAssignStudentsScreen(
                      activityId: activity.id,
                      activityTitle: activity.title,
                      alreadyAssignedIds: const {},
                    ),
                  ),
                );
                if (result == true) vm.loadActivities();
              },
            ),
          const SizedBox(width: 6),
          if (activity.status != ActivityStatus.completed &&
              activity.status != ActivityStatus.cancelled)
            _actionBtn(
              context,
              Icons.edit_rounded,
              'Edit',
              const Color(0xFF00695C),
              () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => EMEditActivityScreen(
                  activity: activity,
                  vm: vm,
                ),
              )),
            ),
          const SizedBox(width: 6),
          if (activity.status == ActivityStatus.active)
            _actionBtn(
              context,
              Icons.check_circle_rounded,
              'Mark Complete',
              const Color(0xFF2E7D32),
              () => _confirmComplete(context),
            ),
          const SizedBox(width: 6),
          if (activity.status == ActivityStatus.active ||
              activity.status == ActivityStatus.draft)
            _actionBtn(
              context,
              Icons.cancel_rounded,
              'Cancel',
              const Color(0xFFC62828),
              () => _confirmCancel(context),
            ),
        ],
      ),
    );
  }

  Widget _actionBtn(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) =>
      OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        icon: Icon(icon, size: 14),
        label:
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      );

  Future<void> _confirmComplete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Completed?'),
        content: Text(
            'Are you sure you want to mark "${activity.title}" as completed?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Complete')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await vm.editActivity(activity.id, {'status': 'completed'});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity marked as completed')),
        );
      }
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Activity?'),
        content: Text('Are you sure you want to cancel "${activity.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  FilledButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
              child: const Text('Cancel Activity')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await vm.editActivity(activity.id, {'status': 'cancelled'});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity cancelled')),
        );
      }
    }
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.status});
  final String? status;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: AppColors.muted.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                status == null
                    ? 'No activities yet'
                    : 'No ${status!} activities',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Activities you create will appear here.',
                style: TextStyle(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
        ),
      );
}
