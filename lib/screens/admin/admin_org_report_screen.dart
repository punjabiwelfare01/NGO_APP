import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/api_models.dart';
import '../../models/event_manager_models.dart';
import '../../models/ngo_profile.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/event_manager_viewmodel.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const _kNavy  = Color(0xFF0A1F44);
const _kNavy2 = Color(0xFF1A3A6C);
const _kGold  = Color(0xFFD4A017);
const _kGreen = Color(0xFF2E7D32);
const _kBg    = Color(0xFFF5F7FA);
const _kCard  = Colors.white;
const _kInk   = Color(0xFF17324D);
const _kMuted = Color(0xFF6B7A8D);
const _kRed   = Color(0xFFC62828);
const _kBlue  = Color(0xFF1565C0);
const _kTeal  = Color(0xFF00695C);
const _kAmber = Color(0xFFE65100);

class AdminOrgReportScreen extends StatefulWidget {
  const AdminOrgReportScreen({
    required this.admin,
    required this.em,
    super.key,
  });

  final AdminViewModel admin;
  final EventManagerViewModel em;

  @override
  State<AdminOrgReportScreen> createState() => _AdminOrgReportScreenState();
}

class _AdminOrgReportScreenState extends State<AdminOrgReportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // ── Aggregates ────────────────────────────────────────────────────────────
  late final List<NGOEvent> _completed;
  late final List<NGOEvent> _ongoing;
  late final List<NGOEvent> _all;
  late final List<EMStudentAssignment> _allAssignments;
  late final int _totalPeople;
  late final double _totalDonation;
  late final int _certEligible;
  late final double _totalHours;
  late final int _totalActivities;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);

    _all = widget.em.events;
    _completed =
        _all.where((e) => e.status == EventStatus.completed).toList();
    _ongoing =
        _all.where((e) => e.status == EventStatus.ongoing).toList();

    _allAssignments = widget.em.assignments;

    _totalPeople =
        _allAssignments.fold(0, (s, a) => s + (a.submission?.peopleReached ?? 0));

    _totalDonation = _allAssignments.fold(
        0.0, (s, a) => s + (a.submission?.donationCollected ?? 0.0));

    _certEligible = _allAssignments
        .where((a) => a.status == AssignmentStatus.certificateEligible)
        .length;

    _totalHours = _allAssignments
        .fold(0.0, (s, a) => s + (a.submission?.hoursWorked ?? 0.0));

    _totalActivities =
        _all.fold(0, (s, e) => s + e.activities.length);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String get _reportNo {
    final now = DateTime.now();
    return 'PWT-ORG-${now.year}${now.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: NestedScrollView(
        headerSliverBuilder: (_, _) => [_appBar()],
        body: TabBarView(
          controller: _tab,
          children: [
            _overviewTab(),
            _eventsTab(),
            _volunteersTab(),
            _complianceTab(),
          ],
        ),
      ),
      bottomNavigationBar: _BottomBar(onCopy: _copyReportId),
    );
  }

  Widget _appBar() => SliverAppBar(
        pinned: true,
        expandedHeight: 210,
        backgroundColor: _kNavy,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
        actions: [
          IconButton(
            onPressed: _copyReportId,
            icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
            tooltip: 'Copy Report ID',
          ),
        ],
        flexibleSpace: FlexibleSpaceBar(
          background: _OrgCoverBanner(
            reportNo: _reportNo,
            generatedAt: DateTime.now(),
            admin: widget.admin,
          ),
        ),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          indicatorColor: _kGold,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle:
              const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 11.5),
          tabs: const [
            Tab(text: '  Overview  '),
            Tab(text: '  Events  '),
            Tab(text: '  Volunteers  '),
            Tab(text: '  Compliance  '),
          ],
        ),
      );

  // ── Tabs ─────────────────────────────────────────────────────────────────

  Widget _overviewTab() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          children: [
            _OrgSection(
              number: '01',
              title: 'Executive Summary',
              icon: Icons.bar_chart_rounded,
              child: _OrgExecutiveSummary(
                all: _all,
                completed: _completed,
                ongoing: _ongoing,
                totalPeople: _totalPeople,
                totalDonation: _totalDonation,
                totalHours: _totalHours,
                certEligible: _certEligible,
                totalActivities: _totalActivities,
                stats: widget.admin.stats,
              ),
            ),
            const SizedBox(height: 14),
            _OrgSection(
              number: '02',
              title: 'NGO Overview',
              icon: Icons.business_rounded,
              child: _NgoOverview(reportNo: _reportNo),
            ),
            const SizedBox(height: 14),
            _OrgSection(
              number: '03',
              title: 'Category-wise Event Breakdown',
              icon: Icons.category_rounded,
              child: _CategoryBreakdown(events: _all),
            ),
          ],
        ),
      );

  Widget _eventsTab() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          children: [
            _OrgSection(
              number: '04',
              title: 'Event Status Summary',
              icon: Icons.event_rounded,
              child: _EventStatusSummary(
                  all: _all, completed: _completed, ongoing: _ongoing),
            ),
            const SizedBox(height: 14),
            _OrgSection(
              number: '05',
              title: 'All Events Log',
              icon: Icons.list_alt_rounded,
              child: _AllEventsList(events: _all),
            ),
            const SizedBox(height: 14),
            _OrgSection(
              number: '06',
              title: 'School Partnership Report',
              icon: Icons.school_rounded,
              child: _SchoolPartnerReport(events: _all),
            ),
          ],
        ),
      );

  Widget _volunteersTab() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          children: [
            _OrgSection(
              number: '07',
              title: 'Volunteer Analytics',
              icon: Icons.people_rounded,
              child: _VolunteerAnalytics(
                assignments: _allAssignments,
                totalHours: _totalHours,
                certEligible: _certEligible,
                totalPeople: _totalPeople,
                stats: widget.admin.stats,
              ),
            ),
            const SizedBox(height: 14),
            _OrgSection(
              number: '08',
              title: 'Top Contributors',
              icon: Icons.star_rounded,
              child: _TopContributors(assignments: _allAssignments),
            ),
            const SizedBox(height: 14),
            _OrgSection(
              number: '09',
              title: 'Donation & Financial Analytics',
              icon: Icons.payments_rounded,
              child: _FinancialAnalytics(
                  assignments: _allAssignments,
                  totalDonation: _totalDonation),
            ),
          ],
        ),
      );

  Widget _complianceTab() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          children: [
            _OrgSection(
              number: '10',
              title: 'Certificate Analytics',
              icon: Icons.workspace_premium_rounded,
              child: _CertAnalytics(
                  assignments: _allAssignments,
                  certEligible: _certEligible),
            ),
            const SizedBox(height: 14),
            _OrgSection(
              number: '11',
              title: 'Organization Compliance Status',
              icon: Icons.verified_rounded,
              child: _OrgCompliance(
                all: _all,
                completed: _completed,
                assignments: _allAssignments,
              ),
            ),
            const SizedBox(height: 14),
            _OrgSection(
              number: '12',
              title: 'Official Approval',
              icon: Icons.approval_rounded,
              child: _OrgApproval(reportNo: _reportNo),
            ),
          ],
        ),
      );

  Future<void> _copyReportId() async {
    await Clipboard.setData(ClipboardData(text: _reportNo));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Report ID $_reportNo copied.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// ─── Org Cover Banner ─────────────────────────────────────────────────────────

class _OrgCoverBanner extends StatelessWidget {
  const _OrgCoverBanner({
    required this.reportNo,
    required this.generatedAt,
    required this.admin,
  });
  final String reportNo;
  final DateTime generatedAt;
  final AdminViewModel admin;

  String _date(DateTime d) {
    const m = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kNavy, _kNavy2],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 88, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      color: _kGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.business_rounded,
                        color: _kGold, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      NGOProfile.fallback.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Regt. No. ${NGOProfile.fallback.registrationNumber ?? '736'}',
                      style: const TextStyle(color: Colors.white54, fontSize: 9),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kGold.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'ADMIN REPORT',
                  style: TextStyle(
                      color: _kGold,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'ORGANISATION-WIDE IMPACT REPORT',
            style: TextStyle(
              color: _kGold,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${NGOProfile.fallback.name} — Annual Performance Overview',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              _chip(Icons.tag_rounded, reportNo),
              const SizedBox(width: 10),
              _chip(Icons.calendar_today_rounded, _date(generatedAt)),
              const SizedBox(width: 10),
              _chip(Icons.admin_panel_settings_rounded, 'Admin Access'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white54),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      );
}

// ─── Section wrapper ──────────────────────────────────────────────────────────

class _OrgSection extends StatelessWidget {
  const _OrgSection({
    required this.number,
    required this.title,
    required this.icon,
    required this.child,
  });
  final String number;
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 20,
                offset: Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: const BoxDecoration(
                color: _kNavy,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kGold,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(number,
                        style: const TextStyle(
                            color: _kNavy,
                            fontSize: 10,
                            fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 10),
                  Icon(icon, color: Colors.white70, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.all(14), child: child),
          ],
        ),
      );
}

// ─── 01 Org Executive Summary ─────────────────────────────────────────────────

class _OrgExecutiveSummary extends StatelessWidget {
  const _OrgExecutiveSummary({
    required this.all,
    required this.completed,
    required this.ongoing,
    required this.totalPeople,
    required this.totalDonation,
    required this.totalHours,
    required this.certEligible,
    required this.totalActivities,
    required this.stats,
  });
  final List<NGOEvent> all;
  final List<NGOEvent> completed;
  final List<NGOEvent> ongoing;
  final int totalPeople;
  final double totalDonation;
  final double totalHours;
  final int certEligible;
  final int totalActivities;
  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero stat row
        Row(
          children: [
            _KPI('${all.length}', 'Total Events', _kBlue, Icons.event_rounded),
            _KPI('${completed.length}', 'Completed', _kGreen,
                Icons.check_circle_rounded),
            _KPI('$totalPeople', 'Beneficiaries', _kTeal,
                Icons.volunteer_activism_rounded),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _KPI('${stats.activeUsers}', 'Active Users', _kBlue,
                Icons.people_rounded),
            _KPI('₹${totalDonation.toStringAsFixed(0)}', 'Total Donations',
                _kAmber, Icons.payments_rounded),
            _KPI('$certEligible', 'Cert. Eligible', const Color(0xFF6A1B9A),
                Icons.workspace_premium_rounded),
          ],
        ),
        const SizedBox(height: 14),
        // Completion status bar
        _StatusRow('Events Completed',
            '${all.isEmpty ? 0 : (completed.length / all.length * 100).toStringAsFixed(0)}%',
            completed.isEmpty ? 0.0 : completed.length / all.length,
            _kGreen),
        const SizedBox(height: 8),
        _StatusRow('Volunteer Hours Logged',
            '${totalHours.toStringAsFixed(1)}h',
            totalHours > 0 ? 0.75 : 0.0, _kTeal),
        const SizedBox(height: 8),
        _StatusRow('Activities Conducted',
            '$totalActivities', totalActivities > 0 ? 0.70 : 0.0, _kBlue),
        const SizedBox(height: 14),
        // Key metrics summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kNavy.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _metaRow('Reporting Period',
                  'Organization-wide cumulative data'),
              _metaRow('Total Events', '${all.length}'),
              _metaRow('Completed Events', '${completed.length}'),
              _metaRow('Ongoing Events', '${ongoing.length}'),
              _metaRow('Total Beneficiaries', '$totalPeople'),
              _metaRow('Total Volunteer Hours',
                  '${totalHours.toStringAsFixed(1)} hrs'),
              _metaRow('Total Donations', '₹${totalDonation.toStringAsFixed(2)}'),
              _metaRow('Certificate Eligible', '$certEligible volunteers'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metaRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(fontSize: 11.5, color: _kMuted))),
            Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kInk)),
          ],
        ),
      );
}

