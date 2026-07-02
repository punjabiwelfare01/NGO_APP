import 'package:flutter/material.dart';

import '../../models/counsellor_models.dart';
import '../../models/counsellor_session_models.dart';
import '../../repositories/api_client.dart';
import '../../viewmodels/counsellor_home_viewmodel.dart';
import 'counsellor_meeting_detail_screen.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────

const _kNavy   = Color(0xFF0A1F44);
const _kBlue   = Color(0xFF1565C0);
const _kGreen  = Color(0xFF2E7D32);
const _kAmber  = Color(0xFFF57F17);
const _kPurple = Color(0xFF6A1B9A);
const _kInk    = Color(0xFF17324D);
const _kMuted  = Color(0xFF8E96A3);
const _kCard   = Colors.white;

// ─── Root View ────────────────────────────────────────────────────────────────

class CounsellorHomeView extends StatelessWidget {
  const CounsellorHomeView({
    required this.vm,
    required this.counsellorName,
    required this.onNavigate,
    super.key,
  });

  final CounsellorHomeViewModel vm;
  final String counsellorName;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.state == CounsellorHomeLoadState.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: vm.refreshRequests,
          child: CustomScrollView(
            slivers: [
              _Header(name: counsellorName, profile: vm.profile),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HeroBanner(
                      newCount: vm.newRequests.length,
                      onViewRequests: () => onNavigate(1),
                      onSchedule: () => onNavigate(2),
                    ),
                    const SizedBox(height: 22),
                    _QuickActionsSection(onNavigate: onNavigate),
                    const SizedBox(height: 22),
                    _OverviewSection(stats: vm.stats),
                    const SizedBox(height: 22),
                    _MyImpactSection(
                      vm: vm,
                      onViewAnalytics: () => onNavigate(4),
                    ),
                    if (vm.newRequests.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _NewRequestsSection(
                        requests: vm.newRequests,
                        vm: vm,
                        onSeeAll: () => onNavigate(1),
                      ),
                    ],
                    if (vm.todayMeetings.isNotEmpty ||
                        vm.upcomingReminders.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _ScheduleRemindersRow(vm: vm),
                    ],
                    const SizedBox(height: 22),
                    _NgoFooter(),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.profile});
  final String name;
  final CounsellorProfile profile;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning ☀️';
    if (h < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 👋';
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: _kNavy,
      surfaceTintColor: _kNavy,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_kNavy, Color(0xFF1565C0)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 54, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: identity ────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      _greeting,
                      style: const TextStyle(
                        color: Color(0xFFB3C8E8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Verified Counsellor chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kGreen.withValues(alpha: .25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF81C784)
                                .withValues(alpha: .5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              color: Color(0xFF81C784), size: 13),
                          SizedBox(width: 5),
                          Text(
                            'Verified Counsellor',
                            style: TextStyle(
                              color: Color(0xFFB9F6CA),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Working with',
                      style: TextStyle(
                        color: Color(0xFFB3C8E8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Punjabi Welfare Service Organisation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Verification bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kGreen.withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield_rounded,
                              color: Color(0xFF81C784), size: 13),
                          const SizedBox(width: 6),
                          const Text(
                            'NGO Verified Member',
                            style: TextStyle(
                              color: Color(0xFFB9F6CA),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              profile.ngoVerificationId,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // ── Right: photo + badges ─────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: .4),
                              width: 2),
                          color: Colors.white.withValues(alpha: .15),
                        ),
                        foregroundDecoration: profile.photoUrl != null
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: NetworkImage(
                                    ApiClient.resolveUrl(profile.photoUrl!),
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : null,
                        child: profile.photoUrl == null
                            ? const Icon(Icons.person_rounded,
                                color: Colors.white, size: 34)
                            : null,
                      ),
                      // Online dot
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _kNavy, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // NGO logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assests/ngo_logo.jpeg',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.volunteer_activism_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero Banner ──────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.newCount,
    required this.onViewRequests,
    required this.onSchedule,
  });
  final int newCount;
  final VoidCallback onViewRequests;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 186,
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left: text + buttons ──────────────────────────────────
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Helping students\nbuild a brighter future.',
                      style: TextStyle(
                        color: _kInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      newCount == 0
                          ? 'No new requests today.'
                          : 'You have $newCount new request${newCount > 1 ? 's' : ''} waiting.',
                      style: const TextStyle(
                        color: _kMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        FilledButton.icon(
                          onPressed: onViewRequests,
                          icon: const Icon(Icons.inbox_rounded, size: 13),
                          label: const Text('View Requests',
                              style: TextStyle(fontSize: 11)),
                          style: FilledButton.styleFrom(
                            backgroundColor: _kBlue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: onSchedule,
                          icon: const Icon(Icons.calendar_today_rounded,
                              size: 12),
                          label: const Text('Schedule',
                              style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kInk,
                            side: BorderSide(
                                color: _kInk.withValues(alpha: .25)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // ── Right: illustration ───────────────────────────────────
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(20)),
                child: Image.asset(
                  'assests/home_screen_card_councellor.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: _kBlue.withValues(alpha: .06),
                    child: const Center(
                      child: Icon(Icons.people_alt_rounded,
                          color: _kBlue, size: 40),
                    ),
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

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        icon: Icons.inbox_rounded,
        label: 'View\nRequests',
        color: _kBlue,
        bg: const Color(0xFFE3F2FD),
        idx: 1,
      ),
      (
        icon: Icons.calendar_month_rounded,
        label: 'Calendar',
        color: _kGreen,
        bg: const Color(0xFFE8F5E9),
        idx: 2,
      ),
      (
        icon: Icons.bar_chart_rounded,
        label: 'My Impact',
        color: _kAmber,
        bg: const Color(0xFFFFF8E1),
        idx: 4,
      ),
      (
        icon: Icons.workspace_premium_rounded,
        label: 'Sessions',
        color: _kPurple,
        bg: const Color(0xFFF3E5F5),
        idx: 3,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                color: _kInk,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => onNavigate(1),
              child: const Text(
                'See all',
                style: TextStyle(
                  color: _kBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 122,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: actions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final a = actions[i];
              return GestureDetector(
                onTap: () => onNavigate(a.idx),
                child: Container(
                  width: 96,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: a.color.withValues(alpha: .15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: a.bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(a.icon, color: a.color, size: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        a.label,
                        style: const TextStyle(
                          color: _kInk,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 2),
                      Icon(Icons.chevron_right_rounded,
                          color: _kMuted, size: 14),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Overview ─────────────────────────────────────────────────────────────────

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.stats});
  final CounsellorStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            color: _kInk,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _OverviewCard(
                icon: Icons.today_rounded,
                value: '${stats.todayScheduled}',
                label: "Today's Sessions",
                color: _kBlue,
                bg: const Color(0xFFE3F2FD),
                delta: null,
                deltaUp: false,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OverviewCard(
                icon: Icons.inbox_rounded,
                value: '${stats.newRequests}',
                label: 'New Requests',
                color: _kGreen,
                bg: const Color(0xFFE8F5E9),
                delta: stats.newRequests > 0
                    ? '↑ ${stats.newRequests} From yesterday'
                    : null,
                deltaUp: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OverviewCard(
                icon: Icons.pending_rounded,
                value: '${stats.pendingConfirmation}',
                label: 'Awaiting Confirmation',
                color: _kAmber,
                bg: const Color(0xFFFFF8E1),
                delta: null,
                deltaUp: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
    required this.delta,
    required this.deltaUp,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color bg;
  final String? delta;
  final bool deltaUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: .8),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            delta ?? '— No change',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: deltaUp && delta != null
                  ? _kGreen
                  : _kMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── My Impact ────────────────────────────────────────────────────────────────

class _MyImpactSection extends StatelessWidget {
  const _MyImpactSection({
    required this.vm,
    required this.onViewAnalytics,
  });
  final CounsellorHomeViewModel vm;
  final VoidCallback onViewAnalytics;

  int get _schoolsSupported {
    final names = vm.allRequests
        .where((r) => r.status == SchoolRequestStatus.completed)
        .map((r) => r.schoolName)
        .toSet();
    return names.length;
  }

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        icon: Icons.school_rounded,
        value: '${vm.stats.totalStudentsGuided}',
        label: 'Students\nCounselled',
        color: _kBlue,
        month: vm.stats.totalStudentsGuided,
      ),
      (
        icon: Icons.people_rounded,
        value: '${vm.completedSessions.length}',
        label: 'Sessions\nCompleted',
        color: _kGreen,
        month: vm.stats.completedThisMonth,
      ),
      (
        icon: Icons.account_balance_rounded,
        value: '$_schoolsSupported',
        label: 'Schools\nSupported',
        color: _kAmber,
        month: _schoolsSupported,
      ),
      (
        icon: Icons.star_rounded,
        value: '${vm.completedSessions.length}',
        label: 'Success\nStories',
        color: _kPurple,
        month: vm.stats.completedThisMonth,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'My Impact',
              style: TextStyle(
                color: _kInk,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onViewAnalytics,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Analytics',
                    style: TextStyle(
                      color: _kBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_rounded,
                      color: _kBlue, size: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(metrics.length, (i) {
            final m = metrics[i];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: i < metrics.length - 1 ? 10 : 0),
                child: _ImpactMetricCard(
                  icon: m.icon,
                  value: m.value,
                  label: m.label,
                  color: m.color,
                  monthDelta: m.month,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ImpactMetricCard extends StatelessWidget {
  const _ImpactMetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.monthDelta,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final int monthDelta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _kMuted,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '↑ $monthDelta this month',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: _kGreen.withValues(alpha: .85),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── New School Requests ──────────────────────────────────────────────────────

class _NewRequestsSection extends StatelessWidget {
  const _NewRequestsSection({
    required this.requests,
    required this.vm,
    required this.onSeeAll,
  });
  final List<SchoolBookingRequest> requests;
  final CounsellorHomeViewModel vm;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'New School Requests',
              style: TextStyle(
                color: _kInk,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _kGreen,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .4,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${requests.length}',
                  style: const TextStyle(
                    color: _kGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onSeeAll,
              child: const Text(
                'See all',
                style: TextStyle(
                  color: _kBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...requests.take(2).map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NewRequestCard(request: r, vm: vm),
              ),
            ),
      ],
    );
  }
}

class _NewRequestCard extends StatelessWidget {
  const _NewRequestCard({required this.request, required this.vm});
  final SchoolBookingRequest request;
  final CounsellorHomeViewModel vm;

  String _priority(SchoolBookingRequest r) {
    if (r.expectedStudents >= 100) return 'High Priority';
    if (r.expectedStudents >= 40) return 'Medium Priority';
    return 'Low Priority';
  }

  Color _priorityColor(SchoolBookingRequest r) {
    if (r.expectedStudents >= 100) return const Color(0xFFC62828);
    if (r.expectedStudents >= 40) return _kAmber;
    return _kGreen;
  }

  @override
  Widget build(BuildContext context) {
    final date = request.preferredDate;
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final dateStr =
        '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGreen.withValues(alpha: .15)),
        boxShadow: [
          BoxShadow(
            color: _kGreen.withValues(alpha: .06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_rounded,
                    color: _kGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.schoolName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _kInk,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      request.classGroup.isNotEmpty
                          ? request.classGroup
                          : 'School counselling',
                      style: const TextStyle(
                          fontSize: 12, color: _kMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _kGreen.withValues(alpha: .3)),
                ),
                child: const Text(
                  'New',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _kGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            request.topic,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: _kInk,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: _kMuted),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: const TextStyle(fontSize: 11, color: _kMuted),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.people_outline, size: 13, color: _kMuted),
              const SizedBox(width: 4),
              Text(
                '${request.expectedStudents} Students',
                style: const TextStyle(fontSize: 11, color: _kMuted),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.flag_rounded, size: 13, color: _kAmber),
              const SizedBox(width: 4),
              Text(
                _priority(request),
                style: TextStyle(
                  fontSize: 11,
                  color: _priorityColor(request),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    vm.acceptRequest(request.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Request from ${request.schoolName} accepted!'),
                        backgroundColor: _kGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _kGreen,
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Accept',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CounsellorMeetingDetailScreen(
                          request: request, vm: vm),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kBlue,
                    side: BorderSide(
                        color: _kBlue.withValues(alpha: .4)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('View Details',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Today's Schedule + Upcoming Reminders ────────────────────────────────────

class _ScheduleRemindersRow extends StatelessWidget {
  const _ScheduleRemindersRow({required this.vm});
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vm.todayMeetings.isNotEmpty)
            Expanded(child: _TodayScheduleColumn(vm: vm)),
          if (vm.todayMeetings.isNotEmpty &&
              vm.upcomingReminders.isNotEmpty)
            const SizedBox(width: 12),
          if (vm.upcomingReminders.isNotEmpty)
            Expanded(
              child: _RemindersColumn(
                reminders: vm.upcomingReminders.take(3).toList(),
                vm: vm,
              ),
            ),
        ],
      ),
    );
  }
}

class _TodayScheduleColumn extends StatelessWidget {
  const _TodayScheduleColumn({required this.vm});
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "Today's Schedule",
                style: TextStyle(
                  color: _kInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              'See all',
              style: const TextStyle(
                color: _kBlue,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...vm.todayMeetings.take(3).map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ScheduleItem(request: m, vm: vm),
              ),
            ),
      ],
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  const _ScheduleItem({required this.request, required this.vm});
  final SchoolBookingRequest request;
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = request.effectiveTime;
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    final modeLabel =
        request.mode == SessionMode.online ? 'Online' : 'Offline';
    final modeColor =
        request.mode == SessionMode.online ? _kBlue : _kGreen;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBlue.withValues(alpha: .12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _kBlue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$h:$m $period',
                style: const TextStyle(
                  color: _kBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            request.schoolName,
            style: const TextStyle(
              color: _kInk,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            request.topic,
            style: const TextStyle(color: _kMuted, fontSize: 10.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: modeColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  modeLabel,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: modeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CounsellorMeetingDetailScreen(
                        request: request, vm: vm),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Join',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RemindersColumn extends StatelessWidget {
  const _RemindersColumn({required this.reminders, required this.vm});
  final List<MeetingReminder> reminders;
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Upcoming Reminders',
                style: TextStyle(
                  color: _kInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: _kAmber.withValues(alpha: .15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${reminders.length}',
                  style: const TextStyle(
                    color: _kAmber,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'See all',
              style: TextStyle(
                color: _kBlue,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...reminders.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ReminderItem(reminder: r, vm: vm),
          ),
        ),
      ],
    );
  }
}

class _ReminderItem extends StatelessWidget {
  const _ReminderItem({required this.reminder, required this.vm});
  final MeetingReminder reminder;
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final typeColor = switch (reminder.type) {
      ReminderType.minutes15 => const Color(0xFFC62828),
      ReminderType.hours2 => _kAmber,
      _ => _kBlue,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: typeColor.withValues(alpha: .2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.type.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: typeColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reminder.schoolName,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  reminder.mode == SessionMode.online
                      ? 'Online session'
                      : 'Offline · ${reminder.locationOrLink ?? ''}',
                  style: const TextStyle(
                      fontSize: 10, color: _kMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => vm.dismissReminder(reminder.id),
            child: const Icon(Icons.close_rounded,
                size: 14, color: _kMuted),
          ),
        ],
      ),
    );
  }
}

// ─── NGO Footer ───────────────────────────────────────────────────────────────

class _NgoFooter extends StatelessWidget {
  const _NgoFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGreen.withValues(alpha: .15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Powered by',
                  style: TextStyle(
                    color: _kMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assests/ngo_logo.jpeg',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _kGreen.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                              Icons.volunteer_activism_rounded,
                              color: _kGreen,
                              size: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Punjabi Welfare Service Organisation',
                        style: TextStyle(
                          color: _kInk,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kGreen.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _kGreen.withValues(alpha: .25)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 10, color: _kGreen),
                          SizedBox(width: 3),
                          Text(
                            'Verified NGO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _kGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Serving schools & students with care',
                        style: TextStyle(
                          color: _kMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'A trusted NGO dedicated to student well-being and empowerment.',
                  style: TextStyle(
                    color: _kMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Decorative icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: .06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.volunteer_activism_rounded,
                color: _kGreen, size: 34),
          ),
        ],
      ),
    );
  }
}

