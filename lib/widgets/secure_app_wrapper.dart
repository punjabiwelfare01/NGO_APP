import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';

/// iOS-only: overlays a solid black screen whenever the app enters the
/// inactive/hidden lifecycle state (app-switcher preview or screen-recording
/// thumbnail), preventing sensitive content from being captured.
///
/// Android screenshot/recording protection is handled at the OS level via
/// FLAG_SECURE in MainActivity — this widget is a no-op on Android and web.
class SecureAppWrapper extends StatefulWidget {
  const SecureAppWrapper({required this.child, super.key});

  final Widget child;

  @override
  State<SecureAppWrapper> createState() => _SecureAppWrapperState();
}

class _SecureAppWrapperState extends State<SecureAppWrapper>
    with WidgetsBindingObserver {
  bool _obscure = false;

  bool get _isRestricted =>
      AppState.isAuthenticated && !AppState.role.isAdmin;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isIOS) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && Platform.isIOS) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final shouldObscure = _isRestricted &&
        (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.hidden ||
            state == AppLifecycleState.paused);
    if (shouldObscure != _obscure) setState(() => _obscure = shouldObscure);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !Platform.isIOS || !_obscure) return widget.child;
    return Stack(
      children: [
        widget.child,
        const Positioned.fill(child: ColoredBox(color: Colors.black)),
      ],
    );
  }
}