class _KPI extends StatelessWidget {
  const _KPI(this.value, this.label, this.color, this.icon);
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: color)),
              Text(label,
                  style: const TextStyle(fontSize: 9.5, color: _kMuted),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class _StatusRow extends StatelessWidget {
  const _StatusRow(this.label, this.valueLabel, this.value, this.color);
  final String label;
  final String valueLabel;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(label,
                      style:
                          const TextStyle(fontSize: 12, color: _kInk))),
              Text(valueLabel,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 7,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      );
}

// ─── 02 NGO Overview ─────────────────────────────────────────────────────────

class _NgoOverview extends StatelessWidget {
  const _NgoOverview({required this.reportNo});
  final String reportNo;

  @override
  Widget build(BuildContext context) {
    final ngo = NGOProfile.fallback;
    final rows = <(String, String)>[
      ('Organization Name', ngo.name),
      ('Registration No.', ngo.registrationNumber ?? '736'),
      ('Report Reference', reportNo),
      ('Email', ngo.email ?? 'Punjabiwelfaretrust99@gmail.com'),
      ('Contact', ngo.phone ?? '9211772333, 7834992799'),
      ('Website', ngo.website ?? 'www.punjabihelp.org'),
      ('Tagline', ngo.tagline ?? 'Empowering Communities Through Service'),
      ('Report Type', 'Organisation-wide Impact Report'),
      ('Access Level', 'Admin / Management'),
    ];

    return Column(
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(rows[i].$1,
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: _kMuted,
                          fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text(rows[i].$2,
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: _kInk,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          if (i < rows.length - 1)
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
        ],
      ],
    );
  }
}

