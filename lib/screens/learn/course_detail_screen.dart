import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/course.dart';
import '../../models/lesson.dart';
import '../../repositories/course_repository.dart';
import '../../viewmodels/view_state.dart';
import 'admin/create_lesson_screen.dart';
import 'lesson_viewer_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({required this.course, super.key});

  final Course course;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  ViewState _state = ViewState.loading;
  List<Lesson> _lessons = [];
  double _progress = 0;
  String? _error;
  bool _canManage = false;

  @override
  void initState() {
    super.initState();
    _progress = widget.course.progress;
    final role = AppState.role;
    _canManage =
        role.isAdmin || role.isMentor || role.isContentCreator;
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() {
      _state = ViewState.loading;
      _error = null;
    });
    try {
      final lessons = await CourseRepository.getLessons(widget.course.id);
      if (mounted) {
        setState(() {
          _lessons = lessons;
          _state = ViewState.idle;
          _progress = _computeProgress(lessons);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _state = ViewState.error;
          _error = 'Failed to load lessons.';
        });
      }
    }
  }

  double _computeProgress(List<Lesson> lessons) {
    if (lessons.isEmpty) return widget.course.progress;
    final done = lessons.where((l) => l.completed).length;
    return done / lessons.length;
  }

  Future<void> _openLesson(Lesson lesson) async {
    final didComplete = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LessonViewerScreen(
          lesson: lesson,
          courseId: widget.course.id,
        ),
      ),
    );
    if (didComplete == true && !lesson.completed) {
      setState(() {
        final idx = _lessons.indexWhere((l) => l.id == lesson.id);
        if (idx != -1) _lessons[idx] = _lessons[idx].copyWith(completed: true);
        _progress = _computeProgress(_lessons);
      });
    }
  }

  Future<void> _openCreateLesson() async {
    final created = await Navigator.of(context).push<Lesson>(
      MaterialPageRoute(
        builder: (_) => CreateLessonScreen(
          courseId: widget.course.id,
          nextOrder: _lessons.length,
        ),
      ),
    );
    if (created != null) {
      setState(() => _lessons.add(created));
    }
  }

  Future<void> _confirmDeleteLesson(Lesson lesson) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text(
            'Delete "${lesson.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.softRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await CourseRepository.deleteLesson(widget.course.id, lesson.id);
      setState(() {
        _lessons.removeWhere((l) => l.id == lesson.id);
        _progress = _computeProgress(_lessons);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete lesson.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: course.color,
            foregroundColor: AppColors.ink,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 56, vertical: 14),
              title: Text(
                course.title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Center(
                child: Icon(
                  course.icon,
                  size: 72,
                  color: AppColors.ink.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      _StatChip(
                          course.level, Icons.bar_chart_rounded),
                      _StatChip(
                          course.duration, Icons.timer_outlined),
                      _StatChip(
                          '${_lessons.length} lessons',
                          Icons.menu_book_rounded),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 10,
                            backgroundColor:
                                AppColors.muted.withValues(alpha: 0.15),
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(_progress * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Lessons',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (_state == ViewState.loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_state == ViewState.error)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error ?? 'Error',
                        style:
                            const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 8),
                    TextButton(
                        onPressed: _loadLessons,
                        child: const Text('Retry')),
                  ],
                ),
              ),
            )
          else if (_lessons.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_outlined,
                        size: 48,
                        color: AppColors.muted.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    const Text(
                      'No lessons yet.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    if (_canManage) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _openCreateLesson,
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Lesson'),
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _LessonTile(
                  lesson: _lessons[i],
                  index: i,
                  onTap: () => _openLesson(_lessons[i]),
                  onDelete: _canManage
                      ? () => _confirmDeleteLesson(_lessons[i])
                      : null,
                ),
                childCount: _lessons.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: _canManage
          ? FloatingActionButton(
              heroTag: 'add_lesson_fab',
              backgroundColor: AppColors.primary,
              onPressed: _openCreateLesson,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.label, this.icon);

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.muted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.muted),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.index,
    required this.onTap,
    this.onDelete,
  });

  final Lesson lesson;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: lesson.completed
                ? AppColors.secondary.withValues(alpha: 0.4)
                : AppColors.muted.withValues(alpha: 0.15),
          ),
        ),
        color: lesson.completed
            ? AppColors.secondary.withValues(alpha: 0.06)
            : Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: lesson.completed
                        ? AppColors.secondary
                        : AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: lesson.completed
                      ? const Icon(Icons.check_rounded,
                          size: 18, color: Colors.white)
                      : Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: lesson.completed
                              ? AppColors.muted
                              : AppColors.ink,
                          decoration: lesson.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (lesson.durationLabel.isNotEmpty ||
                          lesson.contentType == 'video') ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (lesson.contentType == 'video')
                              _TypeBadge(
                                  Icons.play_circle_outlined, 'Video'),
                            if (lesson.contentType == 'text')
                              _TypeBadge(Icons.article_outlined, 'Text'),
                            if (lesson.durationLabel.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                lesson.durationLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18),
                    color: AppColors.softRed,
                    onPressed: onDelete,
                    tooltip: 'Delete lesson',
                  )
                else
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.muted),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }
}
