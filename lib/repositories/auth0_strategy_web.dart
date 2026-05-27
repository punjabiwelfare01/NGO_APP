// Flutter Web — full-page redirect flow (more reliable than popup).
// Flow:
//   1. performAuth0Login()  → loginWithRedirect() → browser navigates to Auth0
//   2. User signs in (Google, etc.) on Auth0 Universal Login
//   3. Auth0 redirects back to this app (http://localhost:5000?code=...&state=...)
//   4. main() calls initAuth0() → onLoad() detects code, exchanges it for tokens
//   5. getRedirectIdToken() returns the idToken → backend exchange → home screen
import 'package:auth0_flutter/auth0_flutter_web.dart';

Auth0Web? _auth0;
String? _pendingIdToken; // set by initAuth0 when a redirect callback is detected

Future<void> initAuth0(String domain, String clientId) async {
  _auth0 = Auth0Web(domain, clientId, redirectUrl: Uri.base.origin);
  final credentials = await _auth0!.onLoad();
  _pendingIdToken = credentials?.idToken;
}

/// Returns the idToken from a completed redirect login, then clears it.
/// Returns null when there is no pending callback (normal app start).
String? getRedirectIdToken() {
  final token = _pendingIdToken;
  _pendingIdToken = null;
  return token;
}

/// Initiates Auth0 login — navigates the whole page to Auth0 Universal Login.
/// This function never returns; the browser leaves the page.
Future<String> performAuth0Login(
    String domain, String clientId, String scheme) async {
  final auth0 = _auth0 ??= Auth0Web(domain, clientId,
      redirectUrl: Uri.base.origin);
  await auth0.loginWithRedirect(
    redirectUrl: Uri.base.origin,
    parameters: {'prompt': 'select_account'},
  );
  // Never reached — browser has already navigated away.
  throw StateError('loginWithRedirect should have navigated away');
}

Future<void> performAuth0Logout(
    String domain, String clientId, String scheme) async {
  final auth0 = _auth0 ??= Auth0Web(domain, clientId,
      redirectUrl: Uri.base.origin);
  await auth0.logout(returnToUrl: Uri.base.origin);
}
