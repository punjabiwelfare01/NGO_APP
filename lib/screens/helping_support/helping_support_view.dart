import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/auth_models.dart';
import '../../viewmodels/counselling_viewmodel.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/app_scroll_view.dart';
import '../../widgets/section_header.dart';
import '../../widgets/top_header.dart';
import '../wellness/widgets/booking_flow_card.dart';
import '../wellness/widgets/emergency_help_card.dart';
import '../wellness/widgets/protection_lesson_card.dart';
import '../wellness/widgets/wellness_action_card.dart';
import 'admin/counselling_admin_screen.dart';
import 'admin/emergency_contacts_admin_screen.dart';
import 'mentor/mentor_chats_screen.dart';
import 'mentor/mentor_schedule_screen.dart';
import 'student/mentor_list_screen.dart';
import 'student/my_sessions_screen.dart';
import 'widgets/live_session_banner.dart';
import 'widgets/mentor_card.dart';
import 'widgets/session_tile.dart';

class HelpingSupportView extends StatefulWidget {
  const HelpingSupportView({super.key});

  @override
  State<HelpingSupportView> createState() => _HelpingSupportViewState();
}

class _HelpingSupportViewState extends State<HelpingSupportView> {
  late final CounsellingViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = CounsellingViewModel();
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        if (_vm.state == ViewState.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final role = AppState.role;
        final isAdmin = role.isAdmin || role == UserRole.contentCreator;
        final isMentor = role.isMentor;

        return AppScrollView(
          children: [
            const TopHeader(
              title: 'Helping Support',
              subtitle: 'Connect with mentors. Book a session. Get support.',
              actionIcon: Icons.support_agent_rounded,
            ),
            if (_vm.state == ViewState.error)
              _ErrorBanner(message: _vm.errorMessage!, onRetry: _vm.load),

            // Live session join banner — shown when student has an active session with link
            if (!isAdmin && !isMentor && _vm.liveSession != null)
              LiveSessionBanner(session: _vm.liveSession!),

            // Admin / Content Creator view
            if (isAdmin) ...[
              _AdminPanel(
                onManageMentors: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const CounsellingAdminScreen()),
                ),
                onManageEmergency: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const EmergencyContactsAdminScreen()),
                ),
              ),
              SectionHeader(
                title: 'Recent Bookings',
                action: _vm.mySessions.isEmpty ? null : 'View all',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MySessionsScreen()),
                ),
              ),
              if (_vm.upcomingSessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No upcoming bookings.',
                      style: TextStyle(color: AppColors.muted)),
                )
              else
                ..._vm.upcomingSessions
                    .take(3)
                    .map((s) => SessionTile(session: s)),
            ],

            // Mentor view
            if (isMentor) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ActionTile(
                  icon: Icons.chat_rounded,
                  label: 'My Student Chats',
                  color: AppColors.secondary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const MentorChatsScreen()),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ActionTile(
                  icon: Icons.calendar_month_rounded,
                  label: 'My Schedule',
                  color: AppColors.primary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const MentorScheduleScreen()),
                  ),
                ),
              ),
              SectionHeader(
                title: 'Today\'s Sessions',
                action: _vm.mySessions.isEmpty ? null : 'All sessions',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MySessionsScreen()),
                ),
              ),
              if (_vm.upcomingSessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No sessions scheduled.',
                      style: TextStyle(color: AppColors.muted)),
                )
              else
                ..._vm.upcomingSessions
                    .take(3)
                    .map((s) => SessionTile(session: s)),
            ],

            // Student view
            if (!isAdmin && !isMentor) ...[
              // Quick actions grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.25,
                children: [
                  WellnessActionCard(
                    icon: Icons.calendar_month_rounded,
                    title: 'Book Session',
                    color: AppColors.primary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const MentorListScreen()),
                    ),
                  ),
                  WellnessActionCard(
                    icon: Icons.support_agent_rounded,
                    title: 'Talk to Mentor',
                    color: AppColors.secondary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const MentorListScreen()),
                    ),
                  ),
                  WellnessActionCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Chat Support',
                    color: AppColors.accent,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const MentorListScreen()),
                    ),
                  ),
                  const WellnessActionCard(
                    icon: Icons.video_call_rounded,
                    title: 'Video Call',
                    color: AppColors.lavender,
                  ),
                ],
              ),

              // Browse mentors
              SectionHeader(
                title: 'Browse Mentors',
                action: 'View all',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MentorListScreen()),
                ),
              ),
              if (_vm.mentors.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No mentors available yet.',
                      style: TextStyle(color: AppColors.muted)),
                )
              else
                ..._vm.mentors.take(3).map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: MentorCard(
                          mentor: m,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MentorListScreen(),
                            ),
                          ),
                          onBook: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MentorListScreen(),
                            ),
                          ),
                        ),
                      ),
                    ),

              // My upcoming sessions
              SectionHeader(
                title: 'My Sessions',
                action: _vm.mySessions.isEmpty ? null : 'View all',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MySessionsScreen()),
                ),
              ),
              if (_vm.upcomingSessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No upcoming sessions. Book one above!',
                      style: TextStyle(color: AppColors.muted)),
                )
              else
                ..._vm.upcomingSessions
                    .take(2)
                    .map((s) => SessionTile(session: s)),

              // Slot booking flow (quick book)
              const BookingFlowCard(),
            ],

            // Always at bottom for all roles
            const EmergencyHelpCard(),
            const ProtectionLessonCard(),
          ],
        );
      },
    );
  }
}

class _AdminPanel extends StatelessWidget {
  const _AdminPanel({
    required this.onManageMentors,
    required this.onManageEmergency,
  });

  final VoidCallback onManageMentors;
  final VoidCallback onManageEmergency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.manage_accounts_rounded,
                  label: 'Manage Mentors',
                  color: AppColors.primary,
                  onTap: onManageMentors,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionTile(
                  icon: Icons.bar_chart_rounded,
                  label: 'Analytics',
                  color: AppColors.secondary,
                  onTap: onManageMentors,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.emergency_rounded,
            label: 'Emergency Contacts',
            color: AppColors.softRed,
            onTap: onManageEmergency,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
