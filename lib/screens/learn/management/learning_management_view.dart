import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../../core/colors.dart';
import '../../../models/course.dart';
import '../../../repositories/course_repository.dart';
import '../../../viewmodels/view_state.dart';
import '../admin/create_free_course_screen.dart';
import '../admin/create_lesson_screen.dart';
import '../course_detail_screen.dart';

class LearningManagementView extends StatefulWidget {
  const LearningManagementView({super.key});

  @override
  State<LearningManagementView> createState() => _LearningManagementViewState();
}

class _LearningManagementViewState extends State<LearningManagementView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Course> _courses = [];
  ViewState _loadState = ViewState.idle;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadState = ViewState.loading);
    try {
      final courses = await CourseRepository.getUserCourses(AppState.userId);
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _loadState = ViewState.idle;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadState = ViewState.error);
    }
  }

  List<Course> get _drafts => _courses.where((c) => !c.isPublished).toList();
  int get _publishedCount => _courses.where((c) => c.isPublished).length;
  int get _totalLessons => _courses.fold(0, (s, c) => s + c.lessonCount);

  Future<void> _openCreateCourse() async {
    final created = await Navigator.of(context).push<Course>(
      MaterialPageRoute(builder: (_) => const CreateFreeCourseScreen()),
    );
    if (created != null) _load();
  }

  Future<void> _openEditCourse(Course course) async {
    final updated = await Navigator.of(context).push<Course>(
      MaterialPageRoute(
        builder: (_) => CreateFreeCourseScreen(initialCourse: course),
      ),
    );
    if (updated != null) _load();
  }

  Future<void> _openAddLesson(Course course) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateLessonScreen(
          courseId: course.id,
          courseType: CourseType.skill,
          courseTitle: course.title,
          subject: course.subjects.firstOrNull ?? course.subject,
          skillCategory: course.skillCategory,
          nextOrder: course.lessonCount,
        ),
      ),
    );
    _load();
  }

  Future<void> _openAddLessonWithPicker() async {
    if (_courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a course first before adding lessons.'),
        ),
      );
      return;
    }
    final course = await _showCoursePickerDialog();
    if (course != null) _openAddLesson(course);
  }

  Future<Course?> _showCoursePickerDialog() {
    return showDialog<Course>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Course'),
        content: SizedBox(
          width: 360,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _courses.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final c = _courses[index];
              return ListTile(
                leading: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.primary,
                ),
                title: Text(
                  c.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('Free Course · ${c.freeCategory}'),
                onTap: () => Navigator.of(ctx).pop(c),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _openPreview(Course course) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course)),
    );
  }

  Future<void> _togglePublish(Course course) async {
    try {
      if (course.isPublished) {
        await CourseRepository.unpublishCourse(course.id);
      } else {
        await CourseRepository.publishCourse(course.id);
      }
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update course status.')),
      );
    }
  }

  Future<void> _deleteCourse(Course course) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Delete "${course.title}" and all its lessons?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.softRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await CourseRepository.deleteCourse(course.id);
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete course.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ManagementHeader(
          totalCourses: _courses.length,
          publishedCount: _publishedCount,
          draftCount: _drafts.length,
          totalLessons: _totalLessons,
          showStats: _loadState == ViewState.idle,
          onCreateCourse: _openCreateCourse,
          onAddLesson: _openAddLessonWithPicker,
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          dividerColor: Colors.transparent,
          tabs: [
            Tab(text: 'Free Courses (${_courses.length})'),
            const Tab(text: 'Lessons'),
            const Tab(text: 'Resources'),
            Tab(text: 'Drafts (${_drafts.length})'),
          ],
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: AppColors.muted.withValues(alpha: 0.14),
        ),
        Expanded(
          child: _loadState == ViewState.loading
              ? const Center(child: CircularProgressIndicator())
              : _loadState == ViewState.error
              ? _ErrorPanel(onRetry: _load)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _CourseListTab(
                      courses: _courses,
                      emptyMessage: 'No free courses yet.',
                      emptyHint:
                          'Tap Create Free Course to add videos, notes, chapters and quizzes.',
                      onEdit: _openEditCourse,
                      onAddLesson: _openAddLesson,
                      onPreview: _openPreview,
                      onTogglePublish: _togglePublish,
                      onDelete: _deleteCourse,
                    ),
                    _LessonsTab(courses: _courses, onAddLesson: _openAddLesson),
                    const _ResourcesTab(),
                    _CourseListTab(
                      courses: _drafts,
                      emptyMessage: 'No draft courses.',
                      emptyHint: 'All your courses are published.',
                      onEdit: _openEditCourse,
                      onAddLesson: _openAddLesson,
                      onPreview: _openPreview,
                      onTogglePublish: _togglePublish,
                      onDelete: _deleteCourse,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _ManagementHeader extends StatelessWidget {
  const _ManagementHeader({
    required this.totalCourses,
    required this.publishedCount,
    required this.draftCount,
    required this.totalLessons,
    required this.showStats,
    required this.onCreateCourse,
    required this.onAddLesson,
  });

  final int totalCourses, publishedCount, draftCount, totalLessons;
  final bool showStats;
  final VoidCallback onCreateCourse, onAddLesson;

  @override
  Widget build(BuildContext context) {
    final role = AppState.role;
    final roleName = role.isAdmin
        ? 'Admin'
        : role.isMentor
        ? 'Mentor'
        : 'Content Creator';
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learning Management',
                      style: TextStyle(
                        color: Color(0xFF071A34),
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Create, upload, manage, and publish\nlearning content for students.',
                      style: TextStyle(
                        color: Color(0xFF53647E),
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _RoleBadge(roleName),
            ],
          ),
          if (showStats) ...[
            const SizedBox(height: 14),
            _SummaryStatsRow(
              total: totalCourses,
              published: publishedCount,
              drafts: draftCount,
              lessons: totalLessons,
            ),
          ],
          const SizedBox(height: 14),
          _QuickActionsRow(
            onCreateCourse: onCreateCourse,
            onAddLesson: onAddLesson,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge(this.role);

  final String role;

  Color get _color => switch (role) {
    'Admin' => const Color(0xFF7045D9),
    'Mentor' => const Color(0xFF2FAE65),
    _ => AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _SummaryStatsRow extends StatelessWidget {
  const _SummaryStatsRow({
    required this.total,
    required this.published,
    required this.drafts,
    required this.lessons,
  });

  final int total, published, drafts, lessons;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _StatCard(
            label: 'Total Courses',
            value: '$total',
            color: const Color(0xFF2678F4),
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Published',
            value: '$published',
            color: const Color(0xFF2FAE65),
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Drafts',
            value: '$drafts',
            color: const Color(0xFFFF8A00),
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Total Lessons',
            value: '$lessons',
            color: const Color(0xFF7045D9),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onCreateCourse,
    required this.onAddLesson,
  });

  final VoidCallback onCreateCourse, onAddLesson;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: onCreateCourse,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create Free Course'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onAddLesson,
          icon: const Icon(Icons.playlist_add_rounded, size: 18),
          label: const Text('Add Lesson'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tab: Course list ────────────────────────────────────────────────────────

class _CourseListTab extends StatelessWidget {
  const _CourseListTab({
    required this.courses,
    required this.emptyMessage,
    required this.emptyHint,
    required this.onEdit,
    required this.onAddLesson,
    required this.onPreview,
    required this.onTogglePublish,
    required this.onDelete,
  });

  final List<Course> courses;
  final String emptyMessage, emptyHint;
  final ValueChanged<Course> onEdit;
  final ValueChanged<Course> onAddLesson;
  final ValueChanged<Course> onPreview;
  final ValueChanged<Course> onTogglePublish;
  final ValueChanged<Course> onDelete;

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 52,
                color: AppColors.muted.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 14),
              Text(
                emptyMessage,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                emptyHint,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: courses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) => _ManagementCourseCard(
        course: courses[index],
        onEdit: onEdit,
        onAddLesson: onAddLesson,
        onPreview: onPreview,
        onTogglePublish: onTogglePublish,
        onDelete: onDelete,
      ),
    );
  }
}

class _ManagementCourseCard extends StatelessWidget {
  const _ManagementCourseCard({
    required this.course,
    required this.onEdit,
    required this.onAddLesson,
    required this.onPreview,
    required this.onTogglePublish,
    required this.onDelete,
  });

  final Course course;
  final ValueChanged<Course> onEdit;
  final ValueChanged<Course> onAddLesson;
  final ValueChanged<Course> onPreview;
  final ValueChanged<Course> onTogglePublish;
  final ValueChanged<Course> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _TypeBadge(isAcademic: false),
              const SizedBox(width: 8),
              _StatusBadge(isPublished: course.isPublished),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                tooltip: 'More actions',
                onSelected: (value) {
                  if (value == 'delete') onDelete(course);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.softRed,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(color: AppColors.softRed),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            course.title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _MetaItem(
                icon: Icons.category_rounded,
                label: course.freeCategory,
              ),
              _MetaItem(
                icon: Icons.playlist_play_rounded,
                label: '${course.lessonCount} Lessons',
              ),
              _MetaItem(icon: Icons.schedule_rounded, label: course.duration),
              _MetaItem(
                icon: Icons.signal_cellular_alt_rounded,
                label: course.level,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallOutlinedButton(
                label: 'Edit',
                icon: Icons.edit_outlined,
                onTap: () => onEdit(course),
              ),
              _SmallOutlinedButton(
                label: 'Add Lesson',
                icon: Icons.playlist_add_rounded,
                onTap: () => onAddLesson(course),
              ),
              _SmallOutlinedButton(
                label: 'Preview',
                icon: Icons.preview_rounded,
                onTap: () => onPreview(course),
              ),
              _PublishToggleButton(
                isPublished: course.isPublished,
                onTap: () => onTogglePublish(course),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Tab: Lessons ────────────────────────────────────────────────────────────

class _LessonsTab extends StatelessWidget {
  const _LessonsTab({required this.courses, required this.onAddLesson});

  final List<Course> courses;
  final ValueChanged<Course> onAddLesson;

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.list_alt_rounded, size: 52, color: AppColors.muted),
              SizedBox(height: 14),
              Text(
                'No courses yet.',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Create a course first, then add lessons to it.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: courses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final course = courses[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.muted.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${course.lessonCount} lesson${course.lessonCount == 1 ? '' : 's'}  ·  Free Course',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => onAddLesson(course),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Lesson'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Tab: Resources ──────────────────────────────────────────────────────────

class _ResourcesTab extends StatelessWidget {
  const _ResourcesTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, size: 52, color: AppColors.muted),
            SizedBox(height: 14),
            Text(
              'Manage Resources',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Open a lesson inside a course to upload PDFs,\nnotes, and learning resources.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared small widgets ────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.isAcademic});

  final bool isAcademic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEDFFF5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Free by NGO',
        style: TextStyle(
          color: const Color(0xFF2FAE65),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isPublished});

  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPublished ? const Color(0xFFEDFFF5) : const Color(0xFFFFF5E5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isPublished
                  ? const Color(0xFF2FAE65)
                  : const Color(0xFFFF8A00),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isPublished ? 'Published' : 'Draft',
            style: TextStyle(
              color: isPublished
                  ? const Color(0xFF2FAE65)
                  : const Color(0xFFFF8A00),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SmallOutlinedButton extends StatelessWidget {
  const _SmallOutlinedButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        side: BorderSide(color: AppColors.muted.withValues(alpha: 0.3)),
        foregroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _PublishToggleButton extends StatelessWidget {
  const _PublishToggleButton({required this.isPublished, required this.onTap});

  final bool isPublished;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(
        isPublished ? Icons.visibility_off_rounded : Icons.publish_rounded,
        size: 15,
      ),
      label: Text(isPublished ? 'Unpublish' : 'Publish'),
      style: FilledButton.styleFrom(
        backgroundColor: isPublished
            ? AppColors.muted.withValues(alpha: 0.1)
            : const Color(0xFF2FAE65),
        foregroundColor: isPublished ? AppColors.muted : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Could not load courses.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
