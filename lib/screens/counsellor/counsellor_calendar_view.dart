import 'package:flutter/material.dart';

import '../../viewmodels/counsellor_home_viewmodel.dart';
import 'counsellor_schedule_view.dart';

/// Thin compatibility wrapper — replaced by CounsellorScheduleView.
class CounsellorCalendarView extends StatelessWidget {
  const CounsellorCalendarView({required this.vm, super.key});
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) => CounsellorScheduleView(vm: vm);
}
