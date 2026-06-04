import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';

/// Manages screenshot / screen-recording restrictions at the OS level.
///
/// Android: uses FLAG_SECURE via a MethodChannel to fully block screenshots
///          and screen recordings at the system level.
///
/// iOS:     FLAG_SECURE is not available — use [SecureAppWrapper] in the
///          widget tree to overlay a black screen during app-switch / recording
///          preview.  Calls here are no-ops on iOS.
class ScreenSecurity {
  const ScreenSecurity._();

  static const _channel =
      MethodChannel('com.example.flutter_application_1/screen_security');

  /// Returns true when the current role requires restrictions.
  static bool get _restricted {
    final role = AppState.role;
    return !role.isAdmin;
  }

  /// Apply role-based screen security.
  /// Call this after login and on app cold-start when a session is restored.
  static Future<void> apply() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      if (_restricted) {
        await _channel.invokeMethod<void>('enableSecure');
      } else {
        await _channel.invokeMethod<void>('disableSecure');
      }
    } on PlatformException {
      // Channel not available (e.g., running on a simulator without the plugin)
    }
  }

  /// Remove all restrictions unconditionally.
  /// Call this on logout so the next user starts fresh on the login screen.
  static Future<void> clear() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('disableSecure');
    } on PlatformException {
      // Ignore
    }
  }
}

