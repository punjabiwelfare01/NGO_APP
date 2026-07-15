import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models/counsellor_session_models.dart';
import '../../models/ngo_profile.dart';
import '../../models/school_partner_models.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/ngo_repository.dart';
import '../../viewmodels/counsellor_viewmodel.dart';
import '../../widgets/achievement_certificates_section.dart';
import '../../widgets/donation_impact_card.dart';
import '../../widgets/profile_section.dart';
import '../internship/wall_of_impact_view.dart';
import '../profile/profile_notifications_screen.dart';
import 'counsellor_directory_screen.dart';
import 'school_partner_profile_screen.dart';
import 'school_request_detail_screen.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kNavy     = Color(0xFF0D2B5E);
const _kBlue     = Color(0xFF1565C0);
const _kBlue2    = Color(0xFF1976D2);
const _kGreen    = Color(0xFF2E7D32);
const _kAmber    = Color(0xFFF57F17);
const _kPurple   = Color(0xFF6A1B9A);
const _kBg       = Color(0xFFF5F6FA);
const _kCard     = Colors.white;
const _kInk      = Color(0xFF1A1A2E);
const _kMuted    = Color(0xFF8E96A3);
const _kVerified = Color(0xFF43A047);

class SchoolPartnerPortalScreen extends StatefulWidget {
  const SchoolPartnerPortalScreen({super.key});

  @override
  State<SchoolPartnerPortalScreen> createState() =>
      _SchoolPartnerPortalScreenState();
}

class _SchoolPartnerPortalScreenState
    extends State<SchoolPartnerPortalScreen> {
  final _vm = CounsellorViewModel.shared;
  int _tab = 0;
  NGOProfile _ngo = NGOProfile.fallback;

  @override
  void initState() {
    super.initState();
    _vm.load();
    _vm.loadSchoolRequests();
    _vm.loadSchoolProfile();
    _vm.loadSchoolStats();
    _loadNgo();
  }

  Future<void> _loadNgo() async {
    final ngo = await NGORepository.getProfile();
    if (mounted) setState(() => _ngo = ngo);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) => Scaffold(
        backgroundColor: _kBg,
        body: IndexedStack(
          index: _tab,
          children: [
            _HomeTab(vm: _vm, ngo: _ngo),
            _CounsellorsTab(vm: _vm),
            _RequestsTab(vm: _vm),
            _ImpactTab(vm: _vm),
            _ProfileTab(vm: _vm),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          current: _tab,
          onTap: (i) {
            setState(() => _tab = i);
            if (i == 0 || i == 2) {
              _vm.loadSchoolRequests(force: true);
              _vm.loadSchoolStats(force: true);
            }
          },
        ),
      ),
    );
  }
}

