import 'package:flutter/foundation.dart';

import '../models/creator_content.dart';
import '../repositories/api_client.dart';
import '../repositories/creator_repository.dart';
import 'view_state.dart';

class CreatorHomeViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  CreatorHomeStats? _stats;
  bool _disposed = false;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  CreatorHomeStats? get stats => _stats;

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
      _stats = await CreatorRepository.getHomeStats();
      _state = ViewState.idle;
    } on ApiException catch (e) {
      _state = ViewState.error;
      _errorMessage = e.statusCode == 401
          ? 'Session expired. Please sign in again.'
          : 'Server error (${e.statusCode}). Please try again.';
    } catch (_) {
      _state = ViewState.error;
      _errorMessage = 'Could not reach the server. Is the backend running?';
    }
    if (!_disposed) notifyListeners();
  }
}
