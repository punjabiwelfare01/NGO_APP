import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/auth_models.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/view_state.dart';

class StudentRegisterScreen extends StatefulWidget {
  const StudentRegisterScreen({super.key});

  @override
  State<StudentRegisterScreen> createState() => _StudentRegisterScreenState();
}

class _StudentRegisterScreenState extends State<StudentRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _parentEmailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  late final AuthViewModel _vm;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _requestedRole;

  @override
  void initState() {
    super.initState();
    _vm = AuthViewModel();
  }

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
    _ageCtrl.dispose();
    _parentEmailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final age = int.tryParse(_ageCtrl.text.trim());
    final status = await _vm.registerStudent(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      className: _classCtrl.text.trim(),
      schoolName: _schoolCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      age: age,
      parentEmail: _parentEmailCtrl.text.trim().isEmpty
          ? null
          : _parentEmailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      requestedRole: _requestedRole,
    );
    if (!mounted || status == null) return;
    switch (status) {
      case AccessStatus.approved:
        Navigator.of(context).pushReplacementNamed('/home');
      case AccessStatus.pendingVerification:
        Navigator.of(context).pushReplacementNamed('/pending-approval');
      case AccessStatus.rejected:
        Navigator.of(context).pushReplacementNamed('/rejected');
      case AccessStatus.deactivated:
        Navigator.of(context).pushReplacementNamed('/rejected');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.ink),
        title: const Text(
          'Create Volunteer Account',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final loading = _vm.state == ViewState.loading;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──────────────────────────────────────────
                  _SectionLabel(
                    icon: Icons.person_add_rounded,
                    label: 'Personal Details',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),

                  // Name
                  _FormField(
                    controller: _nameCtrl,
                    label: 'Full Name',
                    icon: Icons.badge_outlined,
                    enabled: !loading,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Email
                  _FormField(
                    controller: _emailCtrl,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !loading,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Password
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    enabled: !loading,
                    decoration: _inputDec('Password', Icons.lock_outline_rounded).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.muted,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscureConfirm,
                    enabled: !loading,
                    decoration: _inputDec('Confirm Password', Icons.lock_rounded).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.muted,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please confirm your password';
                      if (v != _passwordCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Volunteer Details ────────────────────────────────
                  _SectionLabel(
                    icon: Icons.volunteer_activism_rounded,
                    label: 'Volunteer Details',
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 12),

                  // Location
                  _FormField(
                    controller: _locationCtrl,
                    label: 'Location / City',
                    icon: Icons.location_on_outlined,
                    enabled: !loading,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Location is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Optional Details ─────────────────────────────────
                  _SectionLabel(
                    icon: Icons.info_outline_rounded,
                    label: 'Optional Details',
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: 12),

                  // Age
                  _FormField(
                    controller: _ageCtrl,
                    label: 'Age (optional)',
                    icon: Icons.cake_outlined,
                    keyboardType: TextInputType.number,
                    enabled: !loading,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final age = int.tryParse(v.trim());
                      if (age == null || age < 5 || age > 60) {
                        return 'Enter a valid age (5–60)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Phone
                  _FormField(
                    controller: _phoneCtrl,
                    label: 'Phone Number (optional)',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    enabled: !loading,
                  ),
                  const SizedBox(height: 12),

                  // Requested role
                  DropdownButtonFormField<String>(
                    initialValue: _requestedRole,
                    decoration: InputDecoration(
                      labelText: 'I want to join as (optional)',
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        color: AppColors.muted,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'student',
                        child: Text('Student'),
                      ),
                      DropdownMenuItem(
                        value: 'mentor',
                        child: Text('Mentor'),
                      ),
                      DropdownMenuItem(
                        value: 'content_creator',
                        child: Text('Content Creator'),
                      ),
                    ],
                    onChanged: loading
                        ? null
                        : (v) => setState(() => _requestedRole = v),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      'This is a request only. Final role is assigned by admin after review.',
                      style: TextStyle(
                        color: AppColors.muted.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Error ────────────────────────────────────────────
                  if (_vm.state == ViewState.error && _vm.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.softRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.softRed.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.softRed,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _vm.errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.softRed,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Submit ───────────────────────────────────────────
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
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // ── Already have account ─────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDec(String label, IconData icon) => InputDecoration(
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.softRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.softRed, width: 2),
        ),
      );
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  const _FormField({
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
      enabled: enabled,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.softRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.softRed, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}

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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
