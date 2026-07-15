import 'dart:async';

import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/course.dart';
import '../../models/event_models.dart';
import '../../models/impact_post.dart';
import '../../models/skill_category.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/view_state.dart';
import '../../models/volunteer_models.dart';
import '../../viewmodels/volunteer_viewmodel.dart';
import '../../repositories/impact_repository.dart';
import '../../utils/navigation_helper.dart';
import '../../widgets/achievement_certificates_section.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scroll_view.dart';
import '../../widgets/donation_impact_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/top_header.dart';
import '../volunteer/work_submission_screen.dart';
import '../volunteer/daily_log_screen.dart';
import '../volunteer/donation_screen.dart';
import '../volunteer/my_certificates_screen.dart';
import '../volunteer/activity_list_screen.dart';
import '../admin/pending_approvals_screen.dart';
import '../admin/user_management_screen.dart';
import '../../viewmodels/events_viewmodel.dart';
import '../events/events_dashboard_screen.dart';
import '../admin/volunteer_admin_screen.dart';
import '../admin/counsellor_admin_screen.dart';
import '../school_portal/school_partner_portal_screen.dart';
import '../internship/wall_of_impact_view.dart';
import '../helping_support/admin/emergency_contacts_admin_screen.dart';
import '../events/event_detail_pipeline_screen.dart';
import '../helping_support/student/all_slots_screen.dart';
import '../home/admin/safety_awareness_manager_screen.dart';
import '../profile/profile_notifications_screen.dart';
import '../../models/event_pipeline_models.dart';
import '../../models/ngo_profile.dart';
import '../../repositories/ngo_repository.dart';
import '../../viewmodels/event_pipeline_viewmodel.dart';
import 'widgets/counselling_session_card.dart';
import 'widgets/daily_challenge_card.dart';
import 'widgets/daily_motivation_card.dart';
import 'widgets/skill_category_card.dart';
import 'widgets/upcoming_counselling_banner.dart';
import 'widgets/welcome_banner.dart';

class HomeView extends StatefulWidget {
  const HomeView({this.onOpenLearn, super.key});

