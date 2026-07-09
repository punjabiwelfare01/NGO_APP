import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/volunteer_models.dart';
import '../../viewmodels/volunteer_viewmodel.dart';
import '../../widgets/app_card.dart';
import '../../widgets/top_header.dart';
import '../volunteer/work_submission_screen.dart';

class InternshipView extends StatefulWidget {
  const InternshipView({this.onBack, super.key});
  final VoidCallback? onBack;

  @override
  State<InternshipView> createState() => _InternshipViewState();
}

class _InternshipViewState extends State<InternshipView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final VolunteerViewModel _vm;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _vm = VolunteerViewModel.shared..load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _vm,
    builder: (context, _) {
      if (_vm.state == VolunteerLoadState.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_vm.state == VolunteerLoadState.error) {
        return _StateView(
          icon: Icons.cloud_off_rounded,
          title: 'Could not load volunteer work',
          subtitle: _vm.error ?? 'Check your connection and try again.',
          action: 'Retry',
          onAction: _vm.load,
        );
      }
      final firstName = (AppState.studentName ?? 'Student').split(' ').first;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TopHeader(
              title: 'Volunteer Work',
              subtitle: 'Hi $firstName, your applications stay synced',
              actionIcon: Icons.refresh_rounded,
              actionTooltip: 'Refresh',
              onActionTap: _vm.load,
              onBack: widget.onBack,
            ),
          ),
          _Stats(assignments: _vm.assignments),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabs,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.muted,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'My Work'),
                Tab(text: 'Available'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _vm.load,
              child: TabBarView(
                controller: _tabs,
                children: [
                  _Assignments(
                    assignments: _vm.assignments,
                    submissions: _vm.submissions,
                    onSubmit: _openSubmission,
                    onUpdate: _openUpdate,
                  ),
                  _Activities(activities: _vm.activities, onApply: _apply),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  Future<void> _apply(VolunteerActivity activity) async {
    if (activity.applicationStatus != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply for activity?'),
        content: Text(activity.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await _vm.applyForActivity(activity.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Application submitted.' : _vm.error ?? 'Could not apply.',
        ),
        backgroundColor: ok ? AppColors.secondary : AppColors.softRed,
      ),
    );
  }

  Future<void> _openSubmission(ActivityAssignment assignment) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkSubmissionScreen(vm: _vm, assignment: assignment),
      ),
    );
    await _vm.load(force: true);
  }

  Future<void> _openUpdate(
      ActivityAssignment assignment, WorkSubmission existing) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkSubmissionScreen(
          vm: _vm,
          assignment: assignment,
          existingSubmission: existing,
        ),
      ),
    );
    await _vm.load(force: true);
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.assignments});
  final List<ActivityAssignment> assignments;

  @override
  Widget build(BuildContext context) {
    int count(String status) =>
        assignments.where((a) => a.status == status).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _stat('Applied', count('applied'), const Color(0xFF1565C0)),
          const SizedBox(width: 8),
          _stat('Assigned', count('assigned'), const Color(0xFF6B48FF)),
          const SizedBox(width: 8),
          _stat('Submitted', count('submitted'), const Color(0xFFF57F17)),
          const SizedBox(width: 8),
          _stat(
            'Approved',
            assignments
                .where(
                  (a) => const {
                    'admin_approved',
                    'certificate_generated',
                    'completed',
                  }.contains(a.status),
                )
                .length,
            AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Assignments extends StatelessWidget {
  const _Assignments({
    required this.assignments,
    required this.submissions,
    required this.onSubmit,
    required this.onUpdate,
  });
  final List<ActivityAssignment> assignments;
  final List<WorkSubmission> submissions;
  final ValueChanged<ActivityAssignment> onSubmit;
  final void Function(ActivityAssignment, WorkSubmission) onUpdate;

  WorkSubmission? _submissionFor(ActivityAssignment a) {
    try {
      return submissions
          .where((s) => s.assignmentId == a.id)
          .reduce((a, b) =>
              (a.createdAt?.isAfter(b.createdAt ?? DateTime(0)) ?? false)
                  ? a
                  : b);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
      return const _ScrollableState(
        icon: Icons.assignment_outlined,
        title: 'No applications yet',
        subtitle: 'Open Available and apply for a volunteer activity.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      itemCount: assignments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final item = assignments[index];
        final canSubmit = const {'assigned', 'in_progress'}.contains(item.status);
        final canUpdate = const {'submitted', 'resubmission_requested'}.contains(item.status);
        final existing = _submissionFor(item);

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.activity?.title ?? 'Volunteer activity',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _StatusBadge(item.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.activity?.description ??
                    item.notes ??
                    'Awaiting activity details.',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              if (item.location != null || item.activity?.location != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      item.location ?? item.activity!.location!,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ],

              // ── Submitted work preview ──────────────────────────────────
              if (existing != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.18)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.description_rounded,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              existing.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        existing.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _MetaChip(
                            icon: Icons.schedule_rounded,
                            label: '${existing.hoursWorked}h worked',
                          ),
                          _MetaChip(
                            icon: Icons.people_rounded,
                            label: '${existing.peopleReached} reached',
                          ),
                          if (existing.donationCollected > 0)
                            _MetaChip(
                              icon: Icons.currency_rupee_rounded,
                              label:
                                  '₹${existing.donationCollected.toStringAsFixed(0)}',
                            ),
                        ],
                      ),
                      if (existing.reviewerNotes != null &&
                          existing.reviewerNotes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFF57F17).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFF57F17)
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.feedback_outlined,
                                  size: 13, color: Color(0xFFF57F17)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Reviewer: ${existing.reviewerNotes}',
                                  style: const TextStyle(
                                    color: Color(0xFFF57F17),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // ── Action buttons ──────────────────────────────────────────
              if (canSubmit) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => onSubmit(item),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Submit Work'),
                  ),
                ),
              ] else if (canUpdate) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: existing != null
                        ? () => onUpdate(item, existing)
                        : () => onSubmit(item),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit & Resubmit'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF57F17),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.primary),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Activities extends StatelessWidget {
  const _Activities({required this.activities, required this.onApply});
  final List<VolunteerActivity> activities;
  final ValueChanged<VolunteerActivity> onApply;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const _ScrollableState(
        icon: Icons.volunteer_activism_outlined,
        title: 'No open activities',
        subtitle: 'Published volunteer opportunities will appear here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      itemCount: activities.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final item = activities[index];
        final applied = item.applicationStatus != null;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.category.displayName,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: applied ? null : () => onApply(item),
                    child: Text(
                      applied ? _label(item.applicationStatus!) : 'Apply',
                    ),
                  ),
                ],
              ),
              if (item.description?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  item.description!,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 9),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  if (item.location != null)
                    _meta(Icons.location_on_outlined, item.location!),
                  if (item.duration != null)
                    _meta(Icons.schedule_rounded, item.duration!),
                  if (item.certificateEligible)
                    _meta(Icons.workspace_premium_rounded, 'Certificate'),
                  if (item.stipendAmount != null)
                    _meta(
                      Icons.currency_rupee_rounded,
                      item.stipendAmount!.toStringAsFixed(0),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _meta(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AppColors.muted),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
    ],
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final String status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: _color(status).withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      _label(status),
      style: TextStyle(
        color: _color(status),
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

String _label(String status) => status
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');
Color _color(String status) => switch (status) {
  'rejected' => AppColors.softRed,
  'submitted' => const Color(0xFFF57F17),
  'admin_approved' ||
  'certificate_generated' ||
  'completed' => AppColors.secondary,
  'assigned' || 'in_progress' => const Color(0xFF6B48FF),
  _ => AppColors.primary,
};

class _ScrollableState extends StatelessWidget {
  const _ScrollableState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      SizedBox(
        height: 260,
        child: _StateView(icon: icon, title: title, subtitle: subtitle),
      ),
    ],
  );
}

class _StateView extends StatelessWidget {
  const _StateView({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            FilledButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}
