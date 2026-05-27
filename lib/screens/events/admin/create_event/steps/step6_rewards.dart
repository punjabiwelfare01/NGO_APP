import 'package:flutter/material.dart';

import '../../../../../core/colors.dart';
import '../../../../../viewmodels/create_event_viewmodel.dart';

class RewardsStep extends StatelessWidget {
  const RewardsStep({required this.vm, super.key});

  final CreateEventViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rewards & Benefits',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppColors.ink)),
              const SizedBox(height: 8),
              Text(
                'Enable the perks selected participants will receive.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              _RewardTile(
                icon: Icons.support_agent_rounded,
                iconColor: AppColors.primary,
                title: 'Counselling Access',
                description:
                    'Selected participants get a 1-on-1 counselling session',
                value: vm.counsellingEnabled,
                onChanged: vm.setCounsellingEnabled,
              ),
              const Divider(height: 1),
              _RewardTile(
                icon: Icons.workspace_premium_rounded,
                iconColor: AppColors.accent,
                title: 'Completion Certificate',
                description:
                    'Issue digital certificates to selected participants',
                value: vm.certificateEnabled,
                onChanged: vm.setCertificateEnabled,
              ),
              const Divider(height: 1),
              _RewardTile(
                icon: Icons.school_rounded,
                iconColor: AppColors.secondary,
                title: 'Scholarship Eligibility',
                description:
                    'Mark selected participants as scholarship eligible',
                value: vm.scholarshipEnabled,
                onChanged: vm.setScholarshipEnabled,
              ),
              const Divider(height: 1),
              _RewardTile(
                icon: Icons.people_alt_rounded,
                iconColor: const Color(0xFF9C6FDE),
                title: 'Mentorship Access',
                description: 'Connect participants with dedicated mentors',
                value: vm.mentorshipEnabled,
                onChanged: vm.setMentorshipEnabled,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      secondary: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.12),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: AppColors.ink)),
      subtitle: Text(description,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.muted)),
      value: value,
      onChanged: onChanged,
    );
  }
}
