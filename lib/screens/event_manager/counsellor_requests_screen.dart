import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/counsellor_session_models.dart';
import '../../viewmodels/counsellor_viewmodel.dart';

/// Admin oversight of every school counselling request across all
/// counsellors — backed by the real `GET /counsellor/requests` data
/// (`CounsellorViewModel.allAdminRequests`). Read-only: accepting,
/// declining and rescheduling a request is the assigned counsellor's own
/// action (in their portal), not something the backend lets an admin do on
/// their behalf, so this screen surfaces status and detail rather than
/// fake action buttons.
class CounsellorRequestsScreen extends StatefulWidget {
  const CounsellorRequestsScreen({super.key});

  @override
  State<CounsellorRequestsScreen> createState() =>
      _CounsellorRequestsScreenState();
}

class _CounsellorRequestsScreenState extends State<CounsellorRequestsScreen> {
  final _vm = CounsellorViewModel.shared;
  SchoolRequestStatus? _filter;

  static const _pendingStatuses = {
    SchoolRequestStatus.newRequest,
    SchoolRequestStatus.pendingConfirmation,
  };
  static const _activeStatuses = {
    SchoolRequestStatus.accepted,
    SchoolRequestStatus.rescheduled,
    SchoolRequestStatus.confirmed,
    SchoolRequestStatus.scheduled,
  };

  @override
  void initState() {
    super.initState();
    _vm.loadAllAdminRequests();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('School Counsellor Requests'),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => _vm.loadAllAdminRequests(),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: () => _vm.loadAllAdminRequests(),
      child: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final all = _vm.allAdminRequests;
          final requests = _filter == null
              ? all
              : all.where((r) => r.status == _filter).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              const Text(
                'School Counsellor Requests',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Every school counselling request across all counsellors.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _summary(
                    'Pending',
                    all.where((r) => _pendingStatuses.contains(r.status)).length,
                    const Color(0xFFF57F17),
                  ),
                  const SizedBox(width: 9),
                  _summary(
                    'Active',
                    all.where((r) => _activeStatuses.contains(r.status)).length,
                    const Color(0xFF1565C0),
                  ),
                  const SizedBox(width: 9),
                  _summary(
                    'Complete',
                    all
                        .where((r) => r.status == SchoolRequestStatus.completed)
                        .length,
                    const Color(0xFF2E7D32),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterChip('All', null),
                    for (final status in SchoolRequestStatus.values)
                      _filterChip(status.label, status),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (requests.isEmpty)
                _empty()
              else
                for (final request in requests) ...[
                  _requestCard(context, request),
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
    ),
  );

  Widget _summary(String label, int count, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .2)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _filterChip(String label, SchoolRequestStatus? status) {
    final active = _filter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: FilterChip(
        selected: active,
        label: Text(label),
        onSelected: (_) => setState(() => _filter = status),
      ),
    );
  }

  Widget _requestCard(BuildContext context, SchoolBookingRequest r) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: r.status.color.withValues(alpha: .18)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: r.status.color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.school_rounded, color: r.status.color),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.schoolName,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${r.classGroup.isEmpty ? r.program : r.classGroup} • ${r.expectedStudents} students',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            _status(r.status),
          ],
        ),
        const SizedBox(height: 13),
        _line(Icons.person_rounded, 'Counsellor', r.counsellorName),
        _line(Icons.topic_rounded, 'Topic', r.topic),
        _line(r.mode.icon, 'Mode', r.mode.label),
        _line(
          Icons.calendar_month_rounded,
          'Preferred date',
          _date(r.preferredDate),
        ),
        if (r.status == SchoolRequestStatus.declined && r.declineReason != null)
          _line(Icons.info_outline_rounded, 'Decline reason', r.declineReason!.label),
        const Divider(height: 22),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: () => _viewDetails(context, r),
            icon: const Icon(Icons.visibility_rounded, size: 17),
            label: const Text('View Details'),
          ),
        ),
      ],
    ),
  );

  Widget _line(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 8),
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _status(SchoolRequestStatus status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: status.color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status.label,
      style: TextStyle(
        color: status.color,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _empty() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 60),
    child: Column(
      children: [
        Icon(Icons.inbox_rounded, color: AppColors.muted, size: 42),
        SizedBox(height: 10),
        Text(
          'No requests in this status.',
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );

  void _viewDetails(BuildContext context, SchoolBookingRequest r) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(r.schoolName),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _line(Icons.flag_rounded, 'Status', r.status.label),
            _line(Icons.person_rounded, 'Coordinator', r.coordinatorName),
            if (r.coordinatorPhone.isNotEmpty)
              _line(Icons.phone_rounded, 'Phone', r.coordinatorPhone),
            if (r.coordinatorEmail.isNotEmpty)
              _line(Icons.email_rounded, 'Email', r.coordinatorEmail),
            if (r.schoolAddress.isNotEmpty)
              _line(Icons.location_on_rounded, 'Address', r.schoolAddress),
            _line(Icons.person_pin_rounded, 'Counsellor', r.counsellorName),
            _line(Icons.topic_rounded, 'Topic', r.topic),
            _line(Icons.groups_rounded, 'Students', '${r.expectedStudents}'),
            if (r.language.isNotEmpty)
              _line(Icons.translate_rounded, 'Language', r.language),
            _line(r.mode.icon, 'Mode', r.mode.label),
            _line(Icons.calendar_month_rounded, 'Preferred date', _date(r.preferredDate)),
            if (r.suggestedDate != null)
              _line(Icons.event_repeat_rounded, 'Suggested date', _date(r.suggestedDate!)),
            if (r.specialRequirements.isNotEmpty)
              _line(Icons.notes_rounded, 'Requirements', r.specialRequirements),
            if (r.assignedEventManager != null)
              _line(Icons.badge_rounded, 'Event Manager', r.assignedEventManager!),
            if (r.status == SchoolRequestStatus.declined && r.declineReason != null)
              _line(Icons.cancel_rounded, 'Decline reason', r.declineReason!.label),
            if (r.declineNote.isNotEmpty)
              _line(Icons.comment_rounded, 'Decline note', r.declineNote),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
