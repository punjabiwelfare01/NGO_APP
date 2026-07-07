import '../core/config.dart';
import '../models/auth_models.dart';
import '../models/api_models.dart';
import 'api_client.dart';
import 'auth0_strategy.dart';

class AuthRepository {
  const AuthRepository._();

  // ── Email / password ──────────────────────────────────────────────────────

  static Future<TokenResponse> login(String email, String password) async {
    final json =
        await ApiClient.post('/auth/login', {
              'email': email,
              'password': password,
            })
            as Map<String, dynamic>;
    return TokenResponse.fromJson(json);
  }

  static Future<AppUser> getCurrentUser() async {
    final json = await ApiClient.get('/auth/me') as Map<String, dynamic>;
    return AppUser.fromJson(json);
  }

  /// Switches the session's active role for a multi-role account, without
  /// requiring the user to log in again. `role` must be one of the account's
  /// granted roles (e.g. TokenResponse.roles from login) — the API value,
  /// e.g. UserRole.eventManager.apiValue.
  static Future<TokenResponse> switchRole(String role) async {
    final json =
        await ApiClient.post('/auth/switch-role', {'role': role})
            as Map<String, dynamic>;
    return TokenResponse.fromJson(json);
  }

  /// General public registration — creates a pending access request.
  /// requested_role is stored server-side for admin review; it does NOT grant access.
  static Future<TokenResponse> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? className,
    String? schoolName,
    String? location,
    int? age,
    String? parentEmail,
    String? requestedRole,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
    };
    void addIfFilled(String key, String? value) {
      if (value != null && value.isNotEmpty) body[key] = value;
    }

    addIfFilled('phone', phone);
    addIfFilled('class_name', className);
    addIfFilled('school_name', schoolName);
    addIfFilled('location', location);
    if (age != null) body['age'] = age;
    addIfFilled('parent_email', parentEmail);
    addIfFilled('requested_role', requestedRole);

    final raw =
        await ApiClient.post('/auth/register', body) as Map<String, dynamic>;
    return TokenResponse.fromJson(raw);
  }

  /// Registers a new user via POST /auth/register.
  /// The provisional role cannot route to a dashboard until admin approval.
  /// requested_role is stored for admin review; it does NOT grant access.
  static Future<TokenResponse> registerStudent({
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
    List<String>? interests,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'class_name': className,
      'school_name': schoolName,
      'location': location,
    };
    void addIfFilled(String key, String? value) {
      if (value != null && value.isNotEmpty) body[key] = value;
    }

    if (age != null) body['age'] = age;
    addIfFilled('parent_email', parentEmail);
    addIfFilled('phone', phone);
    addIfFilled('requested_role', requestedRole);
    if (interests != null && interests.isNotEmpty) body['interests'] = interests;

    final raw =
        await ApiClient.post('/auth/register', body) as Map<String, dynamic>;
    return TokenResponse.fromJson(raw);
  }

  static Future<void> forgotPassword(String email) async {
    await ApiClient.post('/auth/forgot-password', {'email': email});
  }

  static Future<void> verifyResetCode({
    required String email,
    required String otp,
  }) async {
    await ApiClient.post('/auth/verify-reset-code', {
      'email': email,
      'otp': otp,
    });
  }

  static Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await ApiClient.post('/auth/reset-password', {
      'email': email,
      'otp': otp,
      'new_password': newPassword,
    });
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ApiClient.post('/auth/change-password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  static Future<void> logout() async {
    try {
      await ApiClient.post('/auth/logout', {});
    } catch (_) {}
  }

  // ── Auth0 ─────────────────────────────────────────────────────────────────

  /// Web: called at startup by main() to exchange the redirect callback token.
  /// Android: always returns null (login completes inside loginWithAuth0).
  static Future<TokenResponse?> handleAuth0RedirectCallback() async {
    final idToken = getRedirectIdToken();
    if (idToken == null) return null;
    final json =
        await ApiClient.post('/auth/auth0', {'id_token': idToken})
            as Map<String, dynamic>;
    return TokenResponse.fromJson(json);
  }

  /// Initiates Auth0 login.
  /// - Web: redirects the whole page to Auth0 (this future never resolves on web).
  ///   The completed login is handled by handleAuth0RedirectCallback() in main().
  /// - Android/iOS: opens Chrome Custom Tabs and returns a CareSkill JWT.
  static Future<TokenResponse?> loginWithAuth0() async {
    final idToken = await performAuth0Login(
      AppConfig.auth0Domain,
      AppConfig.auth0ClientId,
      AppConfig.auth0CallbackScheme,
    );
    final json =
        await ApiClient.post('/auth/auth0', {'id_token': idToken})
            as Map<String, dynamic>;
    return TokenResponse.fromJson(json);
  }

  static Future<void> auth0Logout() async {
    await performAuth0Logout(
      AppConfig.auth0Domain,
      AppConfig.auth0ClientId,
      AppConfig.auth0CallbackScheme,
    );
  }
}
