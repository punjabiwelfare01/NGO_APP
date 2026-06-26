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
  final List<DateTime> _weekDays = [];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    for (var i = 0; i < 7; i++) {
      _weekDays.add(_selectedDate.add(Duration(days: i)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final vm = widget.vm;
        final daySlots = vm.slotsForDate(_selectedDate);
        final dayMeetings = vm.upcomingMeetings
            .where(
              (r) =>
                  r.effectiveDate.year == _selectedDate.year &&
                  r.effectiveDate.month == _selectedDate.month &&
                  r.effectiveDate.day == _selectedDate.day,
            )
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
                    // Confirmed meetings for this day
                    if (dayMeetings.isNotEmpty) ...[
                      _SectionLabel(
                        'Confirmed Meetings',
                        Icons.event_available_rounded,
                        const Color(0xFF1565C0),
                      ),
                      const SizedBox(height: 8),
                      ...dayMeetings.map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MeetingCard(request: m, vm: vm),
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
                    ] else if (dayMeetings.isEmpty) ...[
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
          final hasMeeting = vm.upcomingMeetings.any(
            (r) =>
                r.effectiveDate.day == d.day && r.effectiveDate.month == d.month,
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
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF1565C0).withValues(alpha: 0.3),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.videocam_rounded,
                color: Color(0xFF1565C0),
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
                      fontSize: 13,
                      color: Color(0xFF0D47A1),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$h:$m $period  ·  ${request.expectedStudents} students',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF1565C0),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
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