// ─── 03 Category Breakdown ────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.events});
  final List<NGOEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const _Empty('No events found.');
    }

    final counts = <EventCategory, int>{};
    for (final e in events) {
      counts[e.category] = (counts[e.category] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      _kBlue, _kGreen, _kTeal, _kAmber, _kRed,
      const Color(0xFF6A1B9A), const Color(0xFF00838F),
    ];

    return Column(
      children: [
        for (int i = 0; i < sorted.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(sorted[i].key.label,
                      style: const TextStyle(fontSize: 12, color: _kInk)),
                ),
                SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: sorted[i].value / events.length,
                      minHeight: 8,
                      backgroundColor:
                          colors[i % colors.length].withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(
                          colors[i % colors.length]),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  child: Text('${sorted[i].value}',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors[i % colors.length])),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── 04 Event Status Summary ──────────────────────────────────────────────────

class _EventStatusSummary extends StatelessWidget {
  const _EventStatusSummary({
    required this.all,
    required this.completed,
    required this.ongoing,
  });
  final List<NGOEvent> all;
  final List<NGOEvent> completed;
  final List<NGOEvent> ongoing;

  @override
  Widget build(BuildContext context) {
    final draft =
        all.where((e) => e.status == EventStatus.draft).length;
    final archived =
        all.where((e) => e.status == EventStatus.archived).length;

    return Column(
      children: [
        Row(
          children: [
            _StatusChip('Total', '${all.length}', _kBlue),
            const SizedBox(width: 8),
            _StatusChip('Completed', '${completed.length}', _kGreen),
            const SizedBox(width: 8),
            _StatusChip('Ongoing', '${ongoing.length}', _kAmber),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _StatusChip('Draft', '$draft', _kMuted),
            const SizedBox(width: 8),
            _StatusChip('Archived', '$archived', const Color(0xFF9E9E9E)),
            const SizedBox(width: 8),
            _StatusChip('With Schools',
                '${all.where((e) => e.partnerSchool != null).length}',
                _kTeal),
          ],
        ),
        if (all.isNotEmpty) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 20,
              child: Row(
                children: [
                  if (completed.isNotEmpty)
                    Flexible(
                        flex: completed.length,
                        child: Container(color: _kGreen)),
                  if (ongoing.isNotEmpty)
                    Flexible(
                        flex: ongoing.length,
                        child: Container(color: _kAmber)),
                  if (draft > 0)
                    Flexible(
                        flex: draft,
                        child: Container(color: const Color(0xFFBBBBBB))),
                  if (archived > 0)
                    Flexible(
                        flex: archived,
                        child: Container(color: const Color(0xFFDDDDDD))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            children: const [
              _Legend(_kGreen, 'Completed'),
              _Legend(_kAmber, 'Ongoing'),
              _Legend(Color(0xFFBBBBBB), 'Draft'),
              _Legend(Color(0xFFDDDDDD), 'Archived'),
            ],
          ),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: color)),
              Text(label,
                  style: const TextStyle(fontSize: 10, color: _kMuted),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

// ─── 05 All Events List ───────────────────────────────────────────────────────

class _AllEventsList extends StatelessWidget {
  const _AllEventsList({required this.events});
  final List<NGOEvent> events;

  String _date(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const _Empty('No events recorded.');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _kNavy.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            children: [
              Expanded(
                  flex: 4,
                  child: Text('EVENT',
                      style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: _kMuted))),
              Expanded(
                  flex: 2,
                  child: Text('DATE',
                      style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: _kMuted))),
              Text('STATUS',
                  style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: _kMuted)),
            ],
          ),
        ),
        for (int i = 0; i < events.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(events[i].title,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600, color: _kInk),
                          overflow: TextOverflow.ellipsis),
                      Text(events[i].category.label,
                          style: const TextStyle(
                              fontSize: 10, color: _kMuted)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(_date(events[i].date),
                      style: const TextStyle(fontSize: 10.5, color: _kMuted)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: events[i].status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(events[i].status.label,
                      style: TextStyle(
                          fontSize: 9,
                          color: events[i].status.color,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          if (i < events.length - 1)
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
        ],
      ],
    );
  }
}

// ─── 06 School Partnership ────────────────────────────────────────────────────

class _SchoolPartnerReport extends StatelessWidget {
  const _SchoolPartnerReport({required this.events});
  final List<NGOEvent> events;

  @override
  Widget build(BuildContext context) {
    final withSchool =
        events.where((e) => e.partnerSchool != null).toList();

    if (withSchool.isEmpty) {
      return const _Empty('No school partnerships recorded.');
    }

    final schools = <String, int>{};
    for (final e in withSchool) {
      schools[e.partnerSchool!] = (schools[e.partnerSchool!] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _KPI('${withSchool.length}', 'Events w/ Schools', _kTeal,
                Icons.school_rounded),
            const SizedBox(width: 8),
            _KPI('${schools.length}', 'Partner Schools', _kBlue,
                Icons.handshake_rounded),
          ],
        ),
        const SizedBox(height: 14),
        for (final entry in schools.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.school_rounded, size: 14, color: _kTeal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(entry.key,
                      style: const TextStyle(fontSize: 12.5, color: _kInk)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${entry.value} event(s)',
                      style: const TextStyle(
                          fontSize: 10,
                          color: _kTeal,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── 07 Volunteer Analytics ───────────────────────────────────────────────────

class _VolunteerAnalytics extends StatelessWidget {
  const _VolunteerAnalytics({
    required this.assignments,
    required this.totalHours,
    required this.certEligible,
    required this.totalPeople,
    required this.stats,
  });
  final List<EMStudentAssignment> assignments;
  final double totalHours;
  final int certEligible;
  final int totalPeople;
  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final approved = assignments
        .where((a) =>
            a.status == AssignmentStatus.approved ||
            a.status == AssignmentStatus.certificateEligible ||
            a.status == AssignmentStatus.verified)
        .length;
    final rejected =
        assignments.where((a) => a.status == AssignmentStatus.rejected).length;
    final submitted =
        assignments.where((a) => a.status == AssignmentStatus.workSubmitted).length;
    final total = assignments.length;

    return Column(
      children: [
        Row(
          children: [
            _KPI('${stats.activeUsers}', 'Active Users', _kBlue,
                Icons.people_rounded),
            const SizedBox(width: 8),
            _KPI('$total', 'Total Assignments', _kGreen,
                Icons.assignment_rounded),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _KPI('$approved', 'Approved', _kGreen,
                Icons.check_circle_rounded),
            const SizedBox(width: 8),
            _KPI('$submitted', 'Submitted', _kAmber,
                Icons.upload_file_rounded),
            const SizedBox(width: 8),
            _KPI('$rejected', 'Rejected', _kRed, Icons.cancel_rounded),
          ],
        ),
        const SizedBox(height: 14),
        _StatusRow('Approval Rate',
            total > 0
                ? '${(approved / total * 100).toStringAsFixed(0)}%'
                : '0%',
            total > 0 ? approved / total : 0.0, _kGreen),
        const SizedBox(height: 8),
        _StatusRow('Total Volunteer Hours',
            '${totalHours.toStringAsFixed(1)}h',
            totalHours > 0 ? 0.75 : 0.0, _kTeal),
        const SizedBox(height: 8),
        _StatusRow('People Reached', '$totalPeople beneficiaries',
            totalPeople > 0 ? 0.70 : 0.0, _kBlue),
        const SizedBox(height: 8),
        _StatusRow('Certificate Eligible',
            '$certEligible volunteers',
            total > 0 ? certEligible / total : 0.0,
            const Color(0xFF6A1B9A)),
      ],
    );
  }
}

// ─── 08 Top Contributors ──────────────────────────────────────────────────────

class _TopContributors extends StatelessWidget {
  const _TopContributors({required this.assignments});
  final List<EMStudentAssignment> assignments;

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
      return const _Empty('No volunteer data available.');
    }

    // Aggregate by volunteer name
    final hours = <String, double>{};
    final count = <String, int>{};
    for (final a in assignments) {
      final name = a.student.name;
      hours[name] = (hours[name] ?? 0) + (a.submission?.hoursWorked ?? 0);
      count[name] = (count[name] ?? 0) + 1;
    }

    final topByHours = hours.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = topByHours.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top Volunteers by Hours Contributed',
            style: TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w700, color: _kMuted)),
        const SizedBox(height: 10),
        for (int i = 0; i < top.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: i < 3
                        ? _kGold.withValues(alpha: 0.2)
                        : _kBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: i < 3 ? _kGold : _kMuted)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(top[i].key,
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _kInk)),
                      Text('${count[top[i].key] ?? 0} assignment(s)',
                          style: const TextStyle(
                              fontSize: 10.5, color: _kMuted)),
                    ],
                  ),
                ),
                Text('${top[i].value.toStringAsFixed(1)}h',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _kTeal)),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── 09 Financial Analytics ───────────────────────────────────────────────────

