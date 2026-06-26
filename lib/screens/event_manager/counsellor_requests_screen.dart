import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/counsellor_models.dart';
import '../../viewmodels/counsellor_viewmodel.dart';

class CounsellorRequestsScreen extends StatefulWidget {
  const CounsellorRequestsScreen({super.key});

  @override
  State<CounsellorRequestsScreen> createState() =>
      _CounsellorRequestsScreenState();
}

class _CounsellorRequestsScreenState extends State<CounsellorRequestsScreen> {
  final _vm = CounsellorViewModel.shared;
  RequestStatus? _filter;

  @override
  void initState() {
    super.initState();
    _vm.load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('School Counsellor Requests'),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
    ),
    body: ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final requests = _filter == null
            ? _vm.requests
            : _vm.requests.where((r) => r.status == _filter).toList();
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
            'Review, recommend, assign and confirm verified counsellors.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _summary(
                'Pending',
                _vm.pendingRequests.length,
                const Color(0xFFF57F17),
              ),
              const SizedBox(width: 9),
              _summary(
                'Active',
                _vm.activeRequests.length,
                const Color(0xFF1565C0),
              ),
              const SizedBox(width: 9),
              _summary(
                'Complete',
                _vm.requests
                    .where((r) => r.status == RequestStatus.completed)
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
                for (final status in RequestStatus.values)
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

  Widget _filterChip(String label, RequestStatus? status) {
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

  Widget _requestCard(BuildContext context, CounsellingRequest r) => Container(
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
                    '${r.gradeLevel} • ${r.studentCount} students',
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
        _line(Icons.person_rounded, 'Requested counsellor', r.counsellorName),
        _line(Icons.topic_rounded, 'Topic', r.topic),
        _line(r.sessionMode.icon, 'Mode', r.sessionMode.label),
        _line(
          Icons.calendar_month_rounded,
          'Preferred date',
          _date(r.preferredDate),
        ),
        if (r.assignedVolunteers.isNotEmpty)
          _line(
            Icons.volunteer_activism_rounded,
            'Student support',
            r.assignedVolunteers.join(', '),
          ),
        if (r.eventManagerNotes.isNotEmpty)
          _line(Icons.notes_rounded, 'Manager note', r.eventManagerNotes),
        const Divider(height: 22),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            OutlinedButton.icon(
              onPressed: () => _recommend(context, r),
              icon: const Icon(Icons.recommend_rounded, size: 17),
              label: const Text('Recommend'),
            ),
            OutlinedButton.icon(
              onPressed: () => _assignVolunteers(context, r),
              icon: const Icon(Icons.group_add_rounded, size: 17),
              label: const Text('Volunteers'),
            ),
            if (r.status == RequestStatus.pending)
              FilledButton(
                onPressed: () => _vm.updateRequestStatus(
                  r.id,
                  RequestStatus.reviewed,
                  notes: 'Request reviewed by Event Manager.',
                ),
                child: const Text('Start Review'),
              ),
            if (r.status == RequestStatus.reviewed ||
                r.status == RequestStatus.assigned)
              FilledButton.icon(
                onPressed: () => _vm.updateRequestStatus(
                  r.id,
                  RequestStatus.confirmed,
                  notes: 'Counsellor and school schedule confirmed.',
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 17),
                label: const Text('Confirm'),
              ),
            if (r.status == RequestStatus.confirmed)
              FilledButton.icon(
                onPressed: () => _complete(context, r),
                icon: const Icon(Icons.task_alt_rounded, size: 17),
                label: const Text('Complete'),
              ),
            if (r.status == RequestStatus.completed) ...[
              OutlinedButton.icon(
                onPressed: () => _report(context, r),
                icon: const Icon(Icons.description_rounded, size: 17),
                label: const Text('Session Report'),
              ),
              FilledButton.icon(
                onPressed: () => _impact(context, r),
                icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                label: const Text('Wall of Impact'),
              ),
            ],
          ],
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

  Widget _status(RequestStatus status) => Container(
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

  Future<void> _recommend(
    BuildContext context,
    CounsellingRequest request,
  ) async {
    final selected = await showDialog<CounsellorProfile>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Recommend verified counsellor'),
        children: _vm.allCounsellors
            .map(
              (c) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, c),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(c.category.icon, color: c.category.color),
                  title: Text(c.name),
                  subtitle: Text('${c.category.label}\n${c.sessionMode.label}'),
                ),
              ),
            )
            .toList(),
      ),
    );
    if (selected != null) _vm.assignCounsellor(request.id, selected);
  }

  Future<void> _assignVolunteers(
    BuildContext context,
    CounsellingRequest request,
  ) async {
    final controller = TextEditingController(
      text: request.assignedVolunteers.join(', '),
    );
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Assign student volunteers'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Names, comma separated',
            helperText: 'For registration, logistics and session support',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) {
      _vm.updateRequestStatus(
        request.id,
        request.status == RequestStatus.pending
            ? RequestStatus.reviewed
            : request.status,
        volunteers: result
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        notes: request.eventManagerNotes,
      );
    }
  }

  void _complete(BuildContext context, CounsellingRequest r) {
    _vm.updateRequestStatus(
      r.id,
      RequestStatus.completed,
      notes: 'Session completed. Report and impact-post workflow unlocked.',
      volunteers: r.assignedVolunteers,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Session completed. You can now generate its school report and Wall of Impact post.',
        ),
      ),
    );
  }

  void _report(BuildContext context, CounsellingRequest r) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('School Session Report'),
      content: Text(
        '${r.schoolName}\nTopic: ${r.topic}\nCounsellor: ${r.counsellorName}\nStudents guided: ${r.studentCount}\nMode: ${r.sessionMode.label}\nStatus: Completed',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    ),
  );

  void _impact(
    BuildContext context,
    CounsellingRequest r,
  ) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Draft Wall of Impact post created for ${r.schoolName}; ready for admin approval.',
      ),
      backgroundColor: const Color(0xFF6A1B9A),
    ),
  );

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
