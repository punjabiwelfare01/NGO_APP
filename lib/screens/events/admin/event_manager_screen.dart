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

  String get _activeFilterLabel => _filters[_filterIndex].label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EventManagerHero(onCreate: _openCreateEvent),
            const SizedBox(height: 12),
            SizedBox(
              height: 104,
              child: ListenableBuilder(
                listenable: _vm,
                builder: (context, _) => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _MetricTile(
                      icon: Icons.library_add_check_rounded,
                      label: 'Showing',
                      value: '${_vm.events.length}',
                      color: AppColors.primary,
                    ),
                    _MetricTile(
                      icon: Icons.filter_alt_rounded,
                      label: 'Filter',
                      value: _activeFilterLabel,
                      color: AppColors.accent,
                    ),
                    _MetricTile(
                      icon: Icons.route_rounded,
                      label: 'Workflow',
                      value: '8 steps',
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
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
                    return _EventEmptyState(
                      filterLabel: _activeFilterLabel,
                      onCreate: _openCreateEvent,
                      onShowAll: _filterIndex == 0 ? null : () => _setFilter(0),
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

class _EventManagerHero extends StatelessWidget {
  const _EventManagerHero({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;

          final intro = Row(
            children: [
              if (canPop) ...[
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Manager',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create, publish, and monitor student events from one queue.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          );

          final button = FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [intro, const SizedBox(height: 14), button],
            );
          }

          return Row(
            children: [
              Expanded(child: intro),
              const SizedBox(width: 12),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _EventEmptyState extends StatelessWidget {
  const _EventEmptyState({
    required this.filterLabel,
    required this.onCreate,
    this.onShowAll,
  });

  final String filterLabel;
  final VoidCallback onCreate;
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.muted.withValues(alpha: 0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fact_check_rounded,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          filterLabel == 'All'
                              ? 'No events yet'
                              : 'No $filterLabel events',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Start with a guided event draft. The pipeline helps you add timelines, rules, quiz requirements, rewards, notifications, and preview checks before publishing.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _ChecklistPill(Icons.edit_note_rounded, 'Basic info'),
                  _ChecklistPill(Icons.event_available_rounded, 'Timeline'),
                  _ChecklistPill(Icons.quiz_rounded, 'Quiz gate'),
                  _ChecklistPill(Icons.visibility_rounded, 'Preview'),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onCreate,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create Event'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (onShowAll != null) ...[
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: onShowAll,
                      child: const Text('Show All'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _PipelineGuide(),
      ],
    );
  }
}

class _ChecklistPill extends StatelessWidget {
  const _ChecklistPill(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineGuide extends StatelessWidget {
  const _PipelineGuide();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (icon: Icons.save_outlined, title: 'Auto-save drafts'),
      (icon: Icons.rule_rounded, title: 'Required rules'),
      (icon: Icons.quiz_rounded, title: 'Quiz or skip'),
      (icon: Icons.publish_rounded, title: 'Publish check'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pipeline',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == steps.length - 1 ? 0 : 10,
              ),
              child: Row(
                children: [
                  Icon(step.icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      step.title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
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

  bool get _isPublicEvent =>
      event.status == EventStatus.published ||
      event.status == EventStatus.registrationOpen ||
      event.status == EventStatus.live;

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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionBtn(
                    label: _isPublicEvent ? 'Unpublish' : 'Publish',
                    icon: _isPublicEvent
                        ? Icons.unpublished_outlined
                        : Icons.publish_rounded,
                    color: _isPublicEvent
                        ? AppColors.accent
                        : AppColors.secondary,
                    onTap: () => _isPublicEvent
                        ? _unpublish(context)
                        : _publish(context),
                  ),
                  _ActionBtn(
                    label: 'View',
                    icon: Icons.visibility_outlined,
                    color: AppColors.primary,
                    onTap: () =>
                        openEvent(context, event, onRefresh: onRefresh),
                  ),
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

  Future<void> _unpublish(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unpublish Event'),
        content: Text(
          '"${event.title}" will return to draft and no longer appear as a public event.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unpublish'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await EventRepository.advanceStatus(event.id, EventStatus.draft.apiValue);
      onRefresh();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event unpublished and moved to drafts.'),
          backgroundColor: AppColors.accent,
        ),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_statusErrorMessage(e)),
          backgroundColor: AppColors.softRed,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not unpublish event.'),
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

  String _statusErrorMessage(ApiException e) {
    if (e.statusCode == 403) {
      return 'You do not have permission to change this event status.';
    }
    if (e.statusCode == 401) {
      return 'Your session expired. Please sign in again.';
    }
    return 'Could not update event status. Server returned ${e.statusCode}.';
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
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
