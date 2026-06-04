import '../core/config.dart';
import '../models/auth_models.dart';
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

  /// General public registration — sets role=student and access_status=pending_verification.
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
    final raw = await ApiClient.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (className != null && className.isNotEmpty) 'class_name': className,
      if (schoolName != null && schoolName.isNotEmpty) 'school_name': schoolName,
      if (location != null && location.isNotEmpty) 'location': location,
      if (age != null) 'age': age,
      if (parentEmail != null && parentEmail.isNotEmpty)
        'parent_email': parentEmail,
      if (requestedRole != null && requestedRole.isNotEmpty)
        'requested_role': requestedRole,
    }) as Map<String, dynamic>;
    return TokenResponse.fromJson(raw);
  }

  /// Registers a new user via POST /auth/register.
  /// Role is always forced to 'student' server-side.
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
  }) async {
    final raw = await ApiClient.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'class_name': className,
      'school_name': schoolName,
      'location': location,
      if (age != null) 'age': age,
      if (parentEmail != null && parentEmail.isNotEmpty)
        'parent_email': parentEmail,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (requestedRole != null && requestedRole.isNotEmpty)
        'requested_role': requestedRole,
    }) as Map<String, dynamic>;
    return TokenResponse.fromJson(raw);
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
