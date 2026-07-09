import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/volunteer_models.dart';
import '../../viewmodels/volunteer_viewmodel.dart';
import '../../widgets/app_card.dart';
import '../../widgets/top_header.dart';
import 'activity_list_screen.dart';
import 'daily_log_screen.dart';
import 'donation_screen.dart';
import 'my_certificates_screen.dart';
import '../internship/wall_of_impact_view.dart';
import 'work_submission_screen.dart';

class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  State<VolunteerDashboardScreen> createState() =>
      _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState extends State<VolunteerDashboardScreen> {
  late final VolunteerViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = VolunteerViewModel.shared;
    _vm.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final name = (AppState.studentName ?? 'Volunteer').split(' ').first;
        return RefreshIndicator(
          onRefresh: _vm.load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: TopHeader(
                  title: 'Hi $name',
                  subtitle: 'Your social impact mission dashboard',
                  actionIcon: Icons.share_rounded,
                  actionTooltip: 'Share profile',
                  onActionTap: null,
                ),
              ),

              if (_vm.state == VolunteerLoadState.loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                // ── NGO Trust Header ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: _NGOTrustHeader(),
                ),

                // ── Impact Score Cards ────────────────────────────────────
                SliverToBoxAdapter(
                  child: _ImpactScoreSection(stats: _vm.stats),
                ),

                // ── Quick Actions ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _QuickActionsSection(
                    onBrowseActivities: () => _push(ActivityListScreen(vm: _vm)),
                    onSubmitWork: () => _push(WorkSubmissionScreen(vm: _vm)),
                    onDonate: () => _push(DonationScreen(vm: _vm)),
                    onLogbook: () => _push(DailyLogScreen(vm: _vm)),
                    onCertificates: () => _push(MyCertificatesScreen(vm: _vm)),
                    onWallOfImpact: () => _push(const WallOfImpactView()),
                  ),
                ),

                // ── Assigned Activities ───────────────────────────────────
                if (_vm.assignments.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _AssignedSection(
                      assignments: _vm.assignments,
                      onSubmit: (a) => _push(
                        WorkSubmissionScreen(vm: _vm, assignment: a),
                      ),
                    ),
                  ),

                // ── Recent Submissions ────────────────────────────────────
                if (_vm.submissions.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _RecentSubmissionsSection(
                      submissions: _vm.submissions.take(3).toList(),
                    ),
                  ),

                // ── Recent Certificates ───────────────────────────────────
                if (_vm.certificates.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _CertificatesPreview(
                      certs: _vm.certificates.take(3).toList(),
                      onViewAll: () => _push(MyCertificatesScreen(vm: _vm)),
                    ),
                  ),

                // ── Trust Proof Card ──────────────────────────────────────
                const SliverToBoxAdapter(child: _TrustProofCard()),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ],
          ),
        );
      },
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

// ── NGO Trust Header ──────────────────────────────────────────────────────────

class _NGOTrustHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.verified_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Punjabi Welfare Trust',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Verified NGO Activity Platform',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'TRUSTED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Impact Score Cards ────────────────────────────────────────────────────────