// ── Bottom Navigation ─────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.current, required this.onTap});
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home',
                  active: current == 0, onTap: () => onTap(0)),
              _NavItem(icon: Icons.people_alt_rounded, label: 'Counsellors',
                  active: current == 1, onTap: () => onTap(1)),
              _NavItem(icon: Icons.description_rounded, label: 'Requests',
                  active: current == 2, onTap: () => onTap(2)),
              _NavItem(icon: Icons.bar_chart_rounded, label: 'Impact',
                  active: current == 3, onTap: () => onTap(3)),
              _NavItem(icon: Icons.person_rounded, label: 'Profile',
                  active: current == 4, onTap: () => onTap(4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? _kBlue : _kMuted;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── NGO brand header (logo, name, registration) ───────────────────────────────

class _SchoolBrandHeader extends StatelessWidget {
  const _SchoolBrandHeader({required this.ngo});
  final NGOProfile ngo;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipOval(
          child: Image.asset(
            'assests/ngo_logo.jpeg',
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ngo.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: _kInk,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Regd. No. ${ngo.registrationNumber ?? '736'}, Delhi Cantt',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: _kMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const ProfileNotificationsScreen(),
            ),
          ),
          icon: const Icon(Icons.notifications_none_rounded),
          tooltip: 'Notifications',
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 0 — Home
// ══════════════════════════════════════════════════════════════════════════════

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.vm, required this.ngo});
  final CounsellorViewModel vm;
  final NGOProfile ngo;

  @override
  Widget build(BuildContext context) {
    final profile = vm.schoolProfile;
    final stats   = vm.schoolStats;
    final requests = vm.schoolRequests;
    final schoolName = profile?.schoolName ?? 'School';

    return CustomScrollView(
      slivers: [
        // ── NGO brand header ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            color: _kCard,
            padding: EdgeInsets.fromLTRB(
                16, MediaQuery.of(context).padding.top + 12, 16, 12),
            child: _SchoolBrandHeader(ngo: ngo),
          ),
        ),
        // ── Header ───────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            color: _kCard,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $schoolName 👋',
                        style: const TextStyle(
                          color: _kInk,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'School Partner Portal',
                        style: TextStyle(
                          color: _kBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Helping students connect with verified counsellors.',
                        style: TextStyle(
                          color: _kMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    _SchoolBadge(profile: profile),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kVerified.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _kVerified.withValues(alpha: .3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              color: _kVerified, size: 11),
                          SizedBox(width: 3),
                          Text(
                            'Verified School',
                            style: TextStyle(
                              color: _kVerified,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Hero Banner ───────────────────────────────────────────────
              _HeroBanner(vm: vm),
              const SizedBox(height: 22),

              // ── NGO Achievements (builds trust for school partners) ───────
              const AchievementCertificatesSection(),

              // ── School Services ───────────────────────────────────────────
              const _SectionTitle('School Services'),
              const SizedBox(height: 12),
              _ServicesCard(vm: vm),
              const SizedBox(height: 22),

              // ── School Impact ─────────────────────────────────────────────
              Row(
                children: [
                  const Expanded(
                    child: _SectionTitle('School Impact'),
                  ),
                  GestureDetector(
                    onTap: () {}, // navigates to impact tab
                    child: const Row(
                      children: [
                        Text(
                          'View Analytics',
                          style: TextStyle(
                            color: _kBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.arrow_forward_rounded,
                            color: _kBlue, size: 15),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ImpactStatsRow(stats: stats),
              const SizedBox(height: 22),

              // ── Your Requests ─────────────────────────────────────────────
              Row(
                children: [
                  const Expanded(child: _SectionTitle('Your Requests')),
                  if (requests.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kBlue.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${requests.length}',
                        style: const TextStyle(
                          color: _kBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (requests.isEmpty)
                _EmptyRequests(vm: vm)
              else
                for (final r in requests.take(5)) ...[
                  _RequestCard(request: r, vm: vm),
                  const SizedBox(height: 10),
                ],
              const SizedBox(height: 22),
              const DonationImpactCard(),
              const SizedBox(height: 12),
              _AssignmentNotice(),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── School badge / logo ───────────────────────────────────────────────────────

class _SchoolBadge extends StatelessWidget {
  const _SchoolBadge({required this.profile});
  final SchoolPartnerProfile? profile;

  @override
  Widget build(BuildContext context) {
    final photoUrl = profile?.photoUrl;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _kBlue.withValues(alpha: .2), width: 2),
        color: _kBlue.withValues(alpha: .08),
      ),
      child: photoUrl != null
          ? ClipOval(
              child: Image.network(photoUrl, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _fallbackIcon()),
            )
          : _fallbackIcon(),
    );
  }

  Widget _fallbackIcon() => const Icon(Icons.school_rounded,
      color: _kBlue, size: 28);
}

// ── Hero Banner ───────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.vm});
  final CounsellorViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kNavy, _kBlue2],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Illustration placeholder (right side)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 130,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(20)),
              child: _IllustrationWidget(),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 140, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_rounded,
                        color: Color(0xFF81C784), size: 14),
                    SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'VERIFIED BY PUNJABI WELFARE TRUST',
                        style: TextStyle(
                          color: Color(0xFFB3E5FC),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Trusted guidance\nfor every student.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Verified counsellors • Privacy protected\n• NGO supported',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CounsellorDirectoryScreen(viewModel: vm),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  icon: const Icon(Icons.search_rounded, size: 16),
                  label: const Text(
                    'Explore Counsellors',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13),
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

class _IllustrationWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assests/home_screen_card_councellor.png',
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, _, _) => Container(
        color: _kBlue2.withValues(alpha: .3),
        child: const Center(
          child: Icon(Icons.people_alt_rounded,
              color: Colors.white54, size: 48),
        ),
      ),
    );
  }
}

// ── Services Card ─────────────────────────────────────────────────────────────

class _ServicesCard extends StatelessWidget {
  const _ServicesCard({required this.vm});
  final CounsellorViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          _ServiceRow(
            icon: Icons.verified_user_rounded,
            color: _kBlue,
            title: 'Verified Counsellor Panel',
            subtitle:
                'Review qualifications, service background, recognition and availability before requesting.',
            trailing: _VerifiedChip(),
            isFirst: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      CounsellorDirectoryScreen(viewModel: vm)),
            ),
          ),
          const _RowDivider(),
          _ServiceRow(
            icon: Icons.calendar_month_rounded,
            color: _kGreen,
            title: 'Book Counsellor',
            subtitle:
                'Filter trusted experts and submit a school counselling or awareness-camp request.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      CounsellorDirectoryScreen(viewModel: vm)),
            ),
          ),
          const _RowDivider(),
          _ServiceRow(
            icon: Icons.manage_accounts_rounded,
            color: _kPurple,
            title: 'Profile & Account Settings',
            subtitle:
                'View and update your school details, contact info, and manage your account.',
            isLast: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SchoolPartnerProfileScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.isFirst = false,
    this.isLast = false,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(18) : Radius.zero,
          bottom: isLast ? const Radius.circular(18) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          color: _kInk,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        )),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(
                          color: _kMuted,
                          fontSize: 11,
                          height: 1.4,
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: 6),
              ],
              const Icon(Icons.chevron_right_rounded,
                  color: _kMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        indent: 75,
        endIndent: 16,
        color: Color(0xFFEEEEEE),
      );
}

class _VerifiedChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _kVerified.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kVerified.withValues(alpha: .3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded,
                color: _kVerified, size: 11),
            SizedBox(width: 3),
            Text(
              'Verified',
              style: TextStyle(
                color: _kVerified,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}

// ── Impact Stats Row ──────────────────────────────────────────────────────────

class _ImpactStatsRow extends StatelessWidget {
  const _ImpactStatsRow({required this.stats});
  final SchoolStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.school_rounded,
          value: '${stats.studentsCounselled}',
          label: 'Students\nCounselled',
          color: _kBlue,
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: Icons.people_rounded,
          value: '${stats.counsellingSessions}',
          label: 'Counselling\nSessions',
          color: _kGreen,
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: Icons.account_balance_rounded,
          value: '${stats.awarenessPrograms}',
          label: 'Awareness\nPrograms',
          color: _kAmber,
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: Icons.star_rounded,
          value: '${stats.successStories}',
          label: 'Success\nStories',
          color: _kPurple,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: .8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Request Card ──────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.vm});
  final SchoolBookingRequest request;
  final CounsellorViewModel vm;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              SchoolRequestDetailScreen(request: request, vm: vm),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: .04),
                blurRadius: 10,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Counsellor avatar
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  request.status.color.withValues(alpha: .12),
              child: Icon(Icons.person_rounded,
                  color: request.status.color, size: 26),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.topic,
                    style: const TextStyle(
                      color: _kInk,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.counsellorName,
                    style: const TextStyle(
                        color: _kMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  // NGO badge + date
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: _kBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_rounded,
                            color: Colors.white, size: 10),
                      ),
                      const SizedBox(width: 4),
                      const Flexible(
                        child: Text(
                          'Punjabi Welfare Trust',
                          style: TextStyle(
                              color: _kMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Text(' • ',
                          style: TextStyle(
                              color: _kMuted, fontSize: 10)),
                      Text(
                        _fmtDate(request.requestedAt),
                        style: const TextStyle(
                            color: _kMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status + arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: request.status.color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                            request.status.color.withValues(alpha: .3)),
                  ),
                  child: Text(
                    request.status.label,
                    style: TextStyle(
                      color: request.status.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.chevron_right_rounded,
                    color: _kMuted, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests({required this.vm});
  final CounsellorViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_available_rounded,
              color: _kBlue, size: 36),
          const SizedBox(height: 10),
          const Text(
            'No counselling requests yet',
            style: TextStyle(
                color: _kInk, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      CounsellorDirectoryScreen(viewModel: vm)),
            ),
            style: FilledButton.styleFrom(backgroundColor: _kBlue),
            icon: const Icon(Icons.search_rounded, size: 16),
            label: const Text('Book a Counsellor'),
          ),
        ],
      ),
    );
  }
}

