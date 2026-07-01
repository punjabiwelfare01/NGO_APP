import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/auth_models.dart';
import '../../repositories/api_client.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/view_state.dart';

// ── Access type enum ──────────────────────────────────────────────────────────

enum _AccessType {
  studentVolunteer(
    'Student Volunteer / Intern',
    'Learn skills, attend events, earn certificates, and build verified social impact.',
    Icons.school_rounded,
    Color(0xFF1565C0),
    'Submit Volunteer Application',
  ),
  schoolPartner(
    'School Partner',
    'Register your school to book counsellors, awareness camps, and career guidance programs.',
    Icons.business_center_rounded,
    Color(0xFF0D47A1),
    'Register School Partner',
  ),
  counsellor(
    'Counsellor / Officer Mentor',
    'Apply as a verified counsellor, retired officer, or career mentor to guide students.',
    Icons.military_tech_rounded,
    Color(0xFF1B5E20),
    'Apply as Counsellor',
  ),
  ngoStaff(
    'NGO Staff / Event Manager / Creator',
    'Request access as event manager, content creator, support staff, or NGO mentor.',
    Icons.badge_rounded,
    Color(0xFFBF360C),
    'Request Staff Access',
  ),
  donor(
    'Donor / Community Partner Inquiry',
    'Send an inquiry to partner with Punjabi Welfare Trust or support our programs.',
    Icons.volunteer_activism_rounded,
    Color(0xFFAD1457),
    'Submit Inquiry',
  );

  const _AccessType(
    this.label,
    this.description,
    this.icon,
    this.color,
    this.ctaLabel,
  );
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final String ctaLabel;
}

// ── Root widget ───────────────────────────────────────────────────────────────

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  int _tab = 0;
  _AccessType? _accessType;
  bool _registrationSuccess = false;
  String _successLabel = '';
  bool _onForgotPassword = false;

  void _switchTab(int tab) => setState(() {
    _tab = tab;
    _accessType = null;
    _registrationSuccess = false;
    _onForgotPassword = false;
  });

  void _selectAccessType(_AccessType type) =>
      setState(() => _accessType = type);

  void _clearAccessType() => setState(() => _accessType = null);

  void _onSuccess(String label) => setState(() {
    _registrationSuccess = true;
    _successLabel = label;
  });

  void _navigateByStatus(BuildContext ctx, AccessStatus status) {
    if (status == AccessStatus.approved && ctx.mounted) {
      Navigator.of(ctx).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final showHeader = !_registrationSuccess && !_onForgotPassword;
    final showTabToggle = showHeader && _accessType == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHeader) ...[
                const _NgoHeader(),
                const SizedBox(height: 24),
              ],
              if (showTabToggle) ...[
                _TabToggle(selectedTab: _tab, onSwitch: _switchTab),
                const SizedBox(height: 20),
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
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
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_registrationSuccess) {
      return _RegistrationSuccess(
        key: const ValueKey('success'),
        label: _successLabel,
        onGoToSignIn: () => _switchTab(0),
      );
    }
    if (_onForgotPassword) {
      return _ForgotPasswordFlow(
        key: const ValueKey('forgot'),
        onBackToLogin: () => setState(() {
          _onForgotPassword = false;
          _tab = 0;
        }),
      );
    }
    if (_tab == 0) {
      return _SignInForm(
        key: const ValueKey('sign-in'),
        onSuccess: (status) => _navigateByStatus(context, status),
        onGoToRegister: () => _switchTab(1),
        onForgotPassword: () => setState(() => _onForgotPassword = true),
      );
    }
    if (_accessType == null) {
      return _AccessTypeSelector(
        key: const ValueKey('access-type'),
        onSelect: _selectAccessType,
      );
    }
    return _buildForm(_accessType!);
  }

  Widget _buildForm(_AccessType type) {
    final key = ValueKey('form-${type.name}');
    return switch (type) {
      _AccessType.studentVolunteer => _StudentVolunteerForm(
        key: key,
        onSuccess: () => _onSuccess('Student Volunteer Application'),
        onBack: _clearAccessType,
      ),
      _AccessType.schoolPartner => _SchoolPartnerForm(
        key: key,
        onSuccess: () => _onSuccess('School Partnership Request'),
        onBack: _clearAccessType,
      ),
      _AccessType.counsellor => _CounsellorForm(
        key: key,
        onSuccess: () => _onSuccess('Counsellor Application'),
        onBack: _clearAccessType,
      ),
      _AccessType.ngoStaff => _NgoStaffForm(
        key: key,
        onSuccess: () => _onSuccess('NGO Staff Access Request'),
        onBack: _clearAccessType,
      ),
      _AccessType.donor => _DonorInquiryForm(
        key: key,
        onSuccess: () => _onSuccess('Community Inquiry'),
        onBack: _clearAccessType,
      ),
    };
  }
}

// ── NGO branding header ───────────────────────────────────────────────────────

class _NgoHeader extends StatelessWidget {
  const _NgoHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'assests/ngo_logo.jpeg',
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Punjabi Welfare Trust',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'CareSkill — Verified NGO Volunteer & Social Impact Platform',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_rounded, size: 14, color: Color(0xFF2E7D32)),
              SizedBox(width: 6),
              Text(
                'Verified NGO Activity Platform',
                style: TextStyle(
                  color: Color(0xFF1B5E20),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Learn, volunteer, serve society, and build verified social impact',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.5),
        ),
      ],
    );
  }
}