class _FinancialAnalytics extends StatelessWidget {
  const _FinancialAnalytics(
      {required this.assignments, required this.totalDonation});
  final List<EMStudentAssignment> assignments;
  final double totalDonation;

  @override
  Widget build(BuildContext context) {
    final withDonation = assignments
        .where((a) =>
            a.submission != null &&
            (a.submission!.donationCollected ?? 0) > 0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _DonStat('Total Collected',
                '₹${totalDonation.toStringAsFixed(0)}', _kGreen),
            const SizedBox(width: 10),
            _DonStat('Contributors', '${withDonation.length}', _kBlue),
          ],
        ),
        if (withDonation.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('Per-Event Donation Summary',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _kMuted)),
          const SizedBox(height: 8),
          for (final a in withDonation)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.student.name,
                            style: const TextStyle(
                                fontSize: 12, color: _kInk)),
                        Text(a.event.title,
                            style: const TextStyle(
                                fontSize: 10.5, color: _kMuted),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Text(
                    '₹${a.submission!.donationCollected!.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kGreen),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _kAmber.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kAmber.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: _kAmber, size: 14),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Donations collected via UPI, cash, or in-kind. All records subject to audit verification.',
                  style: TextStyle(
                      fontSize: 11, color: _kAmber, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonStat extends StatelessWidget {
  const _DonStat(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: color)),
              Text(label,
                  style: const TextStyle(fontSize: 10.5, color: _kMuted)),
            ],
          ),
        ),
      );
}

