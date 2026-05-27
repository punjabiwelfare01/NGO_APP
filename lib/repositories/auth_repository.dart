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

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required int age,
    String role = 'student',
    String? parentEmail,
  }) async {
    return await ApiClient.post('/auth/register', {
          'name': name,
          'email': email,
          'password': password,
          'age': age,
          'role': role,
          'parent_email': parentEmail,
        })
        as Map<String, dynamic>;
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
