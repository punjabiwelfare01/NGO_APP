import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/course.dart';
import '../../models/creator_content.dart';
import '../../models/event_models.dart';
import '../../models/quiz_models.dart';
import '../../models/skill_category.dart';
import '../../repositories/course_repository.dart';
import '../../repositories/creator_repository.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/quiz_repository.dart';
import 'create_post_screen.dart';
import '../events/admin/create_event/create_event_view.dart';
import '../events/admin/create_event/quiz/create_quiz_screen.dart';
import '../learn/learn_view.dart';
import '../learn/admin/create_course_screen.dart';
import '../learn/admin/manage_skill_categories_screen.dart';

class ContentCreatorUploadView extends StatefulWidget {
  const ContentCreatorUploadView({super.key});

  @override
  State<ContentCreatorUploadView> createState() =>
      _ContentCreatorUploadViewState();
}

class _ContentCreatorUploadViewState extends State<ContentCreatorUploadView> {
  List<SkillCategory> _categories = [];
  List<Course> _courses = [];
  List<EventModel> _events = [];
  List<QuizSummary> _quizzes = [];
  List<CreatorContentItem> _content = [];
  int? _selectedCategoryId;
  String? _selectedStaticFilter;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        CourseRepository.getCategories(),
        CourseRepository.getCourses(),
        EventRepository.getEvents(),
        QuizRepository.getQuizzes(includeInactive: true),
        CreatorRepository.getContent(),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<SkillCategory>;
        _courses = results[1] as List<Course>;
        _events = results[2] as List<EventModel>;
        _quizzes = results[3] as List<QuizSummary>;
        _content = results[4] as List<CreatorContentItem>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load upload dashboard.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentUploads = _recentUploads();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        children: [
          const _UploadHeader(),
          const SizedBox(height: 18),
          _CreateActionGrid(
            onCreateEvent: _openCreateEvent,
            onAddCourse: _openCreateCourse,
            onAddLesson: _openCreateLesson,
            onCreateQuiz: _openCreateQuiz,
            onCreatePost: _openCreatePost,
            onUploadPdfNotes: _openCreateLesson,
          ),
          const SizedBox(height: 18),
          _CategoryFilters(
            categories: _categories,
            selectedCategoryId: _selectedCategoryId,
            selectedStaticFilter: _selectedStaticFilter,
            onSelected: (id) => setState(() {
              _selectedCategoryId = id;
              _selectedStaticFilter = null;
            }),
            onStaticSelected: (filter) => setState(() {
              _selectedStaticFilter = filter;
              _selectedCategoryId = null;
            }),
          ),
          const SizedBox(height: 16),
          _UploadStats(
            drafts: _draftCount,
            pending: _pendingCount,
            published: _publishedCount,
            posts: _postCount,
          ),
          const SizedBox(height: 18),
          if (_loading)
            const _LoadingCard()
          else if (_error != null)
            _ErrorCard(message: _error!, onRetry: _load)
          else
            _RecentUploadsCard(items: recentUploads, onViewAll: _load),
          const SizedBox(height: 18),
          _QuickActionsCard(
            onManageSkills: _openManageSkills,
            onAddCourse: _openCreateCourse,
            onCreatePost: _openCreatePost,
            onViewDrafts: () => _showDrafts(recentUploads),
          ),
        ],
      ),
    );
  }

  int get _draftCount =>
      _filteredContent.where((item) => item.status == 'draft').length;

  int get _pendingCount =>
      _filteredContent.where((item) => item.status == 'pending_review').length;

  int get _publishedCount =>
      _filteredContent.where((item) => item.status == 'published').length;

  int get _postCount =>
      _filteredContent.where((item) => item.type == 'post').length;

  List<_RecentUpload> _recentUploads() {
    final uploads = _filteredContent.map(_RecentUpload.content).toList();
    uploads.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return uploads.take(8).toList();
  }

  List<CreatorContentItem> get _filteredContent {
    var items = _content;
    if (_selectedStaticFilter == 'learning_posts') {
      items = items
          .where(
            (item) =>
                item.type == 'post' &&
                item.meta['post_type'] != 'ngo_event_post',
          )
          .toList();
    } else if (_selectedStaticFilter == 'ngo_events') {
      items = items
          .where(
            (item) =>
                item.type == 'event' ||
                (item.type == 'post' &&
                    item.meta['post_type'] == 'ngo_event_post'),
          )
          .toList();
    }
    if (_selectedCategoryId == null) return items;
    final selectedTitle = _categories
        .where((category) => category.id == _selectedCategoryId)
        .map((category) => category.title.toLowerCase())
        .firstOrNull;
    if (selectedTitle == null) return const [];
    return items
        .where((item) => (item.category ?? '').toLowerCase() == selectedTitle)
        .toList();
  }

  Future<void> _openCreateEvent() async {
    final created = await Navigator.of(context).push<EventModel>(
      MaterialPageRoute(builder: (_) => const CreateEventView()),
    );
    if (created != null) await _load();
  }

  Future<void> _openCreateCourse() async {
    final created = await Navigator.of(context).push<Course>(
      MaterialPageRoute(builder: (_) => const CreateCourseScreen()),
    );
    if (created != null) await _load();
  }

  Future<void> _openCreateLesson() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: LearnView()),
      ),
    );
    await _load();
  }

  Future<void> _openCreateQuiz() async {
    final created = await Navigator.of(context).push<QuizSummary>(
      MaterialPageRoute(builder: (_) => const CreateQuizScreen()),
    );
    if (created != null) await _load();
  }

  Future<void> _openCreatePost() async {
    final created = await Navigator.of(context).push<CreatorContentItem>(
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(
          courses: _courses,
          events: _events,
          quizzes: _quizzes,
        ),
      ),
    );
    if (created != null) await _load();
  }

  Future<void> _openManageSkills() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ManageSkillCategoriesScreen()),
    );
    await _load();
  }

  void _showDrafts(List<_RecentUpload> uploads) {
    final drafts = uploads.where((upload) => upload.status == 'Draft').toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DraftsSheet(drafts: drafts),
    );
  }
}

