import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/event_manager_models.dart';
import '../../models/ngo_profile.dart';
import '../../repositories/event_manager_repository.dart';
import '../../utils/file_download.dart';
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

// ─── Screen ───────────────────────────────────────────────────────────────────

class OfficialEventReportScreen extends StatefulWidget {
  const OfficialEventReportScreen({
    required this.event,
    required this.assignments,
    required this.report,
    required this.vm,
    super.key,
  });

  final NGOEvent event;
  final List<EMStudentAssignment> assignments;
  final EventReport report;
  final EventManagerViewModel vm;

  @override
  State<OfficialEventReportScreen> createState() =>
      _OfficialEventReportScreenState();
}

class _OfficialEventReportScreenState extends State<OfficialEventReportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  bool _downloading = false;
  bool _sharing = false;

  // ── Derived statistics ────────────────────────────────────────────────────
  late final List<EMStudentAssignment> _ea; // event assignments
  late final List<EMStudentAssignment> _approved;
  late final List<EMStudentAssignment> _submitted;
  late final List<EMStudentAssignment> _rejected;
  late final List<String> _photos;
  late final int _totalPeople;
  late final double _totalDonation;
  late final double _totalHours;
  late final int _certEligible;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);

    _ea = widget.assignments
        .where((a) => a.event.id == widget.event.id)
        .toList();

    _approved = _ea
        .where((a) =>
            a.status == AssignmentStatus.approved ||
            a.status == AssignmentStatus.certificateEligible ||
            a.status == AssignmentStatus.verified)
        .toList();

    _submitted = _ea
        .where((a) => a.status == AssignmentStatus.workSubmitted)
        .toList();

    _rejected = _ea
        .where((a) => a.status == AssignmentStatus.rejected)
        .toList();

    _certEligible =
        _ea.where((a) => a.status == AssignmentStatus.certificateEligible).length;

    _photos = _ea
        .expand((a) => a.submission?.photoUrls ?? <String>[])
        .toList();

    _totalPeople = _ea.fold(0, (s, a) => s + (a.submission?.peopleReached ?? 0));

    _totalDonation =
        _ea.fold(0.0, (s, a) => s + (a.submission?.donationCollected ?? 0.0));

    _totalHours =
        _ea.fold(0.0, (s, a) => s + (a.submission?.hoursWorked ?? 0.0));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String get _reportNo =>
      'PWT-ER-${widget.report.id.toString().padLeft(4, '0')}';

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
            _volunteersTab(),
            _evidenceTab(),
            _impactTab(),
            _complianceTab(),
          ],
        ),
      ),
      bottomNavigationBar: _BottomBar(
        onDownload: _download,
        onShare: _share,
        onFinalize: _finalize,
        downloading: _downloading,
        sharing: _sharing,
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────

  Widget _appBar() => SliverAppBar(
        pinned: true,
        expandedHeight: 220,
        backgroundColor: _kNavy,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
        actions: [
          IconButton(
            onPressed: _share,
            icon: Icon(Icons.share_rounded,
                color: _sharing ? Colors.white30 : Colors.white),
          ),
          IconButton(
            onPressed: _download,
            icon: Icon(Icons.download_rounded,
                color: _downloading ? Colors.white30 : Colors.white),
          ),
        ],
        flexibleSpace: FlexibleSpaceBar(
          background: _CoverBanner(
            event: widget.event,
            report: widget.report,
            reportNo: _reportNo,
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
            Tab(text: '  Volunteers  '),
            Tab(text: '  Evidence  '),
            Tab(text: '  Impact  '),
            Tab(text: '  Compliance  '),
          ],
        ),
      );

  // ── Tabs ─────────────────────────────────────────────────────────────────

  Widget _overviewTab() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        child: Column(
          children: [
            _Section(
              number: '01',
              title: 'Executive Summary',
              icon: Icons.bar_chart_rounded,
              child: _ExecutiveSummary(
                event: widget.event,
                report: widget.report,
                totalPeople: _totalPeople,
                totalDonation: _totalDonation,
                totalHours: _totalHours,
                approvedCount: _approved.length,
                certEligible: _certEligible,
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              number: '02',
              title: 'Event Information',
              icon: Icons.event_note_rounded,
              child: _EventInfo(event: widget.event, reportNo: _reportNo),
            ),
            const SizedBox(height: 14),
            _Section(
              number: '03',
              title: 'Event Timeline',
              icon: Icons.timeline_rounded,
              child: _EventTimeline(event: widget.event, report: widget.report),
            ),
          ],
        ),
      );

  Widget _volunteersTab() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        child: Column(
          children: [
            _Section(
              number: '05',
              title: 'Volunteer Performance',
              icon: Icons.people_rounded,
              child: _VolunteerStats(
                ea: _ea,
                approved: _approved,
                submitted: _submitted,
                rejected: _rejected,
                totalHours: _totalHours,
                certEligible: _certEligible,
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              number: '04',
              title: 'Activity-wise Details',
              icon: Icons.assignment_rounded,
              child: _ActivityDetails(
                activities: widget.event.activities,
                ea: _ea,
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              number: '05b',
              title: 'Volunteer Roster',
              icon: Icons.list_alt_rounded,
              child: _VolunteerRoster(ea: _ea),
            ),
          ],
        ),
      );

  Widget _evidenceTab() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        child: Column(
          children: [
            _Section(
              number: '06',
              title: 'Proof of Work Gallery',
              icon: Icons.photo_library_rounded,
              child: _ProofGallery(photos: _photos, ea: _ea),
            ),
            const SizedBox(height: 14),
            _Section(
              number: '06b',
              title: 'Submission Records',
              icon: Icons.upload_file_rounded,
              child: _SubmissionList(ea: _ea),
            ),
          ],
        ),
      );

  Widget _impactTab() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        child: Column(
          children: [
            _Section(
              number: '08',
              title: 'Beneficiary Information',
              icon: Icons.volunteer_activism_rounded,
              child: _BeneficiaryInfo(
                  totalPeople: _totalPeople, event: widget.event),
            ),
            const SizedBox(height: 14),
            _Section(
              number: '09',
              title: 'Donation Report',
              icon: Icons.payments_rounded,
              child: _DonationReport(ea: _ea, total: _totalDonation),
            ),
            const SizedBox(height: 14),
            _Section(
              number: '12',
              title: 'Impact Analysis',
              icon: Icons.analytics_rounded,
              child: _ImpactAnalysis(
                  report: widget.report,
                  event: widget.event,
                  totalHours: _totalHours),
            ),
            const SizedBox(height: 14),
            _Section(
              number: '13',
              title: 'Event Statistics',
              icon: Icons.insights_rounded,
              child: _EventStats(
                ea: _ea,
                activities: widget.event.activities,
                totalHours: _totalHours,
                totalDonation: _totalDonation,
                totalPeople: _totalPeople,
              ),
            ),
          ],
        ),
      );

  Widget _complianceTab() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        child: Column(
          children: [
            _Section(
              number: '14',
              title: 'Certificates',
              icon: Icons.workspace_premium_rounded,
              child: _CertificatesSection(
                ea: _ea,
                certEligible: _certEligible,
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              number: '15',
              title: 'Compliance Checklist',
              icon: Icons.checklist_rounded,
              child: _ComplianceChecklist(
                event: widget.event,
                ea: _ea,
                hasPhotos: _photos.isNotEmpty,
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              number: '16',
              title: 'Approval & Verification',
              icon: Icons.verified_rounded,
              child: _ApprovalSection(
                report: widget.report,
                reportNo: _reportNo,
              ),
            ),
          ],
        ),
      );

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final id = await EventManagerRepository.ensureReport(widget.event.id);
      final ok = await downloadFile(
        EventManagerRepository.reportDownloadUrl(widget.event.id, id),
        'PWT-Report-${widget.event.id}.pdf',
      );
      if (mounted) {
        _snack(ok ? 'PDF download started.' : 'Could not download PDF.');
      }
    } catch (e) {
      if (mounted) _snack('Download failed: $e');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final id = await EventManagerRepository.ensureReport(widget.event.id);
      final url =
          await EventManagerRepository.shareReport(widget.event.id, id);
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) _snack('Shareable report link copied to clipboard.');
    } catch (e) {
      if (mounted) _snack('Could not share: $e');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _finalize() async {
    try {
      final id = await EventManagerRepository.ensureReport(widget.event.id);
      await EventManagerRepository.finalizeReport(widget.event.id, id);
      if (mounted) {
        _snack('Report finalised and locked.', color: _kGreen);
      }
    } catch (e) {
      if (mounted) _snack('Could not finalise: $e');
    }
  }

  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }
}

