import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/auth_models.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Shown right after login/registration when an account has more than one
/// granted role (see AppState.hasMultipleRoles). Picking a role issues a
/// fresh token with that role as active (via AuthViewModel.switchRole) and
/// proceeds to '/home', which routes to the matching dashboard shell.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _vm = AuthViewModel();
  UserRole? _selecting;

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _choose(UserRole role) async {
    setState(() => _selecting = role);
    final ok = role == AppState.role || await _vm.switchRole(role);
    if (!mounted) return;
    if (!ok) {
      setState(() => _selecting = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_vm.errorMessage ?? 'Could not switch role. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose how you want to continue',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your account has access to more than one dashboard. You can switch '
                'anytime from your profile.',
                style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView.separated(
                  itemCount: AppState.availableRoles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (_, i) {
                    final role = AppState.availableRoles[i];
                    return _RoleCard(
                      role: role,
                      loading: _selecting == role,
                      disabled: _selecting != null && _selecting != role,
                      onTap: () => _choose(role),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.loading,
    required this.disabled,
    required this.onTap,
  });

  final UserRole role;
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;

  // "Volunteer" is this app's product name for the student role in the
  // multi-role context — role.displayName says "Student" everywhere else
  // (academic contexts), so it's overridden just for this screen/switcher.
  (IconData, String, String) get _display => switch (role) {
    UserRole.student => (
      Icons.volunteer_activism_rounded,
      'Volunteer',
      'Volunteer dashboard — learn, log hours, earn certificates',
    ),
    UserRole.eventManager => (
      Icons.event_available_rounded,
      'Event Manager',
      'Event Manager dashboard — create and run events and activities',
    ),
    _ => (Icons.dashboard_rounded, role.displayName, role.displayName),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, label, subtitle) = _display;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: InkWell(
        onTap: disabled || loading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue as $label',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.3),
                    ),
                  ],
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