class _UploadHeader extends StatelessWidget {
  const _UploadHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Content Upload',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.ink,
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create and manage learning content',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () {},
          tooltip: 'Search uploads',
          icon: const Icon(Icons.search_rounded, size: 28),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: () {},
          tooltip: 'Upload filters',
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    );
  }
}

class _CreateActionGrid extends StatelessWidget {
  const _CreateActionGrid({
    required this.onCreateEvent,
    required this.onAddCourse,
    required this.onAddLesson,
    required this.onCreateQuiz,
    required this.onCreatePost,
    required this.onUploadPdfNotes,
  });

  final VoidCallback onCreateEvent;
  final VoidCallback onAddCourse;
  final VoidCallback onAddLesson;
  final VoidCallback onCreateQuiz;
  final VoidCallback onCreatePost;
  final VoidCallback onUploadPdfNotes;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _CreateActionData(
        icon: Icons.calendar_month_rounded,
        title: 'Create Event',
        subtitle: '8-step event setup',
        color: AppColors.primary,
        onTap: onCreateEvent,
      ),
      _CreateActionData(
        icon: Icons.school_rounded,
        title: 'Add Course',
        subtitle: 'New course structure',
        color: AppColors.secondary,
        onTap: onAddCourse,
      ),
      _CreateActionData(
        icon: Icons.video_file_rounded,
        title: 'Add Lesson',
        subtitle: 'Video, PDF, notes',
        color: const Color(0xFF7F5AF0),
        onTap: onAddLesson,
      ),
      _CreateActionData(
        icon: Icons.help_rounded,
        title: 'Create Quiz',
        subtitle: 'Add questions & rewards',
        color: AppColors.accent,
        onTap: onCreateQuiz,
      ),
      _CreateActionData(
        icon: Icons.campaign_rounded,
        title: 'Create Post',
        subtitle: 'Learning post or NGO event post',
        color: const Color(0xFF2F8BFF),
        onTap: onCreatePost,
      ),
      _CreateActionData(
        icon: Icons.description_rounded,
        title: 'Upload PDF/Notes',
        subtitle: 'Resources and study material',
        color: const Color(0xFF13B8B2),
        onTap: onUploadPdfNotes,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: constraints.maxWidth > 620 ? 2.65 : 1.55,
          ),
          itemBuilder: (context, index) =>
              _CreateActionCard(data: actions[index]),
        );
      },
    );
  }
}

class _CreateActionCard extends StatelessWidget {
  const _CreateActionCard({required this.data});

