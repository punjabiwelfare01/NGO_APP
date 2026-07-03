import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/course.dart';
import '../../models/learning_resource.dart';
import '../../models/lesson.dart';
import '../../repositories/course_repository.dart';
import '../../viewmodels/view_state.dart';
import 'admin/create_lesson_screen.dart';
import 'widgets/learning_resource_tools.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({required this.course, super.key});

  final Course course;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  ViewState _state = ViewState.loading;
  List<Lesson> _lessons = [];
  Map<int, List<LearningResource>> _resourcesByLesson = {};
  String _filter = 'all';
  double _progress = 0;
  String? _error;
  late final bool _canManage;
  late Course _course;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _progress = widget.course.progress;
    final role = AppState.role;
    _canManage = role.isAdmin || role.isMentor || role.isContentCreator;
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() {
      _state = ViewState.loading;
      _error = null;
    });
    try {
      final lessons = await CourseRepository.getLessons(widget.course.id);
      final resourceEntries = await Future.wait(
        lessons.map((lesson) async {
          final resources = await CourseRepository.getResources(
            widget.course.id,
            lesson.id,
          );
          return MapEntry(lesson.id, resources);
        }),
      );
      if (mounted) {
        setState(() {
          _lessons = lessons;
          _resourcesByLesson = Map.fromEntries(resourceEntries);
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
    final done = lessons.where((lesson) => lesson.completed).length;
    return done / lessons.length;
  }

  List<Lesson> get _filteredLessons {
    return _lessons.where((lesson) {
      final resources = _resourcesByLesson[lesson.id] ?? const [];
      return switch (_filter) {
        'video' =>
          lesson.contentType == 'video' ||
              lesson.contentType == 'mixed' ||
              resources.any((r) => r.type == 'video'),
        'text' =>
          lesson.contentType == 'text' ||
              lesson.contentType == 'mixed' ||
              (lesson.contentText?.trim().isNotEmpty ?? false),
        'pdf' => resources.any((r) => r.type == 'pdf' || r.type == 'pdf_notes'),
        'completed' => lesson.completed,
        'pending' => !lesson.completed,
        _ => true,
      };
    }).toList();
  }

  String? get _previewVideoUrl {
    for (final lesson in _lessons) {
      if ((lesson.contentType == 'video' || lesson.contentType == 'mixed') &&
          lesson.contentUrl != null &&
          lesson.contentUrl!.trim().isNotEmpty) {
        return lesson.contentUrl;
      }
      final videoResource = (_resourcesByLesson[lesson.id] ?? const [])
          .where((resource) => resource.type == 'video')
          .firstOrNull;
      if (videoResource?.fileUrl != null) return videoResource!.fileUrl;
    }
    return null;
  }

  Future<void> _openCreateLesson() async {
    final created = await Navigator.of(context).push<Lesson>(
      MaterialPageRoute(
        builder: (_) => CreateLessonScreen(
          courseId: _course.id,
          courseType: CourseType.skill,
          subject: _course.subjects.firstOrNull ?? _course.subject,
          nextOrder: _lessons.length,
        ),
      ),
    );
    if (created != null) await _loadLessons();
  }

  Future<void> _openEditSalesInfo() async {
    final updated = await showDialog<Course>(
      context: context,
      builder: (_) => _EditSalesInfoDialog(course: _course),
    );
    if (updated != null && mounted) {
      setState(() => _course = updated);
    }
  }

  Future<void> _markComplete(Lesson lesson) async {
    if (lesson.completed) return;
    try {
      await CourseRepository.markLessonComplete(widget.course.id, lesson.id);
      if (!mounted) return;
      setState(() {
        final index = _lessons.indexWhere((item) => item.id == lesson.id);
        if (index != -1) {
          _lessons[index] = _lessons[index].copyWith(completed: true);
          _progress = _computeProgress(_lessons);
        }
      });
      final next = _nextLessonAfter(lesson);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next == null
                ? 'Course completed.'
                : 'Lesson completed successfully. Next: ${next.title}',
          ),
          backgroundColor: AppColors.secondary,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save progress. Try again.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }

  Lesson? _nextLessonAfter(Lesson lesson) {
    final index = _lessons.indexWhere((item) => item.id == lesson.id);
    if (index == -1 || index + 1 >= _lessons.length) return null;
    return _lessons[index + 1];
  }

  Future<void> _confirmDeleteLesson(Lesson lesson) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text('Delete "${lesson.title}"? This cannot be undone.'),
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
      await _loadLessons();
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
    final filteredLessons = _filteredLessons;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        title: Text(
          _course.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: [
          if (_canManage) ...[
            IconButton(
              onPressed: _openEditSalesInfo,
              icon: const Icon(Icons.edit_note_rounded),
              tooltip: 'Edit course info',
            ),
            IconButton(
              onPressed: _openCreateLesson,
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add lesson',
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLessons,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            _CourseHeader(
              course: _course,
              progress: _progress,
              lessonCount: _lessons.length,
              onContinue: () {},
            ),
            _PreviewPanel(
              course: _course,
              lessons: _lessons,
              resourcesByLesson: _resourcesByLesson,
              videoUrl: _previewVideoUrl,
            ),
            const SizedBox(height: 18),
            _FilterBar(
              selected: _filter,
              onChanged: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 10),
            if (_state == ViewState.loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_state == ViewState.error)
              _InlineState(
                icon: Icons.cloud_off_rounded,
                text: _error ?? 'Failed to load lessons.',
                action: TextButton(
                  onPressed: _loadLessons,
                  child: const Text('Retry'),
                ),
              )
            else if (_lessons.isEmpty)
              _InlineState(
                icon: Icons.menu_book_outlined,
                text: _canManage
                    ? 'No lessons added yet.'
                    : 'Lessons will be available soon.',
                action: _canManage
                    ? FilledButton.icon(
                        onPressed: _openCreateLesson,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Lesson'),
                      )
                    : null,
              )
            else if (filteredLessons.isEmpty)
              const _InlineState(
                icon: Icons.filter_alt_off_rounded,
                text: 'No lessons match this filter.',
              )
            else
              ..._groupedLessonWidgets(filteredLessons),
            if (_lessons.isNotEmpty &&
                _lessons.every((lesson) => lesson.completed)) ...[
              const SizedBox(height: 12),
              const _InlineState(
                icon: Icons.workspace_premium_rounded,
                text:
                    'Course completed. You have completed all lessons in this course.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<LearningResource> _visibleResourcesFor(Lesson lesson) {
    final resources = _resourcesByLesson[lesson.id] ?? const [];
    return resources.where((resource) {
      final isLegacyOutcomeNote =
          resource.type == 'note' &&
          resource.title.trim().toLowerCase() == 'text notes' &&
          (resource.textContent?.trim() == lesson.contentText?.trim());
      return !isLegacyOutcomeNote;
    }).toList();
  }

  List<Widget> _groupedLessonWidgets(List<Lesson> lessons) {
    final subjects = <String, Map<String, List<Lesson>>>{};
    for (final lesson in lessons) {
      final subject = lesson.subject?.trim().isNotEmpty == true
          ? lesson.subject!.trim()
          : (_course.subject?.trim().isNotEmpty == true
                ? _course.subject!.trim()
                : 'Course Content');
      final chapter = lesson.chapter?.trim().isNotEmpty == true
          ? lesson.chapter!.trim()
          : 'Core Lessons';
      subjects.putIfAbsent(subject, () => {});
      subjects[subject]!.putIfAbsent(chapter, () => []).add(lesson);
    }
    return [
      for (final subject in subjects.entries) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
          child: Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  subject.key,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final chapter in subject.value.entries) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              chapter.key,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          for (final lesson in chapter.value)
            _LessonExpansionCard(
              courseId: _course.id,
              lesson: lesson,
              index: _lessons.indexWhere((item) => item.id == lesson.id),
              resources: _visibleResourcesFor(lesson),
              nextLesson: _nextLessonAfter(lesson),
              canManage: _canManage,
              onComplete: () => _markComplete(lesson),
              onDelete: () => _confirmDeleteLesson(lesson),
            ),
        ],
      ],
    ];
  }
}

class _CourseHeader extends StatelessWidget {
  const _CourseHeader({
    required this.course,
    required this.progress,
    required this.lessonCount,
    required this.onContinue,
  });

  final Course course;
  final double progress;
  final int lessonCount;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: course.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(course.icon, color: AppColors.ink, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.courseDescription?.trim().isNotEmpty == true
                          ? course.courseDescription!.trim()
                          : 'Learn ${course.title.toLowerCase()} step by step.',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip(course.level, Icons.bar_chart_rounded),
              _StatChip(course.duration, Icons.timer_outlined),
              _StatChip('$lessonCount lessons', Icons.menu_book_rounded),
              if (course.isAcademic && course.classLevel != null)
                _StatChip('Class ${course.classLevel}', Icons.school_outlined),
              if (course.isAcademic && course.subject != null)
                _StatChip(course.subject!, Icons.category_outlined),
              if (course.isSkill && course.skillCategory != null)
                _StatChip(
                  course.skillCategory!,
                  Icons.workspace_premium_outlined,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: AppColors.muted.withValues(alpha: 0.15),
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Progress: ${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.course,
    required this.lessons,
    required this.resourcesByLesson,
    this.videoUrl,
  });

  final Course course;
  final List<Lesson> lessons;
  final Map<int, List<LearningResource>> resourcesByLesson;
  final String? videoUrl;

  List<String> get _learnItems {
    if (course.learnItems != null && course.learnItems!.isNotEmpty) {
      return course.learnItems!;
    }
    final items = <String>[];
    for (final lesson in lessons) {
      final title = lesson.title.trim();
      if (title.isNotEmpty) items.add(title);
      if (items.length >= 4) break;
    }
    if (items.isNotEmpty) return items;
    return [
      'Build confidence with ${course.title.toLowerCase()}',
      'Follow short lessons with guided practice',
      'Use notes and resources for revision',
    ];
  }

  List<String> get _skillItems {
    if (course.skillTags != null && course.skillTags!.isNotEmpty) {
      return course.skillTags!;
    }
    final hasVideo = lessons.any(
      (lesson) =>
          lesson.contentType == 'video' || lesson.contentType == 'mixed',
    );
    final hasPdf = resourcesByLesson.values.any(
      (resources) => resources.any(
        (resource) => resource.type == 'pdf' || resource.type == 'pdf_notes',
      ),
    );
    final hasNotes = resourcesByLesson.values.any(
      (resources) => resources.any((resource) => resource.type == 'note'),
    );
    return [
      course.level,
      if (hasVideo) 'Video learning',
      if (hasPdf) 'PDF notes',
      if (hasNotes) 'Revision notes',
      'Practice ready',
    ];
  }

  String get _courseContent {
    if (course.courseDescription != null &&
        course.courseDescription!.trim().isNotEmpty) {
      return course.courseDescription!.trim();
    }
    for (final lesson in lessons) {
      final content = lesson.contentText?.trim();
      if (content != null && content.isNotEmpty) {
        return content.length > 180
            ? '${content.substring(0, 180)}...'
            : content;
      }
      final description = lesson.description?.trim();
      if (description != null && description.isNotEmpty) {
        return description.length > 180
            ? '${description.substring(0, 180)}...'
            : description;
      }
    }
    return 'Start with the course preview, then move through each lesson, resource, and downloadable note in order.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Course Preview',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final video = videoUrl == null
                  ? const _InlineState(
                      icon: Icons.play_disabled_outlined,
                      text: 'No course preview video available.',
                    )
                  : LessonVideoContent(url: videoUrl, maxHeight: 420);
              final summary = _CourseSalesSummary(
                learnItems: _learnItems,
                skillItems: _skillItems,
                courseContent: _courseContent,
              );

              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [video, const SizedBox(height: 16), summary],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(flex: 4, fit: FlexFit.loose, child: video),
                  const SizedBox(width: 20),
                  Expanded(flex: 5, child: summary),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CourseSalesSummary extends StatelessWidget {
  const _CourseSalesSummary({
    required this.learnItems,
    required this.skillItems,
    required this.courseContent,
  });

  final List<String> learnItems;
  final List<String> skillItems;
  final String courseContent;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What you will learn',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...learnItems.map((item) => _SummaryBullet(item)),
          const SizedBox(height: 16),
          const Text(
            'Skills covered',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skillItems
                .map(
                  (skill) => Chip(
                    label: Text(skill),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.18),
                    ),
                    labelStyle: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Course content',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            courseContent,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBullet extends StatelessWidget {
  const _SummaryBullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 17,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  static const _filters = [
    ('all', 'All'),
    ('video', 'Video'),
    ('text', 'Text'),
    ('pdf', 'PDF'),
    ('completed', 'Completed'),
    ('pending', 'Pending'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final active = selected == filter.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter.$2),
              selected: active,
              onSelected: (_) => onChanged(filter.$1),
              selectedColor: AppColors.mint,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: active
                    ? AppColors.secondary
                    : AppColors.muted.withValues(alpha: 0.12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LessonExpansionCard extends StatelessWidget {
  const _LessonExpansionCard({
    required this.courseId,
    required this.lesson,
    required this.index,
    required this.resources,
    required this.canManage,
    required this.onComplete,
    required this.onDelete,
    this.nextLesson,
  });

  final int courseId;
  final Lesson lesson;
  final int index;
  final List<LearningResource> resources;
  final Lesson? nextLesson;
  final bool canManage;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  bool get _hasVideo =>
      (lesson.contentType == 'video' || lesson.contentType == 'mixed') &&
      lesson.contentUrl != null &&
      lesson.contentUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: lesson.completed
              ? AppColors.secondary.withValues(alpha: 0.35)
              : AppColors.muted.withValues(alpha: 0.12),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        leading: CircleAvatar(
          backgroundColor: lesson.completed
              ? AppColors.secondary
              : AppColors.primary.withValues(alpha: 0.1),
          child: lesson.completed
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
              : Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        title: Text(
          lesson.title,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          '${_typeLabel(lesson.contentType)}'
          '${lesson.durationLabel.isEmpty ? '' : ' • ${lesson.durationLabel}'}'
          ' • ${lesson.completed ? 'Completed' : 'Pending'}',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        trailing: canManage
            ? IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.softRed,
                tooltip: 'Delete lesson',
              )
            : null,
        children: [
          if (lesson.description != null &&
              lesson.description!.trim().isNotEmpty) ...[
            _BlockTitle('Description'),
            LessonTextContent(text: lesson.description),
            const SizedBox(height: 12),
          ],
          _BlockTitle('Video'),
          if (_hasVideo)
            LessonVideoContent(url: lesson.contentUrl)
          else
            const _InlineState(
              icon: Icons.play_disabled_outlined,
              text: 'No video available for this lesson.',
            ),
          const SizedBox(height: 12),
          _BlockTitle('Notes & Resources'),
          if (resources.isEmpty)
            const _InlineState(
              icon: Icons.attach_file_rounded,
              text: 'No notes or resources available for this lesson.',
            )
          else
            ...resources.map(
              (resource) => LearningResourceTile(resource: resource),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: lesson.completed ? null : onComplete,
                  icon: Icon(
                    lesson.completed
                        ? Icons.check_circle_rounded
                        : Icons.check_rounded,
                  ),
                  label: Text(
                    lesson.completed ? 'Completed' : 'Mark as Complete',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: lesson.completed
                        ? AppColors.secondary
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (nextLesson != null && lesson.completed) ...[
            const SizedBox(height: 10),
            Text(
              'Next: ${nextLesson!.title}',
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _typeLabel(String type) => switch (type) {
    'video' => 'Video',
    'mixed' => 'Video + Notes',
    'pdf' => 'PDF',
    _ => 'Text',
  };
}

class _BlockTitle extends StatelessWidget {
  const _BlockTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InlineState extends StatelessWidget {
  const _InlineState({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.muted, size: 34),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          if (action != null) ...[const SizedBox(height: 10), action!],
        ],
      ),
    );
  }
}

// ── Admin: Edit Sales/Preview Info Dialog ──────────────────────────────────────

class _EditSalesInfoDialog extends StatefulWidget {
  const _EditSalesInfoDialog({required this.course});

  final Course course;

  @override
  State<_EditSalesInfoDialog> createState() => _EditSalesInfoDialogState();
}

class _EditSalesInfoDialogState extends State<_EditSalesInfoDialog> {
  late List<TextEditingController> _learnControllers;
  late List<TextEditingController> _skillControllers;
  late TextEditingController _descController;
  late TextEditingController _offerPriceController;
  late TextEditingController _originalPriceController;
  late TextEditingController _offerLabelController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _learnControllers = (c.learnItems ?? [])
        .map((item) => TextEditingController(text: item))
        .toList();
    _skillControllers = (c.skillTags ?? [])
        .map((tag) => TextEditingController(text: tag))
        .toList();
    _descController = TextEditingController(text: c.courseDescription ?? '');
    _offerPriceController = TextEditingController(
      text: c.offerPrice?.toString() ?? '',
    );
    _originalPriceController = TextEditingController(
      text: c.originalPrice?.toString() ?? '',
    );
    _offerLabelController = TextEditingController(text: c.offerLabel ?? '');
  }

  @override
  void dispose() {
    for (final ctrl in [..._learnControllers, ..._skillControllers]) {
      ctrl.dispose();
    }
    _descController.dispose();
    _offerPriceController.dispose();
    _originalPriceController.dispose();
    _offerLabelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final learnItems = _learnControllers
          .map((ctrl) => ctrl.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final skillTags = _skillControllers
          .map((ctrl) => ctrl.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final offerPrice = int.tryParse(_offerPriceController.text.trim());
      final originalPrice = int.tryParse(_originalPriceController.text.trim());
      final offerLabel = _offerLabelController.text.trim();
      final desc = _descController.text.trim();

      final updated = await CourseRepository.updateCourseSalesInfo(
        widget.course.id,
        learnItems: learnItems.isEmpty ? null : learnItems,
        skillTags: skillTags.isEmpty ? null : skillTags,
        courseDescription: desc.isEmpty ? null : desc,
        offerPrice: offerPrice,
        originalPrice: originalPrice,
        offerLabel: offerLabel.isEmpty ? null : offerLabel,
      );
      if (mounted) Navigator.of(context).pop(updated);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save. Try again.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Edit Course Info',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              _SectionLabel('What you will learn'),
              const SizedBox(height: 8),
              ..._learnControllers.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: entry.value,
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () =>
                              FocusScope.of(context).nextFocus(),
                          decoration: _fieldDecoration('Item ${entry.key + 1}'),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(
                          () => _learnControllers.removeAt(entry.key),
                        ),
                        icon: const Icon(
                          Icons.remove_circle_outline_rounded,
                          color: AppColors.softRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(
                  () => _learnControllers.add(TextEditingController()),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add item'),
              ),
              const SizedBox(height: 16),

              _SectionLabel('Skills covered'),
              const SizedBox(height: 8),
              ..._skillControllers.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: entry.value,
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () =>
                              FocusScope.of(context).nextFocus(),
                          decoration: _fieldDecoration(
                            'Skill ${entry.key + 1}',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(
                          () => _skillControllers.removeAt(entry.key),
                        ),
                        icon: const Icon(
                          Icons.remove_circle_outline_rounded,
                          color: AppColors.softRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(
                  () => _skillControllers.add(TextEditingController()),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add skill'),
              ),
              const SizedBox(height: 16),

              _SectionLabel('Course content description'),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: _fieldDecoration('Describe what students will do…'),
              ),
              const SizedBox(height: 16),

              _SectionLabel('Pricing'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _offerPriceController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                      decoration: _fieldDecoration('Offer price (₹)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _originalPriceController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                      decoration: _fieldDecoration('Original price (₹)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _offerLabelController,
                decoration: _fieldDecoration(
                  'Offer label (e.g. Save 60% · videos, PDFs)',
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.muted),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.2)),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

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
