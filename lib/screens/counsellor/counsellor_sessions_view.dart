import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/counsellor_models.dart';
import '../../models/counsellor_session_models.dart';
import '../../viewmodels/counsellor_home_viewmodel.dart';
import 'counsellor_meeting_detail_screen.dart';

class CounsellorSessionsView extends StatefulWidget {
  const CounsellorSessionsView({required this.vm, super.key});
  final CounsellorHomeViewModel vm;

  @override
  State<CounsellorSessionsView> createState() => _CounsellorSessionsViewState();
}

class _CounsellorSessionsViewState extends State<CounsellorSessionsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
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
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A1F44),
            title: const Text(
              'My Sessions',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            automaticallyImplyLeading: false,
            bottom: TabBar(
              controller: _tabs,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF7BA8D4),
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              _UpcomingTab(vm: vm),
              _CompletedTab(vm: vm),
            ],
          ),
        );
      },
    );
  }
}

// ─── Upcoming Tab ─────────────────────────────────────────────────────────────

class _UpcomingTab extends StatelessWidget {
  const _UpcomingTab({required this.vm});
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final upcoming = vm.upcomingMeetings
      ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));

    if (upcoming.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 56,
              color: AppColors.muted.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              'No upcoming sessions',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Accepted requests confirmed by EM will appear here',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.muted.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: upcoming.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _SessionCard(request: upcoming[index], vm: vm, isUpcoming: true),
    );
  }
}

// ─── Completed Tab ────────────────────────────────────────────────────────────

class _CompletedTab extends StatelessWidget {
  const _CompletedTab({required this.vm});
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final completed = vm.completedSessions
      ..sort((a, b) {
        final aDate = a.completedAt ?? a.effectiveDate;
        final bDate = b.completedAt ?? b.effectiveDate;
        return bDate.compareTo(aDate);
      });

    if (completed.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt_outlined,
              size: 56,
              color: AppColors.muted.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              'No completed sessions yet',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: completed.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _SessionCard(request: completed[index], vm: vm, isUpcoming: false),
    );
  }
}

// ─── Session Card ─────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.request,
    required this.vm,
    required this.isUpcoming,
  });

  final SchoolBookingRequest request;
  final CounsellorHomeViewModel vm;
  final bool isUpcoming;

  @override
  Widget build(BuildContext context) {
    final d = request.effectiveDate;
    final t = request.effectiveTime;
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dateStr = '${d.day} ${months[d.month - 1]}  ·  $h:$m $period';

    final accentColor = isUpcoming
        ? const Color(0xFF1565C0)
        : const Color(0xFF00695C);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: accentColor),
                const SizedBox(width: 6),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
                const Spacer(),
                _StatusChip(status: request.status),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.schoolName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.topic,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      request.mode == SessionMode.online
                          ? Icons.videocam_outlined
                          : Icons.location_on_outlined,
                      size: 13,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      request.mode == SessionMode.online
                          ? 'Online'
                          : request.offlineLocation,
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

                // Feedback stars for completed
                if (!isUpcoming && request.feedbackRating != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ...List.generate(5, (i) {
                        final rating = request.feedbackRating!;
                        return Icon(
                          i < rating.floor()
                              ? Icons.star_rounded
                              : i < rating
                                  ? Icons.star_half_rounded
                                  : Icons.star_outline_rounded,
                          color: const Color(0xFFFFB300),
                          size: 16,
                        );
                      }),
                      const SizedBox(width: 6),
                      Text(
                        '${request.feedbackRating!.toStringAsFixed(1)} — School feedback',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],

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
                        icon: const Icon(Icons.open_in_new_rounded, size: 15),
                        label: const Text('Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accentColor,
                          side: BorderSide(color: accentColor),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    if (!isUpcoming) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              _showImpactReportSheet(context, request, vm),
                          icon: const Icon(
                            Icons.bar_chart_rounded,
                            size: 15,
                          ),
                          label: const Text('Impact Report'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00695C),
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

void _showImpactReportSheet(
  BuildContext context,
  SchoolBookingRequest request,
  CounsellorHomeViewModel vm,
) {
  final notesController = TextEditingController();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      final bottom = MediaQuery.of(sheetCtx).viewInsets.bottom;
      return Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generate Impact Report',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF17324D),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${request.schoolName}  ·  ${request.expectedStudents} students reached',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                hintText:
                    'Describe the session impact, key takeaways, and student response...',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.muted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  vm.submitImpactReport(
                    request.id,
                    counsellorNotes: notesController.text,
                    rating: request.feedbackRating,
                    schoolFeedback: request.feedbackComment,
                  );
                  Navigator.pop(sheetCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Impact report submitted successfully!'),
                      backgroundColor: Color(0xFF00695C),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text(
                  'Submit Report',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
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
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: status.color,
        ),
      ),
    );
  }
}