  final _CreateActionData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 220;
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: data.onTap,
            borderRadius: BorderRadius.circular(20),
            child: _SoftCard(
              padding: EdgeInsets.all(compact ? 12 : 16),
              child: Row(
                children: [
                  Container(
                    width: compact ? 42 : 66,
                    height: compact ? 42 : 66,
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(compact ? 13 : 18),
                    ),
                    child: Icon(
                      data.icon,
                      color: data.color,
                      size: compact ? 24 : 34,
                    ),
                  ),
                  SizedBox(width: compact ? 9 : 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          maxLines: compact ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: compact ? 13 : 17,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          data.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: compact ? 11 : 14,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                    size: compact ? 20 : 28,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({
    required this.categories,
    required this.selectedCategoryId,
    required this.selectedStaticFilter,
    required this.onSelected,
    required this.onStaticSelected,
  });

  final List<SkillCategory> categories;
  final int? selectedCategoryId;
  final String? selectedStaticFilter;
  final ValueChanged<int?> onSelected;
  final ValueChanged<String?> onStaticSelected;

  @override
  Widget build(BuildContext context) {
    final chips = [
      (null, 'All', Icons.check_rounded),
      ...categories
          .take(4)
          .map((category) => (category.id, category.title, null)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final chip in chips) ...[
            _CategoryChip(
              label: chip.$2,
              icon: chip.$3,
              selected:
                  selectedCategoryId == chip.$1 && selectedStaticFilter == null,
              onTap: () => onSelected(chip.$1),
            ),
            const SizedBox(width: 10),
          ],
          _CategoryChip(
            label: 'NGO Events',
            selected: selectedStaticFilter == 'ngo_events',
            onTap: () => onStaticSelected('ngo_events'),
          ),
          const SizedBox(width: 10),
          _CategoryChip(
            label: 'Learning Posts',
            selected: selectedStaticFilter == 'learning_posts',
            onTap: () => onStaticSelected('learning_posts'),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: icon == null
          ? const SizedBox.shrink()
          : Icon(icon, size: 18, color: AppColors.primary),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? AppColors.primary : AppColors.muted,
        backgroundColor: selected
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.white,
        side: BorderSide(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.45)
              : AppColors.ink.withValues(alpha: 0.12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _UploadStats extends StatelessWidget {
  const _UploadStats({
    required this.drafts,
    required this.pending,
    required this.published,
    required this.posts,
  });

  final int drafts;
  final int pending;
  final int published;
  final int posts;

  @override
  Widget build(BuildContext context) {
    final total = drafts + pending + published;
    final stats = [
      _StatData(
        icon: Icons.article_rounded,
        label: 'Drafts',
        value: '$drafts',
        helper: '${_percent(drafts, total)}% of total',
        color: const Color(0xFF7F5AF0),
      ),
      _StatData(
        icon: Icons.schedule_rounded,
        label: 'Pending Review',
        value: '$pending',
        helper: '${_percent(pending, total)}% of total',
        color: AppColors.accent,
      ),
      _StatData(
        icon: Icons.task_alt_rounded,
        label: 'Published',
        value: '$published',
        helper: '${_percent(published, total)}% of total',
        color: AppColors.secondary,
      ),
      _StatData(
        icon: Icons.campaign_rounded,
        label: 'Posts',
        value: '$posts',
        helper: 'Learning + NGO posts',
        color: const Color(0xFF2F8BFF),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 620 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 4 ? 1.55 : 1.7,
          ),
          itemBuilder: (context, index) => _StatCard(data: stats[index]),
        );
      },
    );
  }

  int _percent(int value, int total) {
    if (total == 0) return 0;
    return ((value / total) * 100).round();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 27),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.value,
                  style: TextStyle(
                    color: data.color,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.helper,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _RecentUploadsCard extends StatelessWidget {
  const _RecentUploadsCard({required this.items, required this.onViewAll});

  final List<_RecentUpload> items;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recent Content',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(onPressed: onViewAll, child: const Text('View all')),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No content found',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
          else
            for (final item in items.take(4)) ...[
              _RecentUploadRow(item: item),
              if (item != items.take(4).last) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _RecentUploadRow extends StatelessWidget {
  const _RecentUploadRow({required this.item});

  final _RecentUpload item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(item.icon, color: item.color, size: 27),
          ),
          const SizedBox(width: 14),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.typeLabel,
                  style: TextStyle(
                    color: item.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _UploadStatusBadge(label: item.status, color: item.statusColor),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.muted),
            tooltip: 'Upload options',
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'view', child: Text('View')),
              PopupMenuItem(value: 'edit', child: Text('Edit')),
            ],
          ),
        ],
      ),
    );
  }
}

class _UploadStatusBadge extends StatelessWidget {
  const _UploadStatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.onManageSkills,
    required this.onAddCourse,
    required this.onCreatePost,
    required this.onViewDrafts,
  });