// ─── Cover Banner ─────────────────────────────────────────────────────────────

class _CoverBanner extends StatelessWidget {
  const _CoverBanner({
    required this.event,
    required this.report,
    required this.reportNo,
  });
  final NGOEvent event;
  final EventReport report;
  final String reportNo;

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
              // Report status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: event.status.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: event.status.color.withValues(alpha: 0.6)),
                ),
                child: Text(
                  event.status.label.toUpperCase(),
                  style: TextStyle(
                      color: event.status.color,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'OFFICIAL EVENT COMPLETION REPORT',
            style: TextStyle(
              color: _kGold,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            event.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _chip(Icons.tag_rounded, reportNo),
              const SizedBox(width: 8),
              _chip(Icons.calendar_today_rounded, _date(report.generatedAt)),
              const SizedBox(width: 8),
              _chip(Icons.category_rounded, event.category.label),
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

class _Section extends StatelessWidget {
  const _Section({
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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 20, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header — government doc style
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: const BoxDecoration(
              color: _kNavy,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kGold,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: _kNavy,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
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
          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─── 01 Executive Summary ─────────────────────────────────────────────────────

class _ExecutiveSummary extends StatelessWidget {
  const _ExecutiveSummary({
    required this.event,
    required this.report,
    required this.totalPeople,
    required this.totalDonation,
    required this.totalHours,
    required this.approvedCount,
    required this.certEligible,
  });
  final NGOEvent event;
  final EventReport report;
  final int totalPeople;
  final double totalDonation;
  final double totalHours;
  final int approvedCount;
  final int certEligible;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Key metrics row
        Row(
          children: [
            _BigStat(
                '${report.volunteersParticipated}', 'Volunteers', _kBlue,
                Icons.people_rounded),
            _BigStat(
                '$totalPeople', 'Beneficiaries', _kGreen,
                Icons.volunteer_activism_rounded),
            _BigStat(
                '₹${totalDonation.toStringAsFixed(0)}', 'Donations', _kAmber,
                Icons.payments_rounded),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _BigStat('${totalHours.toStringAsFixed(1)}h', 'Volunteer Hours',
                _kTeal, Icons.schedule_rounded),
            _BigStat('${event.activities.length}', 'Activities', _kBlue,
                Icons.assignment_rounded),
            _BigStat('$certEligible', 'Cert. Eligible', _kGreen,
                Icons.workspace_premium_rounded),
          ],
        ),
        const SizedBox(height: 14),
        // Event objective
        if (event.description.isNotEmpty) ...[
          _label('Event Objective'),
          const SizedBox(height: 4),
          Text(event.description,
              style: const TextStyle(
                  fontSize: 13, color: _kInk, height: 1.55)),
          const SizedBox(height: 12),
        ],
        // Key outcomes
        if (report.outcomes.isNotEmpty) ...[
          _label('Key Outcomes & Highlights'),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kGreen.withValues(alpha: 0.18)),
            ),
            child: Text(report.outcomes,
                style: const TextStyle(
                    fontSize: 13, color: _kInk, height: 1.55)),
          ),
        ],
        const SizedBox(height: 12),
        // Completion status
        _StatusRow('Overall Completion', event.status.label, event.status.color),
        _StatusRow('Total Activities Conducted',
            '${event.activities.length}', _kBlue),
        _StatusRow('Approved Volunteers', '$approvedCount', _kGreen),
      ],
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          fontSize: 11, color: _kMuted, fontWeight: FontWeight.w700,
          letterSpacing: 0.5));
}

class _BigStat extends StatelessWidget {
  const _BigStat(this.value, this.label, this.color, this.icon);
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 5),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: color)),
            Text(label,
                style: const TextStyle(fontSize: 9.5, color: _kMuted),
                textAlign: TextAlign.center),
          ],
        ),
      );
}

