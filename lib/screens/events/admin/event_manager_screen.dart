import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/event_models.dart';
import '../../../repositories/api_client.dart';
import '../../../repositories/event_repository.dart';
import '../../../viewmodels/event_list_viewmodel.dart';
import '../../../viewmodels/view_state.dart';
import '../../../utils/navigation_helper.dart';
import 'create_event/create_event_view.dart';

class EventManagerScreen extends StatefulWidget {
  const EventManagerScreen({super.key});

  @override
  State<EventManagerScreen> createState() => _EventManagerScreenState();
}

class _EventManagerScreenState extends State<EventManagerScreen> {
  late final EventListViewModel _vm;
  int _filterIndex = 0;

  static const _filters = [
    (label: 'All', status: null),
    (label: 'Draft', status: 'draft'),
    (label: 'Published', status: 'published'),
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
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Event Manager',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: AppColors.ink),
                    ),
                  ),
                  FloatingActionButton.small(
                    heroTag: 'create_event_fab',
                    backgroundColor: AppColors.primary,
                    onPressed: _openCreateEvent,
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
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
            // Content
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
                        'No events found.',
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
                    itemBuilder: (context, i) => EventAdminCard(
                      event: _vm.events[i],
                      onRefresh: _vm.load,
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

  Future<void> _openCreateEvent() async {
    final created = await Navigator.of(context).push<EventModel>(
      MaterialPageRoute(builder: (_) => const CreateEventView()),
    );
    if (created == null) return;
    _vm.addOrUpdate(created);
    await _vm.load(keepExistingOnEmpty: true, showLoading: false);
  }
}

class EventAdminCard extends StatelessWidget {
  const EventAdminCard({
    required this.event,
    required this.onRefresh,
    super.key,
  });

  final EventModel event;
  final VoidCallback onRefresh;

  Color _statusColor(EventStatus s) => switch (s) {
    EventStatus.draft => AppColors.muted,
    EventStatus.published => AppColors.primary,
    EventStatus.registrationOpen => AppColors.secondary,
    EventStatus.live => AppColors.accent,
    EventStatus.completed => AppColors.muted,
    _ => AppColors.muted,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openEvent(context, event, onRefresh: onRefresh),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: AppColors.ink),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(event.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.status.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _statusColor(event.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _Badge(event.eventType.displayName, AppColors.primary),
                  const SizedBox(width: 8),
                  Icon(Icons.group_outlined, size: 14, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Text(
                    '${event.participantCount}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  const Spacer(),
                  if (event.createdAt != null)
                    Text(
                      '${event.createdAt!.day}/${event.createdAt!.month}/${event.createdAt!.year}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ActionBtn(
                    label: 'Publish',
                    icon: Icons.publish_rounded,
                    color: AppColors.secondary,
                    onTap: () => _publish(context),
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                    label: 'View',
                    icon: Icons.visibility_outlined,
                    color: AppColors.primary,
                    onTap: () =>
                        openEvent(context, event, onRefresh: onRefresh),
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                    label: 'Delete',
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.softRed,
                    onTap: () => _delete(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _publish(BuildContext context) async {
    try {
      final updated = await EventRepository.publishEvent(event.id);
      onRefresh();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.status == EventStatus.registrationOpen
                ? 'Event is open for registration.'
                : 'Event published. Students can register now.',
          ),
          backgroundColor: AppColors.secondary,
        ),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_publishErrorMessage(e)),
          backgroundColor: AppColors.softRed,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not publish event. Is the backend running?'),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }

  String _publishErrorMessage(ApiException e) {
    if (e.statusCode == 403) {
      return 'You do not have permission to publish this event.';
    }
    if (e.statusCode == 401) {
      return 'Your session expired. Please sign in again.';
    }
    return 'Could not publish event. Server returned ${e.statusCode}.';
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text(
          'Are you sure you want to delete "${event.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.softRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await EventRepository.deleteEvent(event.id);
      onRefresh();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event deleted.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete event.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
