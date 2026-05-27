import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/event_models.dart';
import '../../../viewmodels/event_list_viewmodel.dart';
import '../../../viewmodels/view_state.dart';
import '../../../utils/navigation_helper.dart';
import 'event_registration_form_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  late final EventListViewModel _vm;
  int _filterIndex = 0;

  static const _filters = [
    (label: 'All', status: null),
    (label: 'Open', status: 'registration_open'),
    (label: 'Live', status: 'live'),
    (label: 'Completed', status: 'completed'),
  ];

  @override
  void initState() {
    super.initState();
    _vm = EventListViewModel();
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _setFilter(int index) {
    setState(() => _filterIndex = index);
    _vm.setFilter(_filters[index].status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                'Events & Drives',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: AppColors.ink),
              ),
            ),
            // Filter chips
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final selected = _filterIndex == i;
                  return FilterChip(
                    label: Text(_filters[i].label),
                    selected: selected,
                    onSelected: (_) => _setFilter(i),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.primary : AppColors.muted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListenableBuilder(
                listenable: _vm,
                builder: (context, _) {
                  if (_vm.state == ViewState.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_vm.state == ViewState.error) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _vm.errorMessage ?? 'Error',
                            style: const TextStyle(color: AppColors.softRed),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _vm.load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (_vm.events.isEmpty) {
                    return const Center(
                      child: Text(
                        'No events available.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    itemCount: _vm.events.length,
                    itemBuilder: (context, i) => _EventCard(
                      event: _vm.events[i],
                      onRegistered: () => _vm.load(
                        showLoading: false,
                        keepExistingOnEmpty: true,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onRegistered});

  final EventModel event;
  final VoidCallback onRegistered;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openEvent(context, event, onRefresh: onRegistered),
      child: Card(
        margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    event.themeColorValue,
                    event.themeColorValue.withValues(alpha: 0.5),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.eventType.displayName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.ink),
                        ),
                      ),
                      _StatusChip(status: event.status),
                    ],
                  ),
                  if (event.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.subtitle!,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (event.eventStart != null) ...[
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.eventStart!.day}/${event.eventStart!.month}/${event.eventStart!.year}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      const Icon(
                        Icons.group_outlined,
                        size: 13,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.participantCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      const Spacer(),
                      if (event.canRegister)
                        FilledButton(
                          onPressed: () => _openRegistrationForm(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Register',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRegistrationForm(BuildContext context) async {
    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EventRegistrationFormScreen(event: event),
      ),
    );
    if (registered == true) onRegistered();
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final EventStatus status;

  Color get _color => switch (status) {
    EventStatus.draft => AppColors.muted,
    EventStatus.published => AppColors.primary,
    EventStatus.registrationOpen => AppColors.secondary,
    EventStatus.live => AppColors.accent,
    EventStatus.completed => AppColors.muted,
    _ => AppColors.muted,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}
