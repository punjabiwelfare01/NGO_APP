import 'package:flutter/foundation.dart';

import '../app_state.dart';
import '../models/auth_models.dart';
import '../repositories/api_client.dart';
import '../repositories/auth_repository.dart';
import 'view_state.dart';

class AuthViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  bool _disposed = false;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<bool> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      _errorMessage = 'Please enter your email and password.';
      _state = ViewState.error;
      notifyListeners();
      return false;
    }
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await AuthRepository.login(email.trim(), password);
      AppState.setFromLogin(
        response.userId,
        response.accessToken,
        UserRole.fromString(response.role),
      );
      _state = ViewState.idle;
      if (!_disposed) notifyListeners();
      return true;
    } on ApiException catch (e) {
      _state = ViewState.error;
      _errorMessage = e.statusCode == 401
          ? 'Invalid email or password.'
          : 'Server error (${e.statusCode}). Please try again.';
      if (!_disposed) notifyListeners();
      return false;
    } catch (_) {
      _state = ViewState.error;
      _errorMessage = 'Connection failed. Is the backend running?';
      if (!_disposed) notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithAuth0() async {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await AuthRepository.loginWithAuth0();
      if (response == null) {
        _state = ViewState.idle;
        if (!_disposed) notifyListeners();
        return false;
      }
      AppState.setFromLogin(
        response.userId,
        response.accessToken,
        UserRole.fromString(response.role),
      );
      _state = ViewState.idle;
      if (!_disposed) notifyListeners();
      return true;
    } on ApiException catch (e) {
      _state = ViewState.error;
      _errorMessage = e.statusCode == 401
          ? 'Auth0 sign-in failed. Please try again.'
          : 'Server error (${e.statusCode}). Please try again.';
      if (!_disposed) notifyListeners();
      return false;
    } catch (e) {
      _state = ViewState.error;
      _errorMessage = 'Auth0 sign-in failed: ${e.toString()}';
      if (!_disposed) notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await AuthRepository.logout();
    await AuthRepository.auth0Logout();
    AppState.clear();
    if (!_disposed) notifyListeners();
  }
}
