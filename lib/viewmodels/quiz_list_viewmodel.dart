import 'package:flutter/foundation.dart';

import '../models/quiz_models.dart';
import '../repositories/quiz_repository.dart';
import 'view_state.dart';

class QuizListViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  List<QuizSummary> _quizzes = [];
  DailyChallengeModel? _dailyChallenge;
  bool _disposed = false;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  List<QuizSummary> get quizzes => _quizzes;
  DailyChallengeModel? get dailyChallenge => _dailyChallenge;

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
      final results = await Future.wait([
        QuizRepository.getQuizzes(),
        QuizRepository.getDailyChallenge(),
      ]);
      _quizzes = results[0] as List<QuizSummary>;
      _dailyChallenge = results[1] as DailyChallengeModel?;
      _state = ViewState.idle;
    } catch (_) {
      _state = ViewState.error;
      _errorMessage = 'Failed to load quizzes.';
    }
    if (!_disposed) notifyListeners();
  }
}