class _StatusRow extends StatelessWidget {
  const _StatusRow(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(fontSize: 12, color: _kInk))),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(value,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ),
          ],
        ),
      );
}

// ─── 02 Event Information ─────────────────────────────────────────────────────

class _EventInfo extends StatelessWidget {
  const _EventInfo({required this.event, required this.reportNo});
  final NGOEvent event;
  final String reportNo;

  String _date(DateTime d) {
    const m = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, IconData)>[
      ('Event Name', event.title, Icons.event_rounded),
      ('Category', event.category.label, Icons.category_rounded),
      ('Report Number', reportNo, Icons.tag_rounded),
      ('Event ID', 'EVT-${event.id.toString().padLeft(4, '0')}', Icons.confirmation_number_rounded),
      ('Venue / Location', event.location, Icons.location_on_rounded),
      ('Event Date', _date(event.date), Icons.calendar_today_rounded),
      if (event.partnerSchool != null)
        ('Partner School', event.partnerSchool!, Icons.school_rounded),
      ('Status', event.status.label, Icons.flag_rounded),
      ('Max Volunteers', '${event.maxVolunteers}', Icons.group_rounded),
      if (event.certificateEligible)
        ('Certificate Eligible', 'Yes', Icons.workspace_premium_rounded),
      if (event.donationEligible)
        ('Donation Drive', 'Yes', Icons.payments_rounded),
      if (event.stipendAmount != null)
        ('Stipend Amount', '₹${event.stipendAmount!.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded),
      if (event.expectedWork != null)
        ('Expected Work', event.expectedWork!, Icons.work_outline_rounded),
      if (event.proofRequired != null)
        ('Proof Required', event.proofRequired!, Icons.attach_file_rounded),
    ];

    return Column(
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          _InfoRow(
            icon: rows[i].$3,
            label: rows[i].$1,
            value: rows[i].$2,
          ),
          if (i < rows.length - 1)
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: _kMuted),
            const SizedBox(width: 10),
            SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 11.5, color: _kMuted, fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 12.5, color: _kInk,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

// ─── 03 Event Timeline ────────────────────────────────────────────────────────

class _EventTimeline extends StatelessWidget {
  const _EventTimeline({required this.event, required this.report});
  final NGOEvent event;
  final EventReport report;

  String _date(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Build timeline based on event status pipeline
    final stages = <(String, IconData, Color, String, bool)>[
      ('Event Planning', Icons.edit_rounded, _kBlue,
          _date(event.createdAt), true),
      ('Published & Approved', Icons.public_rounded, _kGreen,
          _date(event.date),
          event.status != EventStatus.draft),
      ('Volunteer Assignment', Icons.assignment_ind_rounded, _kAmber,
          _date(event.date),
          event.status != EventStatus.draft &&
              event.status != EventStatus.published),
      ('Activity Execution', Icons.play_circle_rounded, _kTeal,
          _date(event.date),
          event.status == EventStatus.ongoing ||
              event.status == EventStatus.completed ||
              event.status == EventStatus.archived),
      ('Work Submission', Icons.upload_file_rounded, const Color(0xFF6A1B9A),
          _date(event.date),
          event.status == EventStatus.completed ||
              event.status == EventStatus.archived),
      ('Certificates Generated', Icons.workspace_premium_rounded, _kGold,
          _date(report.generatedAt),
          event.status == EventStatus.completed ||
              event.status == EventStatus.archived),
      ('Event Closed', Icons.check_circle_rounded, _kGreen,
          _date(report.generatedAt),
          event.status == EventStatus.completed ||
              event.status == EventStatus.archived),
    ];

    return Column(
      children: [
        for (int i = 0; i < stages.length; i++)
          _TimelineRow(
            icon: stages[i].$2,
            color: stages[i].$3,
            label: stages[i].$1,
            date: stages[i].$4,
            done: stages[i].$5,
            isLast: i == stages.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.date,
    required this.done,
    required this.isLast,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String date;
  final bool done;
  final bool isLast;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 36,
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: done
                          ? color.withValues(alpha: 0.12)
                          : const Color(0xFFEEEEEE),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: done ? color : Colors.grey.shade300,
                          width: 2),
                    ),
                    child: Icon(icon,
                        size: 14, color: done ? color : Colors.grey.shade400),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: done ? color.withValues(alpha: 0.3) : Colors.grey.shade200,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18, top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: done ? _kInk : _kMuted)),
                    const SizedBox(height: 2),
                    Text(date,
                        style: const TextStyle(
                            fontSize: 11, color: _kMuted)),
                    if (done)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 12, color: _kGreen),
                            const SizedBox(width: 4),
                            Text('Completed',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: _kGreen,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

// ─── 04 Activity Details ──────────────────────────────────────────────────────

class _ActivityDetails extends StatelessWidget {
  const _ActivityDetails({required this.activities, required this.ea});
  final List<EventActivity> activities;
  final List<EMStudentAssignment> ea;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const _Empty('No activities recorded for this event.');
    }

    return Column(
      children: [
        for (int i = 0; i < activities.length; i++) ...[
          _ActivityCard(activity: activities[i], ea: ea, index: i + 1),
          if (i < activities.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ActivityCard extends StatefulWidget {
  const _ActivityCard({
    required this.activity,
    required this.ea,
    required this.index,
  });
  final EventActivity activity;
  final List<EMStudentAssignment> ea;
  final int index;

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final asgns = widget.ea
        .where((a) => a.activity.id == widget.activity.id)
        .toList();
    final approved = asgns
        .where((a) =>
            a.status == AssignmentStatus.approved ||
            a.status == AssignmentStatus.certificateEligible ||
            a.status == AssignmentStatus.verified)
        .length;
    final pct = widget.activity.maxStudents > 0
        ? (approved / widget.activity.maxStudents * 100).clamp(0, 100)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE8EEF6)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(10),
              bottom: _expanded ? Radius.zero : const Radius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _kNavy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text('${widget.index}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _kNavy)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.activity.title,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _kInk)),
                        Text(widget.activity.role.label,
                            style: const TextStyle(
                                fontSize: 10.5, color: _kMuted)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$approved/${widget.activity.maxStudents}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _kGreen)),
                      const Text('Approved',
                          style: TextStyle(fontSize: 9, color: _kMuted)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _kMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Progress bar
          LinearProgressIndicator(
            value: pct / 100,
            backgroundColor: _kGreen.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation(_kGreen),
            minHeight: 3,
          ),
          // Expanded detail
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.activity.description != null) ...[
                    Text(widget.activity.description!,
                        style: const TextStyle(
                            fontSize: 12, color: _kInk, height: 1.5)),
                    const SizedBox(height: 10),
                  ],
                  _infoGrid([
                    ('Total Slots', '${widget.activity.maxStudents}'),
                    ('Assigned', '${asgns.length}'),
                    ('Approved', '$approved'),
                    ('Completion', '${pct.toStringAsFixed(0)}%'),
                  ]),
                  if (asgns.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text('Volunteers',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _kMuted)),
                    const SizedBox(height: 6),
                    for (final a in asgns)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor:
                                  _kBlue.withValues(alpha: 0.12),
                              child: Text(a.student.initials,
                                  style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: _kBlue)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(a.student.name,
                                  style: const TextStyle(
                                      fontSize: 12, color: _kInk)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: a.status.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(a.status.label,
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: a.status.color,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoGrid(List<(String, String)> items) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map((i) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(i.$2,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _kInk)),
                      Text(i.$1,
                          style: const TextStyle(
                              fontSize: 9.5, color: _kMuted)),
                    ],
                  ),
                ))
            .toList(),
      );
}

// ─── 05 Volunteer Stats ───────────────────────────────────────────────────────

class _VolunteerStats extends StatelessWidget {
  const _VolunteerStats({
    required this.ea,
    required this.approved,
    required this.submitted,
    required this.rejected,
    required this.totalHours,
    required this.certEligible,
  });
  final List<EMStudentAssignment> ea;
  final List<EMStudentAssignment> approved;
  final List<EMStudentAssignment> submitted;
  final List<EMStudentAssignment> rejected;
  final double totalHours;
  final int certEligible;

  @override
  Widget build(BuildContext context) {
    final total = ea.length;
    final assigned =
        ea.where((a) => a.status == AssignmentStatus.assigned).length;

    return Column(
      children: [
        // Stats grid
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatChip('Total Assigned', '$total', _kBlue),
            _StatChip('Approved', '${approved.length}', _kGreen),
            _StatChip('Submitted', '${submitted.length}', _kAmber),
            _StatChip('Rejected', '${rejected.length}', _kRed),
            _StatChip('Cert. Eligible', '$certEligible', const Color(0xFF6A1B9A)),
            _StatChip('Total Hours', '${totalHours.toStringAsFixed(1)}h', _kTeal),
          ],
        ),
        const SizedBox(height: 14),
        // Attendance bar
        if (total > 0) ...[
          _label('Participation Breakdown'),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 16,
              child: Row(
                children: [
                  if (approved.isNotEmpty)
                    Flexible(
                      flex: approved.length,
                      child: Container(color: _kGreen),
                    ),
                  if (submitted.isNotEmpty)
                    Flexible(
                      flex: submitted.length,
                      child: Container(color: _kAmber),
                    ),
                  if (rejected.isNotEmpty)
                    Flexible(
                      flex: rejected.length,
                      child: Container(color: _kRed),
                    ),
                  if (assigned > 0)
                    Flexible(
                      flex: assigned,
                      child: Container(color: const Color(0xFFE0E0E0)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            children: [
              _Legend(_kGreen, 'Approved'),
              _Legend(_kAmber, 'Submitted'),
              _Legend(_kRed, 'Rejected'),
              _Legend(const Color(0xFFE0E0E0), 'Pending'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          fontSize: 11, color: _kMuted, fontWeight: FontWeight.w700));
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: _kMuted)),
          ],
        ),
      );
}

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
          Text(label,
              style: const TextStyle(fontSize: 10, color: _kMuted)),
        ],
      );
}

// ─── Volunteer Roster ─────────────────────────────────────────────────────────

class _VolunteerRoster extends StatelessWidget {
  const _VolunteerRoster({required this.ea});
  final List<EMStudentAssignment> ea;

