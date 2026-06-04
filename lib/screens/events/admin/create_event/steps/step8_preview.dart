import 'package:flutter/material.dart';

import '../../../../../core/colors.dart';
import '../../../../../viewmodels/create_event_viewmodel.dart';

class PreviewStep extends StatelessWidget {
  const PreviewStep({required this.vm, super.key});

  final CreateEventViewModel vm;

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day}/${dt.month}/${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _quizMethodLabel() {
    if (!vm.quizRequired) return 'Skipped';
    return switch (vm.quizAttachmentMethod) {
      'create' => vm.createdQuiz != null ? 'Created quiz' : 'Create new quiz',
      'existing' => 'Attach existing quiz',
      'upload' => 'Uploaded quiz file',
      _ => vm.quizAttachmentMethod,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final validationItems = vm.getValidationItems();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preview',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: 16),
              _ValidationChecklist(items: validationItems),
              const SizedBox(height: 8),
              _Section(
                title: 'Basic Info',
                rows: [
                  _Row('Title', vm.title.isEmpty ? '—' : vm.title),
                  _Row('Subtitle', vm.subtitle.isEmpty ? '—' : vm.subtitle),
                  _Row(
                    'Description',
                    vm.description.isEmpty ? '—' : vm.description,
                  ),
                  _Row('Event Type', vm.selectedEventType.displayName),
                  _Row('Theme Color', vm.themeColor),
                ],
              ),
              _Section(
                title: 'Timeline',
                rows: [
                  _Row('Registration Start', _fmtDate(vm.registrationStart)),
                  _Row('Registration End', _fmtDate(vm.registrationEnd)),
                  _Row('Event Start', _fmtDate(vm.eventStart)),
                  _Row('Event End', _fmtDate(vm.eventEnd)),
                  _Row('Result Date', _fmtDate(vm.resultDate)),
                  _Row('Counselling Date', _fmtDate(vm.counsellingDate)),
                  _Row('Auto Publish', vm.autoPublish ? 'Yes' : 'No'),
                  _Row('Auto Close', vm.autoClose ? 'Yes' : 'No'),
                  _Row(
                    'Auto Result Publish',
                    vm.autoResultPublish ? 'Yes' : 'No',
                  ),
                  _Row('Auto Notification', vm.autoNotification ? 'Yes' : 'No'),
                ],
              ),
              _Section(
                title: 'Rules',
                rows: [
                  _Row(
                    'Age Range',
                    '${vm.ageMin ?? '—'} – ${vm.ageMax ?? '—'}',
                  ),
                  _Row(
                    'Min Quiz Score',
                    vm.minQuizScore != null ? '${vm.minQuizScore}' : '—',
                  ),
                  _Row('Required Challenges', '${vm.requiredChallenges}'),
                  _Row(
                    'Max Participants',
                    vm.maxParticipants != null
                        ? '${vm.maxParticipants}'
                        : 'Unlimited',
                  ),
                ],
              ),
              _Section(
                title: 'Quiz',
                rows: [
                  _Row('Requirement', vm.quizRequired ? 'Required' : 'Skipped'),
                  _Row('Method', _quizMethodLabel()),
                  _Row(
                    'Quiz Title / ID',
                    vm.quizTitle.isEmpty ? '—' : vm.quizTitle,
                  ),
                ],
              ),
              _Section(
                title: 'Selection',
                rows: [
                  _Row('Method', vm.selectedSelectionMethod.displayName),
                  _Row(
                    'Max Selections',
                    vm.maxSelections != null
                        ? '${vm.maxSelections}'
                        : 'Unlimited',
                  ),
                ],
              ),
              _Section(
                title: 'Rewards',
                rows: [
                  _Row('Counselling', vm.counsellingEnabled ? 'Yes' : 'No'),
                  _Row('Certificate', vm.certificateEnabled ? 'Yes' : 'No'),
                  _Row('Scholarship', vm.scholarshipEnabled ? 'Yes' : 'No'),
                  _Row('Mentorship', vm.mentorshipEnabled ? 'Yes' : 'No'),
                ],
              ),
              _Section(
                title: 'Notifications',
                rows: [
                  _Row('Push', vm.pushNotification ? 'On' : 'Off'),
                  _Row('In-App', vm.inAppNotification ? 'On' : 'Off'),
                  _Row('Email', vm.emailNotification ? 'On' : 'Off'),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: validationItems.isEmpty
                      ? AppColors.secondary.withValues(alpha: 0.12)
                      : AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      validationItems.isEmpty
                          ? Icons.check_circle_outline_rounded
                          : Icons.error_outline_rounded,
                      color: validationItems.isEmpty
                          ? AppColors.secondary
                          : AppColors.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        validationItems.isEmpty
                            ? "Everything looks good. Tap 'Publish Event'."
                            : 'Complete the missing fields checklist before publishing.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ValidationChecklist extends StatelessWidget {
  const _ValidationChecklist({required this.items});

  final List<EventValidationItem> items;

  @override
  Widget build(BuildContext context) {
    final isReady = items.isEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isReady
              ? AppColors.secondary.withValues(alpha: 0.35)
              : AppColors.softRed.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isReady
                    ? Icons.check_circle_rounded
                    : Icons.assignment_late_outlined,
                color: isReady ? AppColors.secondary : AppColors.softRed,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isReady ? 'Validation passed' : 'Missing fields checklist',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (!isReady) ...[
            const SizedBox(height: 10),
            ...items.map((item) => _ValidationRow(item: item)),
          ],
        ],
      ),
    );
  }
}

class _ValidationRow extends StatelessWidget {
  const _ValidationRow({required this.item});

  final EventValidationItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.radio_button_unchecked_rounded,
              size: 16,
              color: AppColors.softRed,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${item.step} · ${item.label}: ${item.message}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 12),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.muted.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: rows
                .map((r) => _PreviewRow(label: r.label, value: r.value))
                .toList(),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _Row {
  const _Row(this.label, this.value);
  final String label;
  final String value;
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
