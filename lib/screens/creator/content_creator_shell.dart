import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scroll_view.dart';
import '../../widgets/top_header.dart';
import 'content_analytics_view.dart';
import 'content_creator_content_view.dart';
import 'content_creator_profile_view.dart';
import 'content_creator_upload_view.dart';

class ContentCreatorShell extends StatefulWidget {
  const ContentCreatorShell({super.key});

  @override
  State<ContentCreatorShell> createState() => _ContentCreatorShellState();
}

class _ContentCreatorShellState extends State<ContentCreatorShell> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _CreatorHomeView(),
      const ContentAnalyticsView(),
      const ContentCreatorUploadView(),
      const ContentCreatorContentView(),
      const ContentCreatorProfileView(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _selectedIndex,
        indicatorColor: AppColors.primary.withValues(alpha: 0.16),
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Upload',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Content',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _CreatorHomeView extends StatelessWidget {
  const _CreatorHomeView();

  @override
  Widget build(BuildContext context) {
    return AppScrollView(
      children: const [
        TopHeader(
          title: 'Creator Home',
          subtitle: 'Plan lessons and track learner progress.',
          actionIcon: Icons.notifications_none_rounded,
          badgeCount: 3,
        ),
        _QuickSummaryCard(),
      ],
    );
  }
}

class _QuickSummaryCard extends StatelessWidget {
  const _QuickSummaryCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This Week',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: _MiniMetric(
                  icon: Icons.visibility_rounded,
                  value: '3.2K',
                  label: 'Views',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  icon: Icons.task_alt_rounded,
                  value: '74%',
                  label: 'Completion',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