  final ValueChanged<SkillCategory?>? onOpenLearn;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  late final HomeViewModel _vm;
  AdminViewModel? _adminVm;
  VolunteerViewModel? _volunteerVm;
  EventPipelineViewModel? _pipelineVm;
  late final TextEditingController _skillSearchCtrl;
  Timer? _notificationTimer;
  bool _bannerShown = false;
  bool _eventBannerShown = false;
  OverlayEntry? _eventNotificationEntry;
  String _skillQuery = '';
  NGOProfile _ngo = NGOProfile.fallback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _vm = HomeViewModel.shared;
    _skillSearchCtrl = TextEditingController();
    _vm.addListener(_onVmChanged);
    _vm.load();
    // Check every minute if a session is about to start
    _notificationTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkSessionNotification(),
    );
    // Admins get a live notification + pending-approval count
    if (AppState.role.isAdmin) {
      _adminVm = AdminViewModel.shared;
      _adminVm!.load();
    }
    // Students (NGO volunteers) get live impact stats + assignment data
    if (AppState.role.isStudent) {
      _volunteerVm = VolunteerViewModel.shared..load();
      _volunteerVm!.addListener(_onVolunteerVmChanged);
      _pipelineVm = EventPipelineViewModel.shared..load();
      _pipelineVm!.addListener(_onVolunteerVmChanged);
      _loadNgo();
    }
  }

  Future<void> _loadNgo() async {
    final ngo = await NGORepository.getProfile();
    if (mounted) setState(() => _ngo = ngo);
  }

  void _onVolunteerVmChanged() => setState(() {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _vm.load(force: true);
      _adminVm?.load(force: true);
      _volunteerVm?.load(force: true);
      _pipelineVm?.load();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationTimer?.cancel();
    _eventNotificationEntry?.remove();
    _eventNotificationEntry = null;
    _skillSearchCtrl.dispose();
    _vm.removeListener(_onVmChanged);
    _volunteerVm?.removeListener(_onVolunteerVmChanged);
    _pipelineVm?.removeListener(_onVolunteerVmChanged);
    super.dispose();
  }

  void _onVmChanged() {
    if (_vm.state == ViewState.idle) {
      _checkSessionNotification();
      _checkEventNotification();
    }
  }

  void _checkSessionNotification() {
    if (!mounted) return;
    final session = _vm.upcomingSession;
    if (session == null) return;

    final diffMin = session.scheduledAt.difference(DateTime.now()).inMinutes;
    if (diffMin >= 0 && diffMin <= 15 && !_bannerShown) {
      _bannerShown = true;
      final hasLink = session.hasMeetingLink;
      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
          leading: const Icon(
            Icons.notifications_active_rounded,
            color: AppColors.secondary,
          ),
          content: Text(
            diffMin == 0
                ? 'Your session with ${session.counsellorName} is starting now!'
                : 'Your session with ${session.counsellorName} starts in $diffMin min.',
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            if (hasLink)
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: session.meetingUrl!));
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Join link copied to clipboard!'),
                    ),
                  );
                },
                child: const Text('Copy Link'),
              ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                _bannerShown = false;
              },
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
    }
  }

  void _checkEventNotification() {
    if (!mounted || _eventBannerShown || _vm.upcomingEvents.isEmpty) return;
    final event = _vm.upcomingEvents.firstWhere(
      (item) => item.canRegister || item.status == EventStatus.live,
      orElse: () => _vm.upcomingEvents.first,
    );
    _eventBannerShown = true;
    final endText = _formatDate(event.registrationEnd);
    final label = event.status == EventStatus.live ? 'Join' : 'Register';

    void dismiss() {
      _eventNotificationEntry?.remove();
      _eventNotificationEntry = null;
    }

    _eventNotificationEntry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        top: MediaQuery.of(overlayContext).padding.top + 12,
        left: 16,
        right: 16,
        child: _EventNotificationToast(
          event: event,
          endText: endText,
          label: label,
          onRegister: () {
            dismiss();
            openEvent(context, event, onRefresh: () => _vm.load(force: true));
          },
          onDismiss: dismiss,
        ),
      ),
    );

    Overlay.of(context).insert(_eventNotificationEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        if (_vm.state == ViewState.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_vm.state == ViewState.error) {
          return _ErrorView(
            message: _vm.errorMessage!,
            actionLabel: AppState.isAuthenticated ? 'Retry' : 'Sign In',
            onRetry: AppState.isAuthenticated
                ? _vm.load
                : () => Navigator.of(context).pushReplacementNamed('/login'),
          );
        }
        final visibleSkills = _filteredSkillCategories(_vm.categories);
        final firstName =
            (_vm.studentProfile?.name ?? AppState.studentName ?? 'Student')
                .split(' ')
                .first;
        return AppScrollView(
          children: [
            if (AppState.role.isStudent)
              _NGOBrandHeader(ngo: _ngo)
            else
            ListenableBuilder(
              listenable: _adminVm ?? _vm,
              builder: (_, _) {
                final adminBadge = _adminVm == null
                    ? null
                    : (_adminVm!.unreadCount + _adminVm!.pendingCount);
                return TopHeader(
                  title: 'Hi $firstName',
                  subtitle: AppState.role.isAdmin
                      ? 'Platform overview & management'
                      : 'Ready to learn, play, and grow today?',
                  actionIcon: Icons.notifications_none_rounded,
                  actionTooltip: AppState.role.isAdmin
                      ? 'Notifications'
                      : 'Open action',
                  badgeCount: adminBadge == 0 ? null : adminBadge,
                  onActionTap: AppState.role.isAdmin
                      ? () => _openAdminNotifications()
                      : null,
                );
              },
            ),

            // ── Admin: analytics + management tools ───────────────────
            if (AppState.role.isAdmin && _adminVm != null)
              ListenableBuilder(
                listenable: _adminVm!,
                builder: (_, _) => _AdminAnalyticsSection(
                  vm: _adminVm!,
                  onViewPending: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PendingApprovalsScreen(),
                    ),
                  ),
                  onOpenUsers: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserManagementScreen(vm: _adminVm!),
                    ),
                  ),
                  onOpenEvents: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          EventsDashboardScreen(vm: EventsViewModel.shared(isAdmin: true)..load()),
                    ),
                  ),
                  onOpenCounselling: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CounsellorAdminScreen(),
                    ),
                  ),
                  onOpenSafety: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SafetyAwarenessManagerScreen(),
                    ),
                  ),
                  onOpenEmergency: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EmergencyContactsAdminScreen(),
                    ),
                  ),
                  onOpenVolunteer: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const VolunteerAdminScreen(),
                    ),
                  ),
                ),
              ),

            // ── Personalised welcome card ──────────────────────────
            WelcomeBanner(student: _vm.studentProfile),

            // ── Upcoming events (staff/admin only — NGO volunteers use Work tab) ──
            if (!AppState.role.isStudent)
              UpcomingEventsPanel(
                events: _vm.upcomingEvents,
                onEventTap: (event) =>
                    openEvent(context, event, onRefresh: () => _vm.load(force: true)),
              ),

            // ── Next counselling session (non-student roles only) ──────────────────
            if (!AppState.role.isStudent)
              UpcomingCounsellingBanner(
                upcomingEvent: _vm.upcomingCounsellingEvent,
                liveSession: _vm.upcomingSession,
                onEventTap: () => _openCounsellingBooking(context),
                onJoinTap: () => _openCounsellingSession(context),
              ),

            const DailyMotivationCard(),

            // ── Continue Learning (non-student roles only) ─────────
            if (!AppState.role.isStudent) ...[
              const SectionHeader(title: 'Continue Learning'),
              _ContinueLearningCard(
                course: _vm.continueLearningCourse,
                onTap: () => widget.onOpenLearn?.call(null),
              ),
            ],

            // ── Skill development & counselling (non-student roles only) ──────────
            if (!AppState.role.isStudent) ...[
              SectionHeader(
                title: 'Skill Development',
                action: 'View all',
                onTap: () => widget.onOpenLearn?.call(null),
              ),
              TextField(
                controller: _skillSearchCtrl,
                onChanged: (value) =>
                    setState(() => _skillQuery = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search skills...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _skillQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _skillSearchCtrl.clear();
                            setState(() => _skillQuery = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Clear search',
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (visibleSkills.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        color: AppColors.muted.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'No skill found.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _skillSearchCtrl.clear();
                          setState(() => _skillQuery = '');
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 128,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: visibleSkills.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => SkillCategoryCard(
                      item: visibleSkills[i],
                      onTap: () => widget.onOpenLearn?.call(visibleSkills[i]),
                    ),
                  ),
                ),
              CounsellingSessionCard(
                upcomingSessions: _vm.allUpcomingSessions,
                availableSlots: _vm.availableSlots,
                onViewAll: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AllSlotsScreen()),
                ),
                onBook: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AllSlotsScreen()),
                ),
              ),
            ],

            // ── Daily Challenge (non-student roles only) ───────────
            if (!AppState.role.isStudent) ...[
              const SectionHeader(title: 'School Partner Services'),
              const _SchoolPartnerPortalCard(),
              SectionHeader(
                title: 'Daily Challenge',
                action: _vm.dailyChallenge == null ? null : 'Start',
                onTap: _vm.dailyChallenge == null
                    ? null
                    : () => _openDailyChallenge(context),
              ),
              DailyChallengeCard(
                challenge: _vm.dailyChallenge,
                onTap: _vm.dailyChallenge == null
                    ? null
                    : () => _openDailyChallenge(context),
              ),
            ],

            // ── Student NGO volunteer sections ──────────────────────
            if (AppState.role.isStudent) ...[
              _NGOImpactSummaryRow(stats: _volunteerVm?.stats),
              const SectionHeader(title: 'My Assignments'),
              _NGOAssignmentsSection(
                assignments: _volunteerVm?.assignments
                    .where((a) => !['completed', 'certificate_generated', 'admin_approved', 'rejected'].contains(a.status))
                    .toList() ?? const [],
                vm: _volunteerVm,
                isLoading: _volunteerVm?.state == VolunteerLoadState.loading,
              ),
              const SectionHeader(title: 'Open Activities'),
              _NGOOpenActivitiesCard(
                activities: _volunteerVm?.activities
                    .where((a) => a.applicationStatus == null && a.assignmentId == null)
                    .toList() ?? const [],
                vm: _volunteerVm,
                isLoading: _volunteerVm?.state == VolunteerLoadState.loading,
              ),
              if (_pipelineVm != null &&
                  _ActivePipelineEventCard.hasActive(_pipelineVm!)) ...[
                const SectionHeader(title: 'Active Event'),
                _ActivePipelineEventCard(vm: _pipelineVm!),
              ],
              const _ServiceOfHumanityBanner(),
              const SectionHeader(title: 'Quick Actions'),
              const _NGOQuickActionsGrid(),
              const SectionHeader(title: 'Wall of Impact'),
              const _WallOfImpactPreviewCard(),
              const AchievementCertificatesSection(),
            ],

            // ── Donation call-to-action ─────────────────────────────
            const SectionHeader(title: 'Support Our Cause'),
            const DonationImpactCard(),

            // ── Emergency Help shortcut ────────────────────────────
            const SectionHeader(title: 'Emergency Help'),
            const _EmergencyHelpCard(),
          ],
        );
      },
    );
  }

  void _openDailyChallenge(BuildContext context) {
    final challenge = _vm.dailyChallenge;
    if (challenge == null) return;
    if (challenge.id != null) {
      Navigator.of(context).pushNamed('/daily-challenge/${challenge.id}');
      return;
    }
    final quizId = challenge.quizId ?? challenge.quiz?.id;
    if (quizId != null) {
      Navigator.of(context).pushNamed('/quiz/$quizId');
    }
  }

  List<SkillCategory> _filteredSkillCategories(List<SkillCategory> categories) {
    final query = _skillQuery.toLowerCase();
    if (query.isEmpty) return categories;
    return categories
        .where((category) => category.title.toLowerCase().contains(query))
        .toList();
  }

  void _openAdminNotifications() {
    if (_adminVm == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdminNotificationsSheet(adminVm: _adminVm!),
    );
  }

  void _openCounsellingBooking(BuildContext context) {
    final event = _vm.upcomingCounsellingEvent;
    if (event != null) {
      openEvent(context, event, onRefresh: () => _vm.load(force: true));
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AllSlotsScreen()));
  }

  void _openCounsellingSession(BuildContext context) {
    final event = _vm.upcomingCounsellingEvent;
    if (event != null) {
      openEvent(context, event, onRefresh: () => _vm.load(force: true));
      return;
    }
    final session = _vm.upcomingSession;
    if (session?.hasMeetingLink == true) {
      Clipboard.setData(ClipboardData(text: session!.meetingUrl!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join link copied to clipboard!')),
      );
      return;
    }
    final message = session == null
        ? 'No counselling session is ready to join yet.'
        : 'Your counselling session is scheduled for ${session.formattedTime}.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return 'Date not set';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NGO Student Home — Brand header (logo, name, registration, tagline)
// ─────────────────────────────────────────────────────────────────────────────

class _NGOBrandHeader extends StatelessWidget {
  const _NGOBrandHeader({required this.ngo});
  final NGOProfile ngo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(
              child: Image.asset(
                'assests/ngo_logo.jpeg',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ngo.name,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Regd. No. ${ngo.registrationNumber ?? '736'}, Delhi Cantt',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileNotificationsScreen(),
                ),
              ),
              icon: const Icon(Icons.notifications_none_rounded),
              tooltip: 'Notifications',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Divider(height: 1, color: AppColors.muted.withValues(alpha: 0.25)),
        const SizedBox(height: 10),
        const Text(
          'Together we serve, together we grow. Building a better tomorrow.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NGO Student Home — "In Service of Humanity" banner
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceOfHumanityBanner extends StatelessWidget {
  const _ServiceOfHumanityBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE0B2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups_rounded, color: Color(0xFFEF6C00)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'In Service of Humanity',
                  style: TextStyle(
                    color: Color(0xFFEF6C00),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your time. Their future. Our responsibility.',
                  style: TextStyle(
                    color: Color(0xFFBF6D00),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.favorite_border_rounded, color: Color(0xFFEF6C00), size: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NGO Student Home — Impact Summary Row
// ─────────────────────────────────────────────────────────────────────────────

class _NGOImpactSummaryRow extends StatelessWidget {
  const _NGOImpactSummaryRow({this.stats});

  final VolunteerStats? stats;

  static String _formatDonation(double amount) {
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final hrs = stats == null ? '--' : stats!.totalHours.toStringAsFixed(0);
    final acts = stats == null ? '--' : stats!.activitiesCompleted.toString();
    final don = stats == null ? '--' : _formatDonation(stats!.donationRaised);
    final certs = stats == null ? '--' : stats!.certificatesEarned.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Your Impact'),
        Row(
          children: [
            _ImpactCard(
              icon: Icons.timer_rounded,
              value: hrs,
              unit: 'hrs',
              label: 'Hours\nServed',
              color: const Color(0xFF1565C0),
            ),
            const SizedBox(width: 10),
            _ImpactCard(
              icon: Icons.task_alt_rounded,
              value: acts,
              label: 'Activities\nDone',
              color: const Color(0xFF1A6B3A),
            ),
            const SizedBox(width: 10),
            _ImpactCard(
              icon: Icons.currency_rupee_rounded,
              value: don,
              label: 'Donation\nRaised',
              color: const Color(0xFFFF8C00),
            ),
            const SizedBox(width: 10),
            _ImpactCard(
              icon: Icons.workspace_premium_rounded,
              value: certs,
              label: 'Certificates\nEarned',
              color: const Color(0xFF8B5CF6),
            ),
          ],
        ),
      ],
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.unit,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active NGO Assignment Card
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveNGOActivityCard extends StatelessWidget {
  const _ActiveNGOActivityCard({this.assignment, this.vm});

  final ActivityAssignment? assignment;
  final VolunteerViewModel? vm;

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = dt.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Due Today';
    if (diff == 1) return 'Due Tomorrow';
    if (diff < 0) return 'Overdue';
    return 'Due in $diff days';
  }

  @override
  Widget build(BuildContext context) {
    if (assignment == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF0FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFCFDEFF)),
        ),
        child: const Row(
          children: [
            Icon(Icons.assignment_outlined, color: Color(0xFF6B8FD6), size: 28),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No active assignment',
                    style: TextStyle(
                      color: Color(0xFF1A3A7A),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Check the Work tab to browse and apply for NGO activities.',
                    style: TextStyle(
                      color: Color(0xFF4A6099),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final title = assignment!.activity?.title ?? 'NGO Assignment';
    final category =
        assignment!.activity?.category.name ?? 'Punjabi Welfare Trust';
    final location = assignment!.location ?? '';
    final dueLabel = _formatDate(assignment!.scheduledDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Color(0xFF69FF8A), size: 8),
                    SizedBox(width: 5),
                    Text(
                      'Assigned',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (dueLabel.isNotEmpty)
                Text(
                  dueLabel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Punjabi Welfare Trust  •  ${_toTitleCase(category)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (location.isNotEmpty) ...[
                const Icon(
                  Icons.location_on_outlined,
                  color: Colors.white60,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WorkSubmissionScreen(
                      vm: vm ?? (VolunteerViewModel.shared..load()),
                      assignment: assignment,
                    ),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0D47A1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                child: const Text('Submit Work'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _toTitleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─────────────────────────────────────────────────────────────────────────────
// All Assignments Section (replaces single-assignment card)
// ─────────────────────────────────────────────────────────────────────────────

class _NGOAssignmentsSection extends StatelessWidget {
  const _NGOAssignmentsSection({
    required this.assignments,
    required this.vm,
    required this.isLoading,
  });
  final List<ActivityAssignment> assignments;
  final VolunteerViewModel? vm;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFF0D47A1).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (assignments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF0FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFCFDEFF)),
        ),
        child: Row(
          children: [
            Image.asset(
              'assests/home_screenstudent2.png',
              width: 56,
              height: 56,
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No active assignments',
                    style: TextStyle(
                      color: Color(0xFF1A3A7A),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Browse open activities below and apply to participate.',
                    style: TextStyle(
                      color: Color(0xFF4A6099),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final a in assignments)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ActiveNGOActivityCard(assignment: a, vm: vm),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Open Activities Card — shows activities students can apply for
// ─────────────────────────────────────────────────────────────────────────────

class _NGOOpenActivitiesCard extends StatelessWidget {
  const _NGOOpenActivitiesCard({
    required this.activities,
    required this.vm,
    required this.isLoading,
  });
  final List<VolunteerActivity> activities;
  final VolunteerViewModel? vm;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Activities Open for Participation',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (vm != null)
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ActivityListScreen(vm: vm!),
                    ),
                  ),
                  child: const Text('View All'),
                ),
            ],
          ),
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'No open activities at the moment.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            )
          else ...[
            const SizedBox(height: 4),
            for (final a in activities.take(3))
              _OpenActivityRow(
                activity: a,
                onApply: vm == null
                    ? null
                    : () {
                        vm!.applyForActivity(a.id).then((ok) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'Applied for "${a.title}"!'
                                    : 'Failed to apply. Please try again.'),
                              ),
                            );
                          }
                        });
                      },
              ),
          ],
        ],
      ),
    );
  }
}

class _OpenActivityRow extends StatelessWidget {
  const _OpenActivityRow({required this.activity, this.onApply});
  final VolunteerActivity activity;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.volunteer_activism_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '${activity.rewardHours}h reward  •  ${activity.category.displayName}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onApply,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 12),
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NGO Quick Actions Grid
// ─────────────────────────────────────────────────────────────────────────────

class _SchoolPartnerPortalCard extends StatelessWidget {
  const _SchoolPartnerPortalCard();

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SchoolPartnerPortalScreen()),
      ),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF1565C0).withValues(alpha: .18),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: .1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Color(0xFF1565C0),
                size: 27,
              ),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Verified Counsellor Panel',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      SizedBox(width: 5),
                      Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF2E7D32),
                        size: 17,
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'School partners can review trusted profiles and request a counsellor.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.muted,
              size: 16,
            ),
          ],
        ),
      ),
    ),
  );
}

