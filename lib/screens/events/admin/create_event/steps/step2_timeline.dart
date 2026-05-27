import 'package:flutter/material.dart';

import '../../../../../core/colors.dart';
import '../../../../../viewmodels/create_event_viewmodel.dart';

class TimelineStep extends StatelessWidget {
  const TimelineStep({required this.vm, super.key});

  final CreateEventViewModel vm;

  Future<void> _pickDateTime(
    BuildContext context,
    DateTime? current,
    void Function(DateTime?) onPicked,
  ) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current != null && current.isAfter(now) ? current : now,
      firstDate: now,
      lastDate: DateTime(2030),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime:
          current != null ? TimeOfDay.fromDateTime(current) : TimeOfDay.now(),
    );
    if (time == null) return;
    onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return 'Not set';
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final errors = vm.getTimelineErrors();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Timeline',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppColors.ink)),
              const SizedBox(height: 20),
              _DateRow(
                label: 'Registration Start *',
                value: _fmt(vm.registrationStart),
                error: errors['registrationStart'],
                onTap: () => _pickDateTime(
                    context, vm.registrationStart, vm.setRegistrationStart),
              ),
              _DateRow(
                label: 'Registration End *',
                value: _fmt(vm.registrationEnd),
                error: errors['registrationEnd'],
                onTap: () => _pickDateTime(
                    context, vm.registrationEnd, vm.setRegistrationEnd),
              ),
              _DateRow(
                label: 'Event Start *',
                value: _fmt(vm.eventStart),
                error: errors['eventStart'],
                onTap: () =>
                    _pickDateTime(context, vm.eventStart, vm.setEventStart),
              ),
              _DateRow(
                label: 'Event End *',
                value: _fmt(vm.eventEnd),
                error: errors['eventEnd'],
                onTap: () =>
                    _pickDateTime(context, vm.eventEnd, vm.setEventEnd),
              ),
              _DateRow(
                label: 'Result Date',
                value: _fmt(vm.resultDate),
                error: errors['resultDate'],
                onTap: () =>
                    _pickDateTime(context, vm.resultDate, vm.setResultDate),
              ),
              _DateRow(
                label: 'Counselling Date',
                value: _fmt(vm.counsellingDate),
                error: errors['counsellingDate'],
                onTap: () => _pickDateTime(
                    context, vm.counsellingDate, vm.setCounsellingDate),
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text('Automation',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.ink)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto Publish'),
                subtitle: const Text('Publish automatically at start time'),
                value: vm.autoPublish,
                onChanged: vm.setAutoPublish,
                activeThumbColor: AppColors.primary,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto Close'),
                subtitle: const Text('Close registration automatically'),
                value: vm.autoClose,
                onChanged: vm.setAutoClose,
                activeThumbColor: AppColors.primary,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto Result Publish'),
                subtitle: const Text('Publish results on result date'),
                value: vm.autoResultPublish,
                onChanged: vm.setAutoResultPublish,
                activeThumbColor: AppColors.primary,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto Notification'),
                subtitle: const Text('Send automatic reminders'),
                value: vm.autoNotification,
                onChanged: vm.setAutoNotification,
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.error,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.muted)),
                const SizedBox(height: 2),
                Text(value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: error != null ? AppColors.softRed : AppColors.ink,
                        )),
                if (error != null) ...[
                  const SizedBox(height: 3),
                  Text(error!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.softRed)),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_calendar_outlined),
            color: error != null ? AppColors.softRed : AppColors.primary,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
