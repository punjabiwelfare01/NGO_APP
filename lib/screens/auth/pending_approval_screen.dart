import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/auth_models.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Shown when a user logs in or registers and their account is
/// still pending admin verification.
class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  late final AuthViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = AuthViewModel();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = (AppState.studentName ?? 'there').split(' ').first;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            children: [
              const Spacer(),

              // ── Illustration ───────────────────────────────────────────
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 52,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 28),

              // ── Title ──────────────────────────────────────────────────
              Text(
                'Hi $name, you\'re almost in!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),

              // ── Body ───────────────────────────────────────────────────
              const Text(
                'Your profile has been created successfully.\n\n'
                'Your access request is currently under review by the NGO admin. '
                'You will receive access to the platform once your profile is verified.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // ── Status chip ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFFD600)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: Color(0xFF8A6A00),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Pending Verification',
                      style: TextStyle(
                        color: Color(0xFF8A6A00),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              FilledButton.icon(
                onPressed: _checkApproval,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Check approval status'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Sign out ───────────────────────────────────────────────
              OutlinedButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.muted,
                  side: BorderSide(
                    color: AppColors.muted.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Contact the NGO admin if you need help.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await _vm.logout();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _checkApproval() async {
    final status = await _vm.refreshCurrentSession();
    if (!mounted || status == null) return;
    switch (status) {
      case AccessStatus.approved:
        Navigator.of(context).pushReplacementNamed('/home');
      case AccessStatus.pendingVerification:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your request is still under review.')),
        );
      case AccessStatus.rejected:
      case AccessStatus.deactivated:
        Navigator.of(context).pushReplacementNamed('/rejected');
    }
  }
}