class _ImpactScoreSection extends StatelessWidget {
  const _ImpactScoreSection({required this.stats});
  final VolunteerStats stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Your Impact Score',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                      fontSize: 15,
                    ),
                  ),
                ),
                _RankBadge(rank: stats.volunteerRank),
              ],
            ),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: [
                _ImpactTile(
                  icon: Icons.schedule_rounded,
                  label: 'Hours',
                  value: '${stats.totalHours}',
                  color: AppColors.primary,
                ),
                _ImpactTile(
                  icon: Icons.task_alt_rounded,
                  label: 'Activities',
                  value: '${stats.activitiesCompleted}',
                  color: AppColors.secondary,
                ),
                _ImpactTile(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Raised',
                  value: '₹${stats.donationRaised.toStringAsFixed(0)}',
                  color: AppColors.accent,
                ),
                _ImpactTile(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Certificates',
                  value: '${stats.certificatesEarned}',
                  color: const Color(0xFF9C27B0),
                ),
                _ImpactTile(
                  icon: Icons.hourglass_empty_rounded,
                  label: 'Pending',
                  value: '${stats.pendingApprovals}',
                  color: stats.pendingApprovals > 0
                      ? AppColors.accent
                      : AppColors.muted,
                ),
                _ImpactTile(
                  icon: Icons.emoji_events_rounded,
                  label: 'Rank',
                  value: stats.volunteerRank,
                  color: _rankColor(stats.volunteerRank),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _rankColor(String rank) => switch (rank) {
        'Platinum' => const Color(0xFF00BCD4),
        'Gold'     => const Color(0xFFFFC107),
        'Silver'   => const Color(0xFF9E9E9E),
        _          => const Color(0xFFCD7F32),
      };
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final String rank;

  @override
  Widget build(BuildContext context) {
    final color = switch (rank) {
      'Platinum' => const Color(0xFF00BCD4),
      'Gold'     => const Color(0xFFFFC107),
      'Silver'   => const Color(0xFF9E9E9E),
      _          => const Color(0xFFCD7F32),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$rank Volunteer',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactTile extends StatelessWidget {
  const _ImpactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 14,
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
  }
}

// ── Quick Actions ─────────────────────────────────────────────────────────────

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({
    required this.onBrowseActivities,
    required this.onSubmitWork,
    required this.onDonate,
    required this.onLogbook,
    required this.onCertificates,
    required this.onWallOfImpact,
  });

  final VoidCallback onBrowseActivities;
  final VoidCallback onSubmitWork;
  final VoidCallback onDonate;
  final VoidCallback onLogbook;
  final VoidCallback onCertificates;
  final VoidCallback onWallOfImpact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
            children: [
              _ActionTile(
                icon: Icons.volunteer_activism_rounded,
                label: 'Activities',
                color: AppColors.primary,
                onTap: onBrowseActivities,
              ),
              _ActionTile(
                icon: Icons.upload_file_rounded,
                label: 'Submit Work',
                color: AppColors.secondary,
                onTap: onSubmitWork,
              ),
              _ActionTile(
                icon: Icons.favorite_rounded,
                label: 'Donate',
                color: AppColors.softRed,
                onTap: onDonate,
              ),
              _ActionTile(
                icon: Icons.book_rounded,
                label: 'Daily Log',
                color: AppColors.accent,
                onTap: onLogbook,
              ),
              _ActionTile(
                icon: Icons.workspace_premium_rounded,
                label: 'Certificates',
                color: const Color(0xFF9C27B0),
                onTap: onCertificates,
              ),
              _ActionTile(
                icon: Icons.star_rounded,
                label: 'Wall of Impact',
                color: const Color(0xFFFF8F00),
                onTap: onWallOfImpact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Assigned Activities ───────────────────────────────────────────────────────

class _AssignedSection extends StatelessWidget {
  const _AssignedSection({required this.assignments, required this.onSubmit});
  final List<ActivityAssignment> assignments;
  final void Function(ActivityAssignment) onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assigned to Me',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          ...assignments.take(3).map((a) => _AssignmentCard(
                assignment: a,
                onSubmit: () => onSubmit(a),
              )),
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.assignment, required this.onSubmit});
  final ActivityAssignment assignment;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final activity = assignment.activity;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onSubmit,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.assignment_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity?.title ?? 'Assigned Activity',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          fontSize: 13,
                        ),
                      ),
                      if (assignment.location != null)
                        Text(
                          assignment.location!,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Submit', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Recent Submissions ────────────────────────────────────────────────────────

class _RecentSubmissionsSection extends StatelessWidget {
  const _RecentSubmissionsSection({required this.submissions});
  final List<WorkSubmission> submissions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Submissions',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            ...submissions.map((s) => _SubmissionRow(submission: s)),
          ],
        ),
      ),
    );
  }
}

class _SubmissionRow extends StatelessWidget {
  const _SubmissionRow({required this.submission});
  final WorkSubmission submission;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (submission.status) {
      SubmissionStatus.approved     => AppColors.secondary,
      SubmissionStatus.rejected     => AppColors.softRed,
      SubmissionStatus.under_review => AppColors.accent,
      _                             => AppColors.muted,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              submission.title,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              submission.status.displayName,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Certificates Preview ──────────────────────────────────────────────────────

class _CertificatesPreview extends StatelessWidget {
  const _CertificatesPreview({required this.certs, required this.onViewAll});
  final List<dynamic> certs;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AppCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: Color(0xFF9C27B0), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${certs.length} Certificate${certs.length == 1 ? "" : "s"} Earned',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                      fontSize: 14,
                    ),
                  ),
                  const Text(
                    'Tap to view and download',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text('View All'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Trust Proof Card ──────────────────────────────────────────────────────────

class _TrustProofCard extends StatelessWidget {
  const _TrustProofCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Recognized & Appreciated',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Every activity, donation, certificate, and report is verified by the NGO before becoming public.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _TrustChip(
                    icon: Icons.qr_code_rounded, label: 'QR Verified Certs'),
                _TrustChip(
                    icon: Icons.receipt_rounded, label: 'Donation Receipts'),
                _TrustChip(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Admin Approved'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
