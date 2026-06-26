import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/counsellor_models.dart';
import '../../models/counsellor_session_models.dart';
import '../../repositories/api_client.dart';
import '../../viewmodels/counsellor_home_viewmodel.dart';
import 'counsellor_meeting_detail_screen.dart';

class CounsellorHomeView extends StatelessWidget {
  const CounsellorHomeView({
    required this.vm,
    required this.counsellorName,
    required this.onNavigate,
    super.key,
  });

  final CounsellorHomeViewModel vm;
  final String counsellorName;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.state == CounsellorHomeLoadState.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        return CustomScrollView(
          slivers: [
            _AppBar(name: counsellorName, profile: vm.profile),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _OverviewCards(stats: vm.stats),
                  if (vm.todayMeetings.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _SectionHeader(
                      icon: Icons.today_rounded,
                      title: "Today's Sessions",
                      count: vm.todayMeetings.length,
                      color: const Color(0xFF1565C0),
                    ),
                    const SizedBox(height: 12),
                    _TodayMeetingsSection(meetings: vm.todayMeetings, vm: vm),
                  ],
                  if (vm.newRequests.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _SectionHeader(
                      icon: Icons.fiber_new_rounded,
                      title: 'New School Requests',
                      count: vm.newRequests.length,
                      color: const Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 12),
                    _NewRequestsSection(requests: vm.newRequests, vm: vm),
                  ],
                  if (vm.upcomingReminders.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _SectionHeader(
                      icon: Icons.notifications_active_outlined,
                      title: 'Upcoming Reminders',
                      count: vm.upcomingReminders.length,
                      color: const Color(0xFFF57F17),
                    ),
                    const SizedBox(height: 12),
                    _UpcomingRemindersSection(
                      reminders: vm.upcomingReminders.take(3).toList(),
                      vm: vm,
                    ),
                  ],
                  const SizedBox(height: 28),
                  _QuickActionsSection(onNavigate: onNavigate),
                  const SizedBox(height: 28),
                  _VerificationStatusSection(profile: vm.profile),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  const _AppBar({required this.name, required this.profile});

  final String name;
  final CounsellorProfile profile;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return SliverAppBar(
      expandedHeight: 170,
      pinned: true,
      backgroundColor: const Color(0xFF0A1F44),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1F44), Color(0xFF1565C0)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: Color(0xFFB3C8E8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _VerifiedBadge(ngoId: profile.ngoVerificationId),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                foregroundDecoration: profile.photoUrl == null
                    ? null
                    : BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(
                            ApiClient.resolveUrl(profile.photoUrl!),
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                child: profile.photoUrl == null
                    ? const Icon(
                        Icons.military_tech_rounded,
                        color: Colors.white,
                        size: 28,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      title: Text(
        profile.name.split(' ').take(3).join(' '),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge({required this.ngoId});
  final String ngoId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF81C784).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: Color(0xFF81C784),
            size: 13,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              'PWT Verified · $ngoId',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFB9F6CA),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
    this.count,
  });

  final IconData icon;
  final String title;
  final Color color;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Overview Cards ───────────────────────────────────────────────────────────

class _OverviewCards extends StatelessWidget {
  const _OverviewCards({required this.stats});
  final CounsellorStats stats;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatData(
        "Today's\nSessions",
        '${stats.todayScheduled}',
        Icons.today_rounded,
        const Color(0xFF1565C0),
        const Color(0xFFE3F2FD),
      ),
      _StatData(
        'New\nRequests',
        '${stats.newRequests}',
        Icons.fiber_new_rounded,
        const Color(0xFF2E7D32),
        const Color(0xFFE8F5E9),
      ),
      _StatData(
        'Awaiting\nConfirmation',
        '${stats.pendingConfirmation}',
        Icons.pending_rounded,
        const Color(0xFFF57F17),
        const Color(0xFFFFF8E1),
      ),
      _StatData(
        'Completed\nThis Month',
        '${stats.completedThisMonth}',
        Icons.task_alt_rounded,
        const Color(0xFF00695C),
        const Color(0xFFE0F2F1),
      ),
    ];

    return SizedBox(
      height: 122,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _StatCard(data: cards[index]),
      ),
    );
  }
}

class _StatData {
  const _StatData(this.label, this.value, this.icon, this.color, this.bg);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});
  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: data.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: data.color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: data.color, size: 22),
          const Spacer(),
          Text(
            data.value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: data.color,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: data.color.withValues(alpha: 0.8),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Today's Meetings ─────────────────────────────────────────────────────────

class _TodayMeetingsSection extends StatelessWidget {
  const _TodayMeetingsSection({required this.meetings, required this.vm});
  final List<SchoolBookingRequest> meetings;
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: meetings
          .map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TodayMeetingCard(request: m, vm: vm),
            ),
          )
          .toList(),
    );
  }
}

