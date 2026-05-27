import 'package:flutter/foundation.dart';

import '../app_state.dart';
import '../models/api_models.dart';
import '../repositories/badge_repository.dart';
import '../repositories/user_repository.dart';
import 'view_state.dart';

class ProfileViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  AppUser? _user;
  UserStats? _stats;
  List<UserBadge> _badges = [];
  bool _disposed = false;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  AppUser? get user => _user;
  UserStats? get stats => _stats;
  List<UserBadge> get badges => _badges;

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
      _user = await UserRepository.getUser(AppState.userId);
      _stats = await UserRepository.getUserStats(AppState.userId);
      _badges = await BadgeRepository.getUserBadges(AppState.userId);
      _state = ViewState.idle;
    } catch (_) {
      _state = ViewState.error;
      _errorMessage = 'Failed to load profile.';
    }
    if (!_disposed) notifyListeners();
  }
}