// ── Tab toggle ────────────────────────────────────────────────────────────────

class _TabToggle extends StatelessWidget {
  const _TabToggle({required this.selectedTab, required this.onSwitch});

  final int selectedTab;
  final ValueChanged<int> onSwitch;

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
              selected: selectedTab == 0,
              onTap: () => onSwitch(0),
            ),
          ),
          Expanded(
            child: _ToggleBtn(
              label: 'Request Access',
              icon: Icons.person_add_rounded,
              selected: selectedTab == 1,
              onTap: () => onSwitch(1),
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

// ── Sign In form ──────────────────────────────────────────────────────────────

class _SignInForm extends StatefulWidget {
  const _SignInForm({
    required this.onSuccess,
    required this.onGoToRegister,
    required this.onForgotPassword,
    super.key,
  });

  final ValueChanged<AccessStatus> onSuccess;
  final VoidCallback onGoToRegister;
  final VoidCallback onForgotPassword;

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _vm = AuthViewModel();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
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
      _statusKind = null;
    });
    final status = await _vm.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    if (status == null) return;
    switch (status) {
      case AccessStatus.approved:
        widget.onSuccess(status);
      case AccessStatus.pendingVerification:
        setState(() {
          _statusMessage =
              'Your access request is under review by Punjabi Welfare Trust. You will be notified after approval.';
          _statusKind = _StatusKind.pending;
        });
      case AccessStatus.rejected:
        setState(() {
          _statusMessage =
              'Your access request was not approved. Please contact NGO admin for clarification.';
          _statusKind = _StatusKind.blocked;
        });
      case AccessStatus.deactivated:
        setState(() {
          _statusMessage =
              'Your account has been deactivated. Please contact Punjabi Welfare Trust support.';
          _statusKind = _StatusKind.blocked;
        });
    }
  }

  Future<void> _auth0SignIn() async {
    setState(() {
      _statusMessage = null;
      _statusKind = null;
    });
    final status = await _vm.loginWithAuth0();
    if (!mounted || status == null) return;
    if (status == AccessStatus.approved) widget.onSuccess(status);
  }

  void _fillDemo(String email, String password) {
    _emailCtrl.text = email;
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
            _AuthField(
              controller: _emailCtrl,
              label: 'Email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              enabled: !loading,
            ),
            const SizedBox(height: 12),
            _PasswordField(
              controller: _passwordCtrl,
              label: 'Password',
              enabled: !loading,
              obscure: _obscure,
              onToggle: () => setState(() => _obscure = !_obscure),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: loading ? null : widget.onForgotPassword,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_vm.state == ViewState.error && _vm.errorMessage != null) ...[
              _InlineBanner(
                message: _vm.errorMessage!,
                kind: _StatusKind.blocked,
              ),
              const SizedBox(height: 12),
            ],
            if (_statusMessage != null && _statusKind != null) ...[
              _InlineBanner(message: _statusMessage!, kind: _statusKind!),
              const SizedBox(height: 12),
            ],
            _PrimaryButton(
              label: 'Sign In',
              loading: loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 14),
            const _OrDivider(),
            const SizedBox(height: 14),
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
            const SizedBox(height: 20),
            // Demo chips — development mode only
            if (kDebugMode) ...[
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Dev accounts',
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
                    onTap: () => _fillDemo('admin@careskill.demo', 'admin123'),
                  ),
                  _DemoChip(
                    label: 'Counsellor',
                    color: AppColors.secondary,
                    onTap: () => _fillDemo('meera@careskill.demo', 'mentor123'),
                  ),
                  _DemoChip(
                    label: 'Ev. Manager',
                    color: const Color(0xFFBF360C),
                    onTap: () => _fillDemo('em@careskill.demo', 'em123'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have access? ",
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                GestureDetector(
                  onTap: widget.onGoToRegister,
                  child: const Text(
                    'Request Access',
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
        );
      },
    );
  }
}

// ── Access type selector ──────────────────────────────────────────────────────

class _AccessTypeSelector extends StatelessWidget {
  const _AccessTypeSelector({required this.onSelect, super.key});

  final ValueChanged<_AccessType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'What type of access do you need?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose your role to see the appropriate form. All requests are reviewed by Punjabi Welfare Trust before approval.',
          style: TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.5),
        ),
        const SizedBox(height: 16),
        for (final type in _AccessType.values) ...[
          _AccessTypeCard(type: type, onTap: () => onSelect(type)),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        const _TrustNoteSection(),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _AccessTypeCard extends StatelessWidget {
  const _AccessTypeCard({required this.type, required this.onTap});

  final _AccessType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: type.color.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: type.color.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(type.icon, color: type.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: type.color,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      type.description,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: type.color.withValues(alpha: 0.55),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Form header (back + title) ────────────────────────────────────────────────

class _FormHeader extends StatelessWidget {
  const _FormHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Divider(height: 1, color: AppColors.muted.withValues(alpha: 0.15)),
      ],
    );
  }
}

// ── Student Volunteer form ────────────────────────────────────────────────────

class _StudentVolunteerForm extends StatefulWidget {
  const _StudentVolunteerForm({
    required this.onSuccess,
    required this.onBack,
    super.key,
  });

