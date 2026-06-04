import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/api_models.dart';
import '../../models/auth_models.dart';
import '../../utils/icon_mapper.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scroll_view.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/section_header.dart';
import '../../widgets/top_header.dart';
import 'widgets/badge_pill.dart';
import 'widgets/counselling_history_card.dart';
import 'widgets/profile_hero_card.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileViewModel _vm;
  late final AuthViewModel _authVm;

  @override
  void initState() {
    super.initState();
    _vm = ProfileViewModel();
    _authVm = AuthViewModel();
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    _authVm.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await _authVm.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _openEditProfile() async {
    final user = _vm.user;
    if (user == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        user: user,
        onSave: (name, className, schoolName, location, age, parentEmail, phone) async {
          final ok = await _vm.updateProfile(
            name: name,
            className: className,
            schoolName: schoolName,
            location: location,
            age: age,
            parentEmail: parentEmail,
            phone: phone,
          );
          if (!mounted) return;
          if (ok) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully.')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_vm.updateError ?? 'Failed to update profile.'),
                backgroundColor: Colors.red.shade600,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        if (_vm.state == ViewState.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_vm.state == ViewState.error) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _vm.errorMessage ?? 'Error',
                  style: const TextStyle(color: Colors.grey),
                ),
                TextButton(onPressed: _vm.load, child: const Text('Retry')),
              ],
            ),
          );
        }
        return AppScrollView(
          children: [
            TopHeader(
              title: 'Child Profile',
              subtitle: 'Achievements, learning, and parent view.',
              actionIcon: AppState.role.isStudent ? Icons.edit_rounded : Icons.settings_outlined,
              onActionTap: AppState.role.isStudent ? _openEditProfile : null,
            ),

            // ── Role badge (visible to all roles) ─────────────────────────
            _RoleBadge(role: AppState.role),

            ProfileHeroCard(user: _vm.user),
            const SectionHeader(title: 'Skill Badges'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _vm.badges
                  .map(
                    (ub) => BadgePill(
                      icon: IconMapper.fromName(ub.badge.iconName),
                      label: ub.badge.label,
                    ),
                  )
                  .toList(),
            ),

            const CounsellingHistoryCard(),

            // ── Admin panel shortcut ──────────────────────────────────────
            RoleGuard(
              allowed: const [UserRole.admin, UserRole.superAdmin],
              child: GestureDetector(
                onTap: () =>
                    Navigator.of(context).pushReplacementNamed('/home'),
                child: AppCard(
                  color: AppColors.accent.withValues(alpha: 0.06),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Dashboard',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              'Manage users, approvals, events and more.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Mentor panel hint ─────────────────────────────────────────
            RoleGuard(
              allowed: const [UserRole.mentor],
              child: AppCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.support_agent_rounded,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Mentor Access',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'You can view student progress and award badges.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Sign out ──────────────────────────────────────────────────
            const SizedBox(height: 8),
            ListenableBuilder(
              listenable: _authVm,
              builder: (context, _) => OutlinedButton.icon(
                onPressed: _authVm.state == ViewState.loading ? null : _logout,
                icon: _authVm.state == ViewState.loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.logout_rounded,
                        color: AppColors.softRed,
                      ),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(color: AppColors.softRed),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.softRed),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── sub-widgets ───────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (role) {
      UserRole.superAdmin     => (AppColors.softRed,    Icons.shield_rounded),
      UserRole.admin          => (AppColors.accent,     Icons.admin_panel_settings_rounded),
      UserRole.mentor         => (AppColors.secondary,  Icons.psychology_outlined),
      UserRole.contentCreator => (AppColors.lavender,   Icons.edit_rounded),
      UserRole.student        => (AppColors.primary,    Icons.school_rounded),
      UserRole.eventManager   => (const Color(0xFF6B48FF), Icons.event_available_rounded),
      UserRole.supportStaff   => (const Color(0xFF009688), Icons.support_agent_rounded),
      UserRole.guest          => (AppColors.muted,      Icons.person_outline_rounded),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            role.displayName,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit Profile Bottom Sheet ─────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user, required this.onSave});

  final AppUser user;
  final Future<void> Function(
    String? name,
    String? className,
    String? schoolName,
    String? location,
    int? age,
    String? parentEmail,
    String? phone,
  ) onSave;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _classCtrl;
  late final TextEditingController _schoolCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _parentEmailCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameCtrl = TextEditingController(text: u.name);
    _classCtrl = TextEditingController(text: u.className ?? '');
    _schoolCtrl = TextEditingController(text: u.schoolName ?? '');
    _locationCtrl = TextEditingController(text: u.location ?? '');
    _ageCtrl = TextEditingController(text: u.age?.toString() ?? '');
    _parentEmailCtrl = TextEditingController(text: u.parentEmail ?? '');
    _phoneCtrl = TextEditingController(text: u.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _classCtrl.dispose();
    _schoolCtrl.dispose();
    _locationCtrl.dispose();
    _ageCtrl.dispose();
    _parentEmailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final age = int.tryParse(_ageCtrl.text.trim());
    await widget.onSave(
      _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      _classCtrl.text.trim().isEmpty ? null : _classCtrl.text.trim(),
      _schoolCtrl.text.trim().isEmpty ? null : _schoolCtrl.text.trim(),
      _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      age,
      _parentEmailCtrl.text.trim().isEmpty ? null : _parentEmailCtrl.text.trim(),
      _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Handle ───────────────────────────────────────
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.muted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Update your name, class, school, and location.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 20),

                _SheetField(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  icon: Icons.badge_outlined,
                  enabled: !_saving,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                _SheetField(
                  controller: _classCtrl,
                  label: 'Class / Grade',
                  icon: Icons.class_outlined,
                  enabled: !_saving,
                ),
                const SizedBox(height: 12),
                _SheetField(
                  controller: _schoolCtrl,
                  label: 'School Name',
                  icon: Icons.apartment_outlined,
                  enabled: !_saving,
                ),
                const SizedBox(height: 12),
                _SheetField(
                  controller: _locationCtrl,
                  label: 'Location / City',
                  icon: Icons.location_on_outlined,
                  enabled: !_saving,
                ),
                const SizedBox(height: 12),
                _SheetField(
                  controller: _ageCtrl,
                  label: 'Age',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  enabled: !_saving,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final a = int.tryParse(v.trim());
                    if (a == null || a < 5 || a > 25) return 'Enter a valid age (5–25)';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _SheetField(
                  controller: _parentEmailCtrl,
                  label: 'Parent / Guardian Email',
                  icon: Icons.family_restroom_outlined,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_saving,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _SheetField(
                  controller: _phoneCtrl,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  enabled: !_saving,
                ),
                const SizedBox(height: 24),

                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
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
        fillColor: AppColors.background,
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
