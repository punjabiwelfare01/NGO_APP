import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/event_manager_models.dart';
import '../../models/counsellor_models.dart';
import '../../repositories/event_manager_repository.dart';
import '../../viewmodels/event_manager_viewmodel.dart';
import '../../viewmodels/counsellor_viewmodel.dart';
import '../../widgets/app_card.dart';
import 'counsellor_requests_screen.dart';
import '../events/official_event_report_screen.dart';

class EMHomeView extends StatelessWidget {
  const EMHomeView({
    required this.vm,
    required this.managerName,
    this.onNavigateToStudents,
    super.key,
  });

  final EventManagerViewModel vm;
  final String managerName;
  final void Function(int subTabIndex)? onNavigateToStudents;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.state == EMLoadState.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.state == EMLoadState.error) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.softRed,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  vm.error ?? 'Something went wrong',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: vm.load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          children: [
            _Header(name: managerName, vm: vm),
            const SizedBox(height: 16),
            _TodayPriorityCard(vm: vm),
            const SizedBox(height: 18),
            _StatsRow(stats: vm.stats, studentsReached: _studentsReached(vm)),
            const SizedBox(height: 20),
            _QuickActionsGrid(vm: vm, onNavigateToStudents: onNavigateToStudents),
            const SizedBox(height: 22),
            if (vm.todayEvents.isNotEmpty) ...[
              _TodayEventsSection(events: vm.todayEvents),
              const SizedBox(height: 22),
            ],
            if (vm.pendingSubmissions.isNotEmpty) ...[
              _PendingSubmissionsSection(
                assignments: vm.pendingSubmissions,
                vm: vm,
              ),
              const SizedBox(height: 22),
            ],
            _SchoolRequestsSection(store: CounsellorViewModel.shared),
            const SizedBox(height: 22),
            if (vm.draftPosts.isNotEmpty) ...[
              _DraftPostsSection(posts: vm.draftPosts, vm: vm),
              const SizedBox(height: 22),
            ],
            _DonationCampaignSummary(vm: vm),
            const SizedBox(height: 22),
            _ReportsPendingSection(vm: vm),
            const SizedBox(height: 22),
            _RecentActivitySection(vm: vm),
          ],
        );
      },
    );
  }

  int _studentsReached(EventManagerViewModel vm) => vm.assignments.fold(
    0,
    (sum, assignment) => sum + (assignment.submission?.peopleReached ?? 0),
  );
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.vm});
  final String name;
  final EventManagerViewModel vm;

  @override
  Widget build(BuildContext context) {
    final totalAlerts =
        vm.stats.pendingSubmissions +
        vm.appliedStudents.length +
        vm.draftPosts.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assests/ngo_logo.jpeg',
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 46,
                  height: 46,
                  color: AppColors.primary.withValues(alpha: .1),
                  child: const Icon(
                    Icons.volunteer_activism_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning, ${name.split(' ').first} 👋',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manage events, volunteers, and impact stories today.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Badge(
              isLabelVisible: totalAlerts > 0,
              label: Text('$totalAlerts'),
              child: IconButton.filledTonal(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$totalAlerts operational updates need attention.',
                    ),
                  ),
                ),
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
              ),
            ),
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 21,
              backgroundColor: const Color(0xFFDDEEFF),
              child: Text(
                name.trim().isEmpty ? 'E' : name.trim()[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 16),
              SizedBox(width: 5),
              Text(
                'Verified NGO Event Management',
                style: TextStyle(
                  color: Color(0xFF1B5E20),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayPriorityCard extends StatelessWidget {
  const _TodayPriorityCard({required this.vm});
  final EventManagerViewModel vm;

  @override
  Widget build(BuildContext context) {
    final schoolCount = CounsellorViewModel.shared.pendingRequests.length;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: .22),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: Color(0xFFFFD54F), size: 21),
              SizedBox(width: 7),
              Text(
                'Today’s Priority',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _priority('${vm.todayEvents.length}', 'events today'),
              _priority(
                '${vm.pendingSubmissions.length}',
                'submissions pending',
              ),
              _priority('$schoolCount', 'school requests'),
              _priority('${vm.draftPosts.length}', 'impact drafts'),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (_) => _TodayTasksSheet(vm: vm),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
            ),
            icon: const Icon(Icons.checklist_rounded, size: 18),
            label: const Text('View Today’s Tasks'),
          ),
        ],
      ),
    );
  }

  static Widget _priority(String value, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$value ',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(
            text: label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats, required this.studentsReached});
  final EventManagerStats stats;
  final int studentsReached;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Stats',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.event_rounded,
                  value: '${stats.activeActivities}',
                  label: 'Active Events',
                  color: const Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.pending_actions_rounded,
                  value: '${stats.pendingSubmissions}',
                  label: 'Pending Work',
                  color: const Color(0xFFF57F17),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.auto_awesome_rounded,
                  value: '${stats.pendingImpactPosts}',
                  label: 'Impact Drafts',
                  color: const Color(0xFF6A1B9A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.groups_rounded,
                  value: '$studentsReached',
                  label: 'Students Reached',
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions Grid ───────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.vm, this.onNavigateToStudents});
  final EventManagerViewModel vm;
  final void Function(int subTabIndex)? onNavigateToStudents;

  void _openCreateEvent(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateEventSheet(vm: vm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.add_circle_rounded,
        label: 'Create Event',
        color: const Color(0xFF1565C0),
        onTap: () => _openCreateEvent(context),
      ),
      _QuickAction(
        icon: Icons.add_task_rounded,
        label: 'Create Activity',
        color: const Color(0xFF2E7D32),
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _CreateActivitySheet(vm: vm),
          );
        },
      ),
      _QuickAction(
        icon: Icons.person_add_rounded,
        label: 'Assign Students',
        color: const Color(0xFFE65100),
        onTap: () => onNavigateToStudents?.call(0),
      ),
      _QuickAction(
        icon: Icons.rate_review_rounded,
        label: 'Review Submissions',
        color: const Color(0xFFF57F17),
        badge: vm.stats.pendingSubmissions > 0
            ? '${vm.stats.pendingSubmissions}'
            : null,
        onTap: () => onNavigateToStudents?.call(2),
      ),
      _QuickAction(
        icon: Icons.auto_awesome_rounded,
        label: 'Create Impact Post',
        color: const Color(0xFF6A1B9A),
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _CreateImpactPostSheet(vm: vm),
          );
        },
      ),
      _QuickAction(
        icon: Icons.description_rounded,
        label: 'Generate Report',
        color: const Color(0xFF00695C),
        onTap: () => _generateReport(context),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: actions.map((a) => _QuickActionTile(action: a)).toList(),
        ),
      ],
    );
  }

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _generateReport(BuildContext context) async {
    final completed = vm.events
        .where((event) => event.status == EventStatus.completed)
        .toList();
    final event = completed.firstOrNull ?? vm.events.firstOrNull;
    if (event == null) {
      _showSnackBar(context, 'Create an event before generating a report.');
      return;
    }
    final report = await vm.generateReport(event.id);
    if (!context.mounted) return;
    final assignments =
        vm.assignments.where((a) => a.event.id == event.id).toList();
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => OfficialEventReportScreen(
          event: event,
          assignments: assignments,
          report: report,
          vm: vm,
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: action.color.withValues(alpha: 0.20),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: action.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(action.icon, color: action.color, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (action.badge != null)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.softRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    action.badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Today's Events ───────────────────────────────────────────────────────────

class _TodayEventsSection extends StatelessWidget {
  const _TodayEventsSection({required this.events});
  final List<NGOEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.today_rounded, color: Color(0xFF1565C0), size: 20),
            const SizedBox(width: 6),
            const Text(
              'Today\'s Events',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'LIVE',
                style: const TextStyle(
                  color: Color(0xFFE65100),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final event in events) ...[
          _EventSummaryCard(event: event),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _EventSummaryCard extends StatelessWidget {
  const _EventSummaryCard({required this.event});
  final NGOEvent event;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: event.status.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              event.category.icon,
              color: event.status.color,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${event.date.hour.toString().padLeft(2, '0')}:${event.date.minute.toString().padLeft(2, '0')} • ${event.location}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${event.activities.fold<int>(0, (sum, item) => sum + item.assignedCount)} volunteers assigned',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              _StatusBadge(
                label: event.status.label,
                color: event.status.color,
              ),
              const SizedBox(height: 3),
              TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Open Events tab to manage ${event.title}.'),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Manage', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Pending Submissions ──────────────────────────────────────────────────────

class _PendingSubmissionsSection extends StatelessWidget {
  const _PendingSubmissionsSection({
    required this.assignments,
    required this.vm,
  });
  final List<EMStudentAssignment> assignments;
  final EventManagerViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.pending_actions_rounded,
              color: Color(0xFFF57F17),
              size: 20,
            ),
            const SizedBox(width: 6),
            const Text(
              'Pending Student Submissions',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF57F17).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${assignments.length} pending',
                style: const TextStyle(
                  color: Color(0xFFF57F17),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final a in assignments.take(3)) ...[
          _PendingCard(assignment: a, vm: vm),
          const SizedBox(height: 10),
        ],
        if (assignments.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+${assignments.length - 3} more — go to Students tab',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.assignment, required this.vm});
  final EMStudentAssignment assignment;
  final EventManagerViewModel vm;

  @override
  Widget build(BuildContext context) {
    final sub = assignment.submission!;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StudentAvatar(student: assignment.student, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.student.name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      assignment.activity.role.label,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const _StatusBadge(label: 'Submitted', color: Color(0xFFF57F17)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFF57F17).withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.workTitle,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${sub.hoursWorked}h worked',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.people_rounded,
                      size: 12,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${sub.peopleReached} reached',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${sub.photoUrls.isEmpty ? 'Report uploaded' : '${sub.photoUrls.length} photo proof(s) uploaded'}'
                  '${(sub.donationCollected ?? 0) > 0 ? ' • Donation ₹${sub.donationCollected!.toStringAsFixed(0)}' : ' • No donation'}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => vm.updateAssignmentStatus(
                    assignment.id,
                    AssignmentStatus.rejected,
                    notes: 'Please resubmit with more detail.',
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.softRed,
                    side: BorderSide(
                      color: AppColors.softRed.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => vm.updateAssignmentStatus(
                    assignment.id,
                    AssignmentStatus.approved,
                    notes: 'Well done! Work approved.',
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => vm.updateAssignmentStatus(
                  assignment.id,
                  AssignmentStatus.assigned,
                  notes: 'Please resubmit with the requested proof.',
                ),
                child: const Text(
                  'Ask Resubmission',
                  style: TextStyle(fontSize: 10),
                ),
              ),
              TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Submission forwarded to Admin for final review.',
                    ),
                  ),
                ),
                child: const Text(
                  'Forward to Admin',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Draft Posts Section ──────────────────────────────────────────────────────

class _DraftPostsSection extends StatelessWidget {
  const _DraftPostsSection({required this.posts, required this.vm});
  final List<EMImpactPost> posts;
  final EventManagerViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF6A1B9A),
              size: 20,
            ),
            const SizedBox(width: 6),
            const Text(
              'Impact Promotion Center',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MiniMetric(
                label: 'Drafts',
                value: '${posts.where((p) => !p.isPublished).length}',
                color: const Color(0xFF6A1B9A),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniMetric(
                label: 'Pending Approval',
                value:
                    '${posts.where((p) => p.isPublished && !p.adminApproved).length}',
                color: const Color(0xFFF57F17),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniMetric(
                label: 'Published',
                value: '${vm.publishedPosts.length}',
                color: const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final post in posts.take(2)) ...[
          _DraftPostCard(post: post, vm: vm),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _DraftPostCard extends StatelessWidget {
  const _DraftPostCard({required this.post, required this.vm});
  final EMImpactPost post;
  final EventManagerViewModel vm;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: post.type.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(post.type.icon, color: post.type.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      post.type.label,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                label: post.isPublished ? 'Sent for Approval' : 'Draft',
                color: post.isPublished
                    ? const Color(0xFF1565C0)
                    : const Color(0xFF757575),
              ),
            ],
          ),
          if (!post.isPublished) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  vm.submitImpactPostForApproval(post.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Impact post sent to Admin for approval'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Submit for Admin Approval'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SchoolRequestsSection extends StatelessWidget {
  const _SchoolRequestsSection({required this.store});
  final CounsellorViewModel store;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (_, _) {
      final requests = store.requests
          .where(
            (r) =>
                r.status != RequestStatus.completed &&
                r.status != RequestStatus.cancelled,
          )
          .take(3)
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: 'School Counselling Requests',
            icon: Icons.school_rounded,
            action: 'View all',
            onAction: () => _openRequests(context),
          ),
          const SizedBox(height: 10),
          if (requests.isEmpty)
            const _CompactEmpty(
              icon: Icons.task_alt_rounded,
              text: 'No school requests need attention.',
            )
          else
            for (final request in requests) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: request.status.color.withValues(alpha: .2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            request.schoolName,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _RequestStatusChip(status: request.status),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${request.topic} • ${request.studentCount} students',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Preferred: ${request.preferredDate.day}/${request.preferredDate.month}/${request.preferredDate.year} • ${request.sessionMode.label}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => _openRequests(context),
                      icon: const Icon(Icons.person_search_rounded, size: 17),
                      label: Text(
                        request.status == RequestStatus.pending
                            ? 'Assign Counsellor'
                            : 'Manage Request',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
            ],
        ],
      );
    },
  );

  void _openRequests(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const CounsellorRequestsScreen()));
}

class _DonationCampaignSummary extends StatelessWidget {
  const _DonationCampaignSummary({required this.vm});
  final EventManagerViewModel vm;

  static const _upi     = 'punjabiwelfaretrust@upi';
  static const _account = '35270101011873';
  static const _ifsc    = 'UBIN0535273';
  static const _bank    = 'Union Bank of India';
  static const _branch  = 'Delhi-Cantonment Branch, South West Delhi – 110010';
  static const _holder  = 'Punjabi Welfare Trust';

  @override
  Widget build(BuildContext context) {
    final drives = vm.events.where((e) => e.donationEligible).length;
    final collected = vm.assignments.fold<double>(
      0,
      (sum, a) => sum + (a.submission?.donationCollected ?? 0),
    );
    final pending = vm.pendingSubmissions
        .where((a) => (a.submission?.donationCollected ?? 0) > 0)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'Donation & Campaign',
          icon: Icons.volunteer_activism_rounded,
        ),
        const SizedBox(height: 10),

        // ── Campaign stats ────────────────────────────────────────
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Active Drives',
                  value: '$drives',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniMetric(
                  label: 'Collected',
                  value: '₹${collected.toStringAsFixed(0)}',
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniMetric(
                  label: 'Proof Pending',
                  value: '$pending',
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Payment details card ──────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Official Donation Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              color: Color(0xFF69FF8A), size: 11),
                          SizedBox(width: 3),
                          Text('Verified',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // QR code + bank details
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // QR code image
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assests/new_donation_qr.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(Icons.qr_code_rounded,
                                size: 52, color: Color(0xFF1565C0)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Bank details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _EMPayRow('Beneficiary', _holder),
                          _EMPayRow('Bank', _bank),
                          _EMPayRow('Branch', _branch),
                          _EMPayRow('Account No.', _account,
                              onCopy: () => _copy(context, _account,
                                  'Account number')),
                          _EMPayRow('IFSC', _ifsc,
                              onCopy: () =>
                                  _copy(context, _ifsc, 'IFSC code')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // UPI ID row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.smartphone_rounded,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      const Text('UPI ID: ',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 11)),
                      Expanded(
                        child: Text(_upi,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11)),
                      ),
                      GestureDetector(
                        onTap: () => _copy(context, _upi, 'UPI ID'),
                        child: const Icon(Icons.copy_rounded,
                            size: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Scan tip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    'Share this QR with donors — scan with any UPI app',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Warning footer
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.verified_user_outlined,
                          color: Color(0xFF69FF8A), size: 14),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Donations are accepted only through these official NGO bank / UPI details. Never use personal accounts.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied')),
    );
  }
}

class _EMPayRow extends StatelessWidget {
  const _EMPayRow(this.label, this.value, {this.onCopy});
  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: const TextStyle(
                  color: Colors.white60, fontSize: 10)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    height: 1.3)),
          ),
          if (onCopy != null)
            GestureDetector(
              onTap: onCopy,
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.copy_rounded,
                    size: 11, color: Colors.white60),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReportsPendingSection extends StatelessWidget {
  const _ReportsPendingSection({required this.vm});
  final EventManagerViewModel vm;
  @override
  Widget build(BuildContext context) {
    final events = vm.events
        .where((e) => e.status == EventStatus.completed)
        .take(2)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'Reports Pending',
          icon: Icons.description_rounded,
        ),
        const SizedBox(height: 10),
        if (events.isEmpty)
          const _CompactEmpty(
            icon: Icons.fact_check_outlined,
            text: 'No completed-event reports are pending.',
          )
        else
          for (final event in events)
            Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.muted.withValues(alpha: .14),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.pending_actions_rounded,
                    color: Color(0xFFE65100),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${event.title} Report',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'Photos, feedback, outcomes and metrics',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _generate(context, event),
                    child: const Text('Generate'),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Future<void> _generate(BuildContext context, NGOEvent event) async {
    final report = await vm.generateReport(event.id);
    if (!context.mounted) return;
    final assignments =
        vm.assignments.where((a) => a.event.id == event.id).toList();
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => OfficialEventReportScreen(
          event: event,
          assignments: assignments,
          report: report,
          vm: vm,
        ),
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.vm});
  final EventManagerViewModel vm;
  @override
  Widget build(BuildContext context) {
    final school = CounsellorViewModel.shared.requests.firstOrNull;
    final items = <(IconData, Color, String)>[
      for (final a in vm.pendingSubmissions.take(2))
        (
          Icons.upload_file_rounded,
          const Color(0xFFF57F17),
          '${a.student.name} submitted work for ${a.event.title}',
        ),
      if (vm.publishedPosts.isNotEmpty)
        (
          Icons.verified_rounded,
          const Color(0xFF2E7D32),
          'Admin approved “${vm.publishedPosts.first.title}”',
        ),
      if (school != null)
        (
          Icons.school_rounded,
          const Color(0xFF1565C0),
          '${school.schoolName} request is ${school.status.label.toLowerCase()}',
        ),
      if (vm.events.isNotEmpty)
        (
          Icons.event_available_rounded,
          const Color(0xFF6A1B9A),
          '${vm.events.first.title} is ${vm.events.first.status.label}',
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'Recent Activity',
          icon: Icons.history_rounded,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: items[i].$2.withValues(alpha: .1),
                      child: Icon(items[i].$1, color: items[i].$2, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        items[i].$3,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 11,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Text(
                      'Now',
                      style: TextStyle(color: AppColors.muted, fontSize: 9),
                    ),
                  ],
                ),
                if (i != items.length - 1) const Divider(height: 18),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayTasksSheet extends StatelessWidget {
  const _TodayTasksSheet({required this.vm});
  final EventManagerViewModel vm;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today’s Tasks',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _task(
            '${vm.todayEvents.length} events to coordinate',
            Icons.event_rounded,
          ),
          _task(
            '${vm.pendingSubmissions.length} submissions to review',
            Icons.rate_review_rounded,
          ),
          _task(
            '${CounsellorViewModel.shared.pendingRequests.length} school requests',
            Icons.school_rounded,
          ),
          _task(
            '${vm.draftPosts.length} impact drafts',
            Icons.auto_awesome_rounded,
          ),
        ],
      ),
    ),
  );
  Widget _task(String text, IconData icon) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: AppColors.primary),
    title: Text(text),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.icon,
    this.action,
    this.onAction,
  });
  final String title;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppColors.primary, size: 20),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _CompactEmpty extends StatelessWidget {
  const _CompactEmpty({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.secondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RequestStatusChip extends StatelessWidget {
  const _RequestStatusChip({required this.status});
  final RequestStatus status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: status.color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status.label,
      style: TextStyle(
        color: status.color,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StudentAvatar extends StatelessWidget {
  const _StudentAvatar({required this.student, this.radius = 22});
  final EMStudent student;
  final double radius;

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
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        student.initials,
        style: TextStyle(
          color: color,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─── Create Event Sheet ───────────────────────────────────────────────────────

class _CreateEventSheet extends StatefulWidget {
  const _CreateEventSheet({required this.vm});
  final EventManagerViewModel vm;

  @override
  State<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<_CreateEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _maxVolCtrl = TextEditingController(text: '20');
  final _eligibilityCtrl = TextEditingController();
  final _expectedWorkCtrl = TextEditingController();
  final _proofCtrl = TextEditingController();

  EventCategory _category = EventCategory.workshop;
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  bool _certificate = true;
  bool _donation = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _schoolCtrl.dispose();
    _descCtrl.dispose();
    _maxVolCtrl.dispose();
    _eligibilityCtrl.dispose();
    _expectedWorkCtrl.dispose();
    _proofCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final title = _titleCtrl.text.trim();
    final event = NGOEvent(
      id: 0,
      title: title,
      category: _category,
      status: EventStatus.draft,
      date: _date,
      location: _locationCtrl.text.trim(),
      partnerSchool: _schoolCtrl.text.trim().isEmpty
          ? null
          : _schoolCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      maxVolunteers: int.tryParse(_maxVolCtrl.text.trim()) ?? 20,
      studentEligibility: _eligibilityCtrl.text.trim().isEmpty
          ? null
          : _eligibilityCtrl.text.trim(),
      expectedWork: _expectedWorkCtrl.text.trim().isEmpty
          ? null
          : _expectedWorkCtrl.text.trim(),
      proofRequired: _proofCtrl.text.trim().isEmpty
          ? null
          : _proofCtrl.text.trim(),
      certificateEligible: _certificate,
      donationEligible: _donation,
      createdAt: DateTime.now(),
    );
    try {
      await widget.vm.addNewEvent(event);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create event: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Event "$title" created as Draft'),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.90,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  const Text(
                    'Create New Event',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                  children: [
                    _formLabel('Event Title *'),
                    _field(
                      _titleCtrl,
                      'e.g. Cyber Safety Awareness Camp',
                      required: true,
                    ),
                    const SizedBox(height: 14),
                    _formLabel('Category *'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: EventCategory.values
                          .map(
                            (c) => ChoiceChip(
                              label: Text(c.label),
                              selected: _category == c,
                              onSelected: (_) => setState(() => _category = c),
                              avatar: Icon(c.icon, size: 14),
                              selectedColor: const Color(
                                0xFF1565C0,
                              ).withValues(alpha: 0.15),
                              labelStyle: TextStyle(
                                color: _category == c
                                    ? const Color(0xFF1565C0)
                                    : AppColors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    _formLabel('Date *'),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.muted.withValues(alpha: 0.4),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: Color(0xFF1565C0),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${_date.day}/${_date.month}/${_date.year}',
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _formLabel('Location *'),
                    _field(
                      _locationCtrl,
                      'e.g. Delhi Public School, Cantt',
                      required: true,
                    ),
                    const SizedBox(height: 14),
                    _formLabel('Partner School / Organisation'),
                    _field(_schoolCtrl, 'Optional'),
                    const SizedBox(height: 14),
                    _formLabel('Description *'),
                    _field(
                      _descCtrl,
                      'What is this event about?',
                      required: true,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 14),
                    _formLabel('Max Volunteers *'),
                    _field(
                      _maxVolCtrl,
                      'e.g. 25',
                      required: true,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    _formLabel('Student Eligibility'),
                    _field(_eligibilityCtrl, 'e.g. All enrolled volunteers'),
                    const SizedBox(height: 14),
                    _formLabel('Expected Work'),
                    _field(
                      _expectedWorkCtrl,
                      'What will volunteers do?',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    _formLabel('Proof Required'),
                    _field(_proofCtrl, 'e.g. Photos, attendance sheet, report'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _ToggleTile(
                            icon: Icons.workspace_premium_rounded,
                            label: 'Certificate Eligible',
                            value: _certificate,
                            onChanged: (v) => setState(() => _certificate = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ToggleTile(
                            icon: Icons.payments_rounded,
                            label: 'Donation / Stipend',
                            value: _donation,
                            onChanged: (v) => setState(() => _donation = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save as Draft',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) => TextFormField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.muted.withValues(alpha: 0.6),
        fontSize: 13,
      ),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    validator: required
        ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
        : null,
  );
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFF1565C0).withValues(alpha: 0.06)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? const Color(0xFF1565C0).withValues(alpha: 0.3)
              : AppColors.muted.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? const Color(0xFF1565C0) : AppColors.muted,
            size: 18,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: value ? const Color(0xFF1565C0) : AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF1565C0),
            activeTrackColor: const Color(0xFF1565C0).withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}

// ─── Create Activity Sheet ────────────────────────────────────────────────────

class _CreateActivitySheet extends StatefulWidget {
  const _CreateActivitySheet({required this.vm});
  final EventManagerViewModel vm;

  @override
  State<_CreateActivitySheet> createState() => _CreateActivitySheetState();
}

class _CreateActivitySheetState extends State<_CreateActivitySheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _maxCtrl = TextEditingController(text: '5');

  ActivityRole _role = ActivityRole.volunteerSupport;
  NGOEvent? _selectedEvent;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  // Maps the EM-facing ActivityRole to the backend ActivityCategory enum value
  String _categoryForRole(ActivityRole role) => switch (role) {
    ActivityRole.awarenessSpeaker       => 'awareness_programs',
    ActivityRole.stationeryDistribution => 'education_support',
    ActivityRole.donationCollection     => 'donation_drives',
    ActivityRole.photographyMedia       => 'digital_branding',
    ActivityRole.reportWriting          => 'documentation',
    ActivityRole.schoolCoordination     => 'school_partner',
    _                                   => 'event_organization',
  };

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an activity title'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await EventManagerRepository.createStandaloneActivity(
        title: title,
        category: _categoryForRole(_role),
        eventId: _selectedEvent?.id,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        maxStudents: int.tryParse(_maxCtrl.text.trim()),
      );
      await widget.vm.load();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity created successfully'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create activity: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.vm.events
        .where(
          (e) =>
              e.status != EventStatus.completed &&
              e.status != EventStatus.archived,
        )
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 16,
        left: 18,
        right: 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Create Activity',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Event',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<NGOEvent>(
              initialValue: _selectedEvent,
              hint: const Text('Select an event'),
              items: events
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.title)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedEvent = v),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Activity Role',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: ActivityRole.values
                  .map(
                    (r) => ChoiceChip(
                      label: Text(
                        r.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: _role == r,
                      onSelected: (_) => setState(() => _role = r),
                      avatar: Icon(r.icon, size: 12),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            const Text(
              'Activity Title',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: _role.label,
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Description',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'What will volunteers do in this role?',
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Max Students',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _maxCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '5',
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Activity',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Create Impact Post Sheet (shared) ───────────────────────────────────────

class _CreateImpactPostSheet extends StatefulWidget {
  const _CreateImpactPostSheet({required this.vm});
  final EventManagerViewModel vm;

  @override
  State<_CreateImpactPostSheet> createState() => _CreateImpactPostSheetState();
}

class _CreateImpactPostSheetState extends State<_CreateImpactPostSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _appreciationCtrl = TextEditingController();
  EMImpactPostType _type = EMImpactPostType.eventSuccessReport;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _appreciationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 16,
        left: 18,
        right: 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Create Impact Post',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Post Type',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: EMImpactPostType.values
                  .map(
                    (t) => ChoiceChip(
                      label: Text(
                        t.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: _type == t,
                      onSelected: (_) => setState(() => _type = t),
                      avatar: Icon(t.icon, size: 12),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            const Text(
              'Post Title',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Stationery Drive — 150 Kits Distributed',
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Description',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe what happened and the impact made...',
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Appreciation Message',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _appreciationCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'e.g. Punjabi Welfare Trust salutes the dedication...',
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (_titleCtrl.text.trim().isEmpty) return;
                  final post = EMImpactPost(
                    id: DateTime.now().millisecondsSinceEpoch,
                    type: _type,
                    title: _titleCtrl.text.trim(),
                    eventName: 'NGO Event',
                    location: 'Delhi Cantt',
                    date: DateTime.now(),
                    description: _descCtrl.text.trim(),
                    appreciationMessage: _appreciationCtrl.text.trim(),
                    isPublished: false,
                    adminApproved: false,
                    verifiedByName: AppState.studentName ?? 'Event Manager',
                  );
                  widget.vm.addImpactPost(post);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Impact post saved as Draft'),
                      backgroundColor: Color(0xFF6A1B9A),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Save as Draft',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
