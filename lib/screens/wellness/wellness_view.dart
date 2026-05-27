import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/auth_models.dart';
import '../../widgets/app_scroll_view.dart';
import '../../widgets/top_header.dart';
import 'widgets/booking_flow_card.dart';
import 'widgets/emergency_help_card.dart';
import 'widgets/protection_lesson_card.dart';
import 'widgets/wellness_action_card.dart';

class WellnessView extends StatefulWidget {
  const WellnessView({super.key});

  @override
  State<WellnessView> createState() => _WellnessViewState();
}

class _WellnessViewState extends State<WellnessView> {
  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: AppScrollView(
        children: [
          const TopHeader(
            title: 'Wellness',
            subtitle: 'Private, calm support from trusted people.',
            actionIcon: Icons.lock_outline_rounded,
          ),
          const EmergencyHelpCard(),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.25,
            children: const [
              WellnessActionCard(
                icon: Icons.calendar_month_rounded,
                title: 'Book Session',
                color: AppColors.primary,
              ),
              WellnessActionCard(
                icon: Icons.support_agent_rounded,
                title: 'Talk to Mentor',
                color: AppColors.secondary,
              ),
              WellnessActionCard(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Chat Support',
                color: AppColors.accent,
              ),
              WellnessActionCard(
                icon: Icons.video_call_rounded,
                title: 'Video Call',
                color: AppColors.lavender,
              ),
            ],
          ),
          const BookingFlowCard(),
          if (AppState.role.isMentor ||
              AppState.role.isAdmin ||
              AppState.role == UserRole.superAdmin)
            const MentorCalendarCard(),
          const ProtectionLessonCard(),
        ],
      ),
    );
  }
}
