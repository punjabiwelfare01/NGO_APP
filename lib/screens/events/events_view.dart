import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models/auth_models.dart';
import '../../viewmodels/events_viewmodel.dart';
import '../calendar/student_calendar_view.dart';
import 'events_dashboard_screen.dart';

class EventsView extends StatelessWidget {
  const EventsView({super.key});

  @override
  Widget build(BuildContext context) {
    final role = AppState.role;
    if (role.isAdmin ||
        role == UserRole.superAdmin ||
        role.isMentor ||
        role.isContentCreator) {
      return EventsDashboardScreen(
        vm: EventsViewModel(isAdmin: role.isAdmin || role == UserRole.superAdmin)..load(),
      );
    }
    return const StudentCalendarView();
  }
}
