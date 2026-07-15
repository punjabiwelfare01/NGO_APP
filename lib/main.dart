import 'dart:io';

import 'package:flutter/material.dart';

import 'app_state.dart';
import 'core/colors.dart';
import 'core/config.dart';
import 'models/auth_models.dart';
import 'models/skill_category.dart';
import 'repositories/auth_repository.dart';
import 'repositories/api_client.dart';
import 'screens/admin/pending_approvals_screen.dart';
import 'screens/admin/volunteer_admin_screen.dart';
import 'screens/admin/counsellor_admin_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/volunteer/volunteer_dashboard_screen.dart';
import 'screens/auth/auth_page.dart';
import 'screens/auth/pending_approval_screen.dart';
import 'screens/auth/rejected_screen.dart';
import 'screens/auth/student_register_screen.dart';
import 'screens/counsellor/counsellor_shell.dart';
import 'screens/creator/content_creator_shell.dart';
import 'screens/event_manager/event_manager_shell.dart';
import 'screens/events/events_view.dart';
import 'screens/events/student/event_detail_screen.dart';
import 'screens/home/home_view.dart';
import 'screens/learn/learn_view.dart';
import 'screens/profile/profile_view.dart';
import 'screens/quiz/quiz_play_screen.dart';
import 'screens/helping_support/helping_support_view.dart';
import 'screens/internship/internship_view.dart';
import 'screens/internship/wall_of_impact_view.dart';
import 'screens/school_portal/school_partner_portal_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    stderr.writeln('FlutterError: ${details.exception}\n${details.stack}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('Build error: ${details.exception}');
    return Material(
      color: const Color(0xFFFEF2F2),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)),
              const SizedBox(height: 12),
              Text(
                'Something went wrong.',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF991B1B)),
              ),
              const SizedBox(height: 8),
              Text(
                details.exception.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF7F1D1D), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  };

  AppState.restore();
  // Reconcile the cached role with the backend before choosing a dashboard.
  // Admin approval may have changed a provisional student into a counsellor.
  if (AppState.isAuthenticated) {
    try {
      final currentUser = await AuthRepository.getCurrentUser();
      AppState.setFromLogin(
        currentUser.id,
        AppState.token!,
        UserRole.fromString(currentUser.role ?? 'guest'),
        name: currentUser.name,
        status: AccessStatus.fromString(currentUser.accessStatus ?? 'pending'),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        AppState.clear();
      }
    } catch (_) {
      // A temporary network outage should not destroy a valid saved session.
    }
  }
  runApp(const PunjabiWelfareApp());
}

String _resolveInitialRoute() {
  if (!AppState.isAuthenticated) return '/login';
  return switch (AppState.accessStatus) {
    AccessStatus.approved => '/home',
    AccessStatus.pendingVerification => '/pending-approval',
    AccessStatus.rejected => '/rejected',
    AccessStatus.deactivated => '/rejected',
  };
}

