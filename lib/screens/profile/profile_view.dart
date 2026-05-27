import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
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
            const TopHeader(
              title: 'Child Profile',
              subtitle: 'Achievements, learning, and parent view.',
              actionIcon: Icons.settings_outlined,
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

            // ── Admin panel hint (only admins see this) ───────────────────
            RoleGuard(
              allowed: const [UserRole.admin, UserRole.superAdmin],
              child: AppCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Admin Access',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'You have full system access.',
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
      UserRole.superAdmin => (AppColors.softRed, Icons.shield_rounded),
      UserRole.admin => (AppColors.accent, Icons.admin_panel_settings_rounded),
      UserRole.mentor => (AppColors.secondary, Icons.support_agent_rounded),
      UserRole.contentCreator => (AppColors.lavender, Icons.edit_rounded),
      UserRole.student => (AppColors.primary, Icons.school_rounded),
      UserRole.guest => (AppColors.muted, Icons.person_outline_rounded),
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
