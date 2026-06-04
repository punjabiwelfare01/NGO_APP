import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Shown when a user logs in and their access request has been rejected
/// or their account has been deactivated.
class RejectedScreen extends StatelessWidget {
  const RejectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  color: AppColors.softRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.block_rounded,
                  size: 52,
                  color: AppColors.softRed,
                ),
              ),
              const SizedBox(height: 28),

              // ── Title ──────────────────────────────────────────────────
              const Text(
                'Access Not Approved',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),

              // ── Body ───────────────────────────────────────────────────
              const Text(
                'Your access request was not approved at this time.\n\n'
                'Please contact the NGO admin for more details or to request a review.',
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
                  color: AppColors.softRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.softRed.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cancel_outlined,
                      size: 16,
                      color: AppColors.softRed,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Request Rejected',
                      style: TextStyle(
                        color: AppColors.softRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Sign out ───────────────────────────────────────────────
              FilledButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Back to Sign In'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.softRed,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final vm = AuthViewModel();
    await vm.logout();
    vm.dispose();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}
