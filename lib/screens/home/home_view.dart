import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/event_models.dart';
import '../../models/skill_category.dart';
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
  const HomeView({this.onOpenLearn, super.key});

  final ValueChanged<SkillCategory?>? onOpenLearn;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  late final HomeViewModel _vm;
  late final TextEditingController _skillSearchCtrl;
  Timer? _notificationTimer;
  bool _bannerShown = false;
  bool _eventBannerShown = false;
  OverlayEntry? _eventNotificationEntry;
  String _skillQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _vm = HomeViewModel();
    _skillSearchCtrl = TextEditingController();
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
    _eventNotificationEntry?.remove();
    _eventNotificationEntry = null;
    _skillSearchCtrl.dispose();
    _vm.removeListener(_onVmChanged);
    _vm.dispose();
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
            openEvent(context, event, onRefresh: () => _vm.load());
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
        return AppScrollView(
          children: [
            const TopHeader(
              title: 'Hi Aarav',
              subtitle: 'Ready to learn, play, and grow today?',
              actionIcon: Icons.notifications_none_rounded,
            ),
            const WelcomeBanner(),
            UpcomingEventsPanel(
              events: _vm.upcomingEvents,
              onEventTap: (event) =>
                  openEvent(context, event, onRefresh: () => _vm.load()),
            ),
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
              onTap: () => widget.onOpenLearn?.call(null),
            ),
            TextField(
              controller: _skillSearchCtrl,
              onChanged: (value) => setState(() => _skillQuery = value.trim()),
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
            // Counselling card — shows booked sessions + available slots
            CounsellingSessionCard(
              upcomingSessions: _vm.allUpcomingSessions,
              availableSlots: _vm.availableSlots,
              onViewAll: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AllSlotsScreen())),
              onBook: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AllSlotsScreen())),
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

  List<SkillCategory> _filteredSkillCategories(List<SkillCategory> categories) {
    final query = _skillQuery.toLowerCase();
    if (query.isEmpty) return categories;
    return categories
        .where((category) => category.title.toLowerCase().contains(query))
        .toList();
  }

  void _openCounsellingBooking(BuildContext context) {
    final event = _vm.upcomingCounsellingEvent;
    if (event != null) {
      openEvent(context, event, onRefresh: () => _vm.load());
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AllSlotsScreen()));
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
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
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