  @override
  Widget build(BuildContext context) {
    if (ea.isEmpty) {
      return const _Empty('No volunteers assigned to this event.');
    }

    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _kNavy.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              SizedBox(
                  width: 120,
                  child: Text('NAME',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _kMuted,
                          letterSpacing: 0.5))),
              Expanded(
                child: Text('ACTIVITY',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _kMuted,
                        letterSpacing: 0.5)),
              ),
              Text('STATUS',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _kMuted,
                      letterSpacing: 0.5)),
            ],
          ),
        ),
        for (int i = 0; i < ea.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: _kBlue.withValues(alpha: 0.1),
                      child: Text(ea[i].student.initials,
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _kBlue)),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 86,
                      child: Text(ea[i].student.name,
                          style: const TextStyle(
                              fontSize: 11.5, color: _kInk),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                Expanded(
                  child: Text(ea[i].activity.title,
                      style: const TextStyle(
                          fontSize: 11, color: _kMuted),
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ea[i].status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(ea[i].status.label,
                      style: TextStyle(
                          fontSize: 9,
                          color: ea[i].status.color,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          if (i < ea.length - 1) const Divider(height: 1, color: Color(0xFFF5F5F5)),
        ],
      ],
    );
  }
}

// ─── 06 Proof Gallery ─────────────────────────────────────────────────────────

