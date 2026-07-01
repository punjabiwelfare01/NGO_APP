import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/counsellor_models.dart';
import '../../models/counsellor_session_models.dart';
import '../../viewmodels/counsellor_home_viewmodel.dart';
import 'counsellor_meeting_detail_screen.dart';

class CounsellorScheduleView extends StatefulWidget {
  const CounsellorScheduleView({required this.vm, super.key});
  final CounsellorHomeViewModel vm;

  @override
  State<CounsellorScheduleView> createState() => _CounsellorScheduleViewState();
}

class _CounsellorScheduleViewState extends State<CounsellorScheduleView> {
  late DateTime _selectedDate;
  int _weekOffset = 0; // weeks offset from the current week's Monday

  // The Monday of the base week (this week).
  DateTime get _thisWeekMonday {
    final today = DateTime.now();
    final d = DateTime(today.year, today.month, today.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  List<DateTime> get _weekDays {
    final monday = _thisWeekMonday.add(Duration(days: 7 * _weekOffset));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  String get _weekLabel {
    final days = _weekDays;
    final first = days.first;
    final last = days.last;
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (first.month == last.month) {
      return '${first.day}–${last.day} ${months[first.month]} ${first.year}';
    }
    return '${first.day} ${months[first.month]} – ${last.day} ${months[last.month]} ${last.year}';
  }

  void _goWeek(int delta) {
    setState(() {
      _weekOffset += delta;
      // Keep selected date within the new week if possible; otherwise pick first day.
      final days = _weekDays;
      final stillInWeek = days.any(
        (d) => d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day,
      );
      if (!stillInWeek) _selectedDate = days.first;
    });
  }

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    // Refresh so newly accepted requests appear without restarting the app.
    widget.vm.refreshRequests().then((_) {
      if (mounted) _jumpToNearestSession();
    });
  }

  /// If today has no sessions, move the calendar to the nearest upcoming one.
  void _jumpToNearestSession() {
    final today = _selectedDate;
    final hasToday = widget.vm.calendarRequests.any(
          (r) =>
              r.effectiveDate.year == today.year &&
              r.effectiveDate.month == today.month &&
              r.effectiveDate.day == today.day,
        ) ||
        widget.vm.slotsForDate(today).isNotEmpty;
    if (hasToday) return;

    final upcoming = widget.vm.calendarRequests
        .where((r) => !r.effectiveDate.isBefore(today))
        .toList()
      ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
    if (upcoming.isEmpty) return;

    final nearest = DateTime(
      upcoming.first.effectiveDate.year,
      upcoming.first.effectiveDate.month,
      upcoming.first.effectiveDate.day,
    );
    final weeksOffset =
        nearest.difference(_thisWeekMonday).inDays ~/ 7;
    setState(() {
      _selectedDate = nearest;
      _weekOffset = weeksOffset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final vm = widget.vm;
        final daySlots = vm.slotsForDate(_selectedDate);
        // All non-declined/cancelled requests on the selected date
        final allDayRequests = vm.calendarRequests
            .where(
              (r) =>
                  r.effectiveDate.year == _selectedDate.year &&
                  r.effectiveDate.month == _selectedDate.month &&
                  r.effectiveDate.day == _selectedDate.day,
            )
            .toList();

        // Split into pending/awaiting and confirmed/scheduled
        final pendingRequests = allDayRequests
            .where(
              (r) =>
                  r.status == SchoolRequestStatus.newRequest ||
                  r.status == SchoolRequestStatus.accepted ||
                  r.status == SchoolRequestStatus.pendingConfirmation ||
                  r.status == SchoolRequestStatus.rescheduled,
            )
            .toList();
        final confirmedRequests = allDayRequests
            .where(
              (r) =>
                  r.status == SchoolRequestStatus.confirmed ||
                  r.status == SchoolRequestStatus.scheduled,
            )
            .toList();
        final completedRequests = allDayRequests
            .where((r) => r.status == SchoolRequestStatus.completed)
            .toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A1F44),
            title: const Text(
              'My Schedule',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            automaticallyImplyLeading: false,
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddSlotSheet(context, vm),
            backgroundColor: const Color(0xFF1565C0),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Add Slot',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: Column(
            children: [
              // Week navigation header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 22),
                      color: const Color(0xFF1565C0),
                      tooltip: 'Previous week',
                      onPressed: () => _goWeek(-1),
                    ),
                    Expanded(
                      child: Text(
                        _weekLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF0A1F44),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 22),
                      color: const Color(0xFF1565C0),
                      tooltip: 'Next week',
                      onPressed: () => _goWeek(1),
                    ),
                  ],
                ),
              ),
              _WeekStrip(
                days: _weekDays,
                selected: _selectedDate,
                vm: vm,
                onSelect: (d) => setState(() => _selectedDate = d),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Pending / awaiting confirmation sessions
                    if (pendingRequests.isNotEmpty) ...[
                      _SectionLabel(
                        'Pending Sessions',
                        Icons.pending_actions_rounded,
                        const Color(0xFFF57F17),
                      ),
                      const SizedBox(height: 8),
                      ...pendingRequests.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MeetingCard(request: r, vm: vm),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Confirmed / scheduled sessions
                    if (confirmedRequests.isNotEmpty) ...[
                      _SectionLabel(
                        'Confirmed Sessions',
                        Icons.event_available_rounded,
                        const Color(0xFF1565C0),
                      ),
                      const SizedBox(height: 8),
                      ...confirmedRequests.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MeetingCard(request: r, vm: vm),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Completed sessions
                    if (completedRequests.isNotEmpty) ...[
                      _SectionLabel(
                        'Completed',
                        Icons.task_alt_rounded,
                        const Color(0xFF2E7D32),
                      ),
                      const SizedBox(height: 8),
                      ...completedRequests.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MeetingCard(request: r, vm: vm),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Availability slots
                    if (daySlots.isNotEmpty) ...[
                      _SectionLabel(
                        'Availability Slots',
                        Icons.schedule_rounded,
                        const Color(0xFF2E7D32),
                      ),
                      const SizedBox(height: 8),
                      ...daySlots.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SlotCard(slot: s, vm: vm),
                        ),
                      ),
                    ] else if (allDayRequests.isEmpty) ...[
                      const SizedBox(height: 60),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 52,
                              color:
                                  AppColors.muted.withValues(alpha: 0.35),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No slots for this day',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap "Add Slot" to mark your availability',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    AppColors.muted.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Repeating slots info
                    const SizedBox(height: 24),
                    _RepeatingSection(vm: vm),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddSlotSheet(BuildContext context, CounsellorHomeViewModel vm) {
    TimeOfDay startTime = const TimeOfDay(hour: 10, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 11, minute: 0);
    SessionMode mode = SessionMode.online;
    bool repeating = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final bottom = MediaQuery.of(sheetCtx).viewInsets.bottom;
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (sheetCtx, scrollController) => Container(
              margin: const EdgeInsets.only(top: 60),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(bottom: bottom),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Add Availability Slot',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Color(0xFF17324D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(_selectedDate),
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 20),

                  // Start time
                  _TimePickerField(
                    label: 'Start Time',
                    time: startTime,
                    onPick: () async {
                      final t = await showTimePicker(
                        context: sheetCtx,
                        initialTime: startTime,
                      );
                      if (t != null) setSheetState(() => startTime = t);
                    },
                  ),
                  const SizedBox(height: 12),

                  // End time
                  _TimePickerField(
                    label: 'End Time',
                    time: endTime,
                    onPick: () async {
                      final t = await showTimePicker(
                        context: sheetCtx,
                        initialTime: endTime,
                      );
                      if (t != null) setSheetState(() => endTime = t);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Mode
                  const Text(
                    'Session Mode',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF17324D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: SessionMode.values.map((m) {
                      final selected = mode == m;
                      return ChoiceChip(
                        label: Text(_modeLabel(m)),
                        selected: selected,
                        onSelected: (_) => setSheetState(() => mode = m),
                        selectedColor: const Color(0xFF1565C0),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.ink,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Repeat
                  SwitchListTile.adaptive(
                    value: repeating,
                    onChanged: (v) => setSheetState(() => repeating = v),
                    title: const Text(
                      'Repeat Weekly',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF17324D),
                      ),
                    ),
                    subtitle: Text(
                      'Repeat every ${_dayOfWeek(_selectedDate.weekday)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    activeTrackColor: const Color(0xFF1565C0),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        vm.addSlot(
                          AvailabilitySlot(
                            id: DateTime.now().millisecondsSinceEpoch,
                            date: _selectedDate,
                            startTime: startTime,
                            endTime: endTime,
                            mode: mode,
                            isRepeating: repeating,
                            repeatDayLabel: repeating
                                ? 'Every ${_dayOfWeek(_selectedDate.weekday)}'
                                : null,
                          ),
                        );
                        Navigator.pop(sheetCtx);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Slot',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
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

// ─── Week Strip ───────────────────────────────────────────────────────────────

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.days,
    required this.selected,
    required this.vm,
    required this.onSelect,
  });

  final List<DateTime> days;
  final DateTime selected;
  final CounsellorHomeViewModel vm;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: days.map((d) {
          final isSelected = d.day == selected.day && d.month == selected.month;
          final hasSlot = vm.slotsForDate(d).isNotEmpty;
          final hasMeeting = vm.calendarRequests.any(
            (r) =>
                r.effectiveDate.year == d.year &&
                r.effectiveDate.month == d.month &&
                r.effectiveDate.day == d.day,
          );
          const dayLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1565C0)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      dayLabels[d.weekday - 1],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white70 : AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${d.day}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasMeeting)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        if (hasMeeting && hasSlot)
                          const SizedBox(width: 2),
                        if (hasSlot)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Colors.white70
                                  : const Color(0xFF2E7D32),
                            ),
                          ),
                        if (!hasMeeting && !hasSlot)
                          const SizedBox(width: 5, height: 5),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Slot Card ────────────────────────────────────────────────────────────────

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.slot, required this.vm});
  final AvailabilitySlot slot;
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: slot.displayColor, width: 4),
          top: BorderSide(color: AppColors.muted.withValues(alpha: 0.1)),
          right: BorderSide(color: AppColors.muted.withValues(alpha: 0.1)),
          bottom: BorderSide(color: AppColors.muted.withValues(alpha: 0.1)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.timeLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      slot.displayLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: slot.displayColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _modeLabel(slot.mode),
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (slot.isRepeating) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.repeat_rounded,
                        size: 13,
                        color: AppColors.muted,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => vm.toggleSlotBlock(slot.id),
            icon: Icon(
              slot.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
              size: 15,
            ),
            label: Text(slot.isBlocked ? 'Unblock' : 'Block'),
            style: TextButton.styleFrom(
              foregroundColor: slot.isBlocked
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFC62828),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Meeting Card ─────────────────────────────────────────────────────────────

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({required this.request, required this.vm});
  final SchoolBookingRequest request;
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = request.effectiveTime;
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    final status = request.status;
    final accentColor = status.color;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CounsellorMeetingDetailScreen(request: request, vm: vm),
        ),
      ),
      child: Container(
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
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: school name + status chip ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.07),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.school_rounded, size: 16, color: accentColor),
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: accentColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(status.icon, size: 11, color: accentColor),
                        const SizedBox(width: 4),
                        Text(
                          status.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Body: topic, chips, coordinator ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.topic,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      _InfoChip(
                        icon: Icons.schedule_rounded,
                        label: '$h:$m $period',
                        color: accentColor,
                      ),
                      _InfoChip(
                        icon: Icons.people_rounded,
                        label: '${request.expectedStudents} students',
                        color: accentColor,
                      ),
                      _InfoChip(
                        icon: request.mode == SessionMode.online
                            ? Icons.videocam_rounded
                            : Icons.location_on_rounded,
                        label: request.mode == SessionMode.online
                            ? 'Online'
                            : 'Offline',
                        color: accentColor,
                      ),
                      if (request.classGroup.isNotEmpty)
                        _InfoChip(
                          icon: Icons.school_rounded,
                          label: request.classGroup,
                          color: accentColor,
                        ),
                    ],
                  ),
                  if (request.coordinatorName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 13,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            request.coordinatorName,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ],
  );
}

