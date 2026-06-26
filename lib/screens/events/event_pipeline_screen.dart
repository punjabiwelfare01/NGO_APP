import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/event_pipeline_models.dart';
import '../../viewmodels/event_pipeline_viewmodel.dart';
import 'event_detail_pipeline_screen.dart';
import 'create_event_pipeline_screen.dart';

class EventPipelineScreen extends StatefulWidget {
  const EventPipelineScreen({required this.vm, super.key});
  final EventPipelineViewModel vm;

  @override
  State<EventPipelineScreen> createState() => _EventPipelineScreenState();
}

class _EventPipelineScreenState extends State<EventPipelineScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    widget.vm.load();
    _searchCtrl.addListener(() => setState(() => _search = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final vm = widget.vm;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerScrolled) => [
              SliverAppBar(
                pinned: true,
                expandedHeight: 160,
                backgroundColor: const Color(0xFF0A1F44),
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: _Header(vm: vm),
                ),
                bottom: TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF7BA8D4),
                  indicatorColor: const Color(0xFF41A7F5),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: const [
                    Tab(text: 'All Events'),
                    Tab(text: 'Active'),
                    Tab(text: 'Pending Action'),
                    Tab(text: 'Completed'),
                  ],
                ),
              ),
            ],
            body: Column(
              children: [
                _SearchBar(controller: _searchCtrl),
                if (vm.isLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (vm.error != null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 52,
                              color: AppColors.muted.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('Failed to load events',
                              style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: vm.reload,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Retry'),
                            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        _EventList(vm: vm, events: _filter(vm.events), showEmpty: 'No events found'),
                        _EventList(vm: vm, events: _filter(vm.activeEvents), showEmpty: 'No active events'),
                        _EventList(vm: vm, events: _filter(_pendingAction(vm)), showEmpty: 'No actions pending'),
                        _EventList(vm: vm, events: _filter(vm.completedEvents), showEmpty: 'No completed events'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreateEventPipelineScreen(vm: vm)),
            ),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Create Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        );
      },
    );
  }

  List<PipelineEvent> _filter(List<PipelineEvent> src) {
    if (_search.isEmpty) return src;
    return src.where((e) =>
      e.title.toLowerCase().contains(_search) ||
      e.location.toLowerCase().contains(_search) ||
      (e.partnerSchool?.toLowerCase().contains(_search) ?? false)
    ).toList();
  }

  List<PipelineEvent> _pendingAction(EventPipelineViewModel vm) => vm.events.where((e) =>
    e.pendingSubmissions > 0 ||
    e.status == PipelineEventStatus.adminApprovalPending ||
    e.status == PipelineEventStatus.verificationPending ||
    (e.status.isPostEvent && !e.hasReport) ||
    (e.status.isPostEvent && !e.hasImpactDraft)
  ).toList();
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.vm});
  final EventPipelineViewModel vm;

  @override
  Widget build(BuildContext context) {
    final s = vm.stats;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1F44), Color(0xFF1A3A6C)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 52, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assests/ngo_logo.jpeg',
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 38,
                    height: 38,
                    color: AppColors.primary.withValues(alpha: .2),
                    child: const Icon(Icons.volunteer_activism_rounded, color: AppColors.primary, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Event Pipeline',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatPill(label: 'Active', value: s.activeEvents, color: const Color(0xFF41A7F5)),
                const SizedBox(width: 8),
                _StatPill(label: 'EM Review', value: s.pendingEmReviews, color: const Color(0xFFF57F17)),
                const SizedBox(width: 8),
                _StatPill(label: 'Admin Approval', value: s.pendingAdminApprovals, color: const Color(0xFFC62828)),
                const SizedBox(width: 8),
                _StatPill(label: 'Certs Pending', value: s.certificatesToGenerate, color: const Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                _StatPill(label: 'Impact Drafts', value: s.impactDraftsPending, color: const Color(0xFF6A1B9A)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value > 0)
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  '$value',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search events, schools, locations…',
          hintStyle: TextStyle(fontSize: 13, color: AppColors.muted),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.muted, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: controller.clear,
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ─── Event List ───────────────────────────────────────────────────────────────

class _EventList extends StatelessWidget {
  const _EventList({required this.vm, required this.events, required this.showEmpty});
  final EventPipelineViewModel vm;
  final List<PipelineEvent> events;
  final String showEmpty;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_outlined, size: 52, color: AppColors.muted.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(showEmpty, style: TextStyle(color: AppColors.muted, fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: events.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _EventCard(event: events[i], vm: vm),
    );
  }
}

// ─── Event Card ───────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.vm});
  final PipelineEvent event;
  final EventPipelineViewModel vm;

  @override
  Widget build(BuildContext context) {
    final status = event.status;
    final pendingCount = event.pendingSubmissions;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailPipelineScreen(event: event, vm: vm)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: status.color.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: status.color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: status.color.withValues(alpha: 0.07),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  Icon(status.icon, size: 14, color: status.color),
                  const SizedBox(width: 5),
                  Text(
                    status.label,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: status.color),
                  ),
                  const Spacer(),
                  _CategoryChip(event.category),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 8),
                    _AlertBadge(count: pendingCount, label: 'pending review'),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF17324D),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 13, color: AppColors.muted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(fontSize: 12, color: AppColors.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.muted),
                      const SizedBox(width: 3),
                      Text(
                        _formatDate(event.date),
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.people_outline, size: 12, color: AppColors.muted),
                      const SizedBox(width: 3),
                      Text(
                        '${event.totalAssigned}/${event.maxVolunteers} volunteers',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),

                  // Mini pipeline progress bar
                  const SizedBox(height: 10),
                  _MiniPipelineBar(status: status),

                  // Activity summary
                  if (event.activities.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ...event.activities.take(4).map((a) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              a.role.label.split(' ').first,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )),
                        if (event.activities.length > 4)
                          Text(
                            '+${event.activities.length - 4} more',
                            style: TextStyle(fontSize: 10.5, color: AppColors.muted),
                          ),
                      ],
                    ),
                  ],

                  // Quick action buttons
                  const SizedBox(height: 11),
                  _QuickActions(event: event, vm: vm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ─── Mini Pipeline Bar ────────────────────────────────────────────────────────

class _MiniPipelineBar extends StatelessWidget {
  const _MiniPipelineBar({required this.status});
  final PipelineEventStatus status;

  @override
  Widget build(BuildContext context) {
    final total = PipelineEventStatus.pipeline.length;
    final done = status.pipelineIndex + 1;
    final progress = done / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pipeline: Stage $done of $total',
              style: TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w500),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(fontSize: 10.5, color: status.color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.muted.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(status.color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.event, required this.vm});
  final PipelineEvent event;
  final EventPipelineViewModel vm;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];

    if (event.pendingSubmissions > 0) {
      actions.add(_ActionButton(
        label: 'Review ${event.pendingSubmissions} Submission${event.pendingSubmissions > 1 ? 's' : ''}',
        color: const Color(0xFFF57F17),
        icon: Icons.rate_review_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailPipelineScreen(event: event, vm: vm, initialTab: 1)),
        ),
      ));
    }

    if (event.status == PipelineEventStatus.completed && !event.hasImpactDraft) {
      actions.add(_ActionButton(
        label: 'Create Impact Post',
        color: const Color(0xFF6A1B9A),
        icon: Icons.newspaper_rounded,
        onTap: () {
          vm.generateImpactDraft(event.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impact post draft auto-generated!'),
              backgroundColor: Color(0xFF6A1B9A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ));
    }

    if (event.status.isPostEvent && !event.hasReport) {
      actions.add(_ActionButton(
        label: 'Generate Report',
        color: const Color(0xFF1565C0),
        icon: Icons.summarize_rounded,
        onTap: () {
          vm.generateReport(event.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event report generated!'),
              backgroundColor: Color(0xFF1565C0),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ));
    }

    if (actions.isEmpty) {
      actions.add(
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventDetailPipelineScreen(event: event, vm: vm)),
          ),
          icon: const Icon(Icons.open_in_new_rounded, size: 14),
          label: const Text('View Details', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }

    return Row(
      children: actions.map((a) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 6), child: a))).toList(),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.color, required this.icon, required this.onTap});
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 13),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip(this.category);
  final dynamic category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        (category as dynamic).label as String,
        style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _AlertBadge extends StatelessWidget {
  const _AlertBadge({required this.count, required this.label});
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFC62828),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count $label',
        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}
