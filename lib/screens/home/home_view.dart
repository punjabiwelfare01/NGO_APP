import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/view_state.dart';
import '../../utils/navigation_helper.dart';
import '../../widgets/app_scroll_view.dart';
import '../../widgets/section_header.dart';
import '../../widgets/top_header.dart';
import '../helping_support/student/all_slots_screen.dart';
import 'widgets/counselling_session_card.dart';
import 'widgets/daily_challenge_card.dart';
import 'widgets/daily_motivation_card.dart';
import 'widgets/parent_preview_panel.dart';
import 'widgets/skill_category_card.dart';
import 'widgets/upcoming_counselling_banner.dart';
import 'widgets/welcome_banner.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  late final HomeViewModel _vm;
  Timer? _notificationTimer;
  bool _bannerShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _vm = HomeViewModel();
    _vm.addListener(_onVmChanged);
    _vm.load();
    // Check every minute if a session is about to start
    _notificationTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkSessionNotification(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _vm.load();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationTimer?.cancel();
    _vm.removeListener(_onVmChanged);
    _vm.dispose();
    super.dispose();
  }

  void _onVmChanged() {
    if (_vm.state == ViewState.idle) {
      _checkSessionNotification();
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
          leading: const Icon(Icons.notifications_active_rounded,
              color: AppColors.secondary),
          content: Text(
            diffMin == 0
                ? 'Your session with ${session.counsellorName} is starting now!'
                : 'Your session with ${session.counsellorName} starts in $diffMin min.',
            style: const TextStyle(
                color: AppColors.ink, fontWeight: FontWeight.w600),
          ),
          actions: [
            if (hasLink)
              TextButton(
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: session.meetingUrl!));
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Join link copied to clipboard!')),
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
        return AppScrollView(
          children: [
            const TopHeader(
              title: 'Hi Aarav',
              subtitle: 'Ready to learn, play, and grow today?',
              actionIcon: Icons.notifications_none_rounded,
            ),
            const WelcomeBanner(),
            UpcomingCounsellingBanner(
              upcomingEvent: _vm.upcomingCounsellingEvent,
              liveSession: _vm.upcomingSession,
              onEventTap: () => _openCounsellingBooking(context),
              onJoinTap: () => _openCounsellingSession(context),
            ),
            const DailyMotivationCard(),
            SectionHeader(
              title: 'Skill Development',
              action: 'View all',
              onTap: () {},
            ),
            SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _vm.categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) =>
                    SkillCategoryCard(item: _vm.categories[i]),
              ),
            ),
            // Counselling card — shows booked sessions + available slots
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
            const ParentPreviewPanel(),
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

  void _openCounsellingBooking(BuildContext context) {
    final event = _vm.upcomingCounsellingEvent;
    if (event != null) {
      openEvent(context, event, onRefresh: () => _vm.load());
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AllSlotsScreen()),
    );
  }

  void _openCounsellingSession(BuildContext context) {
    final event = _vm.upcomingCounsellingEvent;
    if (event != null) {
      openEvent(context, event, onRefresh: () => _vm.load());
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
