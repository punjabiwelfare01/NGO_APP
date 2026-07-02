import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../viewmodels/counsellor_home_viewmodel.dart';
import '../internship/wall_of_impact_view.dart';
import 'counsellor_home_view.dart';
import 'counsellor_requests_view.dart';
import 'counsellor_schedule_view.dart';
import 'counsellor_sessions_view.dart';
import 'counsellor_profile_view.dart';

class CounsellorShell extends StatefulWidget {
  const CounsellorShell({super.key});

  @override
  State<CounsellorShell> createState() => _CounsellorShellState();
}

class _CounsellorShellState extends State<CounsellorShell> {
  int _selectedIndex = 0;
  late final CounsellorHomeViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = CounsellorHomeViewModel()..load();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = AppState.studentName ?? 'Counsellor';

    final pages = [
      CounsellorHomeView(
        vm: _vm,
        counsellorName: name,
        onNavigate: (index) => setState(() => _selectedIndex = index),
      ),
      CounsellorRequestsView(vm: _vm),
      CounsellorScheduleView(vm: _vm),
      CounsellorSessionsView(vm: _vm),
      const WallOfImpactView(),
      CounsellorProfileView(vm: _vm),
    ];

    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final newCount = _vm.newRequests.length;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(child: pages[_selectedIndex]),
          bottomNavigationBar: NavigationBar(
            height: 72,
            selectedIndex: _selectedIndex,
            indicatorColor: const Color(0xFF1565C0).withValues(alpha: 0.13),
            backgroundColor: Colors.white,
            elevation: 8,
            shadowColor: AppColors.ink.withValues(alpha: 0.10),
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: [
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: newCount > 0 && _selectedIndex != 0,
                  label: Text('$newCount'),
                  child: const Icon(Icons.home_outlined),
                ),
                selectedIcon: const Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: newCount > 0 && _selectedIndex != 1,
                  label: Text('$newCount'),
                  child: const Icon(Icons.inbox_outlined),
                ),
                selectedIcon: const Icon(Icons.inbox_rounded),
                label: 'Requests',
              ),
              const NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Schedule',
              ),
              const NavigationDestination(
                icon: Icon(Icons.event_note_outlined),
                selectedIcon: Icon(Icons.event_note_rounded),
                label: 'Sessions',
              ),
              const NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome_rounded),
                label: 'Impact',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
