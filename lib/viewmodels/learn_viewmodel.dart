import 'package:flutter/foundation.dart';

import '../app_state.dart';
import '../models/course.dart';
import '../models/skill_category.dart';
import '../repositories/course_repository.dart';
import 'view_state.dart';

class LearnViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  List<Course> _allCourses = [];
  List<Course> _courses = [];
  List<SkillCategory> _categories = skillCategories;
  SkillCategory? _selectedCategory;
  String _searchQuery = '';
  bool _disposed = false;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  List<Course> get courses => _courses;
  List<SkillCategory> get categories => _categories;
  SkillCategory? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get hasActiveFilters =>
      _selectedCategory != null || _searchQuery.trim().isNotEmpty;

  List<SkillCategory> get relatedCategories {
    final selectedKey = _selectedCategory == null
        ? null
        : _primarySkillKey(_selectedCategory!.title);
    return _categories
        .where((category) => _primarySkillKey(category.title) != selectedKey)
        .take(3)
        .toList();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load({SkillCategory? initialCategory}) async {
    _state = ViewState.loading;
    _errorMessage = null;
    if (initialCategory != null) {
      _selectedCategory = initialCategory;
    }
    notifyListeners();
    try {
      final results = await Future.wait([
        CourseRepository.getCategories(),
        CourseRepository.getUserCourses(AppState.userId),
      ]);
      _categories = _mergeCoreSkillCategories(
        results[0] as List<SkillCategory>,
      );
      if (initialCategory != null) {
        _selectedCategory = _resolveCategory(initialCategory);
      }
      _allCourses = results[1] as List<Course>;
      _applyFilters();
      _state = ViewState.idle;
    } catch (_) {
      _state = ViewState.error;
      _errorMessage = 'Failed to load skill lessons.';
    }
    if (!_disposed) notifyListeners();
  }

  void updateSearch(String value) {
    _searchQuery = value.trim();
    _applyFilters();
    if (!_disposed) notifyListeners();
  }

  void selectCategory(SkillCategory? category) {
    _selectedCategory = category == null ? null : _resolveCategory(category);
    _applyFilters();
    if (!_disposed) notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = null;
    _searchQuery = '';
    _applyFilters();
    if (!_disposed) notifyListeners();
  }

  void _applyFilters() {
    final query = _searchQuery.toLowerCase();
    _courses = _allCourses.where((course) {
      final matchesCategory = _matchesSelectedCategory(course);
      final matchesSearch =
          query.isEmpty || _courseSearchText(course).contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  bool _matchesSelectedCategory(Course course) {
    final selected = _selectedCategory;
    if (selected == null) return true;

    // When the selected category has a real DB ID, use strict ID matching only.
    // Text-based fallback must not run here — it causes "literacy" in
    // "Financial Literacy" to match courses filed under "Digital Literacy".
    if (selected.id != 0) {
      return course.categoryId == selected.id;
    }

    // Fallback: text-keyword matching for categories whose IDs aren't resolved yet.
    final categoryTitle = _categories
        .where(
          (category) => category.id != 0 && category.id == course.categoryId,
        )
        .map((category) => category.title)
        .firstOrNull;
    final haystack = '${course.title} ${categoryTitle ?? ''}'.toLowerCase();
    return _keywordsForSkill(
      selected.title,
    ).any((keyword) => haystack.contains(keyword));
  }

  String _courseSearchText(Course course) {
    final categoryTitle = _categories
        .where(
          (category) => category.id != 0 && category.id == course.categoryId,
        )
        .map((category) => category.title)
        .firstOrNull;
    return [
      course.title,
      course.level,
      course.duration,
      ?categoryTitle,
    ].join(' ').toLowerCase();
  }

  SkillCategory _resolveCategory(SkillCategory category) {
    return _categories.firstWhere(
      (item) => _skillsMatch(item.title, category.title),
      orElse: () => category,
    );
  }

  List<SkillCategory> _mergeCoreSkillCategories(
    List<SkillCategory> apiCategories,
  ) {
    final merged = [...skillCategories];
    for (final apiCategory in apiCategories) {
      final index = merged.indexWhere(
        (coreCategory) => _skillsMatch(coreCategory.title, apiCategory.title),
      );
      if (index != -1) {
        final core = merged[index];
        merged[index] = SkillCategory(
          core.title,
          core.icon,
          core.color,
          id: apiCategory.id,
        );
        continue;
      }
      final isDuplicate = merged.any(
        (category) => _skillsMatch(category.title, apiCategory.title),
      );
      if (!isDuplicate) merged.add(apiCategory);
    }
    return merged;
  }

  bool _skillsMatch(String left, String right) {
    final leftKeys = _keywordsForSkill(left).toSet();
    final rightKeys = _keywordsForSkill(right).toSet();
    return leftKeys.intersection(rightKeys).isNotEmpty ||
        _skillKey(left) == _skillKey(right);
  }

  List<String> _keywordsForSkill(String title) {
    final lower = title.toLowerCase();
    final keys = <String>{_skillKey(title), ...lower.split(RegExp(r'\s+'))};
    if (lower.contains('communication') ||
        lower.contains('speak') ||
        lower.contains('public')) {
      keys.addAll(['communication', 'speak', 'speaking', 'confidence']);
    }
    if (lower.contains('digital') ||
        lower.contains('coding') ||
        lower.contains('computer') ||
        lower.contains('web')) {
      keys.addAll(['digital', 'coding', 'code', 'computer', 'web', 'internet']);
    }
    if (lower.contains('career') ||
        lower.contains('job') ||
        lower.contains('interview')) {
      keys.addAll(['career', 'job', 'interview', 'resume', 'work']);
    }
    if (lower.contains('safety') ||
        lower.contains('cyber') ||
        lower.contains('security')) {
      keys.addAll(['safety', 'safe', 'cyber', 'security', 'internet']);
    }
    if (lower.contains('financial') ||
        lower.contains('finance') ||
        lower.contains('money')) {
      keys.addAll(['financial', 'finance', 'money', 'bank', 'budget']);
    }
    return keys.where((key) => key.isNotEmpty).toList();
  }

  String _primarySkillKey(String title) => _keywordsForSkill(title).first;

  String _skillKey(String value) => value
      .toLowerCase()
      .replaceAll('skills', '')
      .replaceAll('skill', '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');
}
