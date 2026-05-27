import 'package:flutter/foundation.dart';

import '../models/quiz_models.dart';
import '../repositories/quiz_repository.dart';
import 'view_state.dart';

class QuizPlayViewModel extends ChangeNotifier {
  QuizPlayViewModel(this.quizId);

  final int quizId;
  final Stopwatch _stopwatch = Stopwatch();

  ViewState _state = ViewState.idle;
  String? _errorMessage;
  QuizModel? _quiz;
  AttemptResult? _result;
  int _currentIndex = 0;
  List<int> _answers = [];
  bool _disposed = false;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  QuizModel? get quiz => _quiz;
  AttemptResult? get result => _result;
  int get currentIndex => _currentIndex;
  List<int> get answers => List.unmodifiable(_answers);
  int get selectedIndex =>
      _currentIndex < _answers.length ? _answers[_currentIndex] : -1;
  bool get isLastQuestion =>
      _quiz == null ||
      _quiz!.questions.isEmpty ||
      _currentIndex == _quiz!.questions.length - 1;
  double get progress {
    final total = _quiz?.questions.length ?? 0;
    if (total == 0) return 0;
    return (_currentIndex + 1) / total;
  }

  @override
  void dispose() {
    _disposed = true;
    _stopwatch.stop();
    super.dispose();
  }

  Future<void> load() async {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _quiz = await QuizRepository.getQuiz(quizId);
      _answers = List<int>.filled(_quiz!.questions.length, -1);
      _currentIndex = 0;
      _stopwatch
        ..reset()
        ..start();
      _state = ViewState.idle;
    } catch (_) {
      _state = ViewState.error;
      _errorMessage = 'Could not load this quiz.';
    }
    if (!_disposed) notifyListeners();
  }

  void selectAnswer(int index) {
    if (_quiz == null || _currentIndex >= _answers.length) return;
    _answers[_currentIndex] = index;
    notifyListeners();
  }

  void goBack() {
    if (_currentIndex == 0) return;
    _currentIndex -= 1;
    notifyListeners();
  }

  bool goNext() {
    if (isLastQuestion) return false;
    _currentIndex += 1;
    notifyListeners();
    return true;
  }

  Future<AttemptResult?> submit() async {
    if (_quiz == null ||
        _quiz!.questions.isEmpty ||
        _state == ViewState.loading) {
      return null;
    }
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _stopwatch.stop();
      _result = await QuizRepository.submitAttempt(
        quizId,
        answers: _answers,
        timeTakenSeconds: _stopwatch.elapsed.inSeconds,
      );
      _state = ViewState.idle;
    } catch (_) {
      _state = ViewState.error;
      _errorMessage = 'Could not submit your answers.';
    }
    if (!_disposed) notifyListeners();
    return _result;
  }
}