  final VoidCallback onManageSkills;
  final VoidCallback onAddCourse;
  final VoidCallback onCreatePost;
  final VoidCallback onViewDrafts;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        icon: Icons.tune_rounded,
        label: 'Manage Skills',
        color: AppColors.primary,
        onTap: onManageSkills,
      ),
      _QuickActionData(
        icon: Icons.add_circle_outline_rounded,
        label: 'Add Course',
        color: AppColors.secondary,
        onTap: onAddCourse,
      ),
      _QuickActionData(
        icon: Icons.campaign_rounded,
        label: 'Create Post',
        color: const Color(0xFF2F8BFF),
        onTap: onCreatePost,
      ),
      _QuickActionData(
        icon: Icons.description_outlined,
        label: 'View Drafts',
        color: const Color(0xFF7F5AF0),
        onTap: onViewDrafts,
      ),
    ];

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              if (compact) {
                return Column(
                  children: [
                    for (final action in actions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _QuickActionButton(data: action),
                      ),
                  ],
                );
              }
              return Row(
                children: [
                  for (final action in actions) ...[
                    Expanded(child: _QuickActionButton(data: action)),
                    if (action != actions.last) const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.data});

  final _QuickActionData data;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: data.onTap,
      icon: Icon(data.icon, color: data.color, size: 22),
      label: FittedBox(fit: BoxFit.scaleDown, child: Text(data.label)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: BorderSide(color: AppColors.ink.withValues(alpha: 0.10)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _DraftsSheet extends StatelessWidget {
  const _DraftsSheet({required this.drafts});

  final List<_RecentUpload> drafts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Drafts',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            if (drafts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 22),
                child: Text(
                  'No drafts found',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            else
              for (final draft in drafts) _RecentUploadRow(item: draft),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _SoftCard(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
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
    return _SoftCard(
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.muted, size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CreateActionData {
  const _CreateActionData({
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
  final VoidCallback onTap;
}

class _StatData {
  const _StatData({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String helper;
  final Color color;
}

class _QuickActionData {
  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _RecentUpload {
  const _RecentUpload({
    required this.title,
    required this.typeLabel,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.color,
    required this.sortDate,
  });

  factory _RecentUpload.content(CreatorContentItem item) {
    final colors = _visualForContent(item);
    final status = _statusForContent(item.status);
    return _RecentUpload(
      title: item.title,
      typeLabel: item.typeLabel,
      subtitle: item.subtitle ?? item.metricLabel,
      status: status.$1,
      statusColor: status.$2,
      icon: colors.$1,
      color: colors.$2,
      sortDate: item.updatedAt ?? item.createdAt ?? DateTime.now(),
    );
  }

  final String title;
  final String typeLabel;
  final String subtitle;
  final String status;
  final Color statusColor;
  final IconData icon;
  final Color color;
  final DateTime sortDate;
}

(String, Color) _statusForContent(String status) => switch (status) {
  'published' => ('Published', AppColors.secondary),
  'pending_review' => ('Pending Review', AppColors.accent),
  'completed' => ('Published', AppColors.secondary),
  'archived' => ('Archived', AppColors.muted),
  'rejected' => ('Rejected', AppColors.softRed),
  _ => ('Draft', AppColors.muted),
};

(IconData, Color) _visualForContent(CreatorContentItem item) {
  if (item.type == 'post') {
    final postType = item.meta['post_type'] as String?;
    return (
      postType == 'ngo_event_post'
          ? Icons.record_voice_over_rounded
          : Icons.campaign_rounded,
      const Color(0xFF2F8BFF),
    );
  }
  return switch (item.type) {
    'course' => (Icons.school_rounded, AppColors.secondary),
    'lesson' => (Icons.video_file_rounded, const Color(0xFF7F5AF0)),
    'quiz' => (Icons.help_rounded, AppColors.accent),
    'event' => (Icons.calendar_month_rounded, AppColors.primary),
    _ => (Icons.article_rounded, AppColors.primary),
  };
}
