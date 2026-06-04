import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/course.dart';
import '../../models/skill_category.dart';
import '../../repositories/course_repository.dart';
import '../../viewmodels/learn_viewmodel.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/app_scroll_view.dart';
import '../../widgets/filter_chip_label.dart';
import '../../widgets/search_box.dart';
import '../../widgets/top_header.dart';
import 'admin/create_course_screen.dart';
import 'admin/manage_skill_categories_screen.dart';
import 'widgets/course_card.dart';

class LearnView extends StatefulWidget {
  const LearnView({this.initialCategory, super.key});

  final SkillCategory? initialCategory;

  @override
  State<LearnView> createState() => _LearnViewState();
}

class _LearnViewState extends State<LearnView> {
  late final LearnViewModel _vm;
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _vm = LearnViewModel();
    _searchCtrl = TextEditingController();
    _vm.load(initialCategory: widget.initialCategory);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = AppState.role;
    final canManage = role.isAdmin || role.isMentor || role.isContentCreator;
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final selected = _vm.selectedCategory ?? widget.initialCategory;
        return AppScrollView(
          children: [
            TopHeader(
              title: selected?.title ?? 'Skill Courses',
              subtitle: selected == null
                  ? 'Build confidence one tiny win at a time.'
                  : 'Courses and lessons filtered for this skill.',
              actionIcon: Icons.school_rounded,
            ),
            SearchBox(
              hint: 'Search skills or lessons...',
              controller: _searchCtrl,
              onChanged: _vm.updateSearch,
              suffixIcon: _vm.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchCtrl.clear();
                        _vm.updateSearch('');
                      },
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Clear search',
                    ),
            ),
            _CategoryFilters(
              categories: _vm.categories,
              selected: selected,
              onSelect: _vm.selectCategory,
            ),
            if (canManage) ...[
              _SkillAdminActions(
                onManageSkills: _openManageSkills,
                onAddCourse: _openCreateCourse,
              ),
              const SizedBox(height: 6),
            ],
            if (selected != null) _SelectedSkillPanel(category: selected),
            const SizedBox(height: 4),
            if (_vm.state == ViewState.loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_vm.state == ViewState.error)
              Center(
                child: Column(
                  children: [
                    Text(
                      _vm.errorMessage ?? 'Error',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () =>
                          _vm.load(initialCategory: widget.initialCategory),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_vm.courses.isEmpty)
              _NoLessonsState(
                selected: selected,
                relatedCategories: _vm.relatedCategories,
                onClear: () {
                  _searchCtrl.clear();
                  _vm.clearFilters();
                },
                onSelectRelated: (category) {
                  _searchCtrl.clear();
                  _vm.updateSearch('');
                  _vm.selectCategory(category);
                },
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 6),
                    child: Text(
                      selected == null
                          ? 'All Skill Lessons'
                          : '${selected.title} Lessons',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  ..._vm.courses.map(
                    (course) => CourseCard(
                      course: course,
                      onEdit: canManage ? () => _openEditCourse(course) : null,
                      onDelete: canManage ? () => _deleteCourse(course) : null,
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Future<void> _openManageSkills() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ManageSkillCategoriesScreen()),
    );
    await _vm.load(initialCategory: widget.initialCategory);
  }

  Future<void> _openCreateCourse() async {
    final created = await Navigator.of(context).push<Course>(
      MaterialPageRoute(builder: (_) => const CreateCourseScreen()),
    );
    if (created != null) {
      await _vm.load(initialCategory: _vm.selectedCategory);
    }
  }

  Future<void> _openEditCourse(Course course) async {
    final updated = await Navigator.of(context).push<Course>(
      MaterialPageRoute(
        builder: (_) => CreateCourseScreen(initialCourse: course),
      ),
    );
    if (updated != null) {
      await _vm.load(initialCategory: _vm.selectedCategory);
    }
  }

  Future<void> _deleteCourse(Course course) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Delete "${course.title}" and its lessons?'),
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
      await _vm.load(initialCategory: _vm.selectedCategory);
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
}

class _SkillAdminActions extends StatelessWidget {
  const _SkillAdminActions({
    required this.onManageSkills,
    required this.onAddCourse,
  });

  final VoidCallback onManageSkills;
  final VoidCallback onAddCourse;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: onManageSkills,
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Manage Skills'),
        ),
        FilledButton.icon(
          onPressed: onAddCourse,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Course'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
        ),
      ],
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<SkillCategory> categories;
  final SkillCategory? selected;
  final ValueChanged<SkillCategory?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilterChipLabel(
          label: 'All',
          selected: selected == null,
          onTap: () => onSelect(null),
        ),
        ...categories.map(
          (category) => FilterChipLabel(
            label: category.title,
            selected:
                selected != null &&
                _skillKey(selected!.title) == _skillKey(category.title),
            onTap: () => onSelect(category),
          ),
        ),
      ],
    );
  }

  String _skillKey(String value) => value
      .toLowerCase()
      .replaceAll('skills', '')
      .replaceAll('skill', '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

class _SelectedSkillPanel extends StatelessWidget {
  const _SelectedSkillPanel({required this.category});

  final SkillCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: category.color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(category.icon, color: AppColors.ink, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category.title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Icon(Icons.arrow_downward_rounded, color: AppColors.ink),
        ],
      ),
    );
  }
}

class _NoLessonsState extends StatelessWidget {
  const _NoLessonsState({
    required this.selected,
    required this.relatedCategories,
    required this.onClear,
    required this.onSelectRelated,
  });

  final SkillCategory? selected;
  final List<SkillCategory> relatedCategories;
  final VoidCallback onClear;
  final ValueChanged<SkillCategory> onSelectRelated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.menu_book_outlined,
            color: AppColors.muted.withValues(alpha: 0.65),
            size: 38,
          ),
          const SizedBox(height: 12),
          Text(
            selected == null
                ? 'No result found.'
                : 'No lessons available for ${selected!.title}.',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off_rounded),
            label: const Text('Clear Filter'),
          ),
          if (relatedCategories.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: relatedCategories
                  .map(
                    (category) => FilterChipLabel(
                      label: category.title,
                      onTap: () => onSelectRelated(category),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
