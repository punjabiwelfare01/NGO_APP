// Fallback — never reached on supported Flutter platforms.
Future<void> initAuth0(String domain, String clientId) async {}

String? getRedirectIdToken() => null;

Future<String> performAuth0Login(
    String domain, String clientId, String scheme) async {
  throw UnsupportedError('Auth0 not supported on this platform.');
}

Future<void> performAuth0Logout(
    String domain, String clientId, String scheme) async {}
