import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/event_pipeline_models.dart';
import '../../viewmodels/event_pipeline_viewmodel.dart';
import 'pipeline_submission_review_screen.dart';
import 'pipeline_impact_draft_screen.dart';
import 'event_report_screen.dart';

class EventDetailPipelineScreen extends StatefulWidget {
  const EventDetailPipelineScreen({
    required this.event,
    required this.vm,
    this.initialTab = 0,
    super.key,
  });

  final PipelineEvent event;
  final EventPipelineViewModel vm;
  final int initialTab;

  @override
  State<EventDetailPipelineScreen> createState() => _EventDetailPipelineScreenState();
}

class _EventDetailPipelineScreenState extends State<EventDetailPipelineScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late PipelineEvent _event;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
    _event = widget.event;
    widget.vm.addListener(_onVmChange);
  }

  void _onVmChange() {
    final updated = widget.vm.events.where((e) => e.id == _event.id).firstOrNull;
    if (updated != null && mounted) setState(() => _event = updated);
  }

  @override
  void dispose() {
    widget.vm.removeListener(_onVmChange);
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          _Header(event: _event, vm: widget.vm),
        ],
        body: Column(
          children: [
            Container(
              color: const Color(0xFF0A1F44),
              child: TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF7BA8D4),
                indicatorColor: const Color(0xFF41A7F5),
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: [
                  const Tab(text: 'Overview'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Activities'),
                        if (_event.pendingSubmissions > 0) ...[
                          const SizedBox(width: 5),
                          _Badge(_event.pendingSubmissions),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Volunteers'),
                  const Tab(text: 'Reports'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _OverviewTab(event: _event, vm: widget.vm),
                  _ActivitiesTab(event: _event, vm: widget.vm),
                  _VolunteersTab(event: _event, vm: widget.vm),
                  _ReportsTab(event: _event, vm: widget.vm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.event, required this.vm});
  final PipelineEvent event;
  final EventPipelineViewModel vm;

  @override
  Widget build(BuildContext context) {
    final status = event.status;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 200,
      backgroundColor: const Color(0xFF0A1F44),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1F44), Color(0xFF1A3A6C)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(18, 90, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: status.color.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, size: 12, color: status.color),
                    const SizedBox(width: 4),
                    Text(status.label, style: TextStyle(fontSize: 11, color: status.color, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 12, color: Colors.white60),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      event.location,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white60),
                  const SizedBox(width: 3),
                  Text(_formatDate(event.date), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.event, required this.vm});
  final PipelineEvent event;
  final EventPipelineViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _PipelineTimeline(status: event.status),
        const SizedBox(height: 18),
        _StatsRow(event: event),
        const SizedBox(height: 18),
        _InfoSection(event: event),
        const SizedBox(height: 18),
        _PipelineActions(event: event, vm: vm),
      ],
    );
  }
}

class _PipelineTimeline extends StatelessWidget {
  const _PipelineTimeline({required this.status});
  final PipelineEventStatus status;