class PunjabiWelfareApp extends StatelessWidget {
  const PunjabiWelfareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: Colors.white,
        ),
        fontFamily: AppConfig.fontFamily,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontWeight: FontWeight.w800),
          headlineMedium: TextStyle(fontWeight: FontWeight.w800),
          titleLarge: TextStyle(fontWeight: FontWeight.w800),
          titleMedium: TextStyle(fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      // Route on startup based on both auth state and access status.
      initialRoute: _resolveInitialRoute(),
      routes: {
        '/login': (_) => const AuthPage(),
        '/home': (_) => AppState.role.isContentCreator
            ? const ContentCreatorShell()
            : AppState.role.isEventManager
            ? const EventManagerShell()
            : AppState.role.isMentor
            ? const CounsellorShell()
            : AppState.role.isSchoolPartner
            ? const SchoolPartnerPortalScreen()
            : AppState.role.isAdmin
            ? const AdminShell()
            : const AppShell(),
        '/register/student': (_) => const StudentRegisterScreen(),
        '/pending-approval': (_) => const PendingApprovalScreen(),
        '/rejected': (_) => const RejectedScreen(),
        '/admin/pending-approvals': (_) => const PendingApprovalsScreen(),
        '/admin/volunteer': (_) => const VolunteerAdminScreen(),
        '/admin/counsellors': (_) => const CounsellorAdminScreen(),
        '/school-partner': (_) => const SchoolPartnerPortalScreen(),
        '/volunteer': (_) => const VolunteerDashboardScreen(),
      },
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        final uri = Uri.parse(name);
        if (uri.pathSegments.length == 2) {
          final id = int.tryParse(uri.pathSegments[1]);
          if (id != null && uri.pathSegments[0] == 'quiz') {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => QuizPlayScreen(quizId: id),
            );
          }
          const eventPrefixes = {
            'event',
            'quiz-event',
            'daily-challenge',
            'workshop',
            'competition',
            'scholarship',
            'counselling-drive',
            'talent-hunt',
            'awareness-campaign',
            'cyber-security',
          };
          if (id != null && eventPrefixes.contains(uri.pathSegments[0])) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => EventDetailScreen(eventId: id),
            );
          }
        }
        return null;
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  SkillCategory? _selectedLearnCategory;
  int _learnOpenVersion = 0;

  void _openLearn([SkillCategory? category]) {
    setState(() {
      _selectedIndex = 1;
      _selectedLearnCategory = category;
      _learnOpenVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = AppState.role.isStudent;

    final pages = isStudent
        ? [
            HomeView(onOpenLearn: _openLearn),
            LearnView(
              key: ValueKey('learn-$_learnOpenVersion'),
              initialCategory: _selectedLearnCategory,
            ),
            InternshipView(onBack: () => setState(() => _selectedIndex = 0)),
            const WallOfImpactView(),
            const ProfileView(),
          ]
        : [
            HomeView(onOpenLearn: _openLearn),
            LearnView(
              key: ValueKey('learn-$_learnOpenVersion'),
              initialCategory: _selectedLearnCategory,
            ),
            const EventsView(),
            const HelpingSupportView(),
            const ProfileView(),
          ];

    const studentItems = [
      _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
      _NavItem(Icons.school_outlined, Icons.school_rounded, 'Learn'),
      _NavItem(
        Icons.volunteer_activism_outlined,
        Icons.volunteer_activism_rounded,
        'Work',
      ),
      _NavItem(
        Icons.emoji_events_outlined,
        Icons.emoji_events_rounded,
        'Impact',
      ),
      _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
    ];

    const staffItems = [
      _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
      _NavItem(Icons.school_outlined, Icons.school_rounded, 'Learn'),
      _NavItem(
        Icons.calendar_month_outlined,
        Icons.calendar_month_rounded,
        'Calendar',
      ),
      _NavItem(
        Icons.support_agent_outlined,
        Icons.support_agent_rounded,
        'Support',
      ),
      _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: _CustomNavBar(
        selectedIndex: _selectedIndex,
        items: isStudent ? studentItems : staffItems,
        onTap: (index) => setState(() {
          _selectedIndex = index;
          if (index != 1) _selectedLearnCategory = null;
          if (index == 1) _learnOpenVersion++;
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom bottom navigation
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _CustomNavBar extends StatelessWidget {
  const _CustomNavBar({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1417324D),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 8,
        bottom: bottomPadding > 0 ? bottomPadding : 10,
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final active = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFDEEAFF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      active ? item.activeIcon : item.icon,
                      size: 22,
                      color: active
                          ? const Color(0xFF17324D)
                          : const Color(0xFFB0BEC5),
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style: TextStyle(
                      color: active
                          ? const Color(0xFF17324D)
                          : const Color(0xFFB0BEC5),
                      fontSize: 10.5,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                      height: 1,
                    ),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
