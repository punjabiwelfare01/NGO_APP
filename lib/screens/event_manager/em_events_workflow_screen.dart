import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/unified_event.dart';
import '../../viewmodels/events_viewmodel.dart';
import '../events/create_event_screen.dart';

const _kBlue = Color(0xFF1565C0);
const _kRed = Color(0xFFC62828);

/// Simplified Event Manager "Events" workflow, replacing the old multi-filter
/// Events dashboard for this role specifically (Admin keeps the full
/// dashboard — see `EventsDashboardScreen`). Three steps only:
///   1. Create Event — dedicated full page, always saved as a draft.
///   2. Draft Events — edit, update, or delete before publishing.
///   3. Published Events — still editable (details/schedule/venue/capacity)
///      any time, but no longer deletable.
class EMEventsWorkflowScreen extends StatefulWidget {
  const EMEventsWorkflowScreen({required this.vm, super.key});
  final EventsViewModel vm;

  @override
  State<EMEventsWorkflowScreen> createState() => _EMEventsWorkflowScreenState();
}

class _EMEventsWorkflowScreenState extends State<EMEventsWorkflowScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _openCreate() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateEventScreen(vm: widget.vm),
      ),
    );
  }

  void _openEdit(UnifiedEvent event) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateEventScreen(vm: widget.vm, existingEvent: event),
      ),
    );
  }

  Future<void> _confirmDelete(UnifiedEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete draft event?'),
        content: Text(
          'This will permanently delete "${event.event.title}". This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _kRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.vm.deleteEvent(event);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${event.event.title}" deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Events', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          labelColor: _kBlue,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: _kBlue,
          tabs: [
            Tab(text: 'Draft (${_draftEvents().length})'),
            Tab(text: 'Published (${_publishedEvents().length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: _kBlue,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Event'),
      ),
      body: ListenableBuilder(
        listenable: widget.vm,
        builder: (context, _) {
          if (widget.vm.isLoading && widget.vm.all.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (widget.vm.errorMessage != null && widget.vm.all.isEmpty) {
            return Center(
              child: TextButton(
                onPressed: () => widget.vm.load(force: true),
                child: Text('Retry\n${widget.vm.errorMessage}',
                    textAlign: TextAlign.center),
              ),
            );
          }
          return TabBarView(
            controller: _tabs,
            children: [
              _EventList(
                events: _draftEvents(),
                emptyText: 'No draft events yet.\nTap "Create Event" to get started.',
                onRefresh: () => widget.vm.load(force: true),
                cardBuilder: (event) => _EventCard(
                  event: event,
                  onEdit: () => _openEdit(event),
                  onDelete: () => _confirmDelete(event),
                ),
              ),
              _EventList(
                events: _publishedEvents(),
                emptyText: 'No published events yet.',
                onRefresh: () => widget.vm.load(force: true),
                cardBuilder: (event) => _EventCard(
                  event: event,
                  onEdit: () => _openEdit(event),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<UnifiedEvent> _draftEvents() =>
      widget.vm.all.where((e) => e.uiStatus == EventUiStatus.draft).toList();

  List<UnifiedEvent> _publishedEvents() =>
      widget.vm.all.where((e) => e.uiStatus != EventUiStatus.draft).toList();
}

class _EventList extends StatelessWidget {
  const _EventList({
    required this.events,
    required this.emptyText,
    required this.onRefresh,
    required this.cardBuilder,
  });
  final List<UnifiedEvent> events;
  final String emptyText;
  final Future<void> Function() onRefresh;
  final Widget Function(UnifiedEvent) cardBuilder;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 420,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    emptyText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => cardBuilder(events[i]),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onEdit, this.onDelete});
  final UnifiedEvent event;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final e = event.event;
    final status = event.uiStatus;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: status.color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, size: 11, color: status.color),
                    const SizedBox(width: 4),
                    Text(
                      status.label,
                      style: TextStyle(
                        color: status.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${e.date.day}/${e.date.month}/${e.date.year}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            e.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 13, color: AppColors.muted),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  e.location.isEmpty ? 'Location to be confirmed' : e.location,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.people_rounded, size: 13, color: AppColors.muted),
              const SizedBox(width: 3),
              Text(
                '${event.assignedCount}/${e.maxVolunteers}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 15),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kBlue,
                    side: const BorderSide(color: _kBlue),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 15),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kRed,
                      side: const BorderSide(color: _kRed),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