  @override
  Widget build(BuildContext context) {
    final pipeline = PipelineEventStatus.pipeline;
    final currentIdx = status.pipelineIndex;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pipeline Progress', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF17324D))),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(pipeline.length, (i) {
                final s = pipeline[i];
                final isDone = i < currentIdx;
                final isCurrent = i == currentIdx;
                return Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isCurrent ? s.color : isDone ? const Color(0xFF70D98B) : AppColors.muted.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: isCurrent ? Border.all(color: s.color, width: 2) : null,
                          ),
                          child: Icon(
                            isDone ? Icons.check_rounded : s.icon,
                            size: 13,
                            color: (isDone || isCurrent) ? Colors.white : AppColors.muted.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 60,
                          child: Text(
                            s.label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                              color: isCurrent ? s.color : isDone ? const Color(0xFF70D98B) : AppColors.muted.withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (i < pipeline.length - 1)
                      Container(
                        width: 20,
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 18),
                        color: i < currentIdx ? const Color(0xFF70D98B) : AppColors.muted.withValues(alpha: 0.2),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.event});
  final PipelineEvent event;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Assigned', value: '${event.totalAssigned}', icon: Icons.people_rounded, color: AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'Submitted', value: '${event.totalSubmitted}', icon: Icons.upload_file_rounded, color: const Color(0xFFF57F17))),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'Approved', value: '${event.totalApproved}', icon: Icons.check_circle_rounded, color: const Color(0xFF2E7D32))),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'Reached', value: '${event.totalPeopleReached}', icon: Icons.volunteer_activism_rounded, color: const Color(0xFF6A1B9A))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 17)),
          Text(label, style: TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.event});
  final PipelineEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Event Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF17324D))),
          const SizedBox(height: 12),
          _infoRow(Icons.description_rounded, 'Description', event.description),
          if (event.partnerSchool != null) _infoRow(Icons.school_rounded, 'Partner School', event.partnerSchool!),
          _infoRow(Icons.person_rounded, 'Event Manager', event.assignedEventManagerName),
          if (event.assignedCounsellorName != null) _infoRow(Icons.support_agent_rounded, 'Counsellor', event.assignedCounsellorName!),
          if (event.expectedWork != null) _infoRow(Icons.assignment_rounded, 'Expected Work', event.expectedWork!),
          if (event.proofRequired != null) _infoRow(Icons.attach_file_rounded, 'Proof Required', event.proofRequired!),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (event.certificateEligible) _Flag('Certificate', Icons.workspace_premium_rounded, const Color(0xFF1565C0)),
              if (event.donationEligible) _Flag('Donation', Icons.payments_rounded, const Color(0xFF2E7D32)),
              if (event.stipendEligible) _Flag('Stipend ₹${event.stipendAmount?.toStringAsFixed(0) ?? '0'}', Icons.currency_rupee_rounded, const Color(0xFF6A1B9A)),
              if (event.isOnline) _Flag('Online', Icons.videocam_rounded, const Color(0xFF00695C)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF17324D))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  const _Flag(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PipelineActions extends StatelessWidget {
  const _PipelineActions({required this.event, required this.vm});
  final PipelineEvent event;
  final EventPipelineViewModel vm;

  @override
  Widget build(BuildContext context) {
    final actions = <_PipelineActionTile>[];

    if (!event.status.isPostEvent && !event.status.isActive) {
      actions.add(_PipelineActionTile(
        label: 'Advance Pipeline Stage',
        subtitle: 'Move to: ${_nextStatus()?.label ?? 'End'}',
        icon: Icons.arrow_forward_rounded,
        color: AppColors.primary,
        onTap: () {
          vm.advanceEventStatus(event.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Event moved to: ${_nextStatus()?.label ?? 'next stage'}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.primary,
            ),
          );
        },
      ));
    }

    if (event.status == PipelineEventStatus.completed && !event.hasImpactDraft) {
      actions.add(_PipelineActionTile(
        label: 'Auto-Generate Impact Post',
        subtitle: 'Draft from event data',
        icon: Icons.newspaper_rounded,
        color: const Color(0xFF6A1B9A),
        onTap: () {
          vm.generateImpactDraft(event.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impact post draft created!'), behavior: SnackBarBehavior.floating),
          );
        },
      ));
    }

    if (event.hasImpactDraft && event.impactDraft!.status != ImpactPostDraftStatus.published) {
      actions.add(_PipelineActionTile(
        label: 'Edit Impact Post Draft',
        subtitle: 'Status: ${event.impactDraft!.status.label}',
        icon: Icons.edit_rounded,
        color: const Color(0xFF6A1B9A),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PipelineImpactDraftScreen(event: event, vm: vm)),
        ),
      ));
    }

    if (event.status.isPostEvent && !event.hasReport) {
      actions.add(_PipelineActionTile(
        label: 'Generate Event Report',
        subtitle: 'Full event summary + impact data',
        icon: Icons.summarize_rounded,
        color: const Color(0xFF1565C0),
        onTap: () {
          vm.generateReport(event.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event report generated!'), behavior: SnackBarBehavior.floating),
          );
        },
      ));
    }

    if (event.hasReport) {
      actions.add(_PipelineActionTile(
        label: 'View Event Report',
        subtitle: 'Status: ${event.report!.status.label}',
        icon: Icons.article_rounded,
        color: const Color(0xFF00695C),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventReportScreen(report: event.report!, vm: vm, eventId: event.id)),
        ),
      ));
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Actions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF17324D))),
          const SizedBox(height: 10),
          ...actions,
        ],
      ),
    );
  }

  PipelineEventStatus? _nextStatus() {
    final nextIdx = event.status.pipelineIndex + 1;
    if (nextIdx >= PipelineEventStatus.pipeline.length) return null;
    return PipelineEventStatus.pipeline[nextIdx];
  }
}