class _ProofGallery extends StatelessWidget {
  const _ProofGallery({required this.photos, required this.ea});
  final List<String> photos;
  final List<EMStudentAssignment> ea;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const _Empty(
          'No photos uploaded yet. Volunteers submit photo proof with their work.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${photos.length} photo(s) submitted as proof of work',
            style: const TextStyle(fontSize: 12, color: _kMuted)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: photos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (_, i) => ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              photos[i],
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: _kBg,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_rounded,
                        color: _kMuted, size: 30),
                    SizedBox(height: 4),
                    Text('Image unavailable',
                        style: TextStyle(fontSize: 10, color: _kMuted)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Submission List ──────────────────────────────────────────────────────────

class _SubmissionList extends StatelessWidget {
  const _SubmissionList({required this.ea});
  final List<EMStudentAssignment> ea;

  @override
  Widget build(BuildContext context) {
    final withSub = ea.where((a) => a.submission != null).toList();
    if (withSub.isEmpty) {
      return const _Empty('No work submissions recorded.');
    }

    return Column(
      children: [
        for (int i = 0; i < withSub.length; i++) ...[
          _SubmissionCard(a: withSub[i]),
          if (i < withSub.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({required this.a});
  final EMStudentAssignment a;

  String _date(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final sub = a.submission!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EEF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: _kBlue.withValues(alpha: 0.1),
                child: Text(a.student.initials,
                    style: const TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w700, color: _kBlue)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.student.name,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: _kInk)),
                    Text(a.activity.title,
                        style: const TextStyle(fontSize: 10.5, color: _kMuted)),
                  ],
                ),
              ),
              Text(_date(sub.submittedAt),
                  style: const TextStyle(fontSize: 10, color: _kMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(sub.workTitle,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700, color: _kInk)),
          const SizedBox(height: 4),
          Text(sub.description,
              style: const TextStyle(fontSize: 12, color: _kInk, height: 1.45),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              _infoTag(
                  Icons.schedule_rounded, '${sub.hoursWorked}h', _kTeal),
              _infoTag(Icons.people_rounded, '${sub.peopleReached} reached',
                  _kGreen),
              if (sub.donationCollected != null)
                _infoTag(Icons.payments_rounded,
                    '₹${sub.donationCollected!.toStringAsFixed(0)}', _kAmber),
              if (sub.photoUrls.isNotEmpty)
                _infoTag(Icons.photo_library_rounded,
                    '${sub.photoUrls.length} photos', _kBlue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTag(IconData icon, String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      );
}

// ─── 08 Beneficiary Information ───────────────────────────────────────────────

class _BeneficiaryInfo extends StatelessWidget {
  const _BeneficiaryInfo(
      {required this.totalPeople, required this.event});
  final int totalPeople;
  final NGOEvent event;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero stat
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Icon(Icons.volunteer_activism_rounded,
                  color: Colors.white70, size: 28),
              const SizedBox(height: 6),
              Text('$totalPeople',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900)),
              const Text('Total Beneficiaries Reached',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Distribution breakdown (illustrative based on available data)
        _infoRow('Partner School', event.partnerSchool ?? 'Community Event'),
        const Divider(height: 1),
        _infoRow('Location', event.location),
        const Divider(height: 1),
        _infoRow('Event Category', event.category.label),
        const Divider(height: 1),
        _infoRow('Target Audience', event.studentEligibility ?? 'Open to all'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _kAmber.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kAmber.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: _kAmber, size: 14),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Detailed demographic breakdown (gender, age, category) is collected at the venue by the registration team and included in the physical attendance sheet.',
                  style: TextStyle(fontSize: 11, color: _kAmber, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: _kMuted, fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 12.5, color: _kInk)),
            ),
          ],
        ),
      );
}

// ─── 09 Donation Report ───────────────────────────────────────────────────────

class _DonationReport extends StatelessWidget {
  const _DonationReport({required this.ea, required this.total});
  final List<EMStudentAssignment> ea;
  final double total;

