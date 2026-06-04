import 'core/config.dart';
import 'models/auth_models.dart';
import 'services/session_storage.dart';

/// Global runtime state set after a successful login.
class AppState {
  const AppState._();

  static const _userIdKey      = '${AppConfig.storagePrefix}.userId';
  static const _tokenKey       = '${AppConfig.storagePrefix}.token';
  static const _roleKey        = '${AppConfig.storagePrefix}.role';
  static const _nameKey        = '${AppConfig.storagePrefix}.studentName';
  static const _accessStatusKey = '${AppConfig.storagePrefix}.accessStatus';

  static int userId = 1;
  static String? token;
  static UserRole role = UserRole.student;
  static String? studentName;
  static AccessStatus accessStatus = AccessStatus.approved;

  static bool get isAuthenticated => token != null;

  /// True when the user's account is fully approved and can access dashboards.
  static bool get canAccessDashboard =>
      accessStatus == AccessStatus.approved || role.isAdmin;

  static void setFromLogin(
    int id,
    String accessToken,
    UserRole userRole, {
    String? name,
    AccessStatus? status,
  }) {
    userId = id;
    // Treat blank token (registration-only response) the same as no token.
    token = accessToken.isEmpty ? null : accessToken;
    role = userRole;
    studentName = name;
    // Admins and super-admins are always considered approved.
    accessStatus = userRole.isAdmin
        ? AccessStatus.approved
        : (status ?? AccessStatus.approved);
    SessionStorage.write(_userIdKey, id.toString());
    if (token != null) SessionStorage.write(_tokenKey, token!);
    SessionStorage.write(_roleKey, userRole.apiValue);
    SessionStorage.write(_accessStatusKey, accessStatus.apiValue);
    if (name != null) SessionStorage.write(_nameKey, name);
  }

  static void clear() {
    userId = 0;
    token = null;
    role = UserRole.guest;
    studentName = null;
    accessStatus = AccessStatus.approved;
    SessionStorage.remove(_userIdKey);
    SessionStorage.remove(_tokenKey);
    SessionStorage.remove(_roleKey);
    SessionStorage.remove(_nameKey);
    SessionStorage.remove(_accessStatusKey);
  }

  static void restore() {
    final savedToken  = SessionStorage.read(_tokenKey);
    final savedUserId = int.tryParse(SessionStorage.read(_userIdKey) ?? '');
    final savedRole   = SessionStorage.read(_roleKey);
    if (savedToken == null || savedUserId == null || savedRole == null) return;
    userId      = savedUserId;
    token       = savedToken;
    role        = UserRole.fromString(savedRole);
    studentName = SessionStorage.read(_nameKey);
    final savedStatus = SessionStorage.read(_accessStatusKey);
    accessStatus = savedStatus != null
        ? AccessStatus.fromString(savedStatus)
        : AccessStatus.approved;
  }
}