class _AssignmentNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kVerified.withValues(alpha: .2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: _kVerified.withValues(alpha: .06),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
            ),
            child: Row(
              children: [
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
                        color: _kVerified.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.volunteer_activism_rounded,
                          color: _kVerified, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Punjabi Welfare Trust',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: _kInk,
                        ),
                      ),
                      Text(
                        'Empowering Communities Through Service',
                        style: TextStyle(
                          fontSize: 10,
                          color: _kMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kVerified.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _kVerified.withValues(alpha: .3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded,
                          size: 10, color: _kVerified),
                      SizedBox(width: 3),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _kVerified,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Contact details ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              children: [
                _NgoRow(
                  icon: Icons.app_registration_rounded,
                  text: 'Regt. No. 736',
                ),
                const SizedBox(height: 6),
                _NgoRow(
                  icon: Icons.phone_rounded,
                  text: '+91 9211772333  /  7834992799',
                ),
                const SizedBox(height: 6),
                _NgoRow(
                  icon: Icons.location_on_rounded,
                  text:
                      'Delhi-Cantonment Branch, South West Delhi – 110010',
                ),
                const SizedBox(height: 6),
                _NgoRow(
                  icon: Icons.language_rounded,
                  text: 'https://punjabiwelfaretrust.org/',
                  isLink: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NgoRow extends StatelessWidget {
  const _NgoRow({required this.icon, required this.text, this.isLink = false});
  final IconData icon;
  final String text;
  final bool isLink;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: _kVerified),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isLink ? _kBlue : _kInk,
              decoration: isLink ? TextDecoration.underline : null,
              decorationColor: isLink ? _kBlue : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: _kInk,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 — Counsellors
// ══════════════════════════════════════════════════════════════════════════════

class _CounsellorsTab extends StatelessWidget {
  const _CounsellorsTab({required this.vm});
  final CounsellorViewModel vm;

  @override
  Widget build(BuildContext context) {
    final list = vm.allCounsellors;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Counsellors',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: _kCard,
        surfaceTintColor: _kCard,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: list.isEmpty
          ? const Center(
              child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = list[i];
                return Material(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CounsellorDirectoryScreen(
                            viewModel: vm),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor:
                                _kBlue.withValues(alpha: .1),
                            backgroundImage: c.photoUrl != null
                                ? NetworkImage(c.photoUrl!)
                                : null,
                            child: c.photoUrl == null
                                ? Text(
                                    c.name.isNotEmpty
                                        ? c.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        color: _kBlue,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(c.name,
                                    style: const TextStyle(
                                      color: _kInk,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    )),
                                const SizedBox(height: 2),
                                Text(c.designation,
                                    style: const TextStyle(
                                        color: _kMuted,
                                        fontSize: 12)),
                                const SizedBox(height: 6),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _kBlue.withValues(
                                        alpha: .08),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    c.category.label,
                                    style: const TextStyle(
                                      color: _kBlue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (c.isVerified)
                            const Icon(Icons.verified_rounded,
                                color: _kVerified, size: 20),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded,
                              color: _kMuted, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 — Requests
// ══════════════════════════════════════════════════════════════════════════════

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({required this.vm});
  final CounsellorViewModel vm;

  @override
  Widget build(BuildContext context) {
    final requests = vm.schoolRequests;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
          'My Requests (${requests.length})',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: _kCard,
        surfaceTintColor: _kCard,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          vm.loadSchoolRequests(force: true),
          vm.loadSchoolStats(force: true),
        ]),
        child: requests.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [_EmptyRequests(vm: vm)],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) =>
                    _RequestCard(request: requests[i], vm: vm),
              ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 3 — Impact
// ══════════════════════════════════════════════════════════════════════════════

class _ImpactTab extends StatelessWidget {
  const _ImpactTab({required this.vm});
  // ignore: unused_element
  final CounsellorViewModel vm;

  @override
  Widget build(BuildContext context) => const WallOfImpactView();
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 4 — Profile
// ══════════════════════════════════════════════════════════════════════════════

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.vm});
  final CounsellorViewModel vm;

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await AuthRepository.logout();
      } catch (_) {}
      AppState.clear();
      if (context.mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (r) => false);
      }
    }
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final p = vm.schoolProfile;
    final statusColor =
        p?.accessStatus == 'active' ? _kVerified : _kAmber;
    final statusLabel = p?.accessStatus != null
        ? p!.accessStatus![0].toUpperCase() +
            p.accessStatus!.substring(1)
        : 'Pending';

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: _kCard,
        surfaceTintColor: _kCard,
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SchoolPartnerProfileScreen()),
            ).then((_) => vm.loadSchoolProfile(force: true)),
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Avatar + identity ───────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _kBlue.withValues(alpha: .2), width: 3),
                    color: _kBlue.withValues(alpha: .08),
                  ),
                  child: p?.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            p!.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                                Icons.school_rounded,
                                color: _kBlue,
                                size: 36),
                          ),
                        )
                      : const Icon(Icons.school_rounded,
                          color: _kBlue, size: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  p?.schoolName ?? 'School Name',
                  style: const TextStyle(
                    color: _kInk,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kBlue.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _kBlue.withValues(alpha: .2)),
                      ),
                      child: Text(
                        p?.partnerId ?? 'SP-0000',
                        style: const TextStyle(
                          color: _kBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withValues(alpha: .25)),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── School Details ──────────────────────────────────────────────
          ProfileSection(
            title: 'School Details',
            rows: [
              if (p?.schoolName != null)
                ProfileRow(
                    Icons.school_rounded, 'School Name', p!.schoolName!),
              if (p?.schoolType != null)
                ProfileRow(
                    Icons.category_rounded, 'School Type', p!.schoolType!),
              if (p?.schoolBoard != null)
                ProfileRow(
                    Icons.menu_book_rounded, 'Board', p!.schoolBoard!),
              if (p?.registrationNumber != null)
                ProfileRow(Icons.badge_rounded, 'Reg. Number',
                    p!.registrationNumber!),
              if (p?.address != null)
                ProfileRow(Icons.home_rounded, 'Address', p!.address!),
              if (p?.city != null && p?.state != null)
                ProfileRow(Icons.location_city_rounded, 'City / State',
                    '${p!.city!}, ${p.state!}')
              else ...[
                if (p?.city != null)
                  ProfileRow(
                      Icons.location_city_rounded, 'City', p!.city!),
                if (p?.state != null)
                  ProfileRow(Icons.map_rounded, 'State', p!.state!),
              ],
              if (p?.pinCode != null)
                ProfileRow(
                    Icons.pin_drop_rounded, 'Pin Code', p!.pinCode!),
            ],
          ),
          const SizedBox(height: 14),

          // ── Contact Person ──────────────────────────────────────────────
          ProfileSection(
            title: 'Contact Person',
            rows: [
              if (p?.coordinatorName != null)
                ProfileRow(Icons.person_rounded, 'Coordinator',
                    p!.coordinatorName!),
              if (p?.coordinatorDesignation != null)
                ProfileRow(Icons.work_rounded, 'Designation',
                    p!.coordinatorDesignation!),
              if (p?.phone != null)
                ProfileRow(Icons.phone_rounded, 'Phone', p!.phone!),
              if (p?.alternatePhone != null)
                ProfileRow(Icons.phone_in_talk_rounded, 'Alt. Phone',
                    p!.alternatePhone!),
              if (p?.email != null)
                ProfileRow(Icons.email_rounded, 'Email', p!.email!),
            ],
          ),
          const SizedBox(height: 14),

          // ── Partnership Info ────────────────────────────────────────────
          ProfileSection(
            title: 'Partnership Info',
            rows: [
              if (p?.partnerId != null)
                ProfileRow(Icons.fingerprint_rounded, 'Partner ID',
                    p!.partnerId!),
              ProfileRow(
                  Icons.verified_rounded, 'Status', statusLabel),
              if (p?.joinedDate != null)
                ProfileRow(Icons.calendar_today_rounded, 'Joined Date',
                    _fmtDate(p!.joinedDate!)),
              if (p?.verificationNote != null &&
                  p!.verificationNote!.isNotEmpty)
                ProfileRow(Icons.info_outline_rounded,
                    'Verification Note', p.verificationNote!),
            ],
          ),
          const SizedBox(height: 14),

          // ── Account Actions ─────────────────────────────────────────────
          ProfileActionsCard(
            actions: [
              ProfileActionTile(
                icon: Icons.edit_rounded,
                label: 'Edit Profile',
                color: _kBlue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SchoolPartnerProfileScreen()),
                ).then((_) => vm.loadSchoolProfile(force: true)),
              ),
              ProfileActionTile(
                icon: Icons.logout_rounded,
                label: 'Logout',
                color: Colors.red,
                onTap: () => _logout(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