  @override
  Widget build(BuildContext context) {
    final donors = ea
        .where((a) =>
            a.submission != null &&
            (a.submission!.donationCollected ?? 0) > 0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        Row(
          children: [
            _DonStat('Total Collected', '₹${total.toStringAsFixed(0)}',
                _kGreen),
            const SizedBox(width: 10),
            _DonStat('Contributors', '${donors.length}', _kBlue),
          ],
        ),
        const SizedBox(height: 14),
        if (donors.isEmpty)
          const _Empty('No donations were recorded for this event.')
        else ...[
          const Text('Donation Records',
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: _kMuted)),
          const SizedBox(height: 8),
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _kNavy.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('VOLUNTEER',
                        style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: _kMuted,
                            letterSpacing: 0.5))),
                Expanded(
                    flex: 2,
                    child: Text('ACTIVITY',
                        style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: _kMuted,
                            letterSpacing: 0.5))),
                Text('AMOUNT',
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: _kMuted,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
          for (int i = 0; i < donors.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(donors[i].student.name,
                        style: const TextStyle(fontSize: 11.5, color: _kInk),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(donors[i].activity.title,
                        style: const TextStyle(fontSize: 11, color: _kMuted),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text(
                    '₹${donors[i].submission!.donationCollected!.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _kGreen),
                  ),
                ],
              ),
            ),
            if (i < donors.length - 1)
              const Divider(height: 1, color: Color(0xFFF5F5F5)),
          ],
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  flex: 5,
                  child: Text('TOTAL',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _kInk)),
                ),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: _kGreen),
                ),
              ],
            ),
          ),
          if (donors.any((d) => d.submission!.transactionId != null)) ...[
            const SizedBox(height: 10),
            const Text('Transaction References',
                style: TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w700, color: _kMuted)),
            const SizedBox(height: 6),
            for (final d in donors.where(
                (d) => d.submission!.transactionId != null))
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        size: 12, color: _kMuted),
                    const SizedBox(width: 6),
                    Text('${d.student.name}: ',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600, color: _kInk)),
                    Text(d.submission!.transactionId!,
                        style: const TextStyle(fontSize: 11, color: _kMuted)),
                  ],
                ),
              ),
          ],
        ],
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

// ─── 12 Impact Analysis ───────────────────────────────────────────────────────

class _ImpactAnalysis extends StatelessWidget {
  const _ImpactAnalysis({
    required this.report,
    required this.event,
    required this.totalHours,
  });
  final EventReport report;
  final NGOEvent event;
  final double totalHours;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (report.summary.isNotEmpty) ...[
          _head('Event Summary', Icons.summarize_rounded, _kBlue),
          const SizedBox(height: 6),
          Text(report.summary,
              style: const TextStyle(
                  fontSize: 13, color: _kInk, height: 1.55)),
          const SizedBox(height: 14),
        ],
        if (report.outcomes.isNotEmpty) ...[
          _head('Outcomes & Impact', Icons.emoji_events_rounded, _kGreen),
          const SizedBox(height: 6),
          Text(report.outcomes,
              style: const TextStyle(
                  fontSize: 13, color: _kInk, height: 1.55)),
          const SizedBox(height: 14),
        ],
        _head('Social Impact Dimensions', Icons.bar_chart_rounded, _kTeal),
        const SizedBox(height: 8),
        _ImpactDimension('Educational Impact',
            'Knowledge shared through ${event.category.label} activities',
            Icons.school_rounded, _kBlue, 0.75),
        _ImpactDimension('Community Reach',
            '${report.peopleReached} beneficiaries directly served',
            Icons.people_rounded, _kGreen,
            (report.peopleReached / (report.peopleReached + 1)).clamp(0.3, 0.95)),
        if (event.donationEligible)
          _ImpactDimension('Financial Impact',
              'Donation drive conducted with ${report.totalDonationCollected.toStringAsFixed(0)} ₹ collected',
              Icons.payments_rounded, _kAmber, 0.65),
        _ImpactDimension('Volunteer Development',
            '${totalHours.toStringAsFixed(0)} hours of skilled community service',
            Icons.engineering_rounded, _kTeal, 0.80),
        const SizedBox(height: 12),
        if (event.partnerSchool != null) ...[
          _head('Institutional Partnership', Icons.handshake_rounded, _kAmber),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kAmber.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kAmber.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_rounded, color: _kAmber, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Partner School',
                          style: TextStyle(
                              fontSize: 10.5, color: _kMuted)),
                      Text(event.partnerSchool!,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _kInk)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _head(String t, IconData icon, Color c) => Row(
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 6),
          Text(t,
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700, color: c)),
        ],
      );
}

