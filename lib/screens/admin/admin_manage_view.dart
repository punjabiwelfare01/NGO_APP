import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/certificate_models.dart';
import '../../models/donation_models.dart';
import '../../repositories/certificate_repository.dart';
import '../../repositories/donation_repository.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/event_manager_viewmodel.dart';
import '../../viewmodels/events_viewmodel.dart';
import '../event_manager/counsellor_requests_screen.dart';
import '../events/events_dashboard_screen.dart';
import '../helping_support/admin/emergency_contacts_admin_screen.dart';
import '../home/admin/safety_awareness_manager_screen.dart';
import '../learn/management/learning_management_view.dart';
import '../../features/certificates/presentation/screens/admin_certificate_approval_screen.dart';
import 'admin_activities_screen.dart';
import 'counsellor_admin_screen.dart';
import 'pending_approvals_screen.dart';
import 'volunteer_admin_screen.dart';

class AdminManageView extends StatelessWidget {
  const AdminManageView({
    required this.adminVm,
    required this.eventVm,
    super.key,
  });
  final AdminViewModel adminVm;
  final EventManagerViewModel eventVm;

  @override
  Widget build(BuildContext context) {
    final tools = <_ManageTool>[
      _ManageTool(
        Icons.assignment_rounded,
        'Activity Management',
        'View, track and manage all activities across Event Managers',
        const Color(0xFF0277BD),
        const AdminActivitiesScreen(),
      ),
      _ManageTool(
        Icons.event_rounded,
        'Events',
        'Create, assign, review and publish — everything in one place',
        const Color(0xFF1565C0),
        EventsDashboardScreen(vm: EventsViewModel.shared(isAdmin: true)..load()),
      ),
      _ManageTool(
        Icons.menu_book_rounded,
        'Free Courses',
        'Courses, subjects, chapters and lessons',
        const Color(0xFF2E7D32),
        const _LearningAdminPage(),
      ),
      _ManageTool(
        Icons.verified_user_rounded,
        'Counsellors',
        'Verification, visibility and availability',
        const Color(0xFF00695C),
        const CounsellorAdminScreen(),
      ),
      _ManageTool(
        Icons.school_rounded,
        'School Requests',
        'Assignments, sessions and reports',
        const Color(0xFF4527A0),
        const CounsellorRequestsScreen(),
      ),
      _ManageTool(
        Icons.volunteer_activism_rounded,
        'Volunteer Work',
        'Review proof, hours and impact',
        const Color(0xFFE65100),
        const VolunteerAdminScreen(),
      ),
      _ManageTool(
        Icons.payments_rounded,
        'Donations & Stipends',
        'Proof, official payment details and reports',
        const Color(0xFFF57F17),
        const AdminFinanceCenter(initialTab: 0),
      ),
      _ManageTool(
        Icons.workspace_premium_rounded,
        'Certificates',
        'Generate, approve, issue and verify',
        const Color(0xFF6A1B9A),
        const AdminCertificateApprovalScreen(),
      ),
      _ManageTool(
        Icons.pending_actions_rounded,
        'Pending Approvals',
        '${adminVm.pendingCount} registrations waiting',
        AppColors.softRed,
        PendingApprovalsScreen(vm: adminVm),
      ),
      _ManageTool(
        Icons.shield_rounded,
        'Safety Content',
        'Awareness questions and moderation',
        const Color(0xFF00838F),
        const SafetyAwarenessManagerScreen(),
      ),
      _ManageTool(
        Icons.contact_phone_rounded,
        'Emergency Contacts',
        'Verified helplines and support',
        AppColors.ink,
        const EmergencyContactsAdminScreen(),
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        const Text(
          'Manage Platform',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 27,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Full operational control across every NGO module.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _manageMetric(
                'Active Events',
                '${eventVm.activeEvents.length}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _manageMetric('Pending Users', '${adminVm.pendingCount}'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _manageMetric(
                'Impact Drafts',
                '${eventVm.draftPosts.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (_, constraints) {
            final columns = constraints.maxWidth >= 850
                ? 3
                : constraints.maxWidth >= 540
                ? 2
                : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tools.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 11,
                mainAxisSpacing: 11,
                childAspectRatio: columns == 1 ? 3.4 : 2.3,
              ),
              itemBuilder: (_, i) => _ManageCard(tool: tools[i]),
            );
          },
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.security_rounded, color: Color(0xFF2E7D32)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sensitive identity, banking, certificate-signature and verification documents remain restricted to authorised administrators.',
                  style: TextStyle(
                    color: Color(0xFF1B5E20),
                    fontSize: 11,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _manageMetric(String label, String value) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          style: const TextStyle(color: AppColors.muted, fontSize: 9),
        ),
      ],
    ),
  );
}

