import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/auth_models.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/view_state.dart';

/// Unified authentication page — Login and Create Account in one place.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  bool _onRegister = false;
  bool _registrationSuccess = false;

  void _switchTab(bool toRegister) {
    setState(() {
      _onRegister = toRegister;
      if (!toRegister) _registrationSuccess = false;
    });
  }

  void _onRegisterSuccess() =>
      setState(() => _registrationSuccess = true);

  void _navigateByStatus(BuildContext ctx, AccessStatus status) {
    final route = switch (status) {
      AccessStatus.approved => '/home',
      _ => null, // handled inline
    };
    if (route != null && ctx.mounted) {
      Navigator.of(ctx).pushReplacementNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── App logo ─────────────────────────────────────────────
              const _LogoSection(),
              const SizedBox(height: 28),

              // ── Tab toggle ────────────────────────────────────────────
              if (!_registrationSuccess) ...[
                _TabToggle(
                  onLogin: !_onRegister,
                  onSwitch: _switchTab,
                ),
                const SizedBox(height: 24),
              ],

              // ── Animated form ─────────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _registrationSuccess
                    ? _RegistrationSuccess(
                        key: const ValueKey('success'),
                        onGoToLogin: () => _switchTab(false),
                      )
                    : _onRegister
                        ? _RegisterForm(
                            key: const ValueKey('register'),
                            onSuccess: _onRegisterSuccess,
                            onGoToLogin: () => _switchTab(false),
                          )
                        : _LoginForm(
                            key: const ValueKey('login'),
                            onSuccess: (status) =>
                                _navigateByStatus(context, status),
                            onGoToRegister: () => _switchTab(true),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Logo ──────────────────────────────────────────────────────────────────────

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 38,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'CareSkill',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'NGO Learning & Counselling Platform',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Tab toggle ────────────────────────────────────────────────────────────────

class _TabToggle extends StatelessWidget {
  const _TabToggle({
    required this.onLogin,
    required this.onSwitch,
  });

  final bool onLogin;
  final ValueChanged<bool> onSwitch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleBtn(
              label: 'Sign In',
              icon: Icons.login_rounded,
              selected: onLogin,
              onTap: () => onSwitch(false),
            ),
          ),
          Expanded(
            child: _ToggleBtn(
              label: 'Create Account',
              icon: Icons.person_add_rounded,
              selected: !onLogin,
              onTap: () => onSwitch(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.ink : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Login form ────────────────────────────────────────────────────────────────

class _LoginForm extends StatefulWidget {
  const _LoginForm({
    required this.onSuccess,
    required this.onGoToRegister,
    super.key,
  });

  final ValueChanged<AccessStatus> onSuccess;
  final VoidCallback onGoToRegister;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _vm           = AuthViewModel();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  // Status-specific message shown instead of navigating away
  String? _statusMessage;
  _StatusKind? _statusKind;

  @override
  void dispose() {
    _vm.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _statusMessage = null;
      _statusKind    = null;
    });
    final status =
        await _vm.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;

    if (status == null) return; // error already in _vm.errorMessage

    switch (status) {
      case AccessStatus.approved:
        widget.onSuccess(status);
      case AccessStatus.pendingVerification:
        setState(() {
          _statusMessage =
              'Your account is pending admin approval. You will receive access once verified.';
          _statusKind = _StatusKind.pending;
        });
      case AccessStatus.rejected:
        setState(() {
          _statusMessage =
              'Your access request was not approved. Please contact the NGO admin for more details.';
          _statusKind = _StatusKind.blocked;
        });
      case AccessStatus.deactivated:
        setState(() {
          _statusMessage =
              'Your account has been blocked. Please contact admin.';
          _statusKind = _StatusKind.blocked;
        });
    }
  }

  Future<void> _auth0SignIn() async {
    setState(() {
      _statusMessage = null;
      _statusKind    = null;
    });
    final status = await _vm.loginWithAuth0();
    if (!mounted || status == null) return;
    if (status == AccessStatus.approved) widget.onSuccess(status);
  }

  void _fillDemo(String email, String password) {
    _emailCtrl.text    = email;
    _passwordCtrl.text = password;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final loading = _vm.state == ViewState.loading;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Email ───────────────────────────────────────────────
            _AuthField(
              controller: _emailCtrl,
              label: 'Email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              enabled: !loading,
            ),
            const SizedBox(height: 12),

            // ── Password ────────────────────────────────────────────
            _PasswordField(
              controller: _passwordCtrl,
              label: 'Password',
              enabled: !loading,
              obscure: _obscure,
              onToggle: () => setState(() => _obscure = !_obscure),
            ),
            const SizedBox(height: 18),

            // ── API error ───────────────────────────────────────────
            if (_vm.state == ViewState.error &&
                _vm.errorMessage != null) ...[
              _InlineBanner(
                message: _vm.errorMessage!,
                kind: _StatusKind.blocked,
              ),
              const SizedBox(height: 12),
            ],

            // ── Status message ──────────────────────────────────────
            if (_statusMessage != null && _statusKind != null) ...[
              _InlineBanner(
                message: _statusMessage!,
                kind: _statusKind!,
              ),
              const SizedBox(height: 12),
            ],

            // ── Sign In button ──────────────────────────────────────
            _PrimaryButton(
              label: 'Sign In',
              loading: loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 14),

            // ── OR ──────────────────────────────────────────────────
            const _OrDivider(),
            const SizedBox(height: 14),

            // ── Auth0 ───────────────────────────────────────────────
            OutlinedButton(
              onPressed: loading ? null : _auth0SignIn,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(color: Color(0xFFDDDDDD)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Auth0Badge(),
                  const SizedBox(width: 10),
                  const Text(
                    'Continue with Auth0',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Demo credentials ────────────────────────────────────
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'Demo accounts',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 6,
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
                  label: 'Counsellor',
                  color: AppColors.secondary,
                  onTap: () =>
                      _fillDemo('meera@careskill.demo', 'mentor123'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

// ── Register form ─────────────────────────────────────────────────────────────

class _RegisterForm extends StatefulWidget {
  const _RegisterForm({
    required this.onSuccess,
    required this.onGoToLogin,
    super.key,
  });

  final VoidCallback onSuccess;
  final VoidCallback onGoToLogin;

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey       = GlobalKey<FormState>();
  final _vm            = AuthViewModel();
  final _nameCtrl      = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  final _classCtrl     = TextEditingController();
  final _schoolCtrl    = TextEditingController();
  final _locationCtrl  = TextEditingController();

  bool    _obscurePass    = true;
  bool    _obscureConfirm = true;
  String? _requestedRole;   // 'student' | 'mentor' | 'other'
  bool    _roleError      = false;

  @override
  void dispose() {
    _vm.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _classCtrl.dispose();
    _schoolCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validate role selection first (not covered by Form)
    if (_requestedRole == null) {
      setState(() => _roleError = true);
      return;
    }
    setState(() => _roleError = false);
    if (!_formKey.currentState!.validate()) return;

    final status = await _vm.registerStudent(
      name:          _nameCtrl.text.trim(),
      email:         _emailCtrl.text.trim(),
      password:      _passwordCtrl.text,
      className:     _classCtrl.text.trim(),
      schoolName:    _schoolCtrl.text.trim(),
      location:      _locationCtrl.text.trim(),
      requestedRole: _requestedRole,
    );
    if (!mounted || status == null) return;
    widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final loading = _vm.state == ViewState.loading;
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Section: Personal ───────────────────────────────────
              _SectionLabel(
                icon: Icons.person_outline_rounded,
                label: 'Personal Details',
                color: AppColors.primary,
              ),
              const SizedBox(height: 10),

              _ValidatedField(
                controller: _nameCtrl,
                label: 'Full Name',
                icon: Icons.badge_outlined,
                enabled: !loading,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Full name is required'
                    : null,
              ),
              const SizedBox(height: 10),

              _ValidatedField(
                controller: _emailCtrl,
                label: 'Email address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                enabled: !loading,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                      .hasMatch(v.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              _PasswordField(
                controller: _passwordCtrl,
                label: 'Create password',
                enabled: !loading,
                obscure: _obscurePass,
                onToggle: () =>
                    setState(() => _obscurePass = !_obscurePass),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              _PasswordField(
                controller: _confirmCtrl,
                label: 'Confirm password',
                enabled: !loading,
                obscure: _obscureConfirm,
                onToggle: () => setState(
                    () => _obscureConfirm = !_obscureConfirm),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (v != _passwordCtrl.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // ── Section: Education / Organization ───────────────────
              _SectionLabel(
                icon: Icons.school_rounded,
                label: 'Education / Organization',
                color: AppColors.accent,
              ),
              const SizedBox(height: 10),

              _ValidatedField(
                controller: _classCtrl,
                label: 'Class / Department',
                icon: Icons.class_outlined,
                enabled: !loading,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Class or department is required'
                    : null,
              ),
              const SizedBox(height: 10),

              _ValidatedField(
                controller: _schoolCtrl,
                label: 'School / Organization Name',
                icon: Icons.apartment_outlined,
                enabled: !loading,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'School or organization name is required'
                    : null,
              ),
              const SizedBox(height: 10),

              _ValidatedField(
                controller: _locationCtrl,
                label: 'Location / City',
                icon: Icons.location_on_outlined,
                enabled: !loading,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Location is required'
                    : null,
              ),
              const SizedBox(height: 18),

              // ── Section: I want to join as ──────────────────────────
              _SectionLabel(
                icon: Icons.how_to_reg_outlined,
                label: 'I want to join as',
                color: const Color(0xFF6B48FF),
              ),
              const SizedBox(height: 10),

              _RoleCard(
                value: 'student',
                selected: _requestedRole == 'student',
                icon: Icons.school_rounded,
                label: 'Student',
                description:
                    'Learn skills, join counselling sessions and events.',
                color: AppColors.primary,
                enabled: !loading,
                onTap: () => setState(() {
                  _requestedRole = 'student';
                  _roleError = false;
                }),
              ),
              const SizedBox(height: 8),

              _RoleCard(
                value: 'mentor',
                selected: _requestedRole == 'mentor',
                icon: Icons.psychology_outlined,
                label: 'Mentor / Counsellor',
                description:
                    'Guide students, host counselling sessions and share expertise.',
                color: AppColors.secondary,
                enabled: !loading,
                onTap: () => setState(() {
                  _requestedRole = 'mentor';
                  _roleError = false;
                }),
              ),
              const SizedBox(height: 8),

              _RoleCard(
                value: 'other',
                selected: _requestedRole == 'other',
                icon: Icons.interests_outlined,
                label: 'Other',
                description:
                    'Content creator, event manager, or support staff. Admin will assign the exact role after review.',
                color: AppColors.accent,
                enabled: !loading,
                onTap: () => setState(() {
                  _requestedRole = 'other';
                  _roleError = false;
                }),
              ),

              // Role validation error
              if (_roleError) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 14,
                      color: AppColors.softRed,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Please select how you want to join.',
                      style: const TextStyle(
                        color: AppColors.softRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),

              // ── Pending notice ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your account will need admin approval before you can access the platform.',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── API error ───────────────────────────────────────────
              if (_vm.state == ViewState.error &&
                  _vm.errorMessage != null) ...[
                _InlineBanner(
                  message: _vm.errorMessage!,
                  kind: _StatusKind.blocked,
                ),
                const SizedBox(height: 12),
              ],

              // ── Submit ──────────────────────────────────────────────
              _PrimaryButton(
                label: 'Create Account',
                loading: loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),

              // ── Already have account ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onGoToLogin,
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ── Registration success panel ────────────────────────────────────────────────

class _RegistrationSuccess extends StatelessWidget {
  const _RegistrationSuccess({
    required this.onGoToLogin,
    super.key,
  });

  final VoidCallback onGoToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),

        // ── Icon ─────────────────────────────────────────────────
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.secondary,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── Heading ───────────────────────────────────────────────
        const Text(
          'Account Created!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),

        // ── Message ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.3),
            ),
          ),
          child: const Text(
            'Account created successfully. Please wait for admin approval.\n\n'
            'The admin will review your profile and assign your access role. '
            'You will be able to log in once your account is verified.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Status badge ─────────────────────────────────────────
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD600)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_top_rounded,
                  size: 15,
                  color: Color(0xFF8A6A00),
                ),
                SizedBox(width: 6),
                Text(
                  'Pending Admin Approval',
                  style: TextStyle(
                    color: Color(0xFF8A6A00),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),

        // ── Go to login button ────────────────────────────────────
        _PrimaryButton(
          label: 'Go to Sign In',
          loading: false,
          onPressed: onGoToLogin,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Shared field widgets ──────────────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      enabled: enabled,
      decoration: _dec(label, icon),
    );
  }
}

class _ValidatedField extends StatelessWidget {
  const _ValidatedField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.enabled = true,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool enabled;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      enabled: enabled,
      decoration: _dec(label, icon),
      validator: validator,
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.enabled,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final dec = _dec(label, Icons.lock_outline_rounded).copyWith(
      suffixIcon: IconButton(
        icon: Icon(
          obscure
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: AppColors.muted,
          size: 20,
        ),
        onPressed: onToggle,
      ),
    );
    if (validator != null) {
      return TextFormField(
        controller: controller,
        obscureText: obscure,
        enabled: enabled,
        decoration: dec,
        validator: validator,
      );
    }
    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      decoration: dec,
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
    );
  }
}

InputDecoration _dec(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.muted.withValues(alpha: 0.15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.softRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.softRed, width: 2),
      ),
    );

// ── Primary button ────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor:
            AppColors.primary.withValues(alpha: 0.55),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
      ),
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

// ── Inline status/error banner ────────────────────────────────────────────────

enum _StatusKind { pending, blocked }

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({
    required this.message,
    required this.kind,
  });

  final String message;
  final _StatusKind kind;

  @override
  Widget build(BuildContext context) {
    final isPending = kind == _StatusKind.pending;
    final bg    = isPending ? const Color(0xFFFFF3CD) : AppColors.softRed.withValues(alpha: 0.1);
    final border = isPending ? const Color(0xFFFFD600) : AppColors.softRed.withValues(alpha: 0.4);
    final ic    = isPending ? const Color(0xFF8A6A00) : AppColors.softRed;
    final icon  = isPending
        ? Icons.hourglass_top_rounded
        : Icons.error_outline_rounded;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: ic),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: ic,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Misc helpers ──────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}

class _Auth0Badge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEB5424),
      ),
      child: const Text(
        'A',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
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
      avatar: CircleAvatar(backgroundColor: color, radius: 7),
      onPressed: onTap,
      labelStyle:
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      backgroundColor: Colors.white,
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

// ── Role selection card ───────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.value,
    required this.selected,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final String       value;
  final bool         selected;
  final IconData     icon;
  final String       label;
  final String       description;
  final Color        color;
  final bool         enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.07) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppColors.muted.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon bubble
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.14)
                    : AppColors.muted.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? color : AppColors.muted,
              ),
            ),
            const SizedBox(width: 13),

            // Label + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: selected ? color : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : Colors.transparent,
                border: Border.all(
                  color:
                      selected ? color : AppColors.muted.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