class _TodayMeetingCard extends StatelessWidget {
  const _TodayMeetingCard({required this.request, required this.vm});
  final SchoolBookingRequest request;
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = request.effectiveTime;
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF1565C0).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: Color(0xFF1565C0),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '$h:$m $period',
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                _StatusChip(status: request.status),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.schoolName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF17324D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.topic,
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      request.mode == SessionMode.online
                          ? Icons.videocam_outlined
                          : Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        request.mode == SessionMode.online
                            ? 'Online Session'
                            : request.offlineLocation,
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.people_outline,
                      size: 14,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${request.expectedStudents} students',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CounsellorMeetingDetailScreen(
                              request: request,
                              vm: vm,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1565C0),
                          side: const BorderSide(color: Color(0xFF1565C0)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    if (request.mode == SessionMode.online &&
                        request.meetingLink != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CounsellorMeetingDetailScreen(
                                request: request,
                                vm: vm,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.videocam_rounded, size: 16),
                          label: const Text('Join'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── New Requests ─────────────────────────────────────────────────────────────

class _NewRequestsSection extends StatelessWidget {
  const _NewRequestsSection({required this.requests, required this.vm});
  final List<SchoolBookingRequest> requests;
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: requests
          .take(2)
          .map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _NewRequestCard(request: r, vm: vm),
            ),
          )
          .toList(),
    );
  }
}

class _NewRequestCard extends StatelessWidget {
  const _NewRequestCard({required this.request, required this.vm});
  final SchoolBookingRequest request;
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final date = request.preferredDate;
    final dateStr =
        '${_dayName(date.weekday)}, ${date.day} ${_monthName(date.month)}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: Color(0xFF2E7D32),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.schoolName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF17324D),
                      ),
                    ),
                    Text(
                      request.classGroup,
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'New',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.topic,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF17324D),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: AppColors.muted,
              ),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(width: 12),
              Icon(Icons.people_outline, size: 13, color: AppColors.muted),
              const SizedBox(width: 4),
              Text(
                '${request.expectedStudents} students',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    vm.acceptRequest(request.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Request from ${request.schoolName} accepted!',
                        ),
                        backgroundColor: const Color(0xFF2E7D32),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CounsellorMeetingDetailScreen(
                        request: request,
                        vm: vm,
                      ),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Upcoming Reminders ───────────────────────────────────────────────────────

class _UpcomingRemindersSection extends StatelessWidget {
  const _UpcomingRemindersSection({required this.reminders, required this.vm});
  final List<MeetingReminder> reminders;
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: reminders
          .map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReminderCard(reminder: r, vm: vm),
            ),
          )
          .toList(),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.reminder, required this.vm});
  final MeetingReminder reminder;
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final typeColor = reminder.type == ReminderType.minutes15
        ? const Color(0xFFC62828)
        : reminder.type == ReminderType.hours2
        ? const Color(0xFFF57F17)
        : const Color(0xFF1565C0);
    final typeIcon = reminder.type == ReminderType.minutes15
        ? Icons.alarm_rounded
        : Icons.notifications_rounded;

    return Container(
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: typeColor.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          Icon(typeIcon, color: typeColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.type.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: typeColor,
                  ),
                ),
                Text(
                  reminder.schoolName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF17324D),
                  ),
                ),
                Text(
                  reminder.mode == SessionMode.online
                      ? 'Online · ${reminder.locationOrLink ?? ''}'
                      : 'Offline · ${reminder.locationOrLink ?? ''}',
                  style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => vm.dismissReminder(reminder.id),
            icon: Icon(Icons.close, size: 18, color: AppColors.muted),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData(
        Icons.inbox_rounded,
        'View Requests',
        const Color(0xFF1565C0),
        const Color(0xFFE3F2FD),
        1,
      ),
      _ActionData(
        Icons.calendar_month_rounded,
        'My Schedule',
        const Color(0xFF6A1B9A),
        const Color(0xFFF3E5F5),
        2,
      ),
      _ActionData(
        Icons.task_alt_rounded,
        'My Sessions',
        const Color(0xFF00695C),
        const Color(0xFFE0F2F1),
        3,
      ),
      _ActionData(
        Icons.bar_chart_rounded,
        'Impact Reports',
        const Color(0xFFF57F17),
        const Color(0xFFFFF8E1),
        3,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 80,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) => _ActionTile(
            data: actions[index],
            onTap: () => onNavigate(actions[index].destinationIndex),
          ),
        ),
      ],
    );
  }
}

class _ActionData {
  const _ActionData(
    this.icon,
    this.label,
    this.color,
    this.bg,
    this.destinationIndex,
  );
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final int destinationIndex;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.data, required this.onTap});
  final _ActionData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: data.bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: data.color.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Verification Status ──────────────────────────────────────────────────────

class _VerificationStatusSection extends StatelessWidget {
  const _VerificationStatusSection({required this.profile});
  final CounsellorProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verification Status',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _VerLine(
            'NGO Verification ID',
            profile.ngoVerificationId,
            bold: true,
          ),
          _VerLine('Verified By', 'PWT Admin — Punjabi Welfare Trust'),
          _VerLine('Designation (Public)', profile.designation),
          if (profile.showRetiredStatus)
            _VerLine('Status', profile.publicStatusLabel),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFF57F17).withValues(alpha: 0.3),
              ),
            ),
            child: const Text(
              'Private information — Army/Govt ID, Aadhaar, PAN, personal phone, and home address are never shared publicly.',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFFE65100),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerLine extends StatelessWidget {
  const _VerLine(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF17324D),
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status Chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final SchoolRequestStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 11, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _dayName(int weekday) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days[weekday - 1];
}

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}