class _ImpactDimension extends StatelessWidget {
  const _ImpactDimension(
      this.title, this.description, this.icon, this.color, this.value);
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final double value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ),
                Text('${(value * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 3),
            Text(description,
                style: const TextStyle(fontSize: 10.5, color: _kMuted)),
          ],
        ),
      );
}

// ─── 13 Event Statistics ──────────────────────────────────────────────────────

class _EventStats extends StatelessWidget {
  const _EventStats({
    required this.ea,
    required this.activities,
    required this.totalHours,
    required this.totalDonation,
    required this.totalPeople,
  });
  final List<EMStudentAssignment> ea;
  final List<EventActivity> activities;
  final double totalHours;
  final double totalDonation;
  final int totalPeople;

  @override
  Widget build(BuildContext context) {
    final total = ea.length;
    final approved = ea
        .where((a) =>
            a.status == AssignmentStatus.approved ||
            a.status == AssignmentStatus.certificateEligible ||
            a.status == AssignmentStatus.verified)
        .length;
    final completionRate = total > 0 ? approved / total : 0.0;
    final activityFillRate = activities.isEmpty
        ? 0.0
        : activities.fold(0.0, (s, a) => s + a.assignedCount) /
            activities.fold(0.0, (s, a) => s + a.maxStudents);

    return Column(
      children: [
        _StatBar('Volunteer Completion Rate',
            '${(completionRate * 100).toStringAsFixed(0)}%',
            completionRate, _kGreen),
        const SizedBox(height: 10),
        _StatBar('Activity Fill Rate',
            '${(activityFillRate * 100).toStringAsFixed(0)}%',
            activityFillRate.clamp(0, 1), _kBlue),
        const SizedBox(height: 10),
        _StatBar('Beneficiary Coverage',
            '$totalPeople benefited',
            totalPeople > 0 ? 0.70 : 0.0,
            _kTeal),
        const SizedBox(height: 16),
        Row(
          children: [
            _NumberCard('Total Hours', '${totalHours.toStringAsFixed(1)}h',
                _kTeal),
            const SizedBox(width: 8),
            _NumberCard('Total Donation',
                '₹${totalDonation.toStringAsFixed(0)}', _kGreen),
            const SizedBox(width: 8),
            _NumberCard('Volunteers', '$total', _kBlue),
          ],
        ),
      ],
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar(this.label, this.valueLabel, this.value, this.color);
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
                    style: const TextStyle(fontSize: 12, color: _kInk)),
              ),
              Text(valueLabel,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      );
}

class _NumberCard extends StatelessWidget {
  const _NumberCard(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 16,
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

// ─── 14 Certificates ─────────────────────────────────────────────────────────

class _CertificatesSection extends StatelessWidget {
  const _CertificatesSection({
    required this.ea,
    required this.certEligible,
  });
  final List<EMStudentAssignment> ea;
  final int certEligible;

  @override
  Widget build(BuildContext context) {
    final eligible =
        ea.where((a) => a.status == AssignmentStatus.certificateEligible).toList();
    final total = ea.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _CertStat('Eligible', '$certEligible', _kGreen),
            const SizedBox(width: 10),
            _CertStat('Total Volunteers', '$total', _kBlue),
            const SizedBox(width: 10),
            _CertStat('Pending', '${total - certEligible}', _kAmber),
          ],
        ),
        const SizedBox(height: 14),
        if (eligible.isEmpty)
          const _Empty(
              'No volunteers have reached certificate-eligible status yet.')
        else ...[
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _kNavy.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('VOLUNTEER',
                        style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: _kMuted))),
                Expanded(
                    flex: 3,
                    child: Text('ACTIVITY',
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
          for (int i = 0; i < eligible.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded,
                            size: 13, color: _kGold),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(eligible[i].student.name,
                              style: const TextStyle(
                                  fontSize: 11.5, color: _kInk),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(eligible[i].activity.title,
                        style: const TextStyle(
                            fontSize: 11, color: _kMuted),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text('Eligible',
                        style: TextStyle(
                            fontSize: 9,
                            color: _kGreen,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            if (i < eligible.length - 1)
              const Divider(height: 1, color: Color(0xFFF5F5F5)),
          ],
        ],
      ],
    );
  }
}

class _CertStat extends StatelessWidget {
  const _CertStat(this.label, this.value, this.color);
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

// ─── 15 Compliance Checklist ──────────────────────────────────────────────────

class _ComplianceChecklist extends StatelessWidget {
  const _ComplianceChecklist({
    required this.event,
    required this.ea,
    required this.hasPhotos,
  });
  final NGOEvent event;
  final List<EMStudentAssignment> ea;
  final bool hasPhotos;

