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

  /// Returns the [AccessStatus] after a successful login so the caller can
  /// route to the correct screen.  Returns null on failure.
  Future<AccessStatus?> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      _errorMessage = 'Please enter your email and password.';
      _state = ViewState.error;
      notifyListeners();
      return null;
    }
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await AuthRepository.login(email.trim(), password);
      final role = UserRole.fromString(response.role);
      final status = response.accessStatus != null
          ? AccessStatus.fromString(response.accessStatus!)
          : AccessStatus.approved;
      AppState.setFromLogin(
        response.userId,
        response.accessToken,
        role,
        name: response.name,
        status: status,
      );
      _state = ViewState.idle;
      if (!_disposed) notifyListeners();
      return AppState.accessStatus;
    } on ApiException catch (e) {
      _state = ViewState.error;
      _errorMessage = e.statusCode == 401
          ? 'Invalid email or password.'
          : 'Server error (${e.statusCode}). Please try again.';
      if (!_disposed) notifyListeners();
      return null;
    } catch (_) {
      _state = ViewState.error;
      _errorMessage = 'Connection failed. Is the backend running?';
      if (!_disposed) notifyListeners();
      return null;
    }
  }

  /// Returns [AccessStatus] on success, null on failure.
  Future<AccessStatus?> loginWithAuth0() async {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await AuthRepository.loginWithAuth0();
      if (response == null) {
        _state = ViewState.idle;
        if (!_disposed) notifyListeners();
        return null;
      }
      final role = UserRole.fromString(response.role);
      final status = response.accessStatus != null
          ? AccessStatus.fromString(response.accessStatus!)
          : AccessStatus.approved;
      AppState.setFromLogin(
        response.userId,
        response.accessToken,
        role,
        name: response.name,
        status: status,
      );
      _state = ViewState.idle;
      if (!_disposed) notifyListeners();
      return AppState.accessStatus;
    } on ApiException catch (e) {
      _state = ViewState.error;
      _errorMessage = e.statusCode == 401
          ? 'Auth0 sign-in failed. Please try again.'
          : 'Server error (${e.statusCode}). Please try again.';
      if (!_disposed) notifyListeners();
      return null;
    } catch (e) {
      _state = ViewState.error;
      _errorMessage = 'Auth0 sign-in failed: ${e.toString()}';
      if (!_disposed) notifyListeners();
      return null;
    }
  }

  /// Registers a new user.
  /// Returns [AccessStatus] so the caller can route to the pending / home screen.
  /// requestedRole is stored server-side for admin review; it does NOT grant
  /// elevated access — the user remains pending until an admin assigns a role.
  Future<AccessStatus?> registerStudent({
    required String name,
    required String email,
    required String password,
    required String className,
    required String schoolName,
    required String location,
    int? age,
    String? parentEmail,
    String? phone,
    String? requestedRole,
  }) async {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await AuthRepository.registerStudent(
        name: name,
        email: email,
        password: password,
        className: className,
        schoolName: schoolName,
        location: location,
        age: age,
        parentEmail: parentEmail,
        phone: phone,
        requestedRole: requestedRole,
      );
      final role = UserRole.fromString(response.role);
      final status = response.accessStatus != null
          ? AccessStatus.fromString(response.accessStatus!)
          : AccessStatus.approved;
      AppState.setFromLogin(
        response.userId,
        response.accessToken,
        role,
        name: response.name,
        status: status,
      );
      _state = ViewState.idle;
      if (!_disposed) notifyListeners();
      return AppState.accessStatus;
    } on ApiException catch (e) {
      _state = ViewState.error;
      _errorMessage = e.statusCode == 409
          ? 'An account with this email already exists.'
          : e.statusCode == 422
          ? 'Please check your details and try again.'
          : 'Server error (${e.statusCode}). Please try again.';
      if (!_disposed) notifyListeners();
      return null;
    } catch (_) {
      _state = ViewState.error;
      _errorMessage = 'Connection failed. Is the backend running?';
      if (!_disposed) notifyListeners();
      return null;
    }
  }

  Future<String?> forgotPassword(String email) async {
    try {
      await AuthRepository.forgotPassword(email.trim());
      return null;
    } on ApiException catch (e) {
      return e.statusCode == 429
          ? 'Too many requests. Please wait before trying again.'
          : 'Server error (${e.statusCode}). Please try again.';
    } catch (_) {
      return 'Connection failed. Is the backend running?';
    }
  }

  Future<AccessStatus?> refreshCurrentSession() async {
    final token = AppState.token;
    if (token == null) return null;
    _state = ViewState.loading;
    _errorMessage = null;
    if (!_disposed) notifyListeners();
    try {
      final user = await AuthRepository.getCurrentUser();
      final role = UserRole.fromString(user.role ?? 'guest');
      final status = AccessStatus.fromString(user.accessStatus ?? 'pending');
      AppState.setFromLogin(
        user.id,
        token,
        role,
        name: user.name,
        status: status,
      );
      _state = ViewState.idle;
      if (!_disposed) notifyListeners();
      return status;
    } on ApiException catch (error) {
      _state = ViewState.error;
      _errorMessage = 'Could not refresh approval (${error.statusCode}).';
      if (!_disposed) notifyListeners();
      return null;
    } catch (_) {
      _state = ViewState.error;
      _errorMessage = 'Could not connect to the backend.';
      if (!_disposed) notifyListeners();
      return null;
    }
  }

  /// Returns null on success, an error message string on failure.
  Future<String?> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await AuthRepository.verifyResetCode(email: email, otp: otp);
      await AuthRepository.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      return null;
    } on ApiException catch (e) {
      return switch (e.statusCode) {
        400 => e.message,
        422 => 'New password must be at least 8 characters.',
        _ => 'Server error (${e.statusCode}). Please try again.',
      };
    } catch (_) {
      return 'Connection failed. Is the backend running?';
    }
  }

  /// Returns null on success, an error message string on failure.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await AuthRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return null;
    } on ApiException catch (e) {
      return switch (e.statusCode) {
        400 => e.message,
        422 => 'New password must be at least 8 characters.',
        _ => 'Server error (${e.statusCode}). Please try again.',
      };
    } catch (_) {
      return 'Connection failed. Is the backend running?';
    }
  }

  Future<void> logout() async {
    await AuthRepository.logout();
    await AuthRepository.auth0Logout();
    AppState.clear();
    if (!_disposed) notifyListeners();
  }
}
