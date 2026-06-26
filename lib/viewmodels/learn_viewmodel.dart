import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/api_models.dart';
import '../models/auth_models.dart';
import '../models/course.dart';
import '../models/skill_category.dart';
import '../repositories/course_repository.dart';
import '../repositories/user_repository.dart';
import 'view_state.dart';

class LearnViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  AppUser? _studentProfile;
  List<Course> _allCourses = [];
  List<Course> _academicCourses = [];
  List<Course> _skillCourses = [];
  List<SkillCategory> _categories = skillCategories;
  SkillCategory? _selectedCategory;
  String _selectedClass = '8';
  String _selectedSubject = 'All';
  String _selectedSkillCategory = 'All';
  String _searchQuery = '';
  String _selectedFreeCategory = 'All';
  bool _disposed = false;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  AppUser? get studentProfile => _studentProfile;
  List<Course> get academicCourses => _academicCourses;
  List<Course> get skillCourses => _skillCourses;
  List<Course> get courses => _skillCourses;
  List<Course> get freeCourses => _skillCourses;
  String get selectedFreeCategory => _selectedFreeCategory;
  List<Course> get continueLearning =>
      _skillCourses
          .where((course) => course.progress > 0 && course.progress < 1)
          .toList()
        ..sort((a, b) => b.progress.compareTo(a.progress));
  List<SkillCategory> get categories => _categories;
  SkillCategory? get selectedCategory => _selectedCategory;
  String get selectedClass => _selectedClass;
  String get selectedSubject => _selectedSubject;
  String get selectedSkillCategory => _selectedSkillCategory;
  String get searchQuery => _searchQuery;
  List<String> get availableSubjects =>
      academicSubjectsForClass(_selectedClass);
  bool get hasActiveFilters =>
      _selectedCategory != null ||
      _selectedSubject != 'All' ||
      _selectedSkillCategory != 'All' ||
      _searchQuery.trim().isNotEmpty;

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
      _selectedSkillCategory = initialCategory.title;
    }
    notifyListeners();
    try {
      final results = await Future.wait([
        CourseRepository.getCategories(),
        CourseRepository.getUserCourses(AppState.userId),
        _loadStudentProfile(),
      ]);
      _categories = _mergeCoreSkillCategories(
        results[0] as List<SkillCategory>,
      );
      _studentProfile = results[2] as AppUser?;
      _selectedClass = _classFromProfile(_studentProfile) ?? _selectedClass;
      _ensureValidSubjectForClass();
      if (initialCategory != null) {
        _selectedCategory = _resolveCategory(initialCategory);
        _selectedSkillCategory = _selectedCategory!.title;
      }
      _allCourses = results[1] as List<Course>;
      _applyFilters();
      _state = ViewState.idle;
    } catch (_) {
      _state = ViewState.error;
      _errorMessage = 'Failed to load learning courses.';
    }
    if (!_disposed) notifyListeners();
  }

  void updateSearch(String value) {
    _searchQuery = value.trim();
    _applyFilters();
    if (!_disposed) notifyListeners();
  }

  void selectClass(String classLevel) {
    _selectedClass = classLevel;
    _ensureValidSubjectForClass();
    _applyFilters();
    if (!_disposed) notifyListeners();
  }

  void selectSubject(String subject) {
    _selectedSubject = subject;
    _applyFilters();
    if (!_disposed) notifyListeners();
  }

  void selectSkillCategory(String category) {
    _selectedSkillCategory = category;
    _selectedCategory = category == 'All'
        ? null
        : _categories.firstWhere(
            (item) => _skillsMatch(item.title, category),
            orElse: () => SkillCategory(
              category,
              _iconForSkill(category),
              const Color(0xFFDDF1FF),
            ),
          );
    _applyFilters();
    if (!_disposed) notifyListeners();
  }

  void selectCategory(SkillCategory? category) {
    _selectedCategory = category == null ? null : _resolveCategory(category);
    _selectedSkillCategory = _selectedCategory?.title ?? 'All';
    _applyFilters();
    if (!_disposed) notifyListeners();
  }

  void selectFreeCategory(String category) {
    _selectedFreeCategory = category;
    _applyFilters();
    if (!_disposed) notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedSubject = 'All';
    _selectedSkillCategory = 'All';
    _searchQuery = '';
    _selectedFreeCategory = 'All';
    _applyFilters();
    if (!_disposed) notifyListeners();
  }

  void _applyFilters() {
    final query = _searchQuery.toLowerCase();
    final canManage =
        AppState.role.isAdmin ||
        AppState.role == UserRole.mentor ||
        AppState.role == UserRole.contentCreator;
    final publishedCourses = canManage
        ? _allCourses
        : _allCourses.where((course) => course.isPublished).toList();

    _academicCourses = const [];
    _skillCourses = publishedCourses.where((course) {
      final matchesCategory =
          _selectedFreeCategory == 'All' ||
          course.freeCategory == _selectedFreeCategory;
      final matchesSearch =
          query.isEmpty || _courseSearchText(course).contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  String _courseSearchText(Course course) {
    return [
      course.title,
      course.level,
      course.duration,
      course.courseType,
      ?course.classLevel,
      ?course.subject,
      ?course.skillCategory,
      ?course.courseDescription,
      course.createdBy,
      course.targetAudience,
      ...course.subjects,
      ?_categoryTitleFor(course),
    ].join(' ').toLowerCase();
  }

  String? _categoryTitleFor(Course course) {
    return _categories
        .where(
          (category) => category.id != 0 && category.id == course.categoryId,
        )
        .map((category) => category.title)
        .firstOrNull;
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

  String? _classFromProfile(AppUser? user) {
    final rawClass = user?.classLevel?.trim().isNotEmpty == true
        ? user!.classLevel!.trim()
        : user?.className?.trim();
    if (rawClass != null && rawClass.isNotEmpty) {
      final match = RegExp(r'(6|7|8|9|10|11|12)').firstMatch(rawClass);
      if (match != null) return match.group(1);
    }
    final age = user?.age;
    if (age == null) return null;
    final inferred = (age - 5).clamp(6, 12);
    return '$inferred';
  }

  Future<AppUser?> _loadStudentProfile() async {
    try {
      return await UserRepository.getUser(AppState.userId);
    } catch (_) {
      return null;
    }
  }

  void _ensureValidSubjectForClass() {
    if (!availableSubjects.contains(_selectedSubject)) {
      _selectedSubject = 'All';
    }
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
        lower.contains('programming') ||
        lower.contains('python') ||
        lower.contains('web') ||
        lower.contains('app')) {
      keys.addAll([
        'digital',
        'coding',
        'code',
        'computer',
        'programming',
        'python',
        'web',
        'app',
        'internet',
      ]);
    }
    if (lower.contains('career') ||
        lower.contains('job') ||
        lower.contains('resume') ||
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
    if (lower.contains('video') ||
        lower.contains('animation') ||
        lower.contains('graphic')) {
      keys.addAll(['video', 'editing', 'animation', 'graphic', 'design']);
    }
    if (lower.contains('ai')) {
      keys.addAll(['ai', 'artificial', 'intelligence']);
    }
    return keys.where((key) => key.isNotEmpty).toList();
  }

  IconData _iconForSkill(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('cyber') || lower.contains('safety')) {
      return Icons.shield_rounded;
    }
    if (lower.contains('program') || lower.contains('python')) {
      return Icons.code_rounded;
    }
    if (lower.contains('web') || lower.contains('digital')) {
      return Icons.devices_rounded;
    }
    if (lower.contains('communication') || lower.contains('speaking')) {
      return Icons.record_voice_over_rounded;
    }
    if (lower.contains('finance')) {
      return Icons.account_balance_wallet_rounded;
    }
    if (lower.contains('career') || lower.contains('resume')) {
      return Icons.workspace_premium_rounded;
    }
    return Icons.school_rounded;
  }

  String _primarySkillKey(String title) => _keywordsForSkill(title).first;

  String _skillKey(String value) => value
      .toLowerCase()
      .replaceAll('skills', '')
      .replaceAll('skill', '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');
}