  @override
  Widget build(BuildContext context) {
    final approved = ea
        .where((a) =>
            a.status == AssignmentStatus.approved ||
            a.status == AssignmentStatus.certificateEligible ||
            a.status == AssignmentStatus.verified)
        .length;
    final hasSubmissions = ea.any((a) => a.submission != null);

    final checks = <(String, bool, String)>[
      ('Event Created & Approved', true, 'Event ID issued by admin'),
      ('Volunteers Assigned', ea.isNotEmpty,
          '${ea.length} volunteer(s) assigned'),
      ('Activities Conducted', event.activities.isNotEmpty,
          '${event.activities.length} activity/activities recorded'),
      ('Work Submissions Received', hasSubmissions,
          '${ea.where((a) => a.submission != null).length} submission(s)'),
      ('Photo Evidence Uploaded', hasPhotos,
          hasPhotos ? 'Photo proof available' : 'No photos yet'),
      ('Work Verified', approved > 0,
          '$approved volunteer(s) verified/approved'),
      ('Certificates Eligible', ea.any((a) =>
          a.status == AssignmentStatus.certificateEligible),
          'Certificate-eligible volunteers identified'),
      ('Report Generated', true, 'Official report created'),
    ];

    final done = checks.where((c) => c.$2).length;
    final total = checks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: done / total,
                  minHeight: 14,
                  backgroundColor: _kGreen.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(_kGreen),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('$done/$total',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _kGreen)),
          ],
        ),
        const SizedBox(height: 4),
        Text('$done of $total compliance items met',
            style: const TextStyle(fontSize: 11, color: _kMuted)),
        const SizedBox(height: 14),
        for (final check in checks) _CheckRow(check.$1, check.$2, check.$3),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow(this.label, this.done, this.note);
  final String label;
  final bool done;
  final String note;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
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

// ─── 16 Approval Section ─────────────────────────────────────────────────────

class _ApprovalSection extends StatelessWidget {
  const _ApprovalSection({required this.report, required this.reportNo});
  final EventReport report;
  final String reportNo;

  String _date(DateTime d) {
    const m = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final ngo = NGOProfile.fallback;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Document meta
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _metaRow('Report Number', reportNo),
              _metaRow('Generated On', _date(report.generatedAt)),
              _metaRow('Report ID', 'RPTID-${report.id}'),
              _metaRow('Organization', ngo.name),
              _metaRow('Regt. No.', ngo.registrationNumber ?? '736'),
              _metaRow('Contact', ngo.phone ?? '9211772333'),
              _metaRow('Email', ngo.email ?? 'Punjabiwelfaretrust99@gmail.com'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Signature block
        Row(
          children: [
            _SigBlock(
              title: 'Prepared By',
              name: report.studentContributors.isNotEmpty
                  ? report.studentContributors.first
                  : 'Event Manager',
              role: 'Event Manager',
            ),
            const SizedBox(width: 10),
            const _SigBlock(
              title: 'Approved By',
              name: '—',
              role: 'Admin / Coordinator',
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Legal footer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kNavy.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kNavy.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_rounded,
                      color: _kGreen, size: 14),
                  const SizedBox(width: 6),
                  const Text('NGO VERIFIED OFFICIAL REPORT',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: _kGreen,
                          letterSpacing: 0.5)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'This is an official report generated by ${ngo.name}. '
                'Report ID $reportNo. '
                'For verification contact ${ngo.phone ?? '9211772333'} '
                'or ${ngo.email ?? 'Punjabiwelfaretrust99@gmail.com'}.',
                style: const TextStyle(
                    fontSize: 10.5, color: _kMuted, height: 1.45),
              ),
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
            SizedBox(
              width: 110,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: _kMuted)),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 10,
                      color: _kMuted,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              // Signature line
              Container(
                  width: 80,
                  height: 1,
                  color: const Color(0xFFCCCCCC)),
              const SizedBox(height: 6),
              Text(name,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: _kInk),
                  textAlign: TextAlign.center),
              Text(role,
                  style: const TextStyle(fontSize: 10, color: _kMuted),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

// ─── Bottom Bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.onDownload,
    required this.onShare,
    required this.onFinalize,
    required this.downloading,
    required this.sharing,
  });
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onFinalize;
  final bool downloading;
  final bool sharing;

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
          // Share
          Expanded(
            child: OutlinedButton.icon(
              onPressed: sharing ? null : onShare,
              icon: sharing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.share_rounded, size: 16),
              label: const Text('Share Link'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: _kBlue),
                foregroundColor: _kBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Download PDF
          Expanded(
            child: FilledButton.icon(
              onPressed: downloading ? null : onDownload,
              icon: downloading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf_rounded, size: 16),
              label:
                  Text(downloading ? 'Downloading…' : 'Download PDF'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: _kNavy,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Finalize
          IconButton.filled(
            onPressed: onFinalize,
            icon: const Icon(Icons.verified_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: _kGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
            tooltip: 'Finalise Report',
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  const _Empty(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const Icon(Icons.inbox_rounded, color: Color(0xFFCCCCCC), size: 36),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: _kMuted)),
          ],
        ),
      );
}
