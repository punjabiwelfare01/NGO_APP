import 'core/config.dart';
import 'models/auth_models.dart';
import 'services/session_storage.dart';

/// Global runtime state set after a successful login.
class AppState {
  const AppState._();

  static const _userIdKey = '${AppConfig.storagePrefix}.userId';
  static const _tokenKey  = '${AppConfig.storagePrefix}.token';
  static const _roleKey   = '${AppConfig.storagePrefix}.role';

  static int userId = 1;
  static String? token;
  static UserRole role = UserRole.student;

  static bool get isAuthenticated => token != null;

  static void setFromLogin(int id, String accessToken, UserRole userRole) {
    userId = id;
    token = accessToken;
    role = userRole;
    SessionStorage.write(_userIdKey, id.toString());
    SessionStorage.write(_tokenKey, accessToken);
    SessionStorage.write(_roleKey, _roleToApiValue(userRole));
  }

  static void clear() {
    userId = 0;
    token = null;
    role = UserRole.guest;
    SessionStorage.remove(_userIdKey);
    SessionStorage.remove(_tokenKey);
    SessionStorage.remove(_roleKey);
  }

  static void restore() {
    final savedToken = SessionStorage.read(_tokenKey);
    final savedUserId = int.tryParse(SessionStorage.read(_userIdKey) ?? '');
    final savedRole = SessionStorage.read(_roleKey);
    if (savedToken == null || savedUserId == null || savedRole == null) {
      return;
    }
    userId = savedUserId;
    token = savedToken;
    role = UserRole.fromString(savedRole);
  }

  static String _roleToApiValue(UserRole value) {
    return switch (value) {
      UserRole.superAdmin => 'super_admin',
      UserRole.admin => 'admin',
      UserRole.mentor => 'mentor',
      UserRole.contentCreator => 'content_creator',
      UserRole.student => 'student',
      UserRole.guest => 'guest',
    };
  }
}
