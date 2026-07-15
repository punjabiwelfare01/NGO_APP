import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/event_manager_models.dart';
import '../../models/unified_event.dart';
import '../../viewmodels/events_viewmodel.dart';

/// Unified event detail screen — replaces `EventDetailPipelineScreen`'s
/// Overview/Activities/Volunteers/Reports tabs with Overview/Timeline/
/// Volunteers/Submissions/Impact/Activity Log, all backed by the same
/// [EventsViewModel] rather than a separate pipeline-only view model.
class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({required this.event, required this.vm, super.key});
  final UnifiedEvent event;
  final EventsViewModel vm;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 6, vsync: this);
  bool _busy = false;

  /// Always read the freshest copy from the view model (it swaps out
  /// `_events` on every `load()`), falling back to the one passed in if the
  /// event isn't found yet (e.g. right after creation) or was deleted.
  UnifiedEvent get _event => widget.vm.all
      .cast<UnifiedEvent?>()
      .firstWhere((e) => e?.event.id == widget.event.event.id, orElse: () => null) ??
      widget.event;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e'), backgroundColor: AppColors.softRed),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Admin can delete any event; an Event Manager can only delete their own
  /// draft/pending-review events (enforced server-side — this just decides
  /// whether to surface the menu item at all).
  bool get _canDelete =>
      widget.vm.isAdmin || _event.event.status == EventStatus.draft;

  Future<void> _confirmDelete() async {
    final u = _event;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text(
          'This permanently deletes "${u.event.title}" and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.softRed)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.vm.deleteEvent(u);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppColors.softRed),
        );
        setState(() => _busy = false);
      }
    }
  }

  void _handleAction(ActionKind kind) {
    final u = _event;
    switch (kind) {
      case ActionKind.reviewSubmissions:
        _tabs.animateTo(3);
      case ActionKind.approveVolunteers:
        _tabs.animateTo(3);
      case ActionKind.createImpactPost:
        _tabs.animateTo(4);
      case ActionKind.submitImpactForApproval:
        if (u.impactPost != null) {
          _run(() => widget.vm.submitImpactForApproval(u.impactPost!.id));
        }
      case ActionKind.approveAndPublishImpact:
        if (u.impactPost != null) {
          _run(() => widget.vm.approveAndPublishImpact(u.impactPost!.id));
        }
      case ActionKind.publishEvent:
        _run(() => widget.vm.publish(u));
      case ActionKind.assignVolunteers:
        _tabs.animateTo(2);
      case ActionKind.markCompleted:
        _run(() => widget.vm.advanceStatus(u, 'completed'));
      case ActionKind.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _event;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(u.event.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        actions: [
          if (_canDelete)
            PopupMenuButton<String>(
              onSelected: (_) => _confirmDelete(),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Event', style: TextStyle(color: AppColors.softRed)),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Timeline'),
            Tab(text: 'Volunteers'),
            Tab(text: 'Submissions'),
            Tab(text: 'Impact'),
            Tab(text: 'Activity Log'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.vm,
        builder: (context, _) {
          final u = _event;
          return Stack(
            children: [
              TabBarView(
                controller: _tabs,
                children: [
                  _OverviewTab(event: u, isAdmin: widget.vm.isAdmin, onAction: _handleAction),
                  _TimelineTab(event: u),
                  _VolunteersTab(event: u),
                  _SubmissionsTab(event: u, vm: widget.vm),
                  _ImpactTab(event: u, vm: widget.vm, onCreate: _handleAction),
                  _ActivityLogTab(event: u),
                ],
              ),
              if (_busy)
                Container(
                  color: Colors.black.withValues(alpha: 0.05),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Overview ─────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.event, required this.isAdmin, required this.onAction});
  final UnifiedEvent event;
  final bool isAdmin;
  final ValueChanged<ActionKind> onAction;

  @override
  Widget build(BuildContext context) {
    final e = event.event;
    final status = event.uiStatus;
    final action = event.nextAction(isAdmin: isAdmin);
    final progress =
        e.maxVolunteers > 0 ? (event.assignedCount / e.maxVolunteers).clamp(0.0, 1.0) : 0.0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(e.category.icon, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(e.category.label,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(status.label,
                        style: TextStyle(
                            color: status.color, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(e.description,
                  style: const TextStyle(color: AppColors.ink, fontSize: 14, height: 1.4)),
              const SizedBox(height: 14),
              _infoRow(Icons.location_on_outlined, 'Location', e.location),
              if (e.partnerSchool != null)
                _infoRow(Icons.school_outlined, 'Partner School', e.partnerSchool!),
              _infoRow(Icons.event_outlined, 'Date',
                  '${e.date.day}/${e.date.month}/${e.date.year}'),
              _infoRow(Icons.people_outline_rounded, 'Volunteers',
                  '${event.assignedCount} / ${e.maxVolunteers}'),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.muted.withValues(alpha: 0.15),
                  color: status.color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (action != null)
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Next Action',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: action.enabled
                      ? FilledButton(
                          onPressed: () => onAction(action.kind),
                          style: FilledButton.styleFrom(
                            backgroundColor: status.color,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: Text(action.label),
                        )
                      : OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13)),
                          child: Text(action.label),
                        ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.muted),
            const SizedBox(width: 8),
            Text('$label: ', style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
            Expanded(
              child: Text(value,
                  style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: 12.5)),
            ),
          ],
        ),
      );
}

// ── Timeline ──────────────────────────────────────────────────────────────────

class _TimelineTab extends StatelessWidget {
  const _TimelineTab({required this.event});
  final UnifiedEvent event;

  @override
  Widget build(BuildContext context) {
    final current = event.uiStatus;
    final currentIndex = EventUiStatus.values.indexOf(current);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final status in EventUiStatus.values)
          _TimelineRow(
            status: status,
            state: EventUiStatus.values.indexOf(status) < currentIndex
                ? _TimelineState.done
                : EventUiStatus.values.indexOf(status) == currentIndex
                    ? _TimelineState.current
                    : _TimelineState.upcoming,
          ),
      ],
    );
  }
}

enum _TimelineState { done, current, upcoming }

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.status, required this.state});
  final EventUiStatus status;
  final _TimelineState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _TimelineState.done => AppColors.secondary,
      _TimelineState.current => status.color,
      _TimelineState.upcoming => AppColors.muted.withValues(alpha: 0.4),
    };
    final icon = switch (state) {
      _TimelineState.done => Icons.check_circle_rounded,
      _TimelineState.current => Icons.radio_button_checked_rounded,
      _TimelineState.upcoming => Icons.radio_button_unchecked_rounded,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(
            status.label,
            style: TextStyle(
              color: state == _TimelineState.upcoming ? AppColors.muted : AppColors.ink,
              fontWeight: state == _TimelineState.current ? FontWeight.w800 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Volunteers ────────────────────────────────────────────────────────────────

class _VolunteersTab extends StatelessWidget {
  const _VolunteersTab({required this.event});
  final UnifiedEvent event;

  @override
  Widget build(BuildContext context) {
    if (event.event.activities.isEmpty && event.assignments.isEmpty) {
      return const Center(
        child: Text('No activities or volunteers assigned yet',
            style: TextStyle(color: AppColors.muted)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (event.event.activities.isNotEmpty) ...[
          const Text('Activities', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 8),
          for (final activity in event.event.activities)
            _Card(
              child: Row(
                children: [
                  Icon(activity.role.icon, color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activity.title,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        Text('${activity.assignedCount}/${activity.maxStudents} filled',
                            style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  if (activity.isFull)
                    const _Badge(label: 'Full', color: AppColors.secondary)
                  else
                    _Badge(label: '${activity.slotsLeft} open', color: AppColors.accent),
                ],
              ),
            ),
          const SizedBox(height: 18),
        ],
        const Text('Volunteers', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 8),
        if (event.assignments.isEmpty)
          const Text('No volunteers assigned yet', style: TextStyle(color: AppColors.muted))
        else
          for (final a in event.assignments)
            _Card(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(a.student.initials,
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 11)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.student.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        Text(a.activity.title,
                            style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  _Badge(label: a.status.label, color: a.status.color),
                ],
              ),
            ),
      ],
    );
  }
}

// ── Submissions ───────────────────────────────────────────────────────────────

class _SubmissionsTab extends StatefulWidget {
  const _SubmissionsTab({required this.event, required this.vm});
  final UnifiedEvent event;
  final EventsViewModel vm;

  @override
  State<_SubmissionsTab> createState() => _SubmissionsTabState();
}

class _SubmissionsTabState extends State<_SubmissionsTab> {
  final _notesCtrl = TextEditingController();
  int? _busyAssignmentId;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _review(EMStudentAssignment a, AssignmentStatus status) async {
    setState(() => _busyAssignmentId = a.id);
    await widget.vm.reviewSubmission(a, status: status,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim());
    if (mounted) setState(() => _busyAssignmentId = null);
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.event.assignments
        .where((a) => a.status == AssignmentStatus.workSubmitted)
        .toList();
    final others = widget.event.assignments
        .where((a) => a.status != AssignmentStatus.workSubmitted && a.submission != null)
        .toList();

    if (pending.isEmpty && others.isEmpty) {
      return const Center(
          child: Text('No work submitted yet', style: TextStyle(color: AppColors.muted)));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[
          Text('Pending Review (${pending.length})',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 8),
          for (final a in pending)
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.student.name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  Text(a.activity.title, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  if (a.submission != null) ...[
                    const SizedBox(height: 6),
                    Text(a.submission!.description,
                        maxLines: 3, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5)),
                    const SizedBox(height: 6),
                    Text('${a.submission!.hoursWorked}h • ${a.submission!.peopleReached} reached',
                        style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busyAssignmentId == a.id
                              ? null
                              : () => _review(a, AssignmentStatus.rejected),
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.softRed),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _busyAssignmentId == a.id
                              ? null
                              : () => _review(a, AssignmentStatus.verified),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
                          child: _busyAssignmentId == a.id
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
        ],
        if (others.isNotEmpty) ...[
          const Text('Reviewed', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 8),
          for (final a in others)
            _Card(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.student.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        Text(a.activity.title,
                            style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  _Badge(label: a.status.label, color: a.status.color),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

// ── Impact ────────────────────────────────────────────────────────────────────

class _ImpactTab extends StatelessWidget {
  const _ImpactTab({required this.event, required this.vm, required this.onCreate});
  final UnifiedEvent event;
  final EventsViewModel vm;
  final ValueChanged<ActionKind> onCreate;

  @override
  Widget build(BuildContext context) {
    final post = event.impactPost;
    if (post == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_outlined, size: 40, color: AppColors.muted),
              const SizedBox(height: 12),
              const Text('No impact post yet for this event',
                  style: TextStyle(color: AppColors.muted), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => vm.createImpactDraftForEvent(event),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Impact Post'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 8),
              Text(post.description, style: const TextStyle(fontSize: 13.5, height: 1.4)),
              const SizedBox(height: 8),
              Text(post.appreciationMessage,
                  style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: AppColors.muted)),
              if (post.photoUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 70,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: post.photoUrls.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(post.photoUrls[i], width: 70, height: 70, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _Badge(
                label: post.adminApproved
                    ? 'Published'
                    : post.isPublished
                        ? 'Pending Admin Approval'
                        : 'Draft',
                color: post.adminApproved
                    ? AppColors.secondary
                    : post.isPublished
                        ? AppColors.accent
                        : AppColors.muted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (!post.isPublished && !vm.isAdmin)
          FilledButton(
            onPressed: () => vm.submitImpactForApproval(post.id),
            child: const Text('Submit for Admin Approval'),
          ),
        if (post.isPublished && !post.adminApproved && vm.isAdmin)
          FilledButton(
            onPressed: () => vm.approveAndPublishImpact(post.id),
            style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('Approve & Publish'),
          ),
      ],
    );
  }
}

// ── Activity Log ──────────────────────────────────────────────────────────────

class _ActivityLogTab extends StatelessWidget {
  const _ActivityLogTab({required this.event});
  final UnifiedEvent event;

  @override
  Widget build(BuildContext context) {
    final entries = <(_LogIcon, String, DateTime)>[
      (_LogIcon.created, 'Event created', event.event.createdAt),
      for (final a in event.assignments) ...[
        (_LogIcon.applied, '${a.student.name} applied', a.appliedAt),
        if (a.submission != null)
          (_LogIcon.submitted, '${a.student.name} submitted work', a.submission!.submittedAt),
      ],
      if (event.impactPost != null)
        (_LogIcon.impact, 'Impact post created', event.impactPost!.date),
    ]..sort((a, b) => b.$3.compareTo(a.$3));

    if (entries.isEmpty) {
      return const Center(child: Text('No activity yet', style: TextStyle(color: AppColors.muted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, i) {
        final (icon, label, date) = entries[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(switch (icon) {
            _LogIcon.created => Icons.flag_outlined,
            _LogIcon.applied => Icons.person_add_alt_1_outlined,
            _LogIcon.submitted => Icons.upload_file_outlined,
            _LogIcon.impact => Icons.auto_awesome_outlined,
          }, color: AppColors.primary, size: 20),
          title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text('${date.day}/${date.month}/${date.year}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
        );
      },
    );
  }
}

enum _LogIcon { created, applied, submitted, impact }

// ── Shared small widgets ──────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: child,
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800)),
      );
}
