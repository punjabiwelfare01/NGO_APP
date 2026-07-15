import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/counsellor_viewmodel.dart';
import '../../viewmodels/event_manager_viewmodel.dart';
import '../event_manager/em_impact_view.dart';
import 'admin_home_view.dart';
import 'admin_manage_view.dart';
import 'admin_settings_view.dart';
import 'user_management_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  late final AdminViewModel _adminVm;
  late final EventManagerViewModel _eventVm;
  final _homeKey = GlobalKey<AdminHomeViewState>();

  @override
  void initState() {
    super.initState();
    _adminVm = AdminViewModel.shared..load();
    _eventVm = EventManagerViewModel.shared..load();
    CounsellorViewModel.shared.load();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminHomeView(
        key: _homeKey,
        adminVm: _adminVm,
        eventVm: _eventVm,
        onOpenTab: (index) => setState(() => _index = index),
      ),
      UserManagementScreen(vm: _adminVm),
      AdminManageView(adminVm: _adminVm, eventVm: _eventVm),
      EMImpactView(vm: _eventVm),
      const AdminSettingsView(),
    ];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 14,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w600,
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.muted,
            ),
          ),
        ),
        child: NavigationBar(
          height: 80,
          selectedIndex: _index,
          onDestinationSelected: (value) {
            if (value == _index) return;
            setState(() => _index = value);
            switch (value) {
              case 0:
                _adminVm.load(force: true);
                _eventVm.load(force: true);
                _homeKey.currentState?.refresh();
              case 1:
                _adminVm.loadAllUsers();
              case 3:
                _eventVm.load(force: true);
            }
          },
          indicatorColor: AppColors.primary.withValues(alpha: .16),
          backgroundColor: Colors.white,
          destinations: [
            NavigationDestination(
              icon: Badge(
                isLabelVisible: _adminVm.pendingCount > 0 && _index != 0,
                label: Text('${_adminVm.pendingCount}'),
                child: const Icon(Icons.home_outlined, size: 26),
              ),
              selectedIcon: const Icon(Icons.home_rounded, size: 26),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.people_outline_rounded, size: 26),
              selectedIcon: Icon(Icons.people_rounded, size: 26),
              label: 'Users',
            ),
            const NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined, size: 26),
              selectedIcon: Icon(Icons.admin_panel_settings_rounded, size: 26),
              label: 'Manage',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: _eventVm.draftPosts.isNotEmpty && _index != 3,
                label: Text('${_eventVm.draftPosts.length}'),
                child: const Icon(Icons.auto_awesome_outlined, size: 26),
              ),
              selectedIcon: const Icon(Icons.auto_awesome_rounded, size: 26),
              label: 'Impact',
            ),
            const NavigationDestination(
              icon: Icon(Icons.settings_outlined, size: 26),
              selectedIcon: Icon(Icons.settings_rounded, size: 26),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