// ─── 10 Certificate Analytics ─────────────────────────────────────────────────

class _CertAnalytics extends StatelessWidget {
  const _CertAnalytics(
      {required this.assignments, required this.certEligible});
  final List<EMStudentAssignment> assignments;
  final int certEligible;

  @override
  Widget build(BuildContext context) {
    final total = assignments.length;
    final eligible = assignments
        .where((a) => a.status == AssignmentStatus.certificateEligible)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _KPI('$certEligible', 'Eligible', const Color(0xFF6A1B9A),
                Icons.workspace_premium_rounded),
            const SizedBox(width: 8),
            _KPI('$total', 'Total Volunteers', _kBlue,
                Icons.people_rounded),
            const SizedBox(width: 8),
            _KPI('${total - certEligible}', 'Pending', _kAmber,
                Icons.pending_rounded),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: total > 0 ? certEligible / total : 0,
            minHeight: 12,
            backgroundColor: const Color(0xFFEEEEEE),
            valueColor:
                const AlwaysStoppedAnimation(Color(0xFF6A1B9A)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          total > 0
              ? '${(certEligible / total * 100).toStringAsFixed(0)}% of volunteers are certificate-eligible'
              : 'No volunteers yet',
          style: const TextStyle(fontSize: 11, color: _kMuted),
        ),
        if (eligible.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('Certificate-Eligible Volunteers',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _kMuted)),
          const SizedBox(height: 6),
          for (final a in eligible)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded,
                      size: 13, color: _kGold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(a.student.name,
                        style: const TextStyle(
                            fontSize: 12, color: _kInk)),
                  ),
                  Text(a.event.title,
                      style: const TextStyle(
                          fontSize: 10.5, color: _kMuted),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

// ─── 11 Org Compliance ───────────────────────────────────────────────────────

class _OrgCompliance extends StatelessWidget {
  const _OrgCompliance({
    required this.all,
    required this.completed,
    required this.assignments,
  });
  final List<NGOEvent> all;
  final List<NGOEvent> completed;
  final List<EMStudentAssignment> assignments;

  @override
  Widget build(BuildContext context) {
    final hasEvents = all.isNotEmpty;
    final hasCompleted = completed.isNotEmpty;
    final hasVolunteers = assignments.isNotEmpty;
    final hasSubmissions = assignments.any((a) => a.submission != null);
    final hasApproved = assignments.any((a) =>
        a.status == AssignmentStatus.approved ||
        a.status == AssignmentStatus.certificateEligible);
    final hasCertEligible =
        assignments.any((a) => a.status == AssignmentStatus.certificateEligible);

    final checks = <(String, bool, String)>[
      ('NGO Registration', true, 'Regt. No. 736 — Active'),
      ('Events Created', hasEvents, '${all.length} total event(s)'),
      ('Events Completed', hasCompleted, '${completed.length} event(s) completed'),
      ('Volunteers Enrolled', hasVolunteers, '${assignments.length} assignment(s)'),
      ('Work Submitted', hasSubmissions,
          '${assignments.where((a) => a.submission != null).length} submission(s)'),
      ('Work Approved', hasApproved,
          '${assignments.where((a) => a.status == AssignmentStatus.approved || a.status == AssignmentStatus.certificateEligible).length} approved'),
      ('Certificate Eligible', hasCertEligible,
          '${assignments.where((a) => a.status == AssignmentStatus.certificateEligible).length} eligible'),
      ('Reports Generated', hasCompleted, 'For all completed events'),
    ];

    final done = checks.where((c) => c.$2).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: done / checks.length,
                  minHeight: 14,
                  backgroundColor: _kGreen.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(_kGreen),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('$done/${checks.length}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _kGreen)),
          ],
        ),
        const SizedBox(height: 14),
        for (final c in checks) _CheckRow(c.$1, c.$2, c.$3),
      ],
    );
  }
}

