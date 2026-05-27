import 'package:flutter/foundation.dart';

import '../models/safety_awareness.dart';
import '../repositories/safety_awareness_repository.dart';

enum SafetyState { idle, loading, answered, error, empty }

class SafetyAwarenessViewModel extends ChangeNotifier {
  bool _disposed = false;

  SafetyState _state = SafetyState.idle;
  SafetyQuestion? _question;
  AnswerResult? _result;
  String? _selectedOption;

  SafetyState get state => _state;
  SafetyQuestion? get question => _question;
  AnswerResult? get result => _result;
  String? get selectedOption => _selectedOption;

  bool get isAnswered => _state == SafetyState.answered;
  bool get isLoading => _state == SafetyState.loading;

  Future<void> loadQuestion() async {
    _state = SafetyState.loading;
    _question = null;
    _result = null;
    _selectedOption = null;
    _notify();

    try {
      final q = await SafetyAwarenessRepository.getDailyQuestion();
      _question = q;
      _state = q == null ? SafetyState.empty : SafetyState.idle;
    } catch (_) {
      _state = SafetyState.error;
    }
    _notify();
  }

  Future<void> submitAnswer(String option) async {
    if (_question == null || isAnswered) return;
    _selectedOption = option;
    _notify();

    try {
      final res = await SafetyAwarenessRepository.submitAnswer(_question!.id, option);
      _result = res;
      _state = SafetyState.answered;
    } catch (_) {
      // Show local feedback even if network fails — keep selected highlight
      _state = SafetyState.answered;
    }
    _notify();
  }

  void loadNext() {
    loadQuestion();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
