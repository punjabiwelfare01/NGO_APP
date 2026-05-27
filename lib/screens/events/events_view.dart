import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models/auth_models.dart';
import 'admin/event_manager_screen.dart';
import 'student/event_list_screen.dart';

class EventsView extends StatelessWidget {
  const EventsView({super.key});

  @override
  Widget build(BuildContext context) {
    final role = AppState.role;
    if (role.isAdmin ||
        role == UserRole.superAdmin ||
        role.isMentor ||
        role.isContentCreator) {
      return const EventManagerScreen();
    }
    return const EventListScreen();
  }
}