// ─── 12 Org Approval ─────────────────────────────────────────────────────────

class _OrgApproval extends StatelessWidget {
  const _OrgApproval({required this.reportNo});
  final String reportNo;

  @override
  Widget build(BuildContext context) {
    final ngo = NGOProfile.fallback;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E8F0)),
          ),
          child: Column(
            children: [
              _metaRow('Report Reference', reportNo),
              _metaRow('Generated On', _dateNow()),
              _metaRow('Organization', ngo.name),
              _metaRow('Regt. No.', ngo.registrationNumber ?? '736'),
              _metaRow('Contact', ngo.phone ?? '9211772333, 7834992799'),
              _metaRow('Email', ngo.email ?? 'Punjabiwelfaretrust99@gmail.com'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: const [
            _SigBlock(title: 'Prepared By', name: 'Admin', role: 'System Admin'),
            SizedBox(width: 10),
            _SigBlock(
                title: 'Authorised By',
                name: 'Punjabi Welfare Trust',
                role: 'NGO Management'),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kNavy.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kNavy.withValues(alpha: 0.1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.verified_rounded, color: _kGreen, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Official Organisation-wide Impact Report issued by ${ngo.name}. '
                  'Report Ref: $reportNo. '
                  'This report is generated from live data and is valid at the time of generation.',
                  style: const TextStyle(
                      fontSize: 11, color: _kMuted, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _dateNow() {
    final d = DateTime.now();
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  Widget _metaRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style: const TextStyle(fontSize: 11, color: _kMuted)),
            ),
            Text(value,
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _kInk)),
          ],
        ),
      );
}

// ─── Bottom Bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onCopy});
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy Report ID'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: _kBlue),
                foregroundColor: _kBlue,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Close Report'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: _kNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: _kMuted)),
        ],
      );
}

class _CheckRow extends StatelessWidget {
  const _CheckRow(this.label, this.done, this.note);
  final String label;
  final bool done;
  final String note;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: done ? _kGreen : const Color(0xFFBBBBBB),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: done ? _kInk : _kMuted)),
                  Text(note,
                      style: const TextStyle(
                          fontSize: 10.5, color: _kMuted)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SigBlock extends StatelessWidget {
  const _SigBlock({
    required this.title,
    required this.name,
    required this.role,
  });
  final String title;
  final String name;
  final String role;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E8F0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 10, color: _kMuted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(width: 80, height: 1, color: const Color(0xFFCCCCCC)),
              const SizedBox(height: 6),
              Text(name,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _kInk),
                  textAlign: TextAlign.center),
              Text(role,
                  style: const TextStyle(fontSize: 10, color: _kMuted),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const Icon(Icons.inbox_rounded,
                color: Color(0xFFCCCCCC), size: 36),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: _kMuted)),
          ],
        ),
      );
}
