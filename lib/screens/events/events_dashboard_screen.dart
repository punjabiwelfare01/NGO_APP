import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/unified_event.dart';
import '../../viewmodels/events_viewmodel.dart';
import 'create_event_sheet.dart';
import 'event_detail_screen.dart';

enum _Filter { all, needsAttention, upcoming, live, completed, archived }

/// Unified "Events" dashboard, replacing both the old admin "Events &
/// Activities" (4-state list) and "Event Pipeline" (12-stage tracker)
/// screens, and the Event Manager's own `EMEventsView`. Answers "what needs
/// my attention today" instead of "what stage is this event in".
class EventsDashboardScreen extends StatefulWidget {
  const EventsDashboardScreen({required this.vm, super.key});
  final EventsViewModel vm;

  @override
  State<EventsDashboardScreen> createState() => _EventsDashboardScreenState();
}

class _EventsDashboardScreenState extends State<EventsDashboardScreen> {
  final _searchCtrl = TextEditingController();
  _Filter _filter = _Filter.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<UnifiedEvent> _eventsFor(_Filter filter) => switch (filter) {
        _Filter.all => widget.vm.all,
        _Filter.needsAttention => widget.vm.needsAttention,
        _Filter.upcoming => widget.vm.upcoming,
        _Filter.live => widget.vm.live,
        _Filter.completed => widget.vm.completed,
        _Filter.archived => widget.vm.archived,
      };

  String _label(_Filter filter) => switch (filter) {
        _Filter.all => 'All',
        _Filter.needsAttention => 'Needs Attention',
        _Filter.upcoming => 'Upcoming',
        _Filter.live => 'Live',
        _Filter.completed => 'Completed',
        _Filter.archived => 'Archived',
      };

  void _openCreate() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateEventSheet(onCreate: widget.vm.createEvent),
    );
  }

  void _openDetail(UnifiedEvent event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(event: event, vm: widget.vm),
      ),
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: widget.vm.load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
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
                onPressed: widget.vm.load,
                child: Text('Retry\n${widget.vm.errorMessage}',
                    textAlign: TextAlign.center),
              ),
            );
          }
          final events = _eventsFor(_filter);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: widget.vm.search,
                  decoration: InputDecoration(
                    hintText: 'Search events, schools, locations…',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.2)),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _Filter.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final f = _Filter.values[i];
                    final selected = _filter == f;
                    final count =
                        f == _Filter.needsAttention ? widget.vm.needsAttentionCount : null;
                    return FilterChip(
                      label: Text(count != null ? '${_label(f)} ($count)' : _label(f)),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = f),
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
              const SizedBox(height: 8),
              Expanded(
                child: events.isEmpty
                    ? Center(
                        child: Text(
                          _filter == _Filter.needsAttention
                              ? 'Nothing needs attention right now 🎉'
                              : 'No events here yet',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                        itemCount: events.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _EventCard(
                          event: events[i],
                          isAdmin: widget.vm.isAdmin,
                          onTap: () => _openDetail(events[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.isAdmin, required this.onTap});
  final UnifiedEvent event;
  final bool isAdmin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = event.event;
    final status = event.uiStatus;
    final action = event.nextAction(isAdmin: isAdmin);
    final progress = e.maxVolunteers > 0
        ? (event.assignedCount / e.maxVolunteers).clamp(0.0, 1.0)
        : 0.0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(e.category.icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                          color: status.color, fontSize: 10.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: AppColors.muted),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      e.partnerSchool ?? e.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.event_outlined, size: 13, color: AppColors.muted),
                  const SizedBox(width: 3),
                  Text(
                    '${e.date.day}/${e.date.month}/${e.date.year}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: AppColors.muted.withValues(alpha: 0.15),
                  color: status.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${event.assignedCount}/${e.maxVolunteers} volunteers',
                style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
              ),
              if (action != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: action.enabled
                      ? FilledButton(
                          onPressed: onTap,
                          style: FilledButton.styleFrom(
                            backgroundColor: status.color,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape:
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(action.label,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        )
                      : OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape:
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(action.label, style: const TextStyle(fontSize: 13)),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
