import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/api_models.dart';
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
import '../event_manager/counsellor_requests_screen.dart';
import '../events/admin/event_manager_screen.dart';
import '../learn/admin/create_free_course_screen.dart';
import 'admin_manage_view.dart';
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
          await Future.wait([admin.load(), events.load(), _loadModuleData()]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          children: [
            _header(admin),
            const SizedBox(height: 16),
            _criticalAlerts(admin, events),
            const SizedBox(height: 18),
            _overview(admin),
            const SizedBox(height: 20),
            _quickActions(),
            const SizedBox(height: 22),
            _pendingApprovals(admin),
            const SizedBox(height: 22),
            _volunteerReview(events),
            const SizedBox(height: 22),
            _eventsOverview(events),
            const SizedBox(height: 22),
            _schoolRequests(),
            const SizedBox(height: 22),
            _donationSummary(),
            const SizedBox(height: 22),
            _certificateCenter(),
            const SizedBox(height: 22),
            _impactApproval(events),
            const SizedBox(height: 22),
            _courseReview(),
            const SizedBox(height: 22),
            _reportsAnalytics(admin, events),
            const SizedBox(height: 22),
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
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assests/ngo_logo.jpeg',
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.volunteer_activism_rounded,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning, $name 👋',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    AppState.role.displayName == 'Super Admin'
                        ? 'Super Admin Dashboard'
                        : 'Admin Dashboard',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Manage the complete NGO platform',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Badge(
              isLabelVisible: vm.unreadCount > 0,
              label: Text('${vm.unreadCount}'),
              child: IconButton.filledTonal(
                onPressed: () => _showNotifications(vm),
                icon: const Icon(Icons.notifications_outlined),
              ),
            ),
            const SizedBox(width: 6),
            CircleAvatar(
              backgroundColor: const Color(0xFFE8E1FF),
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF6A1B9A),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 16),
              SizedBox(width: 5),
              Text(
                'Full Platform Access • Verified NGO Admin',
                style: TextStyle(
                  color: Color(0xFF1B5E20),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
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
    final school = CounsellorViewModel.shared.pendingRequests.length;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7F1D1D), Color(0xFFB91C1C)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFFFD54F)),
              SizedBox(width: 7),
              Text(
                'Critical Alerts / Pending Actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _alert('${admin.pendingCount} users'),
              _alert('${events.pendingSubmissions.length} work reviews'),
              _alert('$pendingDonations donations'),
              _alert('$pendingCertificates certificates'),
              _alert('${events.draftPosts.length} impact posts'),
              _alert('$school school requests'),
            ],
          ),
          const SizedBox(height: 13),
          FilledButton.icon(
            onPressed: () => _push(PendingApprovalsScreen(vm: widget.adminVm)),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF991B1B),
            ),
            icon: const Icon(Icons.fact_check_rounded),
            label: const Text('Review Pending Tasks'),
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
        const SizedBox(height: 10),
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
            const SizedBox(width: 9),
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
        const SizedBox(height: 9),
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
            const SizedBox(width: 9),
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
        () => _push(const EventManagerScreen()),
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
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
          childAspectRatio: 2.25,
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
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(13),
    decoration: _cardDecoration(),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              child: Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase()),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${_roleLabel(user.requestedRole ?? user.currentRole)} • ${user.location ?? 'Location not set'}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _push(
                UserApprovalDetailScreen(userId: user.id, vm: widget.adminVm),
              ),
              child: const Text('View'),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => widget.adminVm.rejectUser(user.id),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () => widget.adminVm.assignRole(
                  userId: user.id,
                  role: user.requestedRole ?? user.currentRole,
                ),
                child: const Text('Approve'),
              ),
            ),
          ],
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
          onAction: () => _push(const EventManagerScreen()),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final item in [
              ('Active', active),
              ('Upcoming', upcoming),
              ('Draft', draft),
              ('Completed', complete),
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _smallMetric(item.$1, '${item.$2}'),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _schoolRequests() {
    final requests = CounsellorViewModel.shared.requests.take(2).toList();
    return _previewSection(
      'School Counselling Requests',
      Icons.school_rounded,
      requests.isEmpty
          ? [_empty('No school requests found.', Icons.school_outlined)]
          : requests
                .map(
                  (r) => _previewCard(
                    r.schoolName,
                    '${r.topic} • ${r.studentCount} students',
                    'Review Request',
                    () => _push(const CounsellorRequestsScreen()),
                    badge: r.status.label,
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
    final published = _courses.where((c) => c.isPublished).length;
    final drafts = _courses.where((c) => !c.isPublished).length;
    return _centerSummary(
      'Learning Course Review',
      Icons.menu_book_rounded,
      [
        ('Published', '$published'),
        ('Drafts', '$drafts'),
        (
          'Total Learners',
          '${widget.adminVm.stats.roleCounts['student'] ?? 0}',
        ),
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
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            _reportRow(
              'Monthly NGO Impact Report',
              '${events.events.length} events • ${events.publishedPosts.length} posts',
            ),
            const Divider(),
            _reportRow(
              'Volunteer Performance Report',
              '${admin.stats.activeUsers} active users',
            ),
            const Divider(),
            _reportRow(
              'School Partnership Report',
              '${CounsellorViewModel.shared.requests.length} counselling requests',
            ),
            const Divider(),
            _reportRow(
              'Course Learning Report',
              '${_courses.length} free courses',
            ),
          ],
        ),
      ),
    ],
  );

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
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              if (items.isEmpty)
                const Text(
                  'No recent activity.',
                  style: TextStyle(color: AppColors.muted),
                )
              else
                for (var i = 0; i < items.length; i++) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.secondary,
                        size: 18,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          items[i],
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Text(
                        'Now',
                        style: TextStyle(color: AppColors.muted, fontSize: 9),
                      ),
                    ],
                  ),
                  if (i != items.length - 1) const Divider(height: 18),
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
      CounsellorViewModel.shared.pendingRequests.length;

  Widget _alert(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
  Widget _stat(String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: .16)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      );
  Widget _actionCard(_Action a) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: a.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: a.color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(a.icon, color: a.color, size: 20),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                a.label,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
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
      Icon(icon, color: AppColors.primary, size: 20),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action)),
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
      const SizedBox(height: 10),
      ...children,
    ],
  );
  Widget _previewCard(
    String title,
    String subtitle,
    String action,
    VoidCallback onTap, {
    String? badge,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(13),
    decoration: _cardDecoration(),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
              if (badge != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
        TextButton(onPressed: onTap, child: Text(action)),
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
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
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
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  trust,
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: onTap, child: Text(action)),
            ),
          ],
        ),
      ),
    ],
  );
  Widget _smallMetric(String label, String value) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 3),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.muted, fontSize: 8),
        ),
      ],
    ),
  );
  Widget _reportRow(String title, String subtitle) => Row(
    children: [
      const Icon(Icons.description_outlined, color: AppColors.primary),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.muted, fontSize: 9),
            ),
          ],
        ),
      ),
      TextButton(
        onPressed: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$title generated.'))),
        child: const Text('Generate'),
      ),
    ],
  );
  Widget _empty(String text, IconData icon) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(17),
    decoration: _cardDecoration(),
    child: Row(
      children: [
        Icon(icon, color: AppColors.secondary),
        const SizedBox(width: 9),
        Text(text, style: const TextStyle(color: AppColors.muted)),
      ],
    ),
  );
  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: AppColors.muted.withValues(alpha: .12)),
  );
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
