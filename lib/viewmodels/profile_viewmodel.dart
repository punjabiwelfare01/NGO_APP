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

  String? _updateError;
  String? get updateError => _updateError;

  /// Updates editable student profile fields via PATCH /users/me/profile.
  /// Optionally uploads a new profile photo via POST /users/me/photo first.
  /// Returns true on success. On failure keeps the view intact and returns false.
  /// Does NOT set ViewState.error — that would replace the whole profile view.
  Future<bool> updateProfile({
    String? name,
    String? className,
    String? schoolName,
    String? location,
    int? age,
    DateTime? dateOfBirth,
    String? parentEmail,
    String? phone,
    List<int>? photoBytes,
    String? photoPath,
    String? photoFileName,
  }) async {
    _updateError = null;
    notifyListeners();
    try {
      // Upload photo first — if it fails, abort so the user sees the error.
      if (photoBytes != null || photoPath != null) {
        _user = await UserRepository.uploadProfilePhoto(
          bytes: photoBytes,
          // Android's picker can return both bytes and a cache path. The
          // repository accepts one source, so prefer the already-loaded bytes.
          filePath: photoBytes == null ? photoPath : null,
          fileName: photoFileName ?? 'profile.jpg',
        );
      }

      // Patch text fields only when at least one is provided.
      if (name != null ||
          className != null ||
          schoolName != null ||
          location != null ||
          age != null ||
          dateOfBirth != null ||
          parentEmail != null ||
          phone != null) {
        final updated = await UserRepository.updateProfile(
          name: name,
          className: className,
          schoolName: schoolName,
          location: location,
          age: age,
          dateOfBirth: dateOfBirth,
          parentEmail: parentEmail,
          phone: phone,
        );
        _user = updated;
      }

      if (name != null) AppState.updateStudentName(name);
      if (!_disposed) notifyListeners();
      return true;
    } catch (_) {
      _updateError = 'Failed to update profile. Please try again.';
      if (!_disposed) notifyListeners();
      return false;
    }
  }
}
