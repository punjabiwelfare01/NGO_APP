import 'package:flutter/material.dart';

import '../../../../../core/colors.dart';
import '../../../../../viewmodels/create_event_viewmodel.dart';

class NotificationsStep extends StatelessWidget {
  const NotificationsStep({required this.vm, super.key});

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
              Text('Notifications',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppColors.ink)),
              const SizedBox(height: 8),
              Text(
                'Choose how participants will be notified about this event.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.notifications_active_outlined,
                    color: AppColors.primary),
                title: const Text('Push Notification'),
                subtitle: const Text(
                    'Send push alerts to participants\' devices'),
                value: vm.pushNotification,
                onChanged: (v) => vm.setPushNotification(v ?? true),
                activeColor: AppColors.primary,
              ),
              const Divider(height: 1),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.mark_chat_unread_outlined,
                    color: AppColors.secondary),
                title: const Text('In-App Notification'),
                subtitle: const Text(
                    'Show notifications inside the Punjabi Welfare Trust app'),
                value: vm.inAppNotification,
                onChanged: (v) => vm.setInAppNotification(v ?? true),
                activeColor: AppColors.primary,
              ),
              const Divider(height: 1),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.email_outlined,
                    color: AppColors.accent),
                title: const Text('Email Notification'),
                subtitle: const Text(
                    'Send event updates to participants\' email addresses'),
                value: vm.emailNotification,
                onChanged: (v) => vm.setEmailNotification(v ?? false),
                activeColor: AppColors.primary,
              ),
            ],
          ),
        );
      },
    );
  }
}
