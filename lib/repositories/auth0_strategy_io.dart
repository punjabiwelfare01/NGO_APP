// Android / iOS — Chrome Custom Tabs / Safari View Controller.
import 'package:auth0_flutter/auth0_flutter.dart';

Future<void> initAuth0(String domain, String clientId) async {
  // No-op on mobile — auth0_flutter initializes lazily.
}

// Redirect flow is web-only; mobile uses webAuthentication which returns directly.
String? getRedirectIdToken() => null;

Future<String> performAuth0Login(
    String domain, String clientId, String scheme) async {
  final credentials = await Auth0(domain, clientId)
      .webAuthentication(scheme: scheme)
      .login(scopes: {'openid', 'profile', 'email'});
  return credentials.idToken;
}

Future<void> performAuth0Logout(
    String domain, String clientId, String scheme) async {
  await Auth0(domain, clientId).webAuthentication(scheme: scheme).logout();
}
