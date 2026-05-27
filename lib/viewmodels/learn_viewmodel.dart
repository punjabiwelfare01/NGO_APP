import 'package:flutter/foundation.dart';

import '../app_state.dart';
import '../models/course.dart';
import '../repositories/course_repository.dart';
import 'view_state.dart';

class LearnViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  List<Course> _courses = [];
  bool _disposed = false;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  List<Course> get courses => _courses;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _courses = await CourseRepository.getUserCourses(AppState.userId);
      _state = ViewState.idle;
    } catch (_) {
      _state = ViewState.error;
      _errorMessage = 'Failed to load courses.';
    }
    if (!_disposed) notifyListeners();
  }
}
