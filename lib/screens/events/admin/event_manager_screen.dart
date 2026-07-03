import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/event_models.dart';
import '../../../repositories/api_client.dart';
import '../../../repositories/event_repository.dart';
import '../../../viewmodels/event_list_viewmodel.dart';
import '../../../viewmodels/view_state.dart';
import '../../../utils/navigation_helper.dart';


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
    final created = await showModalBottomSheet<EventModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateEventSheet(),
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

// ── Quick Create Event Bottom Sheet ────────────────────────────────────────────

class _CreateEventSheet extends StatefulWidget {
  const _CreateEventSheet();

  @override
  State<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<_CreateEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _partnerCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _eligCtrl = TextEditingController();
  final _maxVolCtrl = TextEditingController(text: '20');

  EventType? _selectedType;
  DateTime? _selectedDate;
  bool _submitting = false;

  static const _categories = [
    (label: 'Quiz Event', type: EventType.quiz),
    (label: 'Workshop', type: EventType.workshop),
    (label: 'Awareness Campaign', type: EventType.awarenessCampaign),
    (label: 'Competition', type: EventType.competition),
    (label: 'Talent Hunt', type: EventType.talentHunt),
    (label: 'Scholarship Drive', type: EventType.scholarship),
    (label: 'Counselling Drive', type: EventType.counsellingDrive),
    (label: 'Cyber Security', type: EventType.cyberSecurity),
    (label: 'Stationery Drive', type: EventType.stationeryDrive),
    (label: 'Donation Drive', type: EventType.donationDrive),
    (label: 'School Partnership', type: EventType.schoolPartnership),
    (label: 'Community Outreach', type: EventType.communityOutreach),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    _locationCtrl.dispose();
    _partnerCtrl.dispose();
    _descCtrl.dispose();
    _eligCtrl.dispose();
    _maxVolCtrl.dispose();
    super.dispose();
  }

  void _selectChip(({String label, EventType type}) cat) {
    setState(() {
      _selectedType = cat.type;
      _categoryCtrl.text = cat.label;
    });
  }

  void _onCategoryTyped(String value) {
    // Clear chip selection when user types a custom category
    if (_selectedType != null &&
        _categories.any((c) => c.type == _selectedType) &&
        _categories
                .firstWhere((c) => c.type == _selectedType)
                .label
                .toLowerCase() !=
            value.toLowerCase()) {
      setState(() => _selectedType = null);
    }
  }

  EventType _resolveEventType() {
    if (_selectedType != null) return _selectedType!;
    // Try to match typed text to a known category label
    final text = _categoryCtrl.text.trim().toLowerCase();
    for (final cat in _categories) {
      if (cat.label.toLowerCase() == text) return cat.type;
    }
    // Default to workshop for free-text custom categories
    return EventType.workshop;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an event date.'),
          backgroundColor: AppColors.softRed,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    // Build description with optional partner/eligibility prefix
    final parts = <String>[];
    final partner = _partnerCtrl.text.trim();
    final elig = _eligCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (partner.isNotEmpty) parts.add('Partner School / Organisation: $partner');
    if (elig.isNotEmpty) parts.add('Student Eligibility: $elig');
    if (desc.isNotEmpty) parts.add(desc);
    final fullDescription = parts.join('\n\n');

    final eventDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      12, // noon
    );

    final maxVol = int.tryParse(_maxVolCtrl.text.trim());

    try {
      final created = await EventRepository.createEvent({
        'title': _titleCtrl.text.trim(),
        'subtitle': _locationCtrl.text.trim().isEmpty
            ? null
            : _locationCtrl.text.trim(),
        'description': fullDescription.isEmpty ? null : fullDescription,
        'event_type': _resolveEventType().apiValue,
        'is_daily_challenge': false,
        'theme_color': '#41A7F5',
        'event_start': eventDate.toIso8601String(),
        'start_date': eventDate.toIso8601String(),
        'max_participants': maxVol,
        'auto_notification': true,
        'push_notification': true,
        'in_app_notification': true,
        'email_notification': false,
        'certificate_enabled': true,
      });
      if (!mounted) return;
      Navigator.of(context).pop(created);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event created as draft.'),
          backgroundColor: AppColors.secondary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not create event. Please try again.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 3),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.muted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Create New Event',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scrollable form
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleCtrl,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Event Title *',
                        hintText: 'e.g. Cyber Safety Awareness Camp',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 20),

                    // Category label
                    Text(
                      'Category *',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Category chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final selected = _selectedType == cat.type;
                        return GestureDetector(
                          onTap: () => _selectChip(cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : AppColors.muted.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.muted.withValues(alpha: 0.25),
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected ? AppColors.primary : AppColors.ink,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Custom category text field
                    TextFormField(
                      controller: _categoryCtrl,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                      decoration: InputDecoration(
                        labelText: 'Or type a custom category',
                        hintText: 'e.g. Blood Donation Camp',
                        border: const OutlineInputBorder(),
                        suffixIcon: _categoryCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    size: 18, color: AppColors.muted),
                                onPressed: () {
                                  setState(() {
                                    _categoryCtrl.clear();
                                    _selectedType = null;
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: _onCategoryTyped,
                      validator: (v) {
                        if ((v == null || v.trim().isEmpty) &&
                            _selectedType == null) {
                          return 'Please select or type a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Date
                    GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Date *',
                            hintText: 'Select event date',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.calendar_today_rounded,
                                size: 18, color: AppColors.primary),
                            suffixText: _selectedDate == null
                                ? null
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          ),
                          controller: TextEditingController(
                            text: _selectedDate == null
                                ? ''
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location
                    TextFormField(
                      controller: _locationCtrl,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Location *',
                        hintText: 'e.g. Delhi Public School, Cantt',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_rounded,
                            size: 18, color: AppColors.primary),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Location is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Partner School / Organisation
                    TextFormField(
                      controller: _partnerCtrl,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Partner School / Organisation',
                        hintText: 'Optional',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business_rounded,
                            size: 18, color: AppColors.muted),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        hintText: 'What is this event about?',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Description is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Max Volunteers
                    TextFormField(
                      controller: _maxVolCtrl,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Max Volunteers *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people_rounded,
                            size: 18, color: AppColors.primary),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Required';
                        }
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 1) return 'Enter a positive number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Student Eligibility
                    TextFormField(
                      controller: _eligCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Student Eligibility',
                        hintText: 'Optional — e.g. Class 8–12, Age 13+',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school_rounded,
                            size: 18, color: AppColors.muted),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create Event',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
