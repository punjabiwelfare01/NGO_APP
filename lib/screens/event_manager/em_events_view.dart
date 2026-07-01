import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/event_manager_models.dart';
import '../../repositories/event_repository.dart';
import '../../viewmodels/event_manager_viewmodel.dart';
import '../../widgets/app_card.dart';
import '../events/official_event_report_screen.dart';
import 'em_create_activity_screen.dart';

class EMEventsView extends StatefulWidget {
  const EMEventsView({required this.vm, super.key});
  final EventManagerViewModel vm;

  @override
  State<EMEventsView> createState() => _EMEventsViewState();
}

class _EMEventsViewState extends State<EMEventsView> {
  EventStatus? _filter;

  List<NGOEvent> get _filtered => _filter == null
      ? widget.vm.events
      : widget.vm.events.where((e) => e.status == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _Header(vm: widget.vm),
              _FilterRow(
                selected: _filter,
                onChanged: (s) => setState(() => _filter = s),
              ),
              Expanded(
                child: _filtered.isEmpty
                    ? _EmptyState(filter: _filter)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 90),
                        itemCount: _filtered.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) => _EventCard(
                          event: _filtered[i],
                          vm: widget.vm,
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openCreateEvent(context),
            backgroundColor: const Color(0xFF1565C0),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Create Event',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14),
            ),
          ),
        );
      },
    );
  }

  void _openCreateEvent(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateEventSheet(vm: widget.vm),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.vm});
  final EventManagerViewModel vm;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canPop) ...[
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF1565C0),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Events',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${vm.events.length} total · ${vm.activeEvents.length} active',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded,
                    color: Color(0xFF1565C0), size: 14),
                const SizedBox(width: 5),
                Text(
                  '${vm.stats.totalEventsThisMonth} this month',
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Row ───────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onChanged});
  final EventStatus? selected;
  final ValueChanged<EventStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = <(EventStatus?, String)>[
      (null, 'All'),
      ...EventStatus.values.map((s) => (s, s.label)),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (status, label) = filters[i];
          final active = selected == status;
          final color = status?.color ?? const Color(0xFF1565C0);
          return GestureDetector(
            onTap: () => onChanged(status),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? color : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? color : AppColors.muted.withValues(alpha: 0.25),
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status != null) ...[
                    Icon(status.icon,
                        size: 12,
                        color: active ? Colors.white : AppColors.muted),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Event Card ───────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.vm});
  final NGOEvent event;
  final EventManagerViewModel vm;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: event.status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(event.category.icon,
                      color: event.status.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.category.label,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusPill(status: event.status),
              ],
            ),
            const SizedBox(height: 12),
            // Meta row
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _MetaChip(
                    icon: Icons.calendar_today_rounded,
                    label:
                        '${event.date.day}/${event.date.month}/${event.date.year}'),
                _MetaChip(
                    icon: Icons.location_on_rounded, label: event.location),
                _MetaChip(
                    icon: Icons.people_rounded,
                    label: '${event.maxVolunteers} volunteers max'),
                if (event.partnerSchool != null)
                  _MetaChip(
                      icon: Icons.school_rounded,
                      label: event.partnerSchool!),
              ],
            ),
            const SizedBox(height: 12),
            // Tags
            Row(
              children: [
                if (event.certificateEligible)
                  _Tag(
                      icon: Icons.workspace_premium_rounded,
                      label: 'Certificate',
                      color: const Color(0xFF1565C0)),
                if (event.certificateEligible && event.donationEligible)
                  const SizedBox(width: 8),
                if (event.donationEligible)
                  _Tag(
                      icon: Icons.payments_rounded,
                      label: event.stipendAmount != null
                          ? '₹${event.stipendAmount!.toStringAsFixed(0)} stipend'
                          : 'Donation eligible',
                      color: const Color(0xFF2E7D32)),
                const Spacer(),
                Text(
                  '${event.activities.length} activit${event.activities.length == 1 ? 'y' : 'ies'}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.muted, size: 16),
              ],
            ),
            // Completed event: Generate Report button
            if (event.status == EventStatus.completed) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _generateReport(context),
                  icon: const Icon(Icons.summarize_rounded, size: 16),
                  label: const Text('Generate Event Report'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1565C0),
                    side: const BorderSide(
                        color: Color(0xFF1565C0), width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generateReport(BuildContext context) async {
    final report = await vm.generateReport(event.id);
    if (!context.mounted) return;
    final assignments =
        vm.assignments.where((a) => a.event.id == event.id).toList();
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => OfficialEventReportScreen(
          event: event,
          assignments: assignments,
          report: report,
          vm: vm,
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventDetailSheet(event: event, vm: vm),
    );
  }
}

// ─── Status Pill ──────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final EventStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, color: status.color, size: 10),
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
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});
  final EventStatus? filter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filter == null
                ? Icons.event_busy_rounded
                : filter!.icon,
            color: AppColors.muted.withValues(alpha: 0.4),
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            filter == null
                ? 'No events yet'
                : 'No ${filter!.label.toLowerCase()} events',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + Create Event to add one',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Event Detail Sheet ───────────────────────────────────────────────────────

