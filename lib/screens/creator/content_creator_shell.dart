import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/creator_content.dart';
import '../../repositories/api_client.dart';
import '../../repositories/creator_repository.dart';
import '../../widgets/app_card.dart';
import '../events/admin/create_event/create_event_view.dart';
import '../events/admin/create_event/quiz/create_quiz_screen.dart';
import '../learn/admin/create_course_screen.dart';
import '../learn/learn_view.dart';
import 'content_analytics_view.dart';
import 'content_creator_content_view.dart';
import 'content_creator_profile_view.dart';
import 'content_creator_upload_view.dart';
import 'create_post_screen.dart';

class ContentCreatorShell extends StatefulWidget {
  const ContentCreatorShell({super.key});

  @override
  State<ContentCreatorShell> createState() => _ContentCreatorShellState();
}

class _ContentCreatorShellState extends State<ContentCreatorShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _CreatorHomeView(),
      const ContentAnalyticsView(),
      const ContentCreatorUploadView(),
      const ContentCreatorContentView(),
      const ContentCreatorProfileView(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _selectedIndex,
        indicatorColor: AppColors.primary.withValues(alpha: 0.16),
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Upload',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Content',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── Home View ───────────────────────────────────────────────────────────────

class _CreatorHomeView extends StatefulWidget {
  const _CreatorHomeView();

  @override
  State<_CreatorHomeView> createState() => _CreatorHomeViewState();
}

class _CreatorHomeViewState extends State<_CreatorHomeView> {
  CreatorHomeStats? _stats;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await CreatorRepository.getHomeStats();
      if (!mounted) return;
      setState(() {
        _stats = result;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.statusCode == 401
            ? 'Session expired. Please sign in again.'
            : 'Server error (${e.statusCode}). Please try again.';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not reach the server. Is the backend running?';
        _loading = false;
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final name = AppState.studentName ?? 'Creator';
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
      children: [
        _buildHeader(name),
        const SizedBox(height: 20),
        if (_loading)
          const _LoadingCard()
        else if (_error != null)
          _ErrorCard(message: _error!, onRetry: _retry)
        else ...[
          _AnalyticsCard(stats: _stats!),
          const SizedBox(height: 20),
          _CreationToolsSection(drafts: _stats!.drafts),
          const SizedBox(height: 20),
          const _PromoBanner(),
          const SizedBox(height: 20),
          _RecentContentSection(items: _stats!.recentContent),
          const SizedBox(height: 20),
          _TopPerformingSection(items: _stats!.topPerforming),
        ],
      ],
    );
  }

  Widget _buildHeader(String name) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi $name',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Welcome back, Content Creator',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: AppColors.ink,
                size: 22,
              ),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.softRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16),
                child: const Text(
                  '2',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Loading / Error ─────────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Icon(Icons.error_outline_rounded,
              color: AppColors.softRed, size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Analytics Card ──────────────────────────────────────────────────────────

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({required this.stats});

  final CreatorHomeStats stats;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Creator Analytics',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Content overview & management',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.description_outlined,
                  value: '${stats.totalContent}',
                  label: 'Total Content',
                  iconColor: AppColors.primary,
                  bgColor: AppColors.primary.withValues(alpha: 0.10),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.check_circle_outline_rounded,
                  value: '${stats.published}',
                  label: 'Published',
                  iconColor: AppColors.secondary,
                  bgColor: AppColors.secondary.withValues(alpha: 0.15),
                  valueColor: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.access_time_rounded,
                  value: '${stats.pendingReview}',
                  label: 'Pending Review',
                  iconColor: AppColors.accent,
                  bgColor: AppColors.accent.withValues(alpha: 0.12),
                  valueColor: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.remove_red_eye_outlined,
                  value: stats.totalViewsLabel,
                  label: 'Total Views',
                  iconColor: const Color(0xFF8B5CF6),
                  bgColor: const Color(0xFF8B5CF6).withValues(alpha: 0.10),
                  valueColor: const Color(0xFF8B5CF6),
                ),
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
    required this.value,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    this.valueColor = AppColors.ink,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Creation Tools ──────────────────────────────────────────────────────────

class _CreationToolsSection extends StatelessWidget {
  const _CreationToolsSection({required this.drafts});

  final int drafts;

  Future<void> _openScaffold(BuildContext context, Widget screen) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => screen),
      );

  @override
  Widget build(BuildContext context) {
    final tools = [
      _ToolEntry(
        icon: Icons.edit_outlined,
        title: 'Create Post',
        subtitle: 'Learning & NGO posts',
        color: const Color(0xFF3B82F6),
        onTap: () => _openScaffold(
          context,
          const CreatePostScreen(courses: [], events: [], quizzes: []),
        ),
      ),
      _ToolEntry(
        icon: Icons.school_outlined,
        title: 'Add Course',
        subtitle: 'Course structure',
        color: const Color(0xFF10B981),
        onTap: () => _openScaffold(context, const CreateCourseScreen()),
      ),
      _ToolEntry(
        icon: Icons.play_circle_outline_rounded,
        title: 'Add Lesson',
        subtitle: 'Video, PDF, notes',
        color: const Color(0xFF8B5CF6),
        onTap: () => _openScaffold(
          context,
          const Scaffold(body: LearnView()),
        ),
      ),
      _ToolEntry(
        icon: Icons.help_outline_rounded,
        title: 'Create Quiz',
        subtitle: 'Questions & rewards',
        color: const Color(0xFFF59E0B),
        onTap: () => _openScaffold(context, const CreateQuizScreen()),
      ),
      _ToolEntry(
        icon: Icons.calendar_today_outlined,
        title: 'Create Event',
        subtitle: 'Workshops & drives',
        color: const Color(0xFFEF4444),
        onTap: () => _openScaffold(context, const CreateEventView()),
      ),
      _ToolEntry(
        icon: Icons.folder_open_outlined,
        title: 'Drafts',
        subtitle: drafts > 0 ? '$drafts items' : 'No drafts yet',
        color: const Color(0xFF6B7280),
        onTap: null,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Creation Tools',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              for (int i = 0; i < tools.length; i += 2)
                Row(
                  children: [
                    Expanded(child: _ToolTile(entry: tools[i])),
                    if (i + 1 < tools.length)
                      Expanded(child: _ToolTile(entry: tools[i + 1])),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolEntry {
  const _ToolEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.entry});

  final _ToolEntry entry;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: entry.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: entry.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(entry.icon, color: entry.color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    entry.subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.muted, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Promo Banner ─────────────────────────────────────────────────────────────

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -12,
            right: 90,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -8,
            right: 60,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Create something impactful today!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Share knowledge. Inspire change.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.laptop_mac_rounded,
                      color: Colors.white, size: 38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recent Content ──────────────────────────────────────────────────────────

class _RecentContentSection extends StatelessWidget {
  const _RecentContentSection({required this.items});

  final List<CreatorContentItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Content',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'View all',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No content yet',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < items.length; i++) ...[
                      _ContentItem(item: items[i]),
                      if (i < items.length - 1)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _ContentItem extends StatelessWidget {
  const _ContentItem({required this.item});

  final CreatorContentItem item;

  static const _statusColors = {
    'published': Color(0xFF10B981),
    'pending_review': Color(0xFFF59E0B),
    'draft': Color(0xFF6B7280),
    'rejected': Color(0xFFEF4444),
    'completed': Color(0xFF10B981),
    'archived': Color(0xFF6B7280),
  };

  static const _typeIcons = {
    'course': Icons.menu_book_outlined,
    'lesson': Icons.play_circle_outline_rounded,
    'quiz': Icons.help_outline_rounded,
    'event': Icons.calendar_today_outlined,
    'post': Icons.description_outlined,
  };

  static const _typeColors = {
    'course': Color(0xFF3B82F6),
    'lesson': Color(0xFF8B5CF6),
    'quiz': Color(0xFFF59E0B),
    'event': Color(0xFFEF4444),
    'post': Color(0xFF3B82F6),
  };

  @override
  Widget build(BuildContext context) {
    final iconColor = _typeColors[item.type] ?? AppColors.primary;
    final icon = _typeIcons[item.type] ?? Icons.description_outlined;
    final badgeColor = _statusColors[item.status] ?? AppColors.muted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item.subtitle ?? item.typeLabel,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: badgeColor.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Text(
              item.statusLabel,
              style: TextStyle(
                color: badgeColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top Performing ──────────────────────────────────────────────────────────

class _TopPerformingSection extends StatelessWidget {
  const _TopPerformingSection({required this.items});

  final List<CreatorContentItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top Performing Content',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'View all',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          AppCard(
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No published content yet',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _TopPerformingItem(item: items[i]),
                if (i < items.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
      ],
    );
  }
}

class _TopPerformingItem extends StatelessWidget {
  const _TopPerformingItem({required this.item});

  final CreatorContentItem item;

  static const _typeColors = {
    'course': Color(0xFF10B981),
    'lesson': Color(0xFF8B5CF6),
    'quiz': Color(0xFFF59E0B),
    'event': Color(0xFFEF4444),
    'post': Color(0xFF3B82F6),
  };

  static const _typeIcons = {
    'course': Icons.menu_book_outlined,
    'lesson': Icons.play_circle_outline_rounded,
    'quiz': Icons.help_outline_rounded,
    'event': Icons.calendar_today_outlined,
    'post': Icons.description_outlined,
  };

  String _shortNumber(int value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[item.type] ?? AppColors.secondary;
    final icon = _typeIcons[item.type] ?? Icons.menu_book_outlined;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item.subtitle ?? item.typeLabel,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _MetricColumn(
            icon: Icons.remove_red_eye_outlined,
            value: _shortNumber(item.views),
            label: 'Views',
          ),
          const SizedBox(width: 16),
          _MetricColumn(
            icon: Icons.check_circle_outline_rounded,
            value: '${item.completionRate ?? 0}%',
            label: 'Completion',
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.muted, size: 20),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.muted, size: 16),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
