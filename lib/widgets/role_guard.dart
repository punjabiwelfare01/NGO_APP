import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/auth_models.dart';

/// Renders [child] only when the current user's role is in [allowed].
/// Renders [fallback] (or an empty box) otherwise.
///
/// Usage:
///   RoleGuard(
///     allowed: [UserRole.admin, UserRole.mentor],
///     child: AdminPanel(),
///   )
class RoleGuard extends StatelessWidget {
  const RoleGuard({
    required this.allowed,
    required this.child,
    this.fallback,
    super.key,
  });

  final List<UserRole> allowed;
  final Widget child;

  /// Shown when the user does not have a required role. Defaults to an empty box.
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    if (allowed.contains(AppState.role)) return child;
    return fallback ?? const SizedBox.shrink();
  }
}
