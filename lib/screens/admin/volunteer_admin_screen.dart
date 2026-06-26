import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/volunteer_models.dart';
import '../../viewmodels/volunteer_viewmodel.dart';

class VolunteerAdminScreen extends StatefulWidget {
  const VolunteerAdminScreen({super.key});

  @override
  State<VolunteerAdminScreen> createState() => _VolunteerAdminScreenState();
}

class _VolunteerAdminScreenState extends State<VolunteerAdminScreen>
    with SingleTickerProviderStateMixin {
  late final VolunteerViewModel _vm;
  late final TabController _tabs;
  List<WorkSubmission> _pending = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _vm = VolunteerViewModel();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _vm.dispose();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _vm.load();
    _pending = await _vm.getPendingSubmissions();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Volunteer Management',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(
              text:
                  'Pending (${_pending.length})',
            ),
            const Tab(text: 'Activities'),
            const Tab(text: 'Impact Stories'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _PendingTab(
                  submissions: _pending,
                  onReview: _onReview,
                ),
                _ActivitiesTab(vm: _vm),
                _ImpactTab(vm: _vm),
              ],
            ),
    );
  }

  Future<void> _onReview(WorkSubmission sub, String status, String? notes) async {
    final ok = await _vm.reviewSubmission(sub.id, status: status, notes: notes);
    if (ok) {
      setState(() => _pending.removeWhere((s) => s.id == sub.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission ${status == "approved" ? "approved" : "rejected"}')),
        );
      }
    }
  }
}

// ── Pending Submissions Tab ───────────────────────────────────────────────────

class _PendingTab extends StatelessWidget {
  const _PendingTab({required this.submissions, required this.onReview});
  final List<WorkSubmission> submissions;
  final Future<void> Function(WorkSubmission, String, String?) onReview;

  @override
  Widget build(BuildContext context) {
    if (submissions.isEmpty) {
      return const Center(
        child: Text('No pending submissions',
            style: TextStyle(color: AppColors.muted)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: submissions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _PendingCard(
        submission: submissions[i],
        onReview: onReview,
      ),
    );
  }
}

class _PendingCard extends StatefulWidget {
  const _PendingCard({required this.submission, required this.onReview});
  final WorkSubmission submission;
  final Future<void> Function(WorkSubmission, String, String?) onReview;

  @override
  State<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends State<_PendingCard> {
  bool _busy = false;
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.submission;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sub.title,
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(sub.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              _InfoChip(
                  icon: Icons.schedule_rounded,
                  label: '${sub.hoursWorked}h',
                  color: AppColors.primary),
              _InfoChip(
                  icon: Icons.people_rounded,
                  label: '${sub.peopleReached} reached',
                  color: AppColors.secondary),
              if (sub.donationCollected > 0)
                _InfoChip(
                    icon: Icons.currency_rupee_rounded,
                    label: '₹${sub.donationCollected.toStringAsFixed(0)}',
                    color: AppColors.accent),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesCtrl,
            decoration: InputDecoration(
              hintText: 'Reviewer notes (optional)',
              hintStyle: TextStyle(
                  color: AppColors.muted.withValues(alpha: 0.6), fontSize: 12),
              filled: true,
              fillColor: AppColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: AppColors.muted.withValues(alpha: 0.3))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: AppColors.muted.withValues(alpha: 0.3))),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _review('rejected'),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.softRed,
                    side:
                        const BorderSide(color: AppColors.softRed),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _review('approved'),
                  icon: _busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _review(String status) async {
    setState(() => _busy = true);
    await widget.onReview(
      widget.submission,
      status,
      _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    if (mounted) setState(() => _busy = false);
  }
}

// ── Activities Tab ────────────────────────────────────────────────────────────

class _ActivitiesTab extends StatelessWidget {
  const _ActivitiesTab({required this.vm});
  final VolunteerViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.activities.isEmpty) {
          return const Center(
            child: Text('No activities yet. Add activities from the API.',
                style: TextStyle(color: AppColors.muted)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: vm.activities.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final a = vm.activities[i];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink)),
                        Text(a.category.displayName,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('${a.rewardHours}h',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: a.isActive
                          ? AppColors.secondary.withValues(alpha: 0.1)
                          : AppColors.muted.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      a.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                          color: a.isActive
                              ? AppColors.secondary
                              : AppColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Impact Stories Tab ────────────────────────────────────────────────────────

class _ImpactTab extends StatelessWidget {
  const _ImpactTab({required this.vm});
  final VolunteerViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.impactStories.isEmpty) {
          return const Center(
            child: Text('No impact stories yet.',
                style: TextStyle(color: AppColors.muted)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: vm.impactStories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final s = vm.impactStories[i];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink)),
                        if (s.impactNumbers != null)
                          Text(s.impactNumbers!,
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (s.isFeatured)
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: s.isPublic
                              ? AppColors.secondary.withValues(alpha: 0.1)
                              : AppColors.muted.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.isPublic ? 'Public' : 'Draft',
                          style: TextStyle(
                              color: s.isPublic
                                  ? AppColors.secondary
                                  : AppColors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Shared widget ─────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