class _PipelineActionTile extends StatelessWidget {
  const _PipelineActionTile({required this.label, required this.subtitle, required this.icon, required this.color, required this.onTap});
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        tileColor: color.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.muted)),
        trailing: Icon(Icons.chevron_right_rounded, color: color),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}

// ─── Activities Tab ───────────────────────────────────────────────────────────

class _ActivitiesTab extends StatelessWidget {
  const _ActivitiesTab({required this.event, required this.vm});
  final PipelineEvent event;
  final EventPipelineViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (event.activities.isEmpty) {
      return Center(
        child: Text('No activities yet', style: TextStyle(color: AppColors.muted, fontSize: 15)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: event.activities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, i) => _ActivityCard(
        activity: event.activities[i],
        event: event,
        vm: vm,
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.event, required this.vm});
  final PipelineActivity activity;
  final PipelineEvent event;
  final EventPipelineViewModel vm;

  @override
  Widget build(BuildContext context) {
    final pending = activity.pendingSubmissions;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: pending > 0 ? const Color(0xFFF57F17).withValues(alpha: 0.3) : AppColors.muted.withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(activity.role.icon, size: 15, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    activity.title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF17324D)),
                  ),
                ),
                Text(
                  '${activity.assignedCount}/${activity.maxStudents}',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: activity.isFull ? const Color(0xFFC62828) : AppColors.primary),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activity.description != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(activity.description!, style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  ),
                Row(
                  children: [
                    if (activity.hasCertificate) _Flag2('Certificate', const Color(0xFF1565C0)),
                    if (activity.requiresDonationProof) ...[
                      const SizedBox(width: 6),
                      _Flag2('Donation Proof', const Color(0xFF2E7D32)),
                    ],
                    const Spacer(),
                    if (pending > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF57F17),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$pending pending review',
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                if (activity.assignments.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...activity.assignments.map((a) => _AssignmentRow(
                    assignment: a,
                    event: event,
                    activity: activity,
                    vm: vm,
                  )),
                ] else ...[
                  const SizedBox(height: 8),
                  Text('No volunteers assigned yet', style: TextStyle(fontSize: 12, color: AppColors.muted, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentRow extends StatelessWidget {
  const _AssignmentRow({required this.assignment, required this.event, required this.activity, required this.vm});
  final PipelineAssignment assignment;
  final PipelineEvent event;
  final PipelineActivity activity;
  final EventPipelineViewModel vm;

  @override
  Widget build(BuildContext context) {
    final status = assignment.status;
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: status.color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: status.color.withValues(alpha: 0.15),
            child: Text(assignment.initials, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: status.color)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(assignment.studentName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF17324D))),
                Row(
                  children: [
                    Icon(status.icon, size: 10, color: status.color),
                    const SizedBox(width: 3),
                    Text(status.label, style: TextStyle(fontSize: 10.5, color: status.color, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          if (status == PipelineAssignmentStatus.submitted)
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PipelineSubmissionReviewScreen(
                  assignment: assignment,
                  event: event,
                  activity: activity,
                  vm: vm,
                )),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF57F17),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              child: const Text('Review', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          if (status == PipelineAssignmentStatus.adminApproved)
            TextButton(
              onPressed: () {
                vm.generateCertificate(event.id, activity.id, assignment.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Certificate generated for ${assignment.studentName}!'),
                    backgroundColor: const Color(0xFF1565C0),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1565C0),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              child: const Text('Gen. Cert', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class _Flag2 extends StatelessWidget {
  const _Flag2(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 9.5, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Volunteers Tab ───────────────────────────────────────────────────────────

class _VolunteersTab extends StatelessWidget {
  const _VolunteersTab({required this.event, required this.vm});
  final PipelineEvent event;
  final EventPipelineViewModel vm;

  @override
  Widget build(BuildContext context) {
    final all = event.allAssignments;
    if (all.isEmpty) {
      return Center(child: Text('No volunteers assigned yet', style: TextStyle(color: AppColors.muted)));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: all.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final a = all[i];
        final status = a.status;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.muted.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: status.color.withValues(alpha: 0.15),
                child: Text(a.initials, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: status.color)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.studentName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF17324D))),
                    Text(a.activityTitle, style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                    if (a.submission != null)
                      Text(
                        '${a.submission!.hoursWorked.toStringAsFixed(1)} hrs · ${a.submission!.peopleReached} reached',
                        style: TextStyle(fontSize: 11, color: AppColors.muted.withValues(alpha: 0.7)),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, size: 10, color: status.color),
                    const SizedBox(width: 3),
                    Text(status.label, style: TextStyle(fontSize: 9.5, color: status.color, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Reports Tab ──────────────────────────────────────────────────────────────

class _ReportsTab extends StatelessWidget {
  const _ReportsTab({required this.event, required this.vm});
  final PipelineEvent event;
  final EventPipelineViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Impact Post
        _ReportSection(
          title: 'Impact Post',
          icon: Icons.newspaper_rounded,
          color: const Color(0xFF6A1B9A),
          status: event.hasImpactDraft ? event.impactDraft!.status.label : null,
          statusColor: event.hasImpactDraft ? event.impactDraft!.status.color : null,
          description: event.hasImpactDraft
              ? event.impactDraft!.description
              : 'Not yet generated. Complete the event first.',
          actionLabel: event.hasImpactDraft
              ? (event.impactDraft!.status == ImpactPostDraftStatus.published ? 'View' : 'Edit Draft')
              : 'Generate',
          actionAvailable: true,
          onAction: () {
            if (!event.hasImpactDraft) {
              vm.generateImpactDraft(event.id);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PipelineImpactDraftScreen(event: event, vm: vm)),
              );
            }
          },
        ),
        const SizedBox(height: 14),
        // Event Report
        _ReportSection(
          title: 'Event Report',
          icon: Icons.summarize_rounded,
          color: const Color(0xFF1565C0),
          status: event.hasReport ? event.report!.status.label : null,
          statusColor: event.hasReport ? event.report!.status.color : null,
          description: event.hasReport
              ? 'Report generated on ${_formatDate(event.report!.generatedAt)}. ${event.report!.totalVolunteers} volunteers, ${event.report!.studentsReached} reached.'
              : 'Not yet generated.',
          actionLabel: event.hasReport ? 'View Report' : 'Generate Report',
          actionAvailable: event.status.isPostEvent || event.status == PipelineEventStatus.completed,
          onAction: () {
            if (!event.hasReport) {
              vm.generateReport(event.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Event report generated!'), behavior: SnackBarBehavior.floating),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EventReportScreen(report: event.report!, vm: vm, eventId: event.id)),
              );
            }
          },
        ),
        const SizedBox(height: 14),
        // Certificates
        _CertificateSummarySection(event: event, vm: vm),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.status,
    required this.statusColor,
    required this.description,
    required this.actionLabel,
    required this.actionAvailable,
    required this.onAction,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String? status;
  final Color? statusColor;
  final String description;
  final String actionLabel;
  final bool actionAvailable;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF17324D)))),
              if (status != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor!.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status!, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(description, style: TextStyle(fontSize: 12.5, color: AppColors.muted), maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: actionAvailable ? onAction : null,
              icon: Icon(icon, size: 14),
              label: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.muted.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificateSummarySection extends StatelessWidget {
  const _CertificateSummarySection({required this.event, required this.vm});
  final PipelineEvent event;
  final EventPipelineViewModel vm;

  @override
  Widget build(BuildContext context) {
    final certs = event.allAssignments
        .where((a) => a.certificate != null)
        .map((a) => a.certificate!)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF1565C0).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF1565C0), size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Certificates', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF17324D))),
              const Spacer(),
              Text('${certs.length} generated', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
          if (certs.isEmpty) ...[
            const SizedBox(height: 12),
            Text('No certificates generated yet.\nApprove student submissions to enable certificate generation.',
                style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
          ] else ...[
            const SizedBox(height: 10),
            ...certs.map((cert) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Icon(
                    cert.isPhysicallySigned ? Icons.verified_rounded : Icons.pending_rounded,
                    size: 14,
                    color: cert.isPhysicallySigned ? const Color(0xFF2E7D32) : const Color(0xFFF57F17),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cert.studentName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF17324D))),
                        Text('${cert.certificateId} · ${cert.hoursServed.toStringAsFixed(0)} hrs', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: cert.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(cert.status.label, style: TextStyle(fontSize: 9.5, color: cert.status.color, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge(this.count);
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: const Color(0xFFC62828), borderRadius: BorderRadius.circular(8)),
      child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }
}