// ─── Repeating Section ────────────────────────────────────────────────────────

class _RepeatingSection extends StatelessWidget {
  const _RepeatingSection({required this.vm});
  final CounsellorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final repeating = vm.slots.where((s) => s.isRepeating).toList();
    if (repeating.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.repeat_rounded,
                size: 16,
                color: Color(0xFF6A1B9A),
              ),
              const SizedBox(width: 8),
              Text(
                'Repeating Slots',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...repeating.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.radio_button_checked_rounded,
                    size: 12,
                    color: Color(0xFF6A1B9A),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${s.repeatDayLabel ?? ''}  ·  ${s.timeLabel}  ·  ${_modeLabel(s.mode)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.icon, this.color);
  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

// ─── Time Picker Field ────────────────────────────────────────────────────────

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
    required this.label,
    required this.time,
    required this.onPick,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.muted.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded, size: 18, color: Color(0xFF1565C0)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const Spacer(),
            Text(
              '$h:$m $period',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF17324D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _modeLabel(SessionMode mode) {
  return switch (mode) {
    SessionMode.online => 'Online',
    SessionMode.offline => 'Offline',
    SessionMode.both => 'Both',
  };
}

String _dayOfWeek(int weekday) {
  const days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  return days[weekday - 1];
}

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${_dayOfWeek(d.weekday)}, ${d.day} ${months[d.month - 1]} ${d.year}';
}