class _NGOQuickActionsGrid extends StatelessWidget {
  const _NGOQuickActionsGrid();

  void _open(BuildContext context, int index) {
    final vm = VolunteerViewModel.shared..load();
    final screen = switch (index) {
      0 => WorkSubmissionScreen(vm: vm),
      1 => DailyLogScreen(vm: vm),
      2 => DonationScreen(vm: vm),
      _ => MyCertificatesScreen(vm: vm),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  static const _actions = [
    (Icons.upload_file_rounded, 'Submit\nWork', Color(0xFF1565C0)),
    (Icons.menu_book_rounded, 'Daily\nLogbook', Color(0xFF1A6B3A)),
    (Icons.attach_money_rounded, 'Donation\nProof', Color(0xFFFF8C00)),
    (Icons.workspace_premium_rounded, 'View\nCertificates', Color(0xFF8B5CF6)),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_actions.length, (i) {
        final (icon, label, color) = _actions[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 0 : 5,
              right: i == _actions.length - 1 ? 0 : 5,
            ),
            child: GestureDetector(
              onTap: () => _open(context, i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 19),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wall of Impact Preview Card
// ─────────────────────────────────────────────────────────────────────────────

class _WallOfImpactPreviewCard extends StatefulWidget {
  const _WallOfImpactPreviewCard();

  @override
  State<_WallOfImpactPreviewCard> createState() =>
      _WallOfImpactPreviewCardState();
}

class _WallOfImpactPreviewCardState extends State<_WallOfImpactPreviewCard> {
  ImpactPost? _post;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final posts = await ImpactRepository.getPublished();
      if (mounted) setState(() => _post = posts.firstOrNull);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    if (post == null) {
      return AppCard(
        child: Row(
          children: [
            const Icon(Icons.auto_awesome_outlined, color: AppColors.muted),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Published impact stories will appear here.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
            TextButton(onPressed: _load, child: const Text('Refresh')),
          ],
        ),
      );
    }
    return AppCard(
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
                  errorBuilder: (context, error, _) => Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.volunteer_activism_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
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
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 12,
                          color: Color(0xFF18B86D),
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Verified NGO',
                          style: TextStyle(
                            color: Color(0xFF18B86D),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  post.category,
                  style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.title,
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            post.description,
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ImpactPill(
                '${post.hoursServed.toStringAsFixed(0)} hrs served',
                const Color(0xFF1565C0),
              ),
              const SizedBox(width: 6),
              _ImpactPill(
                '${post.peopleReached} reached',
                const Color(0xFF1A6B3A),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WallOfImpactView()),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View all →',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactPill extends StatelessWidget {
  const _ImpactPill(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
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

class UpcomingEventsPanel extends StatelessWidget {
  const UpcomingEventsPanel({
    required this.events,
    required this.onEventTap,
    super.key,
  });

  final List<EventModel> events;
  final ValueChanged<EventModel> onEventTap;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Upcoming Events'),
        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _UpcomingEventCard(
              event: events[index],
              onTap: () => onEventTap(events[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _UpcomingEventCard extends StatelessWidget {
  const _UpcomingEventCard({required this.event, required this.onTap});

  final EventModel event;
  final VoidCallback onTap;

  String _formatDate(DateTime? value) {
    if (value == null) return 'Date not set';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final actionLabel = event.status == EventStatus.live ? 'Join' : 'Register';
    return SizedBox(
      width: 284,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: event.themeColorValue.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: event.themeColorValue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.event_available_rounded,
                        color: event.themeColorValue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        event.eventType.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Ends ${_formatDate(event.registrationEnd)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        actionLabel,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    this.actionLabel = 'Retry',
  });
  final String message;
  final VoidCallback onRetry;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _EventNotificationToast extends StatefulWidget {
  const _EventNotificationToast({
    required this.event,
    required this.endText,
    required this.label,
    required this.onRegister,
    required this.onDismiss,
  });

  final EventModel event;
  final String endText;
  final String label;
  final VoidCallback onRegister;
  final VoidCallback onDismiss;

  @override
  State<_EventNotificationToast> createState() =>
      _EventNotificationToastState();
}

class _EventNotificationToastState extends State<_EventNotificationToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slide = Tween<Offset>(
      begin: const Offset(-1.2, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(14),
        shadowColor: Colors.black26,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.endText == 'Date not set'
                      ? '${widget.event.title} is open. Tap to view and participate.'
                      : '${widget.event.title} is open until ${widget.endText}. Tap to register or join.',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: widget.onRegister,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  widget.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: widget.onDismiss,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.muted,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard({required this.course, required this.onTap});

  final Course? course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (course == null) {
      return AppCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start Learning',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Explore beginner courses and pick one to start.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Browse', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );
    }

    final progressPct = (course!.progress * 100).round();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: course!.color.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(course!.icon, color: AppColors.ink, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course!.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${course!.level} · ${course!.duration}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Continue', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: course!.progress.clamp(0.0, 1.0),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 7,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$progressPct%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmergencyHelpCard extends StatelessWidget {
  const _EmergencyHelpCard();

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCFE3FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2B68).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header banner ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assests/ngo_logo.jpeg',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, _) => Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.volunteer_activism_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
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
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF69FF8A),
                            size: 13,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Registered NGO  •  Regt. No. 736',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Address & contact details ─────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ContactRow(
                  icon: Icons.location_on_rounded,
                  color: const Color(0xFF1565C0),
                  label: 'Office Address',
                  value: 'Punjabi Welfare Trust, Sadar Bazar, Delhi Cantt, New Delhi',
                  onTap: () => _launch(
                    'https://maps.google.com/?q=Sadar+Bazar+Delhi+Cantt+New+Delhi',
                  ),
                  actionLabel: 'Get Directions',
                ),
                const _Divider(),
                _ContactRow(
                  icon: Icons.phone_rounded,
                  color: const Color(0xFF1A6B3A),
                  label: 'Helpline Numbers',
                  value: '+91 92117 72333\n+91 78349 92799',
                  onTap: () => _launch('tel:+919211772333'),
                  actionLabel: 'Call Now',
                ),
                const _Divider(),
                _ContactRow(
                  icon: Icons.chat_rounded,
                  color: const Color(0xFF25D366),
                  label: 'WhatsApp',
                  value: '+91 92117 72333',
                  onTap: () => _launch(
                    'https://wa.me/919211772333?text=Hello%20Punjabi%20Welfare%20Trust%2C%20I%20need%20help.',
                  ),
                  actionLabel: 'Message',
                ),
                const _Divider(),
                _ContactRow(
                  icon: Icons.mail_rounded,
                  color: const Color(0xFFFF8C00),
                  label: 'Email',
                  value: 'Punjabiwelfaretrust99@gmail.com',
                  onTap: () => _launch(
                    'mailto:Punjabiwelfaretrust99@gmail.com?subject=Help%20Request',
                  ),
                  actionLabel: 'Send Mail',
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // ── Office hours footer ───────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F7FF),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: AppColors.muted,
                ),
                SizedBox(width: 6),
                Text(
                  'Office Hours: Mon – Sat, 9:00 AM – 6:00 PM',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onTap,
    required this.actionLabel,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback onTap;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                actionLabel,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0));
  }
}

// ── Admin analytics section ───────────────────────────────────────────────────

class _AdminAnalyticsSection extends StatelessWidget {
  const _AdminAnalyticsSection({
    required this.vm,
    required this.onViewPending,
    required this.onOpenUsers,
    required this.onOpenEvents,
    required this.onOpenCounselling,
    required this.onOpenSafety,
    required this.onOpenEmergency,
    required this.onOpenVolunteer,
  });

  final AdminViewModel vm;
  final VoidCallback onViewPending;
  final VoidCallback onOpenUsers;
  final VoidCallback onOpenEvents;
  final VoidCallback onOpenCounselling;
  final VoidCallback onOpenSafety;
  final VoidCallback onOpenEmergency;
  final VoidCallback onOpenVolunteer;

  @override
  Widget build(BuildContext context) {
    final stats = vm.stats;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform Overview',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Analytics and admin controls',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stats grid: 2×2
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: [
              _StatTile(
                icon: Icons.people_alt_rounded,
                label: 'Total Users',
                value: stats.totalUsers,
                color: AppColors.ink,
                onTap: onOpenUsers,
              ),
              _StatTile(
                icon: Icons.verified_user_rounded,
                label: 'Active Users',
                value: stats.activeUsers,
                color: AppColors.secondary,
                onTap: onOpenUsers,
              ),
              _StatTile(
                icon: Icons.schedule_rounded,
                label: 'Pending Approvals',
                value: vm.pendingCount,
                color: const Color(0xFFFF8C00),
                onTap: onViewPending,
              ),
              _StatTile(
                icon: Icons.block_rounded,
                label: 'Blocked Users',
                value: stats.blockedUsers,
                color: AppColors.softRed,
                onTap: onOpenUsers,
              ),
            ],
          ),

          if (vm.pendingCount > 0) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onViewPending,
              icon: const Icon(Icons.fact_check_outlined, size: 16),
              label: Text(
                'Review ${vm.pendingCount} pending ${vm.pendingCount == 1 ? "request" : "requests"}',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Text(
            'Management Tools',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),

          // Tools grid: 2×3
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 3.2,
            children: [
              _ToolTileHome(
                icon: Icons.pending_actions_rounded,
                label: 'Approvals',
                subtitle: '${vm.pendingCount} waiting',
                color: AppColors.accent,
                onTap: onViewPending,
              ),
              _ToolTileHome(
                icon: Icons.manage_accounts_rounded,
                label: 'Users',
                subtitle: '${stats.totalUsers} records',
                color: AppColors.primary,
                onTap: onOpenUsers,
              ),
              _ToolTileHome(
                icon: Icons.event_rounded,
                label: 'Events',
                subtitle: 'Create & manage',
                color: const Color(0xFF6B48FF),
                onTap: onOpenEvents,
              ),
              _ToolTileHome(
                icon: Icons.psychology_outlined,
                label: 'Counselling',
                subtitle: 'Sessions',
                color: const Color(0xFF009688),
                onTap: onOpenCounselling,
              ),
              _ToolTileHome(
                icon: Icons.shield_rounded,
                label: 'Safety',
                subtitle: 'Stories & questions',
                color: AppColors.softRed,
                onTap: onOpenSafety,
              ),
              _ToolTileHome(
                icon: Icons.contact_phone_rounded,
                label: 'Emergency',
                subtitle: 'Helplines',
                color: AppColors.ink,
                onTap: onOpenEmergency,
              ),
              _ToolTileHome(
                icon: Icons.volunteer_activism_rounded,
                label: 'Volunteer',
                subtitle: 'Submissions & logs',
                color: const Color(0xFF0288D1),
                onTap: onOpenVolunteer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      height: 1,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolTileHome extends StatelessWidget {
  const _ToolTileHome({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Admin notifications bottom sheet ─────────────────────────────────────────

class _AdminNotificationsSheet extends StatelessWidget {
  const _AdminNotificationsSheet({required this.adminVm});

  final AdminViewModel adminVm;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  if (adminVm.unreadCount > 0)
                    TextButton(
                      onPressed: adminVm.markAllRead,
                      child: const Text('Mark all read'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListenableBuilder(
                listenable: adminVm,
                builder: (_, _) {
                  final notes = adminVm.notifications;
                  if (notes.isEmpty) {
                    return const Center(
                      child: Text(
                        'No notifications yet.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: notes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _NotificationTile(
                      notification: notes[i],
                      onTap: () => adminVm.markNotificationRead(notes[i].id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final dynamic notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead as bool;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.white
              : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead
                ? AppColors.muted.withValues(alpha: 0.15)
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRead
                    ? Icons.notifications_none_rounded
                    : Icons.notifications_active_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title as String,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                      color: AppColors.ink,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.message as String,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Active Pipeline Event Card ───────────────────────────────────────────────

class _ActivePipelineEventCard extends StatelessWidget {
  const _ActivePipelineEventCard({required this.vm});
  final EventPipelineViewModel vm;

  static List<PipelineAssignment> _activeAssignments(EventPipelineViewModel vm) =>
      vm.events
          .expand((e) => e.allAssignments)
          .where((a) =>
              a.status == PipelineAssignmentStatus.assigned ||
              a.status == PipelineAssignmentStatus.inProgress ||
              a.status == PipelineAssignmentStatus.resubmissionRequested)
          .toList();

  /// Whether this card has anything to show beyond a "nothing here" message
  /// — used by the caller to skip the whole "Active Event" section when
  /// empty, since "My Assignments" above it already covers that case.
  static bool hasActive(EventPipelineViewModel vm) =>
      _activeAssignments(vm).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final allAssignments = _activeAssignments(vm);

    if (allAssignments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.event_outlined, size: 28, color: AppColors.muted.withValues(alpha: 0.4)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No active event assignment', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.muted)),
                    Text('Browse events to apply for an activity', style: TextStyle(fontSize: 12, color: AppColors.muted.withValues(alpha: 0.7))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final assignment = allAssignments.first;
    final event = vm.events.where((e) => e.id == assignment.eventId).firstOrNull;
    final status = assignment.status;
    final isResubmission = status == PipelineAssignmentStatus.resubmissionRequested;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: event == null
            ? null
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventDetailPipelineScreen(event: event, vm: vm),
                  ),
                ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isResubmission
                  ? const Color(0xFF6A1B9A).withValues(alpha: 0.35)
                  : AppColors.primary.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.07),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  children: [
                    Icon(status.icon, size: 13, color: status.color),
                    const SizedBox(width: 5),
                    Text(status.label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: status.color)),
                    const Spacer(),
                    if (event != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(event.category.label, style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(assignment.eventTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF17324D))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.assignment_ind_rounded, size: 13, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(assignment.activityTitle, style: TextStyle(fontSize: 12.5, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    if (event != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 12, color: AppColors.muted),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(event.location, style: TextStyle(fontSize: 12, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.muted),
                          const SizedBox(width: 3),
                          Text(_formatDate(assignment.dueDate), style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                        ],
                      ),
                    ],
                    if (isResubmission && assignment.reviewerNotes != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A1B9A).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.replay_rounded, size: 13, color: Color(0xFF6A1B9A)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text('Reviewer: ${assignment.reviewerNotes}', style: const TextStyle(fontSize: 12, color: Color(0xFF6A1B9A))),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: event == null
                                ? null
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (ctx) => EventDetailPipelineScreen(event: event, vm: vm)),
                                    ),
                            icon: const Icon(Icons.info_outline_rounded, size: 14),
                            label: const Text('Details', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: event == null
                                ? null
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (ctx) => EventDetailPipelineScreen(event: event, vm: vm)),
                                    ),
                            icon: Icon(isResubmission ? Icons.replay_rounded : Icons.upload_file_rounded, size: 14),
                            label: Text(
                              isResubmission ? 'Resubmit' : 'Submit Work',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: isResubmission ? const Color(0xFF6A1B9A) : AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (allAssignments.length > 1) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          '+${allAssignments.length - 1} more active assignment${allAssignments.length > 2 ? 's' : ''}',
                          style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }
}
