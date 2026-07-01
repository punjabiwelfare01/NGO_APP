import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../viewmodels/event_manager_viewmodel.dart';
import '../../viewmodels/counsellor_viewmodel.dart';
import '../profile/profile_view.dart';
import 'em_activities_view.dart';
import 'em_home_view.dart';
import 'em_events_view.dart';
import 'em_students_view.dart';
import 'em_impact_view.dart';

class EventManagerShell extends StatefulWidget {
  const EventManagerShell({super.key});

  @override
  State<EventManagerShell> createState() => _EventManagerShellState();
}

class _EventManagerShellState extends State<EventManagerShell> {
  int _selectedIndex = 0;
  late final EventManagerViewModel _vm;
  final _studentsTabNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _vm = EventManagerViewModel()..load();
    CounsellorViewModel.shared.load();
  }

  @override
  void dispose() {
    _studentsTabNotifier.dispose();
    _vm.dispose();
    super.dispose();
  }

  void _navigateToStudents(int subTabIndex) {
    _studentsTabNotifier.value = subTabIndex;
    setState(() => _selectedIndex = 3); // Students is now index 3
  }

  @override
  Widget build(BuildContext context) {
    final name = AppState.studentName ?? 'Event Manager';

    final pages = [
      EMHomeView(vm: _vm, managerName: name, onNavigateToStudents: _navigateToStudents),
      EMEventsView(vm: _vm),
      EMActivitiesView(vm: _vm),
      EMStudentsView(vm: _vm, tabNotifier: _studentsTabNotifier),
      EMImpactView(vm: _vm),
      const ProfileView(),
    ];

    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final pendingCount =
            _vm.stats.pendingSubmissions +
            _vm.stats.pendingImpactPosts +
            _vm.appliedStudents.length;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(child: pages[_selectedIndex]),
          bottomNavigationBar: NavigationBar(
            height: 72,
            selectedIndex: _selectedIndex,
            indicatorColor: const Color(0xFF1565C0).withValues(alpha: 0.14),
            backgroundColor: Colors.white,
            elevation: 8,
            shadowColor: AppColors.ink.withValues(alpha: 0.10),
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: [
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: pendingCount > 0 && _selectedIndex != 0,
                  label: Text('$pendingCount'),
                  child: const Icon(Icons.home_outlined),
                ),
                selectedIcon: const Icon(Icons.home_rounded),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.event_outlined),
                selectedIcon: Icon(Icons.event_rounded),
                label: 'Events',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible:
                      _vm.stats.pendingSubmissions > 0 && _selectedIndex != 2,
                  label: Text('${_vm.stats.pendingSubmissions}'),
                  child: const Icon(Icons.assignment_outlined),
                ),
                selectedIcon: const Icon(Icons.assignment_rounded),
                label: 'Activities',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible:
                      _vm.appliedStudents.isNotEmpty && _selectedIndex != 3,
                  label: Text('${_vm.appliedStudents.length}'),
                  child: const Icon(Icons.people_outline_rounded),
                ),
                selectedIcon: const Icon(Icons.people_rounded),
                label: 'Students',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible:
                      _vm.draftPosts.isNotEmpty && _selectedIndex != 4,
                  label: Text('${_vm.draftPosts.length}'),
                  child: const Icon(Icons.emoji_events_outlined),
                ),
                selectedIcon: const Icon(Icons.emoji_events_rounded),
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
