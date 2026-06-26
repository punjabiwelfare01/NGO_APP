import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/counsellor_models.dart';
import '../../models/counsellor_session_models.dart';
import '../../viewmodels/counsellor_home_viewmodel.dart';
import 'counsellor_meeting_detail_screen.dart';

class CounsellorRequestsView extends StatefulWidget {
  const CounsellorRequestsView({required this.vm, super.key});
  final CounsellorHomeViewModel vm;

  @override
  State<CounsellorRequestsView> createState() => _CounsellorRequestsViewState();
}

class _CounsellorRequestsViewState extends State<CounsellorRequestsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
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
        final newReqs = vm.newRequests;
        final accepted = vm.allRequests
            .where(
              (r) =>
                  r.status == SchoolRequestStatus.accepted ||
                  r.status == SchoolRequestStatus.pendingConfirmation ||
                  r.status == SchoolRequestStatus.confirmed ||
                  r.status == SchoolRequestStatus.scheduled,
            )
            .toList();
        final rescheduled = vm.rescheduledRequests;
        final all = vm.allRequests;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A1F44),
            title: const Text(
              'School Requests',
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
              tabs: [
                Tab(text: newReqs.isEmpty ? 'New' : 'New (${newReqs.length})'),
                Tab(text: 'Accepted'),
                Tab(
                  text: rescheduled.isEmpty
                      ? 'Rescheduled'
                      : 'Rescheduled (${rescheduled.length})',
                ),
                const Tab(text: 'All'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              _RequestList(
                requests: newReqs,
                vm: vm,
                emptyMessage: 'No new school requests',
                emptyIcon: Icons.inbox_outlined,
              ),
              _RequestList(
                requests: accepted,
                vm: vm,
                emptyMessage: 'No accepted requests',
                emptyIcon: Icons.check_circle_outline_rounded,
              ),
              _RequestList(
                requests: rescheduled,
                vm: vm,
                emptyMessage: 'No rescheduled requests',
                emptyIcon: Icons.schedule_outlined,
              ),
              _RequestList(
                requests: all,
                vm: vm,
                emptyMessage: 'No requests yet',
                emptyIcon: Icons.folder_open_outlined,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Request List ─────────────────────────────────────────────────────────────

class _RequestList extends StatelessWidget {
  const _RequestList({
    required this.requests,
    required this.vm,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  final List<SchoolBookingRequest> requests;
  final CounsellorHomeViewModel vm;
  final String emptyMessage;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 56, color: AppColors.muted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
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
      itemCount: requests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _RequestCard(request: requests[index], vm: vm),
    );
  }
}

// ─── Request Card ─────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.vm});
  final SchoolBookingRequest request;
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final d = request.effectiveDate;
    final t = request.effectiveTime;
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    final dateStr = '${d.day}/${d.month}/${d.year}  $h:$m $period';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: request.status.color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: request.status.color.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.school_rounded,
                  size: 16,
                  color: request.status.color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.schoolName,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                  request.topic,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  Icons.people_outline_rounded,
                  '${request.classGroup}  ·  ${request.expectedStudents} students',
                ),
                _InfoRow(Icons.calendar_today_outlined, dateStr),
                _InfoRow(
                  request.mode == SessionMode.online
                      ? Icons.videocam_outlined
                      : Icons.location_on_outlined,
                  request.mode == SessionMode.online
                      ? 'Online Session'
                      : request.offlineLocation.isNotEmpty
                          ? request.offlineLocation
                          : 'Offline — ${request.schoolAddress}',
                ),
                _InfoRow(Icons.translate_rounded, request.language),
                if (request.specialRequirements.isNotEmpty)
                  _InfoRow(
                    Icons.info_outline_rounded,
                    request.specialRequirements,
                    muted: false,
                  ),

                // Contact visible after acceptance
                if (request.contactVisible) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  _InfoRow(
                    Icons.person_outline_rounded,
                    '${request.coordinatorName}  ·  ${request.coordinatorPhone}',
                    muted: false,
                    color: const Color(0xFF2E7D32),
                  ),
                ],

                // Decline reason
                if (request.declineReason != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cancel_outlined,
                          size: 14,
                          color: Color(0xFFC62828),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            request.declineReason!.label,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFC62828),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Rescheduled info
                if (request.suggestedDate != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: Color(0xFF6A1B9A),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Suggested: ${request.suggestedDate!.day}/${request.suggestedDate!.month}/${request.suggestedDate!.year}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6A1B9A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action buttons for new requests
                if (request.status == SchoolRequestStatus.newRequest) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _ActionButton(
                        label: 'Decline',
                        icon: Icons.cancel_outlined,
                        color: const Color(0xFFC62828),
                        filled: false,
                        onTap: () => _showDeclineSheet(context),
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        label: 'Reschedule',
                        icon: Icons.schedule_rounded,
                        color: const Color(0xFF6A1B9A),
                        filled: false,
                        onTap: () => _showRescheduleDialog(context),
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        label: 'Accept',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF2E7D32),
                        filled: true,
                        onTap: () {
                          vm.acceptRequest(request.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Accepted request from ${request.schoolName}',
                              ),
                              backgroundColor: const Color(0xFF2E7D32),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
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
                      label: const Text('View Full Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1565C0),
                        side: const BorderSide(
                          color: Color(0xFF1565C0),
                        ),
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
          ),
        ],
      ),
    );
  }

  void _showDeclineSheet(BuildContext context) {
    DeclineReason? selected;
    final noteController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
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
                Text(
                  'Decline Request',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Why are you declining this request?',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                RadioGroup<DeclineReason>(
                  groupValue: selected,
                  onChanged: (v) => setSheetState(() => selected = v),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: DeclineReason.values.map(
                      (r) => RadioListTile<DeclineReason>(
                        value: r,
                        title: Text(
                          r.label,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        activeColor: const Color(0xFFC62828),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    hintText: 'Additional note (optional)',
                    hintStyle:
                        TextStyle(fontSize: 13, color: AppColors.muted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: selected == null
                            ? null
                            : () {
                                vm.declineRequest(
                                  request.id,
                                  selected!,
                                  note: noteController.text,
                                );
                                Navigator.pop(sheetCtx);
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showRescheduleDialog(BuildContext context) async {
    DateTime? pickedDate;
    TimeOfDay? pickedTime;

    pickedDate = await showDatePicker(
      context: context,
      initialDate: request.preferredDate.isAfter(DateTime.now())
          ? request.preferredDate
          : DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (pickedDate == null || !context.mounted) return;

    pickedTime = await showTimePicker(
      context: context,
      initialTime: request.preferredTime,
    );
    if (pickedTime == null || !context.mounted) return;

    vm.rescheduleRequest(request.id, pickedDate, pickedTime);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Suggested new time for ${request.schoolName}',
        ),
        backgroundColor: const Color(0xFF6A1B9A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text, {this.muted = true, this.color});
  final IconData icon;
  final String text;
  final bool muted;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? (muted ? AppColors.muted : AppColors.ink);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 14, color: c),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                color: c,
                fontWeight: muted ? FontWeight.w500 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Expanded(
        child: FilledButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 14),
          label: Text(label, style: const TextStyle(fontSize: 12)),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
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
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: status.color,
        ),
      ),
    );
  }
}
