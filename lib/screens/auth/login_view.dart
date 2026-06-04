import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/auth_models.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/view_state.dart';
import 'student_register_screen.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final AuthViewModel _vm;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _vm = AuthViewModel();
  }

  @override
  void dispose() {
    _vm.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final status = await _vm.login(_emailCtrl.text, _passwordCtrl.text);
    if (!mounted || status == null) return;
    _navigateByStatus(status);
  }

  Future<void> _auth0SignIn() async {
    final status = await _vm.loginWithAuth0();
    if (!mounted || status == null) return;
    _navigateByStatus(status);
  }

  void _navigateByStatus(AccessStatus status) {
    final route = switch (status) {
      AccessStatus.approved            => '/home',
      AccessStatus.pendingVerification => '/pending-approval',
      AccessStatus.rejected            => '/rejected',
      AccessStatus.deactivated         => '/rejected',
    };
    Navigator.of(context).pushReplacementNamed(route);
  }

  void _fillDemo(String email, String password) {
    _emailCtrl.text = email;
    _passwordCtrl.text = password;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ListenableBuilder(
              listenable: _vm,
              builder: (context, _) {
                final loading = _vm.state == ViewState.loading;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ────────────────────────────────────────────
                    const _Logo(),
                    const SizedBox(height: 36),

                    // ── Email ─────────────────────────────────────────────
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !loading,
                      decoration: _inputDecoration(
                        'Email',
                        Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Password ──────────────────────────────────────────
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      enabled: !loading,
                      onSubmitted: (_) => _submit(),
                      decoration:
                          _inputDecoration(
                            'Password',
                            Icons.lock_outline_rounded,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.muted,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                    ),
                    const SizedBox(height: 24),

                    // ── Error message ──────────────────────────────────────
                    if (_vm.state == ViewState.error &&
                        _vm.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _vm.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.softRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    // ── Login button ───────────────────────────────────────
                    FilledButton(
                      onPressed: loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),

                    const SizedBox(height: 14),

                    // ── OR divider ─────────────────────────────────────────
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ── Auth0 Sign-In button ───────────────────────────────
                    OutlinedButton(
                      onPressed: loading ? null : _auth0SignIn,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _Auth0Logo(),
                          const SizedBox(width: 10),
                          Text(
                            'Continue with Auth0',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 12),

                    // ── Demo credentials ────────────────────────────────────
                    const Text(
                      'Demo accounts',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DemoChip(
                          label: 'Student',
                          color: AppColors.primary,
                          onTap: () =>
                              _fillDemo('aarav@careskill.demo', 'careskill123'),
                        ),
                        _DemoChip(
                          label: 'Admin',
                          color: AppColors.accent,
                          onTap: () =>
                              _fillDemo('admin@careskill.demo', 'admin123'),
                        ),
                        _DemoChip(
                          label: 'Mentor',
                          color: AppColors.secondary,
                          onTap: () =>
                              _fillDemo('meera@careskill.demo', 'mentor123'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // ── New student CTA ─────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'New student? ',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: loading
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const StudentRegisterScreen(),
                                    ),
                                  ),
                          child: const Text(
                            'Create account',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.muted),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      );
}

// ── sub-widgets ───────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'CareSkill',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'NGO Learning Platform',
          style: TextStyle(color: AppColors.muted, fontSize: 14),
        ),
      ],
    );
  }
}

class _DemoChip extends StatelessWidget {
  const _DemoChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: CircleAvatar(backgroundColor: color, radius: 8),
      onPressed: onTap,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      backgroundColor: Colors.white,
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }
}

class _Auth0Logo extends StatelessWidget {
  const _Auth0Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEB5424),
        border: Border.all(color: const Color(0xFFEB5424)),
      ),
      child: const Text(
        'A',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
