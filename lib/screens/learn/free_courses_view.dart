import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/course.dart';
import '../../models/skill_category.dart';
import '../../viewmodels/learn_viewmodel.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/app_scroll_view.dart';
import 'course_detail_screen.dart';

class FreeCoursesView extends StatefulWidget {
  const FreeCoursesView({this.initialCategory, super.key});

  final SkillCategory? initialCategory;

  @override
  State<FreeCoursesView> createState() => _FreeCoursesViewState();
}

class _FreeCoursesViewState extends State<FreeCoursesView> {
  late final LearnViewModel _vm;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = LearnViewModel()..load(initialCategory: widget.initialCategory);
  }

  @override
  void dispose() {
    _search.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _vm,
    builder: (context, _) => AppScrollView(
      children: [
        _header(),
        _searchBar(),
        _filters(),
        if (_vm.state == ViewState.loading)
          const Padding(
            padding: EdgeInsets.all(42),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_vm.state == ViewState.error)
          _error()
        else ...[
          if (_vm.continueLearning.isNotEmpty) ...[
            _sectionTitle('Continue Learning'),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _vm.continueLearning.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(
                  width: 310,
                  child: _ContinueCard(
                    course: _vm.continueLearning[i],
                    onOpen: _open,
                  ),
                ),
              ),
            ),
          ],
          if (_vm.freeCourses.isNotEmpty) ...[
            _sectionTitle('Featured Course'),
            _FeaturedCourse(course: _vm.freeCourses.first, onOpen: _open),
            _sectionTitle('All Free Courses', count: _vm.freeCourses.length),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 920
                    ? 3
                    : constraints.maxWidth >= 620
                    ? 2
                    : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _vm.freeCourses.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: columns == 1 ? 1.55 : 1.08,
                  ),
                  itemBuilder: (_, i) => _FreeCourseCard(
                    course: _vm.freeCourses[i],
                    onOpen: _open,
                  ),
                );
              },
            ),
          ] else
            _empty(),
        ],
      ],
    ),
  );

  Widget _header() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text(
                  'Free Courses',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.volunteer_activism_rounded,
                  color: AppColors.secondary,
                  size: 25,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Free learning videos, notes, quizzes, and guidance by Punjabi Welfare Trust',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF2E7D32),
                    size: 15,
                  ),
                  SizedBox(width: 5),
                  Text(
                    '100% free NGO learning',
                    style: TextStyle(
                      color: Color(0xFF1B5E20),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      CircleAvatar(
        radius: 25,
        backgroundColor: const Color(0xFFDDEEFF),
        child: Text(
          (AppState.studentName ?? 'S').trim().characters.first.toUpperCase(),
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  );

  Widget _searchBar() => Container(
    height: 56,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.muted.withValues(alpha: .18)),
    ),
    child: TextField(
      controller: _search,
      onChanged: _vm.updateSearch,
      decoration: InputDecoration(
        hintText: 'Search courses, subjects, chapters, or lessons',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _search.clear();
                  _vm.updateSearch('');
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded),
              ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 17),
      ),
    ),
  );

  Widget _filters() => SizedBox(
    height: 46,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: freeCourseCategories.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final category = freeCourseCategories[i];
        return ChoiceChip(
          label: Text(category),
          selected: _vm.selectedFreeCategory == category,
          onSelected: (_) => _vm.selectFreeCategory(category),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: _vm.selectedFreeCategory == category
                ? Colors.white
                : AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
          backgroundColor: Colors.white,
          side: BorderSide(
            color: _vm.selectedFreeCategory == category
                ? AppColors.primary
                : AppColors.muted.withValues(alpha: .2),
          ),
        );
      },
    ),
  );

  Widget _sectionTitle(String title, {int? count}) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 10),
    child: Row(
      children: [
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
        if (count != null)
          Text(
            '$count courses',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    ),
  );

  Widget _error() => Center(
    child: Column(
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppColors.muted, size: 44),
        const SizedBox(height: 8),
        Text(_vm.errorMessage ?? 'Could not load courses.'),
        TextButton(onPressed: () => _vm.load(), child: const Text('Retry')),
      ],
    ),
  );

  Widget _empty() => Container(
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 42),
        const SizedBox(height: 10),
        const Text(
          'No free courses found',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900),
        ),
        TextButton(
          onPressed: () {
            _search.clear();
            _vm.clearFilters();
          },
          child: const Text('Clear search and filters'),
        ),
      ],
    ),
  );

  void _open(Course course) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course)));
}

class _FeaturedCourse extends StatelessWidget {
  const _FeaturedCourse({required this.course, required this.onOpen});
  final Course course;
  final ValueChanged<Course> onOpen;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        Container(
          width: 78,
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(course.icon, color: Colors.white, size: 40),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FEATURED FREE COURSE',
                style: TextStyle(
                  color: Color(0xFFB3E5FC),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                course.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${course.duration} • ${course.lessonCount} videos • ${course.level}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => onOpen(course),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
                child: Text(
                  course.progress > 0 ? 'Continue' : 'Start Learning',
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FreeCourseCard extends StatelessWidget {
  const _FreeCourseCard({required this.course, required this.onOpen});
  final Course course;
  final ValueChanged<Course> onOpen;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.muted.withValues(alpha: .14)),
      boxShadow: [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: .04),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: course.color,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(course.icon, color: AppColors.ink, size: 29),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _freeBadge(),
                  const SizedBox(height: 5),
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Created by: ${course.createdBy}',
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _meta(
              Icons.play_circle_outline_rounded,
              '${course.lessonCount} videos',
            ),
            if (course.hasNotes)
              _meta(Icons.picture_as_pdf_outlined, 'Notes PDF'),
            if (course.hasQuiz) _meta(Icons.quiz_outlined, 'Practice quiz'),
            _meta(Icons.schedule_rounded, course.duration),
          ],
        ),
        const Spacer(),
        if (course.progress > 0) ...[
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: course.progress,
                    minHeight: 7,
                    backgroundColor: AppColors.background,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(course.progress * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => onOpen(course),
            child: Text(course.progress > 0 ? 'Continue' : 'Start Learning'),
          ),
        ),
      ],
    ),
  );

  Widget _freeBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Text(
      'FREE BY NGO',
      style: TextStyle(
        color: Color(0xFF2E7D32),
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
    ),
  );

  Widget _meta(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AppColors.primary),
      const SizedBox(width: 3),
      Text(
        label,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.course, required this.onOpen});
  final Course course;
  final ValueChanged<Course> onOpen;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.secondary.withValues(alpha: .24)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(course.icon, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                course.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          '${(course.progress * 100).round()}% complete',
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        LinearProgressIndicator(
          value: course.progress,
          minHeight: 7,
          borderRadius: BorderRadius.circular(8),
          color: AppColors.secondary,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: () => onOpen(course),
            child: const Text('Continue'),
          ),
        ),
      ],
    ),
  );
}
