import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/counsellor_viewmodel.dart';
import '../../viewmodels/event_manager_viewmodel.dart';
import '../event_manager/em_impact_view.dart';
import '../profile/profile_view.dart';
import 'admin_home_view.dart';
import 'admin_manage_view.dart';
import 'user_management_screen.dart';
import 'admin_settings_module_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  late final AdminViewModel _adminVm;
  late final EventManagerViewModel _eventVm;

  @override
  void initState() {
    super.initState();
    _adminVm = AdminViewModel()..load();
    _eventVm = EventManagerViewModel()..load();
    CounsellorViewModel.shared.load();
  }

  @override
  void dispose() {
    _adminVm.dispose();
    _eventVm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminHomeView(
        adminVm: _adminVm,
        eventVm: _eventVm,
        onOpenTab: (index) => setState(() => _index = index),
      ),
      UserManagementScreen(vm: _adminVm),
      AdminManageView(adminVm: _adminVm, eventVm: _eventVm),
      EMImpactView(vm: _eventVm),
      const _AdminSettingsView(),
    ];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        indicatorColor: AppColors.primary.withValues(alpha: .13),
        backgroundColor: Colors.white,
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _adminVm.pendingCount > 0 && _index != 0,
              label: Text('${_adminVm.pendingCount}'),
              child: const Icon(Icons.home_outlined),
            ),
            selectedIcon: const Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Users',
          ),
          const NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings_rounded),
            label: 'Manage',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _eventVm.draftPosts.isNotEmpty && _index != 3,
              label: Text('${_eventVm.draftPosts.length}'),
              child: const Icon(Icons.auto_awesome_outlined),
            ),
            selectedIcon: const Icon(Icons.auto_awesome_rounded),
            label: 'Impact',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _AdminSettingsView extends StatelessWidget {
  const _AdminSettingsView();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      const Text(
        'Admin Settings',
        style: TextStyle(
          color: AppColors.ink,
          fontSize: 27,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'NGO profile, permissions, finance and platform security.',
        style: TextStyle(color: AppColors.muted),
      ),
      const SizedBox(height: 18),
      _setting(
        Icons.account_balance_rounded,
        'NGO Profile & Bank Details',
        'Official bank, UPI, QR code and public trust information',
        context,
        AdminSettingsModule.ngo,
      ),
      _setting(
        Icons.manage_accounts_rounded,
        'Roles & Permissions',
        'Control admin, manager, mentor, creator and school access',
        context,
        AdminSettingsModule.roles,
      ),
      _setting(
        Icons.security_rounded,
        'Security & Audit Logs',
        'Session protection, role changes and administrative activity',
        context,
        AdminSettingsModule.audit,
      ),
      _setting(
        Icons.notifications_active_rounded,
        'Announcements',
        'Send verified updates to volunteers and partner schools',
        context,
        AdminSettingsModule.announcements,
      ),
      _setting(
        Icons.tune_rounded,
        'Application Settings',
        'Platform defaults, moderation rules and feature visibility',
        context,
        AdminSettingsModule.app,
      ),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProfileView())),
        icon: const Icon(Icons.person_rounded),
        label: Text(AppState.role.displayName),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Logout?'),
              content: const Text('You will be returned to the login screen.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
          if (ok == true && context.mounted) {
            await AuthViewModel().logout();
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          }
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.red),
        label: const Text('Logout', style: TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
        ),
      ),
    ],
  );

  Widget _setting(
    IconData icon,
    String title,
    String subtitle,
    BuildContext context,
    AdminSettingsModule module,
  ) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminSettingsModuleScreen(module: module),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    ),
  );
}
