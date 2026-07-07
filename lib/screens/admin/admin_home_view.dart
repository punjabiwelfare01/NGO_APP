import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/api_models.dart';
import '../../models/counsellor_session_models.dart';
import '../../models/certificate_models.dart';
import '../../models/course.dart';
import '../../models/donation_models.dart';
import '../../models/event_manager_models.dart';
import '../../repositories/certificate_repository.dart';
import '../../repositories/course_repository.dart';
import '../../repositories/donation_repository.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/counsellor_viewmodel.dart';
import '../../viewmodels/event_manager_viewmodel.dart';
import '../../viewmodels/events_viewmodel.dart';
import '../event_manager/counsellor_requests_screen.dart';
import '../events/events_dashboard_screen.dart';
import '../learn/admin/create_free_course_screen.dart';
import 'admin_design_system.dart';
import 'admin_manage_view.dart';
import 'admin_org_report_screen.dart';
import 'counsellor_admin_screen.dart';
import 'pending_approvals_screen.dart';
import 'user_approval_detail_screen.dart';
import 'volunteer_admin_screen.dart';

class AdminHomeView extends StatefulWidget {
  const AdminHomeView({
    required this.adminVm,
    required this.eventVm,
    required this.onOpenTab,
    super.key,
  });
  final AdminViewModel adminVm;
  final EventManagerViewModel eventVm;
  final ValueChanged<int> onOpenTab;
  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  List<Donation> _donations = [];
  List<Certificate> _certificates = [];
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadModuleData();
  }

  Future<void> _loadModuleData() async {
    // Load school counsellor requests for admin in parallel (non-fatal).
    CounsellorViewModel.shared.loadAllAdminRequests();
    try {
      final result = await Future.wait([
        DonationRepository.getAllDonations(),
        CertificateRepository.getAllCertificates(),
        CourseRepository.getCourses(),
      ]);
      if (!mounted) return;
      setState(() {
        _donations = result[0] as List<Donation>;
        _certificates = result[1] as List<Certificate>;
        _courses = result[2] as List<Course>;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      widget.adminVm,
      widget.eventVm,
      CounsellorViewModel.shared,
    ]),
    builder: (_, _) {
      final admin = widget.adminVm;
      final events = widget.eventVm;
      return RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            admin.load(),
            events.load(),
            _loadModuleData(),
            CounsellorViewModel.shared.loadAllAdminRequests(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            _header(admin),
            const SizedBox(height: AdminSpacing.xl),
            _criticalAlerts(admin, events),
            const SizedBox(height: AdminSpacing.xl),
            _overview(admin),
            const SizedBox(height: AdminSpacing.xl),
            _quickActions(),
            const SizedBox(height: AdminSpacing.xl),
            _pendingApprovals(admin),
            const SizedBox(height: AdminSpacing.xl),
            _volunteerReview(events),
            const SizedBox(height: AdminSpacing.xl),
            _eventsOverview(events),
            const SizedBox(height: AdminSpacing.xl),
            _schoolRequests(),
            const SizedBox(height: AdminSpacing.xl),
            _donationSummary(),
            const SizedBox(height: AdminSpacing.xl),
            _certificateCenter(),
            const SizedBox(height: AdminSpacing.xl),
            _impactApproval(events),
            const SizedBox(height: AdminSpacing.xl),
            _courseReview(),
            const SizedBox(height: AdminSpacing.xl),
            _reportsAnalytics(admin, events),
            const SizedBox(height: AdminSpacing.xl),
            _recentActivity(admin, events),
          ],
        ),
      );
    },
  );

  Widget _header(AdminViewModel vm) {
    final name = (AppState.studentName ?? 'Admin').split(' ').first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assests/ngo_logo.jpeg',
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.volunteer_activism_rounded,
                  color: AppColors.primary,
                  size: 44,
                ),
              ),
            ),
            const SizedBox(width: AdminSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning, $name 👋',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AdminText.pageTitle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppState.role.displayName == 'Super Admin'
                        ? 'Super Admin Dashboard'
                        : 'Admin Dashboard',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Manage the complete NGO platform',
                    style: AdminText.secondary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AdminSpacing.md),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(AdminSpacing.chipRadius),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 18),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Full Platform Access • Verified NGO Admin',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF1B5E20),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AdminSpacing.sm),
            SizedBox(
              width: AdminSpacing.minTouch,
              height: AdminSpacing.minTouch,
              child: Badge(
                isLabelVisible: vm.unreadCount > 0,
                label: Text('${vm.unreadCount}'),
                child: IconButton.filledTonal(
                  onPressed: () => _showNotifications(vm),
                  icon: const Icon(Icons.notifications_outlined, size: 24),
                ),
              ),
            ),
            const SizedBox(width: AdminSpacing.xs),
            SizedBox(
              width: AdminSpacing.minTouch,
              height: AdminSpacing.minTouch,
              child: CircleAvatar(
                backgroundColor: const Color(0xFFE8E1FF),
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF6A1B9A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _criticalAlerts(AdminViewModel admin, EventManagerViewModel events) {
    final pendingDonations = _donations
        .where((d) => d.status == DonationStatus.pending)
        .length;
    final pendingCertificates = _certificates
        .where((c) => c.status == CertificateStatus.pending)
        .length;
    final school = CounsellorViewModel.shared.allAdminRequests
        .where((r) => r.status == SchoolRequestStatus.newRequest)
        .length;
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7F1D1D), Color(0xFFB91C1C)],
        ),
        borderRadius: BorderRadius.circular(AdminSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFFFD54F), size: 24),
              SizedBox(width: AdminSpacing.xs),
              Expanded(
                child: Text(
                  'Critical Alerts / Pending Actions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.md),
          Wrap(
            spacing: AdminSpacing.xs,
            runSpacing: AdminSpacing.xs,
            children: [
              _alert('${admin.pendingCount} users'),
              _alert('${events.pendingSubmissions.length} work reviews'),
              _alert('$pendingDonations donations'),
              _alert('$pendingCertificates certificates'),
              _alert('${events.draftPosts.length} impact posts'),
              _alert('$school school requests'),
            ],
          ),
          const SizedBox(height: AdminSpacing.md),
          AdminPrimaryButton(
            label: 'Review Pending Tasks',
            icon: Icons.fact_check_rounded,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF991B1B),
            onPressed: () => _push(PendingApprovalsScreen(vm: widget.adminVm)),
          ),
        ],
      ),
    );
  }

  Widget _overview(AdminViewModel vm) {
    final volunteers = vm.stats.roleCounts['student'] ?? vm.stats.activeUsers;
    final donations = _donations
        .where(
          (d) =>
              d.status == DonationStatus.verified ||
              d.status == DonationStatus.approved,
        )
        .fold<double>(0, (sum, d) => sum + d.amount);
    final issued = _certificates
        .where((c) => c.status == CertificateStatus.issued)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Platform Overview', Icons.analytics_rounded),
        const SizedBox(height: AdminSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _stat(
                'Volunteers',
                '$volunteers',
                Icons.people_rounded,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: AdminSpacing.sm),
            Expanded(
              child: _stat(
                'Pending Tasks',
                '${_pendingTaskCount()}',
                Icons.pending_actions_rounded,
                AppColors.softRed,
              ),
            ),
          ],
        ),
        const SizedBox(height: AdminSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _stat(
                'Donations',
                _money(donations),
                Icons.payments_rounded,
                AppColors.secondary,
              ),
            ),
            const SizedBox(width: AdminSpacing.sm),
            Expanded(
              child: _stat(
                'Certificates',
                '$issued',
                Icons.workspace_premium_rounded,
                const Color(0xFF6A1B9A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickActions() {
    final actions = [
      _Action(
        Icons.person_add_alt_1_rounded,
        'Approve Users',
        AppColors.primary,
        () => _push(PendingApprovalsScreen(vm: widget.adminVm)),
      ),
      _Action(
        Icons.manage_accounts_rounded,
        'Manage Roles',
        const Color(0xFF6A1B9A),
        () => widget.onOpenTab(1),
      ),
      _Action(
        Icons.event_rounded,
        'Create Event',
        const Color(0xFF1565C0),
        () => _push(EventsDashboardScreen(vm: EventsViewModel(isAdmin: true)..load())),
      ),
      _Action(
        Icons.rate_review_rounded,
        'Review Work',
        const Color(0xFFE65100),
        () => _push(const VolunteerAdminScreen()),
      ),
      _Action(
        Icons.verified_rounded,
        'Verify Donations',
        const Color(0xFFF57F17),
        () => _push(const AdminFinanceCenter(initialTab: 0)),
      ),
      _Action(
        Icons.workspace_premium_rounded,
        'Approve Certificates',
        const Color(0xFF4527A0),
        () => _push(const AdminFinanceCenter(initialTab: 1)),
      ),
      _Action(
        Icons.auto_awesome_rounded,
        'Publish Impact',
        const Color(0xFF880E4F),
        () => widget.onOpenTab(3),
      ),
      _Action(
        Icons.verified_user_rounded,
        'Manage Counsellors',
        const Color(0xFF00695C),
        () => _push(const CounsellorAdminScreen()),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Admin Quick Actions', Icons.bolt_rounded),
        const SizedBox(height: AdminSpacing.sm),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AdminSpacing.sm,
          mainAxisSpacing: AdminSpacing.sm,
          childAspectRatio: 1.55,
          children: actions.map((a) => _actionCard(a)).toList(),
        ),
      ],
    );
  }

  Widget _pendingApprovals(AdminViewModel vm) {
    final users = vm.pendingUsers.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Pending User Approvals',
          Icons.person_add_rounded,
          action: 'View all',
          onAction: () => _push(PendingApprovalsScreen(vm: widget.adminVm)),
        ),
        const SizedBox(height: 10),
        if (users.isEmpty)
          _empty('No pending registrations.', Icons.verified_user_rounded)
        else
          for (final user in users) _pendingUser(user),
      ],
    );
  }

  Widget _pendingUser(PendingUserItem user) => Container(
    margin: const EdgeInsets.only(bottom: AdminSpacing.sm),
    padding: const EdgeInsets.all(AdminSpacing.md),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              child: Text(
                user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: AdminSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AdminText.cardTitle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _roleLabel(user.requestedRole ?? user.currentRole),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AdminText.secondary,
                  ),
                  Text(
                    user.location ?? 'Location not set',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AdminText.secondary,
                  ),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AdminText.secondary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AdminSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AdminSecondaryButton(
                label: 'View',
                onPressed: () => _push(
                  UserApprovalDetailScreen(userId: user.id, vm: widget.adminVm),
                ),
              ),
            ),
            const SizedBox(width: AdminSpacing.xs),
            Expanded(
              child: AdminSecondaryButton(
                label: 'Reject',
                foregroundColor: AppColors.softRed,
                onPressed: () => widget.adminVm.rejectUser(user.id),
              ),
            ),
          ],
        ),
        const SizedBox(height: AdminSpacing.xs),
        AdminPrimaryButton(
          label: 'Approve',
          onPressed: () => widget.adminVm.assignRole(
            userId: user.id,
            role: user.requestedRole ?? user.currentRole,
          ),
        ),
      ],
    ),
  );

  Widget _volunteerReview(EventManagerViewModel vm) {
    final work = vm.pendingSubmissions.take(2).toList();
    return _previewSection(
      'Volunteer Work Review',
      Icons.fact_check_rounded,
      work.isEmpty
          ? [
              _empty(
                'No student work awaiting final review.',
                Icons.task_alt_rounded,
              ),
            ]
          : work.map((a) {
              final sub = a.submission!;
              return _previewCard(
                a.student.name,
                '${a.event.title} • ${sub.hoursWorked} hrs • ${sub.peopleReached} reached',
                'Final Approve',
                () => _push(const VolunteerAdminScreen()),
                badge: 'Manager Verified',
              );
            }).toList(),
      action: () => _push(const VolunteerAdminScreen()),
    );
  }

  Widget _eventsOverview(EventManagerViewModel vm) {
    final active = vm.activeEvents.length;
    final upcoming = vm.events
        .where((e) => e.date.isAfter(DateTime.now()))
        .length;
    final draft = vm.events.where((e) => e.status == EventStatus.draft).length;
    final complete = vm.events
        .where((e) => e.status == EventStatus.completed)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Events & Activities Overview',
          Icons.event_note_rounded,
          action: 'Manage',
          onAction: () => _push(EventsDashboardScreen(vm: EventsViewModel(isAdmin: true)..load())),
        ),
        const SizedBox(height: AdminSpacing.sm),
        Row(
          children: [
            Expanded(child: _metricTile('Active', '$active')),
            const SizedBox(width: AdminSpacing.sm),
            Expanded(child: _metricTile('Upcoming', '$upcoming')),
          ],
        ),
        const SizedBox(height: AdminSpacing.sm),
        Row(
          children: [
            Expanded(child: _metricTile('Draft', '$draft')),
            const SizedBox(width: AdminSpacing.sm),
            Expanded(child: _metricTile('Completed', '$complete')),
          ],
        ),
      ],
    );
  }

  Widget _schoolRequests() {
    final requests = CounsellorViewModel.shared.allAdminRequests.take(2).toList();
    return _previewSection(
      'School Counselling Requests',
      Icons.school_rounded,
      requests.isEmpty
          ? [_empty('No school requests found.', Icons.school_outlined)]
          : requests
                .map(
                  (r) => _previewCard(
                    r.schoolName,
                    '${r.topic} • ${r.expectedStudents} students',
                    'Review Request',
                    () => _push(const CounsellorRequestsScreen()),
                    badge: r.status.label,
                    badgeColor: r.status.color,
                  ),
                )
                .toList(),
      action: () => _push(const CounsellorRequestsScreen()),
    );
  }

  Widget _donationSummary() {
    final pending = _donations
        .where((d) => d.status == DonationStatus.pending)
        .length;
    final verified = _donations
        .where(
          (d) =>
              d.status == DonationStatus.verified ||
              d.status == DonationStatus.approved,
        )
        .length;
    return _centerSummary(
      'Donations & Stipends',
      Icons.payments_rounded,
      [
        ('Total', '${_donations.length}'),
        ('Pending Proof', '$pending'),
        ('Verified', '$verified'),
      ],
      'Review Donations',
      () => _push(const AdminFinanceCenter(initialTab: 0)),
      trust: 'Only official NGO account/UPI payments are permitted.',
    );
  }

  Widget _certificateCenter() {
    final pending = _certificates
        .where((c) => c.status == CertificateStatus.pending)
        .length;
    final issued = _certificates
        .where((c) => c.status == CertificateStatus.issued)
        .length;
    return _centerSummary(
      'Certificate Approval Center',
      Icons.workspace_premium_rounded,
      [
        ('Pending', '$pending'),
        ('Generated', '${_certificates.length}'),
        ('Issued', '$issued'),
      ],
      'Review Certificates',
      () => _push(const AdminFinanceCenter(initialTab: 1)),
    );
  }

  Widget _impactApproval(EventManagerViewModel vm) => _centerSummary(
    'Wall of Impact Approval',
    Icons.auto_awesome_rounded,
    [
      ('Drafts', '${vm.draftPosts.where((p) => !p.isPublished).length}'),
      ('Pending', '${vm.draftPosts.where((p) => p.isPublished).length}'),
      ('Published', '${vm.publishedPosts.length}'),
    ],
    'Review Posts',
    () => widget.onOpenTab(3),
  );

  Widget _courseReview() {
    final stats = widget.adminVm.stats;
    return _centerSummary(
      'Learning Course Review',
      Icons.menu_book_rounded,
      [
        ('Published', '${stats.publishedCourses}'),
        ('Drafts', '${stats.draftCourses}'),
        ('Total Learners', '${stats.totalCourseLearners}'),
      ],
      'Create Free Course',
      () => _push(const CreateFreeCourseScreen()),
    );
  }

  Widget _reportsAnalytics(
    AdminViewModel admin,
    EventManagerViewModel events,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle('Reports & Analytics', Icons.analytics_rounded),
      const SizedBox(height: AdminSpacing.sm),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.md, vertical: 4),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            _reportRow(
              'Monthly NGO Impact Report',
              '${events.events.length} events • ${events.publishedPosts.length} posts',
              onTap: () => _openOrgReport(admin, events),
            ),
            const Divider(),
            _reportRow(
              'Volunteer Performance Report',
              '${admin.stats.activeUsers} active users',
              onTap: () => _openOrgReport(admin, events),
            ),
            const Divider(),
            _reportRow(
              'School Partnership Report',
              '${CounsellorViewModel.shared.allAdminRequests.length} counselling requests',
              onTap: () => _openOrgReport(admin, events),
            ),
            const Divider(),
            _reportRow(
              'Course Learning Report',
              '${_courses.length} free courses',
              onTap: () => _openOrgReport(admin, events),
            ),
          ],
        ),
      ),
    ],
  );

  void _openOrgReport(AdminViewModel admin, EventManagerViewModel em) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminOrgReportScreen(admin: admin, em: em),
      ),
    );
  }

  Widget _recentActivity(AdminViewModel admin, EventManagerViewModel events) {
    final items = [
      ...admin.notifications.take(2).map((n) => n.message),
      if (events.pendingSubmissions.isNotEmpty)
        '${events.pendingSubmissions.first.student.name} submitted volunteer work',
      if (events.draftPosts.isNotEmpty)
        'Impact post “${events.draftPosts.first.title}” awaits approval',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Recent Admin Activity', Icons.history_rounded),
        const SizedBox(height: AdminSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AdminSpacing.md),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              if (items.isEmpty)
                const Text('No recent activity.', style: AdminText.secondary)
              else
                for (var i = 0; i < items.length; i++) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.secondary,
                        size: 22,
                      ),
                      const SizedBox(width: AdminSpacing.xs),
                      Expanded(
                        child: Text(
                          items[i],
                          style: AdminText.body,
                        ),
                      ),
                      const SizedBox(width: AdminSpacing.xs),
                      const Text('Now', style: AdminText.secondary),
                    ],
                  ),
                  if (i != items.length - 1) const Divider(height: AdminSpacing.lg),
                ],
            ],
          ),
        ),
      ],
    );
  }

  int _pendingTaskCount() =>
      widget.adminVm.pendingCount +
      widget.eventVm.pendingSubmissions.length +
      _donations.where((d) => d.status == DonationStatus.pending).length +
      _certificates.where((c) => c.status == CertificateStatus.pending).length +
      widget.eventVm.draftPosts.length +
      CounsellorViewModel.shared.allAdminRequests
          .where((r) => r.status == SchoolRequestStatus.newRequest)
          .length;

  Widget _alert(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(AdminSpacing.chipRadius),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
  Widget _stat(String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(AdminSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AdminSpacing.cardRadius),
          border: Border.all(color: color.withValues(alpha: .18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AdminSpacing.sm),
            Expanded(
              child: AdminStatBlock(label: label, value: value, valueColor: color),
            ),
          ],
        ),
      );
  Widget _actionCard(_Action a) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AdminSpacing.cardRadius),
    child: InkWell(
      onTap: a.onTap,
      borderRadius: BorderRadius.circular(AdminSpacing.cardRadius),
      child: Container(
        constraints: const BoxConstraints(minHeight: AdminSpacing.minTouch),
        padding: const EdgeInsets.all(AdminSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AdminSpacing.cardRadius),
          border: Border.all(color: AppColors.muted.withValues(alpha: .12)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: a.color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(a.icon, color: a.color, size: 24),
            ),
            const SizedBox(width: AdminSpacing.sm),
            Expanded(
              child: Text(
                a.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _sectionTitle(
    String title,
    IconData icon, {
    String? action,
    VoidCallback? onAction,
  }) => Row(
    children: [
      Icon(icon, color: AppColors.primary, size: 24),
      const SizedBox(width: AdminSpacing.xs),
      Expanded(
        child: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AdminText.sectionTitle,
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, AdminSpacing.minTouch),
            padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.xs),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(action, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 2),
              const Icon(Icons.arrow_forward_rounded, size: 16),
            ],
          ),
        ),
    ],
  );
  Widget _previewSection(
    String title,
    IconData icon,
    List<Widget> children, {
    VoidCallback? action,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle(title, icon, action: 'View all', onAction: action),
      const SizedBox(height: AdminSpacing.sm),
      ...children,
    ],
  );
  Widget _previewCard(
    String title,
    String subtitle,
    String action,
    VoidCallback onTap, {
    String? badge,
    Color? badgeColor,
  }) => Container(
    margin: const EdgeInsets.only(bottom: AdminSpacing.sm),
    padding: const EdgeInsets.all(AdminSpacing.md),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AdminText.cardTitle,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AdminText.secondary,
        ),
        if (badge != null) ...[
          const SizedBox(height: AdminSpacing.xs),
          AdminStatusBadge(label: badge, color: badgeColor),
        ],
        const SizedBox(height: AdminSpacing.sm),
        AdminSecondaryButton(label: action, onPressed: onTap),
      ],
    ),
  );
  Widget _centerSummary(
    String title,
    IconData icon,
    List<(String, String)> metrics,
    String action,
    VoidCallback onTap, {
    String? trust,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle(title, icon),
      const SizedBox(height: AdminSpacing.sm),
      Container(
        padding: const EdgeInsets.all(AdminSpacing.md),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Row(
              children: [
                for (final m in metrics)
                  Expanded(child: _smallMetric(m.$1, m.$2)),
              ],
            ),
            if (trust != null)
              Padding(
                padding: const EdgeInsets.only(top: AdminSpacing.sm),
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: Color(0xFF2E7D32), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        trust,
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AdminSpacing.md),
            AdminSecondaryButton(label: action, onPressed: onTap),
          ],
        ),
      ),
    ],
  );
  /// Compact centered stat used inside a 3-across row (e.g. center-summary
  /// cards). The value auto-shrinks via FittedBox so it can never overflow
  /// its column regardless of digit count, and the label wraps to 2 lines
  /// rather than clipping.
  Widget _smallMetric(String label, String value) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
    ),
  );

  /// Bordered metric card used for the 2x2 events-overview grid — same
  /// visual weight as [_stat] but without a leading icon.
  Widget _metricTile(String label, String value) => Container(
    padding: const EdgeInsets.all(AdminSpacing.md),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AdminSpacing.cardRadius),
      border: Border.all(color: AppColors.muted.withValues(alpha: .14)),
    ),
    child: AdminStatBlock(label: label, value: value),
  );
  Widget _reportRow(String title, String subtitle, {VoidCallback? onTap}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AdminSpacing.sm),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: AdminSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AdminText.bodyStrong.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AdminText.secondary,
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, AdminSpacing.minTouch),
          ),
          child: const Text('Generate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
  Widget _empty(String text, IconData icon) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AdminSpacing.md),
    decoration: _cardDecoration(),
    child: Row(
      children: [
        Icon(icon, color: AppColors.secondary, size: 24),
        const SizedBox(width: AdminSpacing.sm),
        Expanded(child: Text(text, style: AdminText.body)),
      ],
    ),
  );
  BoxDecoration _cardDecoration() => adminCardDecoration();
  String _money(double value) => value >= 100000
      ? '₹${(value / 100000).toStringAsFixed(1)}L'
      : value >= 1000
      ? '₹${(value / 1000).toStringAsFixed(1)}K'
      : '₹${value.toStringAsFixed(0)}';
  String _roleLabel(String role) => switch (role) {
    'student' => 'Student Volunteer',
    'event_manager' => 'Event Manager',
    'mentor' => 'Mentor / Counsellor',
    'content_creator' => 'Content Creator',
    'school_partner' => 'School Partner',
    'admin' => 'Admin',
    _ => role,
  };
  Future<void> _push(Widget screen) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    await widget.adminVm.load();
  }

  void _showNotifications(AdminViewModel vm) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Admin Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          for (final n in vm.notifications.take(10))
            ListTile(
              leading: Icon(
                n.isRead
                    ? Icons.notifications_none
                    : Icons.notifications_active,
                color: n.isRead ? AppColors.muted : AppColors.primary,
              ),
              title: Text(n.title),
              subtitle: Text(n.message),
              onTap: () => vm.markNotificationRead(n.id),
            ),
        ],
      ),
    ),
  );
}

class _Action {
  const _Action(this.icon, this.label, this.color, this.onTap);
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}