  final VoidCallback onSuccess;
  final VoidCallback onBack;

  @override
  State<_StudentVolunteerForm> createState() => _StudentVolunteerFormState();
}

class _StudentVolunteerFormState extends State<_StudentVolunteerForm> {
  final _formKey = GlobalKey<FormState>();
  final _vm = AuthViewModel();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  final Set<String> _interests = {};

  static const _interestOptions = [
    'Education Support',
    'Donation Drive',
    'Awareness Camp',
    'Event Support',
    'Documentation',
    'Social Media / Promotion',
  ];

  @override
  void dispose() {
    _vm.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _dobCtrl.dispose();
    _classCtrl.dispose();
    _institutionCtrl.dispose();
    _locationCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final status = await _vm.registerStudent(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      className: _classCtrl.text.trim(),
      schoolName: _institutionCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      requestedRole: 'student',
      interests: _interests.toList(),
    );
    if (!mounted || status == null) return;
    if (status == AccessStatus.approved) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      widget.onSuccess();
    }
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
              _FormHeader(
                title: 'Student Volunteer / Intern',
                subtitle: 'Submit for admin review — Punjabi Welfare Trust',
                icon: Icons.school_rounded,
                color: const Color(0xFF1565C0),
                onBack: widget.onBack,
              ),
              const SizedBox(height: 18),
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
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                enabled: !loading,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _phoneCtrl,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                enabled: !loading,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (v.trim().length < 10) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _PasswordField(
                controller: _passwordCtrl,
                label: 'Create Password',
                enabled: !loading,
                obscure: _obscurePass,
                onToggle: () => setState(() => _obscurePass = !_obscurePass),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _PasswordField(
                controller: _confirmCtrl,
                label: 'Confirm Password',
                enabled: !loading,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) =>
                    v != _passwordCtrl.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 20),
              _SectionLabel(
                icon: Icons.school_outlined,
                label: 'Education Details',
                color: AppColors.accent,
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _dobCtrl,
                label: 'Age / Date of Birth',
                icon: Icons.cake_outlined,
                enabled: !loading,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Age or date of birth is required'
                    : null,
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _classCtrl,
                label: 'Class / College / Year',
                icon: Icons.class_outlined,
                enabled: !loading,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Class or college is required'
                    : null,
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _institutionCtrl,
                label: 'School / College / Institution',
                icon: Icons.apartment_outlined,
                enabled: !loading,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Institution name is required'
                    : null,
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _locationCtrl,
                label: 'City / Location',
                icon: Icons.location_on_outlined,
                enabled: !loading,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'City is required' : null,
              ),
              const SizedBox(height: 20),
              _SectionLabel(
                icon: Icons.interests_outlined,
                label: 'Area of Interest',
                color: const Color(0xFF6B48FF),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _interestOptions.map((opt) {
                    final sel = _interests.contains(opt);
                    return FilterChip(
                      label: Text(opt),
                      selected: sel,
                      onSelected: loading
                          ? null
                          : (v) => setState(
                              () => v
                                  ? _interests.add(opt)
                                  : _interests.remove(opt),
                            ),
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: sel ? AppColors.primary : AppColors.muted,
                      ),
                      selectedColor: AppColors.primary.withValues(alpha: 0.1),
                      checkmarkColor: AppColors.primary,
                      side: BorderSide(
                        color: sel
                            ? AppColors.primary
                            : AppColors.muted.withValues(alpha: 0.3),
                      ),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel(
                icon: Icons.edit_note_rounded,
                label: 'Reason for Joining',
                color: AppColors.secondary,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _reasonCtrl,
                enabled: !loading,
                maxLines: 3,
                decoration: _dec(
                  'Why do you want to volunteer with Punjabi Welfare Trust?',
                  Icons.chat_bubble_outline_rounded,
                ).copyWith(alignLabelWithHint: true),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please share your reason for joining'
                    : null,
              ),
              const SizedBox(height: 18),
              const _PendingNotice(),
              const SizedBox(height: 14),
              if (_vm.state == ViewState.error && _vm.errorMessage != null) ...[
                _InlineBanner(
                  message: _vm.errorMessage!,
                  kind: _StatusKind.blocked,
                ),
                const SizedBox(height: 12),
              ],
              _PrimaryButton(
                label: 'Submit Volunteer Application',
                loading: loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ── School Partner form ───────────────────────────────────────────────────────

class _SchoolPartnerForm extends StatefulWidget {
  const _SchoolPartnerForm({
    required this.onSuccess,
    required this.onBack,
    super.key,
  });

  final VoidCallback onSuccess;
  final VoidCallback onBack;

  @override
  State<_SchoolPartnerForm> createState() => _SchoolPartnerFormState();
}

class _SchoolPartnerFormState extends State<_SchoolPartnerForm> {
  final _formKey = GlobalKey<FormState>();
  final _vm = AuthViewModel();
  final _schoolNameCtrl = TextEditingController();
  final _principalCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _studentCountCtrl = TextEditingController();
  final _classesCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _schoolType;
  final Set<String> _requestTypes = {};
  DateTime? _preferredDate;
  TimeOfDay? _preferredTime;

  static const _schoolTypes = [
    'Government',
    'Private',
    'NGO-Supported',
    'Other',
  ];

  static const _requestTypeOptions = [
    'Book Counsellor',
    'Awareness Camp',
    'Career Guidance',
    'NDA / Defence Guidance',
    'Cyber Safety Session',
    'Anti-Drug Awareness',
    'Women Safety Program',
  ];

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _preferredDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _preferredDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _preferredTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _preferredTime = picked);
  }

  @override
  void dispose() {
    _vm.dispose();
    _schoolNameCtrl.dispose();
    _principalCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _studentCountCtrl.dispose();
    _classesCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final status = await _vm.registerStudent(
      name: _principalCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      className: _classesCtrl.text.trim(),
      schoolName: _schoolNameCtrl.text.trim(),
      location: _cityCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      requestedRole: 'school_partner',
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
              _FormHeader(
                title: 'School Partner',
                subtitle: 'Register your school with Punjabi Welfare Trust',
                icon: Icons.business_center_rounded,
                color: const Color(0xFF0D47A1),
                onBack: widget.onBack,
              ),
              const SizedBox(height: 18),
              _SectionLabel(
                icon: Icons.school_outlined,
                label: 'School Information',
                color: const Color(0xFF0D47A1),
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _schoolNameCtrl,
                label: 'School Name',
                icon: Icons.apartment_outlined,
                enabled: !loading,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'School name is required'
                    : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _schoolType,
                decoration: _dec('School Type', Icons.category_outlined),
                items: _schoolTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: loading
                    ? null
                    : (v) => setState(() => _schoolType = v),
                validator: (v) =>
                    v == null ? 'Please select school type' : null,
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _principalCtrl,
                label: 'Principal / Coordinator Name',
                icon: Icons.person_outline_rounded,
                enabled: !loading,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Coordinator name is required'
                    : null,
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _phoneCtrl,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                enabled: !loading,
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Enter a valid phone number'
                    : null,
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _emailCtrl,
                label: 'School Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                enabled: !loading,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _addressCtrl,
                label: 'School Address',
                icon: Icons.location_on_outlined,
                enabled: !loading,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Address is required'
                    : null,
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _cityCtrl,
                label: 'City',
                icon: Icons.location_city_outlined,
                enabled: !loading,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'City is required' : null,
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _studentCountCtrl,
                label: 'Approx. Number of Students',
                icon: Icons.groups_outlined,
                keyboardType: TextInputType.number,
                enabled: !loading,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Student count is required'
                    : null,
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _classesCtrl,
                label: 'Classes Covered (e.g. 8–12)',
                icon: Icons.class_outlined,
                enabled: !loading,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Classes covered is required'
                    : null,
              ),
              const SizedBox(height: 20),
              _SectionLabel(
                icon: Icons.check_circle_outline_rounded,
                label: 'Type of Request',
                color: AppColors.primary,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _requestTypeOptions.map((opt) {
                    final sel = _requestTypes.contains(opt);
                    return FilterChip(
                      label: Text(opt),
                      selected: sel,
                      onSelected: loading
                          ? null
                          : (v) => setState(
                              () => v
                                  ? _requestTypes.add(opt)
                                  : _requestTypes.remove(opt),
                            ),
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: sel ? const Color(0xFF0D47A1) : AppColors.muted,
                      ),
                      selectedColor: const Color(
                        0xFF0D47A1,
                      ).withValues(alpha: 0.09),
                      checkmarkColor: const Color(0xFF0D47A1),
                      side: BorderSide(
                        color: sel
                            ? const Color(0xFF0D47A1)
                            : AppColors.muted.withValues(alpha: 0.3),
                      ),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              // Preferred Date / Time — side-by-side tap targets
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onTap: loading ? null : _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.muted.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: AppColors.muted,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _preferredDate == null
                                    ? 'Preferred Date'
                                    : '${_preferredDate!.day.toString().padLeft(2, '0')}/'
                                        '${_preferredDate!.month.toString().padLeft(2, '0')}/'
                                        '${_preferredDate!.year}',
                                style: TextStyle(
                                  color: _preferredDate == null
                                      ? AppColors.muted.withValues(alpha: 0.6)
                                      : AppColors.ink,
                                  fontSize: 13,
                                  fontWeight: _preferredDate == null
                                      ? FontWeight.w400
                                      : FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: loading ? null : _pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.muted.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_outlined,
                              color: AppColors.muted,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _preferredTime == null
                                    ? 'Time'
                                    : _preferredTime!.format(context),
                                style: TextStyle(
                                  color: _preferredTime == null
                                      ? AppColors.muted.withValues(alpha: 0.6)
                                      : AppColors.ink,
                                  fontSize: 13,
                                  fontWeight: _preferredTime == null
                                      ? FontWeight.w400
                                      : FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionLabel(
                icon: Icons.lock_outline_rounded,
                label: 'Set Portal Password',
                color: AppColors.muted,
              ),
              const SizedBox(height: 6),
              Text(
                'Set a password to access the school portal after admin approval.',
                style: TextStyle(
                  color: AppColors.muted.withValues(alpha: 0.8),
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 10),
              _PasswordField(
                controller: _passwordCtrl,
                label: 'Set Access Password',
                enabled: !loading,
                obscure: _obscurePass,
                onToggle: () => setState(() => _obscurePass = !_obscurePass),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _PasswordField(
                controller: _confirmCtrl,
                label: 'Confirm Password',
                enabled: !loading,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) =>
                    v != _passwordCtrl.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 18),
              const _PendingNotice(),
              const SizedBox(height: 14),
              if (_vm.state == ViewState.error && _vm.errorMessage != null) ...[
                _InlineBanner(
                  message: _vm.errorMessage!,
                  kind: _StatusKind.blocked,
                ),
                const SizedBox(height: 12),
              ],
              _PrimaryButton(
                label: 'Register School Partner',
                loading: loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ── Counsellor / Officer Mentor form ─────────────────────────────────────────

class _CounsellorForm extends StatefulWidget {
  const _CounsellorForm({
    required this.onSuccess,
    required this.onBack,
    super.key,
  });

  final VoidCallback onSuccess;
  final VoidCallback onBack;

  @override
  State<_CounsellorForm> createState() => _CounsellorFormState();
}

class _CounsellorFormState extends State<_CounsellorForm> {
  final _formKey = GlobalKey<FormState>();
  final _vm = AuthViewModel();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _qualCtrl = TextEditingController();
  final _expertiseCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _languagesCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _category;
  String? _sessionPreference;
  bool _consentVerification = false;
  bool _consentPublicProfile = false;

  static const _categories = [
    'Retired Army Officer Counsellor',
    'Air Force Officer Mentor',
    'Government Officer Mentor',
    'Career Counsellor',
    'Mental Wellness Counsellor',
    'Defence Guidance Mentor',
  ];

  static const _sessionPrefs = ['Online', 'Offline', 'Both Online & Offline'];

  @override
  void dispose() {
    _vm.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _designationCtrl.dispose();
    _qualCtrl.dispose();
    _expertiseCtrl.dispose();
    _experienceCtrl.dispose();
    _languagesCtrl.dispose();
    _locationCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_consentVerification) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please consent to document verification.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final status = await _vm.registerStudent(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      // className stores Designation, schoolName stores Qualifications
      className: _designationCtrl.text.trim(),
      schoolName: _qualCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      requestedRole: 'mentor',
    );
    if (!mounted || status == null) return;

    // Persist counsellor-specific fields after registration while token is active
    try {
      // Create/update mentor profile with category and expertise
      await ApiClient.patch('/counselling/mentors/me', {
        'display_name': _nameCtrl.text.trim(),
        if (_category != null) 'category': _category,
        if (_expertiseCtrl.text.trim().isNotEmpty)
          'expertise': _expertiseCtrl.text.trim(),
      });
      // Save extended fields (experience, languages, session mode)
      final extPayload = <String, dynamic>{};
      if (_qualCtrl.text.trim().isNotEmpty) {
        extPayload['qualification'] = _qualCtrl.text.trim();
      }
      if (_experienceCtrl.text.trim().isNotEmpty) {
        final yoe = int.tryParse(_experienceCtrl.text.trim());
        if (yoe != null) extPayload['years_of_experience'] = yoe;
      }
      if (_languagesCtrl.text.trim().isNotEmpty) {
        extPayload['languages_known'] = _languagesCtrl.text.trim();
      }
      if (_sessionPreference != null) {
        extPayload['counselling_mode'] = _sessionPreference == 'Online'
            ? 'online'
            : _sessionPreference == 'Offline'
            ? 'offline'
            : 'both';
      }
      if (extPayload.isNotEmpty) {
        await ApiClient.patch('/counselling/mentors/me/extended', extPayload);
      }
    } catch (_) {
      // Non-fatal — profile data can be updated later from the profile screen
    }

    if (!mounted) return;
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
              _FormHeader(
                title: 'Counsellor / Officer Mentor',
                subtitle: 'Apply for verified mentor status',
                icon: Icons.military_tech_rounded,
                color: const Color(0xFF1B5E20),
                onBack: widget.onBack,
              ),
              const SizedBox(height: 18),
              _SectionLabel(
                icon: Icons.person_outline_rounded,
                label: 'Personal Details',
                color: const Color(0xFF1B5E20),
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
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                enabled: !loading,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _phoneCtrl,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                enabled: !loading,
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Enter a valid phone number'
                    : null,
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _designationCtrl,
                label: 'Designation / Service Background',
                icon: Icons.work_outline_rounded,
                enabled: !loading,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Designation is required'
                    : null,
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _locationCtrl,
                label: 'City / Location',
                icon: Icons.location_on_outlined,
                enabled: !loading,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'City is required' : null,
              ),
              const SizedBox(height: 20),
              _SectionLabel(
                icon: Icons.military_tech_outlined,
                label: 'Counsellor Category',
                color: const Color(0xFF1B5E20),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final sel = _category == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: sel,
                      onSelected: loading
                          ? null
                          : (v) => setState(() => _category = v ? cat : null),
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: sel ? const Color(0xFF1B5E20) : AppColors.muted,
                      ),
                      selectedColor: const Color(
                        0xFF1B5E20,
                      ).withValues(alpha: 0.1),
                      side: BorderSide(
                        color: sel
                            ? const Color(0xFF1B5E20)
                            : AppColors.muted.withValues(alpha: 0.3),
                      ),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel(
                icon: Icons.school_outlined,
                label: 'Professional Details',
                color: AppColors.primary,
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _qualCtrl,
                label: 'Qualifications',
                icon: Icons.workspace_premium_outlined,
                enabled: !loading,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Qualifications are required'
                    : null,
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _expertiseCtrl,
                label: 'Expertise Areas',
                icon: Icons.lightbulb_outline_rounded,
                enabled: !loading,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Expertise is required'
                    : null,
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _experienceCtrl,
                label: 'Years of Experience',
                icon: Icons.timeline_rounded,
                keyboardType: TextInputType.number,
                enabled: !loading,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Experience is required'
                    : null,
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _languagesCtrl,
                label: 'Languages (e.g. Punjabi, Hindi, English)',
                icon: Icons.translate_rounded,
                enabled: !loading,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Languages are required'
                    : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _sessionPreference,
                decoration: _dec(
                  'Session Preference',
                  Icons.video_call_outlined,
                ),
                items: _sessionPrefs
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: loading
                    ? null
                    : (v) => setState(() => _sessionPreference = v),
                validator: (v) =>
                    v == null ? 'Please select session preference' : null,
              ),
              const SizedBox(height: 20),
              _SectionLabel(
                icon: Icons.lock_outline_rounded,
                label: 'Set Portal Password',
                color: AppColors.muted,
              ),
              const SizedBox(height: 10),
              _PasswordField(
                controller: _passwordCtrl,
                label: 'Create Password',
                enabled: !loading,
                obscure: _obscurePass,
                onToggle: () => setState(() => _obscurePass = !_obscurePass),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _PasswordField(
                controller: _confirmCtrl,
                label: 'Confirm Password',
                enabled: !loading,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) =>
                    v != _passwordCtrl.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 20),
              _SectionLabel(
                icon: Icons.verified_user_outlined,
                label: 'Consent & Privacy',
                color: AppColors.accent,
              ),
              const SizedBox(height: 10),
              _ConsentTile(
                value: _consentVerification,
                onChanged: loading
                    ? null
                    : (v) => setState(() => _consentVerification = v ?? false),
                label:
                    'I consent to submit verification documents (ID / service record) for admin review. Private IDs will not be publicly displayed.',
              ),
              const SizedBox(height: 8),
              _ConsentTile(
                value: _consentPublicProfile,
                onChanged: loading
                    ? null
                    : (v) => setState(() => _consentPublicProfile = v ?? false),
                label:
                    'I consent to show my verified public profile to schools after admin approval.',
              ),
              const SizedBox(height: 18),
              const _PendingNotice(),
              const SizedBox(height: 14),
              if (_vm.state == ViewState.error && _vm.errorMessage != null) ...[
                _InlineBanner(
                  message: _vm.errorMessage!,
                  kind: _StatusKind.blocked,
                ),
                const SizedBox(height: 12),
              ],
              _PrimaryButton(
                label: 'Apply as Counsellor',
                loading: loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ── NGO Staff form ────────────────────────────────────────────────────────────

class _NgoStaffForm extends StatefulWidget {
  const _NgoStaffForm({
    required this.onSuccess,
    required this.onBack,
    super.key,
  });

  final VoidCallback onSuccess;
  final VoidCallback onBack;

  @override
  State<_NgoStaffForm> createState() => _NgoStaffFormState();
}

class _NgoStaffFormState extends State<_NgoStaffForm> {
  final _formKey = GlobalKey<FormState>();
  final _vm = AuthViewModel();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _requestedRole;

  static const _roles = [
    'Event Manager',
    'Content Creator',
    'Support Staff',
    'Mentor',
  ];

  @override
  void dispose() {
    _vm.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _orgCtrl.dispose();
    _reasonCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final roleKey = _requestedRole?.toLowerCase().replaceAll(' ', '_');
    final status = await _vm.registerStudent(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      className: _orgCtrl.text.trim(),
      schoolName: _orgCtrl.text.trim(),
      location: '',
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      requestedRole: roleKey ?? 'other',
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
              _FormHeader(
                title: 'NGO Staff / Event Manager / Creator',
                subtitle: 'Request staff access — admin approval required',
                icon: Icons.badge_rounded,
                color: const Color(0xFFBF360C),
                onBack: widget.onBack,
              ),
              const SizedBox(height: 18),
              _SectionLabel(
                icon: Icons.person_outline_rounded,
                label: 'Personal Details',
                color: const Color(0xFFBF360C),
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
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                enabled: !loading,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _phoneCtrl,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                enabled: !loading,
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Enter a valid phone number'
                    : null,
              ),
              const SizedBox(height: 10),
              _ValidatedField(
                controller: _orgCtrl,
                label: 'Organization / Department',
                icon: Icons.business_outlined,
                enabled: !loading,
                validator: (v) => null,
              ),
              const SizedBox(height: 16),
              _SectionLabel(
                icon: Icons.work_outline_rounded,
                label: 'Requested Role',
                color: AppColors.primary,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _roles.map((role) {
                    final sel = _requestedRole == role;
                    return ChoiceChip(
                      label: Text(role),
                      selected: sel,
                      onSelected: loading
                          ? null
                          : (v) => setState(
                              () => _requestedRole = v ? role : null,
                            ),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: sel ? AppColors.primary : AppColors.muted,
                      ),
                      selectedColor: AppColors.primary.withValues(alpha: 0.1),
                      checkmarkColor: AppColors.primary,
                      side: BorderSide(
                        color: sel
                            ? AppColors.primary
                            : AppColors.muted.withValues(alpha: 0.3),
                      ),
                      backgroundColor: Colors.white,
                    );
                  }).toList(),
                ),
              ),
              if (_requestedRole == null) ...[
                const SizedBox(height: 6),
                Text(
                  'Please select a role.',
                  style: TextStyle(color: AppColors.softRed, fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonCtrl,
                enabled: !loading,
                maxLines: 3,
                decoration: _dec(
                  'Reason for requesting access',
                  Icons.edit_note_rounded,
                ).copyWith(alignLabelWithHint: true),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please provide a reason'
                    : null,
              ),
              const SizedBox(height: 16),
              _SectionLabel(
                icon: Icons.lock_outline_rounded,
                label: 'Set Portal Password',
                color: AppColors.muted,
              ),
              const SizedBox(height: 10),
              _PasswordField(
                controller: _passwordCtrl,
                label: 'Create Password',
                enabled: !loading,
                obscure: _obscurePass,
                onToggle: () => setState(() => _obscurePass = !_obscurePass),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _PasswordField(
                controller: _confirmCtrl,
                label: 'Confirm Password',
                enabled: !loading,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) =>
                    v != _passwordCtrl.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF6D00).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 16,
                      color: Color(0xFFBF360C),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Admin and Super Admin roles cannot be self-registered. Admin accounts are created or approved only by Super Admin.',
                        style: TextStyle(
                          color: Color(0xFFBF360C),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const _PendingNotice(),
              const SizedBox(height: 14),
              if (_vm.state == ViewState.error && _vm.errorMessage != null) ...[
                _InlineBanner(
                  message: _vm.errorMessage!,
                  kind: _StatusKind.blocked,
                ),
                const SizedBox(height: 12),
              ],
              _PrimaryButton(
                label: 'Request Staff Access',
                loading: loading,
                onPressed: _requestedRole == null ? () {} : _submit,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ── Donor / Community inquiry form ────────────────────────────────────────────

class _DonorInquiryForm extends StatefulWidget {
  const _DonorInquiryForm({
    required this.onSuccess,
    required this.onBack,
    super.key,
  });

  final VoidCallback onSuccess;
  final VoidCallback onBack;

  @override
  State<_DonorInquiryForm> createState() => _DonorInquiryFormState();
}

class _DonorInquiryFormState extends State<_DonorInquiryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _orgCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _submitting = false);
    widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FormHeader(
            title: 'Donor / Community Partner Inquiry',
            subtitle: 'We will get in touch with you shortly',
            icon: Icons.volunteer_activism_rounded,
            color: const Color(0xFFAD1457),
            onBack: widget.onBack,
          ),
          const SizedBox(height: 18),
          _SectionLabel(
            icon: Icons.person_outline_rounded,
            label: 'Contact Details',
            color: const Color(0xFFAD1457),
          ),
          const SizedBox(height: 10),
          _ValidatedField(
            controller: _nameCtrl,
            label: 'Your Name / Organization',
            icon: Icons.badge_outlined,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 10),
          _ValidatedField(
            controller: _emailCtrl,
            label: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          _ValidatedField(
            controller: _phoneCtrl,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) => null,
          ),
          const SizedBox(height: 10),
          _ValidatedField(
            controller: _orgCtrl,
            label: 'Organization / Company (optional)',
            icon: Icons.business_outlined,
            validator: (v) => null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _messageCtrl,
            maxLines: 4,
            decoration: _dec(
              'Message — how would you like to support or partner with us?',
              Icons.message_outlined,
            ).copyWith(alignLabelWithHint: true),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please write a message'
                : null,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFAD1457).withValues(alpha: 0.25),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: Color(0xFFAD1457),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Donations should only be made through official NGO bank / UPI details available inside the app after approval. Do not transfer funds based on any external request.',
                    style: TextStyle(
                      color: Color(0xFFAD1457),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _PrimaryButton(
            label: 'Submit Inquiry',
            loading: _submitting,
            onPressed: _submit,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Registration success ──────────────────────────────────────────────────────

class _RegistrationSuccess extends StatelessWidget {
  const _RegistrationSuccess({
    required this.label,
    required this.onGoToSignIn,
    super.key,
  });

  final String label;
  final VoidCallback onGoToSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.secondary,
              size: 50,
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Request Submitted!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.3),
            ),
          ),
          child: const Text(
            'Your request has been submitted to Punjabi Welfare Trust for review.\n\n'
            'An administrator will review your profile and assign the appropriate access role. '
            'You will be notified once your account is verified and approved.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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
                  'Pending Admin Review',
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
        _PrimaryButton(
          label: 'Go to Sign In',
          loading: false,
          onPressed: onGoToSignIn,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Forgot password flow ──────────────────────────────────────────────────────

enum _FpStep { email, reset, done }

class _ForgotPasswordFlow extends StatefulWidget {
  const _ForgotPasswordFlow({required this.onBackToLogin, super.key});

  final VoidCallback onBackToLogin;

  @override
  State<_ForgotPasswordFlow> createState() => _ForgotPasswordFlowState();
}

class _ForgotPasswordFlowState extends State<_ForgotPasswordFlow> {
  final _vm = AuthViewModel();
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  _FpStep _step = _FpStep.email;
  String? _email;
  String? _error;
  bool _loading = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _vm.dispose();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await _vm.forgotPassword(_emailCtrl.text.trim());
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
      return;
    }
    setState(() {
      _loading = false;
      _email = _emailCtrl.text.trim();
      _step = _FpStep.reset;
    });
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await _vm.resetPassword(
      email: _email!,
      otp: _otpCtrl.text.trim(),
      newPassword: _newPwCtrl.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
    } else {
      setState(() {
        _loading = false;
        _step = _FpStep.done;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: switch (_step) {
        _FpStep.email => _buildEmailStep(),
        _FpStep.reset => _buildResetStep(),
        _FpStep.done => _buildDoneStep(),
      },
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('fp-email'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.ink,
                onPressed: widget.onBackToLogin,
              ),
              const SizedBox(width: 2),
              const Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              "Enter your registered email and we'll send a reset code.",
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          const SizedBox(height: 22),
          _ValidatedField(
            controller: _emailCtrl,
            label: 'Email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            enabled: !_loading,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _InlineBanner(message: _error!, kind: _StatusKind.blocked),
          ],
          const SizedBox(height: 18),
          _PrimaryButton(
            label: 'Get Reset Code',
            loading: _loading,
            onPressed: _requestOtp,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: widget.onBackToLogin,
              child: const Text('Back to Sign In'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    return Form(
      key: _resetFormKey,
      child: Column(
        key: const ValueKey('fp-reset'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.ink,
                onPressed: () => setState(() {
                  _step = _FpStep.email;
                  _error = null;
                }),
              ),
              const SizedBox(width: 2),
              const Text(
                'Enter Reset Code',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.mark_email_read_outlined, color: AppColors.primary),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Enter the six-digit code sent to your registered email.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ValidatedField(
            controller: _otpCtrl,
            label: 'Reset Code (6 digits)',
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            enabled: !_loading,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter the reset code';
              if (v.trim().length != 6) return 'Code must be exactly 6 digits';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _PasswordField(
            controller: _newPwCtrl,
            label: 'New Password',
            enabled: !_loading,
            obscure: !_showNew,
            onToggle: () => setState(() => _showNew = !_showNew),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter a new password';
              if (v.length < 8) return 'Must be at least 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _PasswordField(
            controller: _confirmCtrl,
            label: 'Confirm New Password',
            enabled: !_loading,
            obscure: !_showConfirm,
            onToggle: () => setState(() => _showConfirm = !_showConfirm),
            validator: (v) =>
                v != _newPwCtrl.text ? 'Passwords do not match' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _InlineBanner(message: _error!, kind: _StatusKind.blocked),
          ],
          const SizedBox(height: 18),
          _PrimaryButton(
            label: 'Reset Password',
            loading: _loading,
            onPressed: _resetPassword,
          ),
        ],
      ),
    );
  }

  Widget _buildDoneStep() {
    return Column(
      key: const ValueKey('fp-done'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              color: AppColors.secondary,
              size: 42,
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Password Reset!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your password has been updated successfully.\nYou can now sign in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.55),
        ),
        const SizedBox(height: 28),
        _PrimaryButton(
          label: 'Back to Sign In',
          loading: false,
          onPressed: widget.onBackToLogin,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Trust note section ────────────────────────────────────────────────────────

class _TrustNoteSection extends StatelessWidget {
  const _TrustNoteSection();

  @override
  Widget build(BuildContext context) {
    const notes = [
      'All access requests are reviewed by Punjabi Welfare Trust before approval.',
      'Counsellor and officer profiles are visible to schools only after verification.',
      'Private IDs such as Army ID, Government ID, Aadhaar, or PAN will never be publicly displayed.',
      'School and counsellor contact details are protected and shown only after a confirmed booking.',
      'Donations must only be made through official NGO bank / UPI details inside the app.',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, size: 14, color: AppColors.muted),
              SizedBox(width: 6),
              Text(
                'Trust & Privacy',
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pending notice ────────────────────────────────────────────────────────────

class _PendingNotice extends StatelessWidget {
  const _PendingNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your request will be reviewed by Punjabi Welfare Trust admin. Access is granted only after approval.',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Consent checkbox tile ─────────────────────────────────────────────────────

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: onChanged == null ? null : () => onChanged!(!value),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared field widgets ──────────────────────────────────────────────────────

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
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.15)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.primary, width: 2),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.softRed, width: 1.5),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.softRed, width: 2),
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
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.55),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
    );
  }
}

// ── Inline status / error banner ──────────────────────────────────────────────

enum _StatusKind { pending, blocked }

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({required this.message, required this.kind});

  final String message;
  final _StatusKind kind;

  @override
  Widget build(BuildContext context) {
    final isPending = kind == _StatusKind.pending;
    final bg = isPending
        ? const Color(0xFFFFF3CD)
        : AppColors.softRed.withValues(alpha: 0.1);
    final border = isPending
        ? const Color(0xFFFFD600)
        : AppColors.softRed.withValues(alpha: 0.4);
    final ic = isPending ? const Color(0xFF8A6A00) : AppColors.softRed;
    final iconData = isPending
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
          Icon(iconData, size: 17, color: ic),
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
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      backgroundColor: Colors.white,
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