class _ManageTool {
  const _ManageTool(
    this.icon,
    this.title,
    this.subtitle,
    this.color,
    this.screen,
  );
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget screen;
}

class _ManageCard extends StatelessWidget {
  const _ManageCard({required this.tool});
  final _ManageTool tool;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => tool.screen)),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tool.color.withValues(alpha: .17)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: tool.color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(tool.icon, color: tool.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool.title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tool.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    ),
  );
}

class _LearningAdminPage extends StatelessWidget {
  const _LearningAdminPage();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: SafeArea(child: LearningManagementView()));
}

class AdminFinanceCenter extends StatefulWidget {
  const AdminFinanceCenter({required this.initialTab, super.key});
  final int initialTab;
  @override
  State<AdminFinanceCenter> createState() => _AdminFinanceCenterState();
}

class _AdminFinanceCenterState extends State<AdminFinanceCenter>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Donation> _donations = [];
  List<Certificate> _certificates = [];
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final result = await Future.wait([
        DonationRepository.getAllDonations(),
        CertificateRepository.getAllCertificates(),
      ]);
      if (mounted) {
        setState(() {
          _donations = result[0] as List<Donation>;
          _certificates = result[1] as List<Certificate>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Finance & Certificates'),
      bottom: TabBar(
        controller: _tabs,
        tabs: const [
          Tab(text: 'Donations & Stipends'),
          Tab(text: 'Certificates'),
        ],
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabs,
            children: [
              _DonationAdminList(donations: _donations),
              _CertificateAdminList(certificates: _certificates),
            ],
          ),
  );
}

class _DonationAdminList extends StatelessWidget {
  const _DonationAdminList({required this.donations});
  final List<Donation> donations;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Donations must go only to the official NGO bank/UPI. Personal-account collection is prohibited.',
          style: TextStyle(
            color: Color(0xFF795548),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (donations.isEmpty)
        const Center(child: Text('No donation records found.'))
      else
        for (final d in donations)
          Card(
            child: ListTile(
              leading: const Icon(Icons.payments_rounded),
              title: Text(d.donorName ?? 'Anonymous Donor'),
              subtitle: Text(
                'Logged by ${d.referredByName ?? 'Unknown'} • ${d.status.displayName} • ${d.purpose ?? d.category ?? 'NGO Support'}',
              ),
              trailing: Text(
                '₹${d.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
    ],
  );
}

class _CertificateAdminList extends StatelessWidget {
  const _CertificateAdminList({required this.certificates});
  final List<Certificate> certificates;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      if (certificates.isEmpty)
        const Center(child: Text('No certificate records found.'))
      else
        for (final c in certificates)
          Card(
            child: ListTile(
              leading: Icon(
                c.isVerified
                    ? Icons.verified_rounded
                    : Icons.workspace_premium_outlined,
                color: c.isVerified ? AppColors.secondary : AppColors.accent,
              ),
              title: Text(c.activityName),
              subtitle: Text(
                '${c.studentName ?? 'Unknown Student'} • ${c.certificateId} • ${c.status.displayName}',
              ),
              trailing: Text(c.isVerified ? 'Verified' : 'Review'),
            ),
          ),
    ],
  );
}

