import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models/skill_category.dart';
import 'free_courses_view.dart';
import 'management/learning_management_view.dart';

/// One learning destination: students browse free NGO courses while creators,
/// mentors, and admins manage the same unified catalogue.
class LearnView extends StatelessWidget {
  const LearnView({this.initialCategory, super.key});

  final SkillCategory? initialCategory;

  @override
  Widget build(BuildContext context) {
    if (AppState.role.isStudent) {
      return FreeCoursesView(initialCategory: initialCategory);
    }
    return const LearningManagementView();
  }
}
