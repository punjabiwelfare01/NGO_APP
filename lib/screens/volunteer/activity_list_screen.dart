import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/volunteer_models.dart';
import '../../viewmodels/volunteer_viewmodel.dart';
import 'work_submission_screen.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({required this.vm, super.key});
  final VolunteerViewModel vm;

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  ActivityCategory? _selectedCategory;

  List<VolunteerActivity> get _filtered {
    if (_selectedCategory == null) return widget.vm.activities;
    return widget.vm.activities
        .where((a) => a.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activities',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: widget.vm,
        builder: (context, _) {
          return Column(
            children: [
              // Category filter chips
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  children: [
                    _CategoryChip(
                      label: 'All',
                      selected: _selectedCategory == null,
                      onTap: () =>
                          setState(() => _selectedCategory = null),
                    ),
                    ...ActivityCategory.values.map((c) => _CategoryChip(
                          label: c.displayName,
                          selected: _selectedCategory == c,
                          onTap: () =>
                              setState(() => _selectedCategory = c),
                        )),
                  ],
                ),
              ),
              Expanded(
                child: _filtered.isEmpty
                    ? const Center(
                        child: Text('No activities found.',
                            style: TextStyle(color: AppColors.muted)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ActivityCard(
                          activity: _filtered[i],
                          onTap: () => _showDetail(_filtered[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDetail(VolunteerActivity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActivityDetailSheet(
        activity: activity,
        applicationStatus: activity.applicationStatus,
        onSubmitWork: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => WorkSubmissionScreen(
              vm: widget.vm,
              preselectedActivity: activity,
            ),
          ));
        },
        onApply: (activity.applicationStatus == null && activity.assignmentId == null)
            ? () {
                Navigator.of(context).pop();
                _applyForActivity(activity);
              }
            : null,
      ),
    );
  }

  Future<void> _applyForActivity(VolunteerActivity activity) async {
    final ok = await widget.vm.applyForActivity(activity.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Applied for "${activity.title}" successfully!'
              : 'Failed to apply. Please try again.'),
        ),
      );
    }
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.muted,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
        side: BorderSide(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.muted.withValues(alpha: 0.3),
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.onTap});
  final VolunteerActivity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.volunteer_activism_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activity.category.displayName,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12),
                    ),
                    if (activity.subdivision != null)
                      Text(
                        activity.subdivision!,
                        style: TextStyle(
                          color: AppColors.primary.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${activity.rewardHours}h',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const Text(
                    'reward',
                    style:
                        TextStyle(color: AppColors.muted, fontSize: 10),
                  ),
                  if (activity.applicationStatus != null) ...[
                    const SizedBox(height: 4),
                    _StatusChip(status: activity.applicationStatus!),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityDetailSheet extends StatelessWidget {
  const _ActivityDetailSheet({
    required this.activity,
    required this.onSubmitWork,
    this.onApply,
    this.applicationStatus,
  });
  final VolunteerActivity activity;
  final VoidCallback onSubmitWork;
  final VoidCallback? onApply;
  final String? applicationStatus;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (ctx, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: ListView(
          controller: ctrl,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              activity.title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            _InfoRow(
                icon: Icons.category_rounded,
                text: activity.category.displayName),
            if (activity.subdivision != null)
              _InfoRow(
                  icon: Icons.subdirectory_arrow_right_rounded,
                  text: activity.subdivision!),
            if (activity.location != null)
              _InfoRow(
                  icon: Icons.location_on_rounded,
                  text: activity.location!),
            _InfoRow(
                icon: Icons.schedule_rounded,
                text: '${activity.rewardHours} hrs reward'),
            if (activity.startDate != null)
              _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  text: activity.endDate != null
                      ? '${_fmtDate(activity.startDate!)} – ${_fmtDate(activity.endDate!)}'
                      : _fmtDate(activity.startDate!)),
            if (activity.maxStudents != null)
              _InfoRow(
                  icon: Icons.people_rounded,
                  text: '${activity.maxStudents} volunteers max'),
            if (activity.certificateEligible)
              const _InfoRow(
                  icon: Icons.workspace_premium_rounded,
                  text: 'Certificate eligible upon completion'),
            if (activity.stipendAmount != null)
              _InfoRow(
                  icon: Icons.payments_rounded,
                  text: '₹${activity.stipendAmount!.toStringAsFixed(0)} stipend'),
            const SizedBox(height: 12),
            if (activity.description != null) ...[
              _SectionLabel('Description'),
              const SizedBox(height: 4),
              Text(activity.description!,
                  style: const TextStyle(
                      color: AppColors.muted, height: 1.5)),
              const SizedBox(height: 12),
            ],
            if (activity.expectedWork != null) ...[
              _SectionLabel('Work Details'),
              const SizedBox(height: 4),
              Text(activity.expectedWork!,
                  style: const TextStyle(
                      color: AppColors.muted, height: 1.5)),
              const SizedBox(height: 12),
            ],
            if (activity.workInstructions != null) ...[
              _SectionLabel('Work Instructions'),
              const SizedBox(height: 4),
              Text(activity.workInstructions!,
                  style: const TextStyle(
                      color: AppColors.muted, height: 1.5)),
              const SizedBox(height: 12),
            ],
            if (activity.proofRequired != null) ...[
              _SectionLabel('Proof Required'),
              const SizedBox(height: 4),
              _ProofBadge(text: activity.proofRequired!),
              const SizedBox(height: 16),
            ],
            if (onApply != null) ...[
              FilledButton.icon(
                onPressed: onApply,
                icon: const Icon(Icons.volunteer_activism_rounded),
                label: const Text('Apply for This Activity'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onSubmitWork,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Submit Work Directly'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else if (applicationStatus == 'applied') ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hourglass_empty_rounded,
                        color: AppColors.accent, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Application Submitted — Awaiting Approval',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: onSubmitWork,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Submit Work for This Activity'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else ...[
              FilledButton.icon(
                onPressed: onSubmitWork,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Submit Work for This Activity'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'applied'   => ('Applied', AppColors.accent),
      'approved'  => ('Approved', AppColors.secondary),
      'assigned'  => ('Assigned', AppColors.primary),
      'rejected'  => ('Rejected', AppColors.softRed),
      _           => (status, AppColors.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
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

// ── Shared helpers ────────────────────────────────────────────────────────────

String _fmtDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          fontSize: 14,
        ),
      );
}

class _ProofBadge extends StatelessWidget {
  const _ProofBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.upload_file_rounded,
                size: 16, color: AppColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
}