class _EventDetailSheet extends StatefulWidget {
  const _EventDetailSheet({required this.event, required this.vm});
  final NGOEvent event;
  final EventManagerViewModel vm;

  @override
  State<_EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<_EventDetailSheet> {
  late bool _isPublished;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _isPublished = widget.event.status == EventStatus.published ||
        widget.event.status == EventStatus.registrationOpen ||
        widget.event.status == EventStatus.ongoing;
  }

  Future<void> _openCreateActivity(BuildContext context) async {
    final event = widget.event;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EMCreateActivityScreen(
          vm: widget.vm,
          eventId: event.id,
          eventTitle: event.title,
        ),
      ),
    );
    widget.vm.load();
  }

  Future<void> _togglePublish() async {
    setState(() => _loading = true);
    try {
      if (_isPublished) {
        await EventRepository.advanceStatus(widget.event.id, 'draft');
        if (!mounted) return;
        setState(() => _isPublished = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event unpublished and moved to drafts.'),
            backgroundColor: Color(0xFFE65100),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await EventRepository.publishEvent(widget.event.id);
        if (!mounted) return;
        setState(() => _isPublished = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event published! Students can register now.'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      widget.vm.load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update event status. Is the backend running?'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: event.status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(event.category.icon,
                        color: event.status.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                children: [
                  _StatusPill(
                    status: _isPublished ? EventStatus.published : EventStatus.draft,
                  ),
                  const SizedBox(height: 14),
                  _DetailRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value:
                          '${event.date.day}/${event.date.month}/${event.date.year}'),
                  _DetailRow(
                      icon: Icons.location_on_rounded,
                      label: 'Location',
                      value: event.location),
                  if (event.partnerSchool != null)
                    _DetailRow(
                        icon: Icons.school_rounded,
                        label: 'Partner School',
                        value: event.partnerSchool!),
                  _DetailRow(
                      icon: Icons.people_rounded,
                      label: 'Max Volunteers',
                      value: '${event.maxVolunteers}'),
                  if (event.studentEligibility != null)
                    _DetailRow(
                        icon: Icons.how_to_reg_rounded,
                        label: 'Eligibility',
                        value: event.studentEligibility!),
                  const SizedBox(height: 14),
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  if (event.expectedWork != null) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Expected Work',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.expectedWork!,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Activities',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _openCreateActivity(context),
                        icon: const Icon(Icons.add_rounded, size: 14),
                        label: const Text(
                          'Add Activity',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (event.activities.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.muted.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined,
                              color: AppColors.muted.withValues(alpha: 0.5),
                              size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'No activities yet — tap Add Activity to create one.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final a in event.activities) _ActivityRow(activity: a),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('Edit Event'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _loading ? null : _togglePublish,
                          icon: _loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  _isPublished
                                      ? Icons.unpublished_rounded
                                      : Icons.public_rounded,
                                  size: 16,
                                ),
                          label: Text(_isPublished ? 'Unpublish' : 'Publish'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _isPublished
                                ? const Color(0xFFE65100)
                                : const Color(0xFF1565C0),
                          ),
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
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.muted, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});
  final EventActivity activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.muted.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(activity.role.icon,
              color: const Color(0xFF1565C0), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${activity.assignedCount}/${activity.maxStudents} assigned · '
                  '${activity.slotsLeft} slots left',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (activity.isFull)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.softRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Full',
                style: TextStyle(
                  color: AppColors.softRed,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Create Event Sheet ───────────────────────────────────────────────────────

class _CreateEventSheet extends StatefulWidget {
  const _CreateEventSheet({required this.vm});
  final EventManagerViewModel vm;

  @override
  State<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<_CreateEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _maxVolCtrl = TextEditingController(text: '20');
  final _eligibilityCtrl = TextEditingController();
  final _expectedWorkCtrl = TextEditingController();
  final _proofCtrl = TextEditingController();

  EventCategory _category = EventCategory.workshop;
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  bool _certificate = true;
  bool _donation = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _schoolCtrl.dispose();
    _descCtrl.dispose();
    _maxVolCtrl.dispose();
    _eligibilityCtrl.dispose();
    _expectedWorkCtrl.dispose();
    _proofCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final title = _titleCtrl.text.trim();
    final event = NGOEvent(
      id: 0,
      title: title,
      category: _category,
      status: EventStatus.draft,
      date: _date,
      location: _locationCtrl.text.trim(),
      partnerSchool: _schoolCtrl.text.trim().isEmpty
          ? null
          : _schoolCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      maxVolunteers: int.tryParse(_maxVolCtrl.text.trim()) ?? 20,
      studentEligibility: _eligibilityCtrl.text.trim().isEmpty
          ? null
          : _eligibilityCtrl.text.trim(),
      expectedWork: _expectedWorkCtrl.text.trim().isEmpty
          ? null
          : _expectedWorkCtrl.text.trim(),
      proofRequired: _proofCtrl.text.trim().isEmpty
          ? null
          : _proofCtrl.text.trim(),
      certificateEligible: _certificate,
      donationEligible: _donation,
      createdAt: DateTime.now(),
    );
    try {
      await widget.vm.addNewEvent(event);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create event: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Event "$title" created as Draft'),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.90,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  const Text(
                    'Create New Event',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: ctrl,
                  padding:
                      const EdgeInsets.fromLTRB(18, 16, 18, 28),
                  children: [
                    _label('Event Title *'),
                    _field(_titleCtrl,
                        'e.g. Cyber Safety Awareness Camp',
                        required: true),
                    const SizedBox(height: 14),
                    _label('Category *'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: EventCategory.values
                          .map(
                            (c) => ChoiceChip(
                              label: Text(c.label,
                                  style: const TextStyle(fontSize: 11)),
                              selected: _category == c,
                              onSelected: (_) =>
                                  setState(() => _category = c),
                              avatar: Icon(c.icon, size: 12),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    _label('Date *'),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.muted
                                  .withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: Color(0xFF1565C0), size: 18),
                            const SizedBox(width: 10),
                            Text(
                              '${_date.day}/${_date.month}/${_date.year}',
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _label('Location *'),
                    _field(_locationCtrl,
                        'e.g. Delhi Public School, Cantt',
                        required: true),
                    const SizedBox(height: 14),
                    _label('Partner School / Organisation'),
                    _field(_schoolCtrl, 'Optional'),
                    const SizedBox(height: 14),
                    _label('Description *'),
                    _field(_descCtrl, 'What is this event about?',
                        required: true, maxLines: 4),
                    const SizedBox(height: 14),
                    _label('Max Volunteers *'),
                    _field(_maxVolCtrl, 'e.g. 25',
                        required: true,
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 14),
                    _label('Student Eligibility'),
                    _field(_eligibilityCtrl,
                        'e.g. All enrolled volunteers'),
                    const SizedBox(height: 14),
                    _label('Expected Work'),
                    _field(_expectedWorkCtrl,
                        'What will volunteers do?',
                        maxLines: 3),
                    const SizedBox(height: 14),
                    _label('Proof Required'),
                    _field(_proofCtrl,
                        'e.g. Photos, attendance sheet, report'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _ToggleTile(
                            icon: Icons.workspace_premium_rounded,
                            label: 'Certificate',
                            value: _certificate,
                            onChanged: (v) =>
                                setState(() => _certificate = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ToggleTile(
                            icon: Icons.payments_rounded,
                            label: 'Donation / Stipend',
                            value: _donation,
                            onChanged: (v) =>
                                setState(() => _donation = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2),
                              )
                            : const Text(
                                'Save as Draft',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: AppColors.muted.withValues(alpha: 0.6),
              fontSize: 13),
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: AppColors.muted.withValues(alpha: 0.4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: AppColors.muted.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Color(0xFF1565C0), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
        ),
        validator: required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      );
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFF1565C0).withValues(alpha: 0.06)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? const Color(0xFF1565C0).withValues(alpha: 0.3)
              : AppColors.muted.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              color:
                  value ? const Color(0xFF1565C0) : AppColors.muted,
              size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: value
                    ? const Color(0xFF1565C0)
                    : AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF1565C0),
            activeTrackColor:
                const Color(0xFF1565C0).withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}
