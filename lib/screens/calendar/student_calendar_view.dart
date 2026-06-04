import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/calendar_item.dart';
import '../../repositories/calendar_repository.dart';

enum _CalendarFilter { all, classes, events, counselling, reminders }

class StudentCalendarView extends StatefulWidget {
  const StudentCalendarView({super.key});

  @override
  State<StudentCalendarView> createState() => _StudentCalendarViewState();
}

class _StudentCalendarViewState extends State<StudentCalendarView> {
  List<CalendarItem> _items = [];
  bool _loading = true;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  _CalendarFilter _filter = _CalendarFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await CalendarRepository.getMyCalendar();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load calendar.';
        _loading = false;
      });
    }
  }

  List<CalendarItem> get _filteredItems {
    final today = _startOfDay(DateTime.now());
    return _items
        .where(
          (item) =>
              item.startsAt.isAfter(today) || _isSameDay(item.startsAt, today),
        )
        .where(
          (item) => switch (_filter) {
            _CalendarFilter.all => true,
            _CalendarFilter.classes => item.type == CalendarItemType.classItem,
            _CalendarFilter.events =>
              item.type == CalendarItemType.event ||
                  item.type == CalendarItemType.quiz ||
                  item.type == CalendarItemType.workshop,
            _CalendarFilter.counselling =>
              item.type == CalendarItemType.counselling,
            _CalendarFilter.reminders => item.type == CalendarItemType.reminder,
          },
        )
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  List<CalendarItem> get _reminders =>
      _items.where((item) => item.type == CalendarItemType.reminder).toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  Future<void> _openMeet(CalendarItem item) async {
    final url = item.actionUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri);
    }
  }

  void _openItem(CalendarItem item) {
    if (item.type == CalendarItemType.counselling && item.hasActionUrl) {
      _openMeet(item);
      return;
    }
    if (item.type == CalendarItemType.event ||
        item.type == CalendarItemType.quiz ||
        item.type == CalendarItemType.workshop) {
      Navigator.of(context).pushNamed('/event/${item.sourceId}');
    }
  }

  Future<void> _toggleReminder(CalendarItem item, bool value) async {
    try {
      await CalendarRepository.updateReminder(item.sourceId, isDone: value);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update reminder.')),
      );
    }
  }

  Future<void> _openAddReminder() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddReminderSheet(),
    );
    if (created == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.muted)),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final upcoming = _filteredItems;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
        children: [
          _CalendarHeader(onRefresh: _load),
          const SizedBox(height: 18),
          _WeekCalendarCard(
            selectedDate: _selectedDate,
            items: _items,
            onSelectDate: (date) => setState(() => _selectedDate = date),
          ),
          const SizedBox(height: 18),
          _FilterBar(
            selected: _filter,
            onChanged: (filter) => setState(() => _filter = filter),
          ),
          const SizedBox(height: 20),
          _SectionHeading(
            title: 'Upcoming',
            actionLabel: 'View All',
            onAction: () => setState(() => _filter = _CalendarFilter.all),
          ),
          const SizedBox(height: 10),
          if (upcoming.isEmpty)
            const _EmptyCalendarCard()
          else
            ...upcoming
                .take(6)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ScheduleCard(
                      item: item,
                      onTap: () => _openItem(item),
                      onOpenMeet: item.hasActionUrl
                          ? () => _openMeet(item)
                          : null,
                    ),
                  ),
                ),
          const SizedBox(height: 6),
          _RemindersPanel(
            reminders: _reminders.take(3).toList(),
            onAdd: _openAddReminder,
            onToggle: _toggleReminder,
          ),
        ],
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (Navigator.canPop(context)) ...[
          _CircleButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
        ],
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calendar',
                style: TextStyle(
                  color: Color(0xFF08164A),
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Your schedule & activities',
                style: TextStyle(
                  color: Color(0xFF4A587C),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _CircleButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          badge: 3,
          onTap: onRefresh,
        ),
        const SizedBox(width: 10),
        _AvatarBadge(name: AppState.studentName ?? 'Student'),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8ECF4)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF08164A).withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: const Color(0xFF08164A), size: 28),
            ),
            if (badge != null && badge! > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(
            color: Color(0xFFE9F4FF),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _initials(name),
              style: const TextStyle(
                color: Color(0xFF08164A),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 4,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: const Color(0xFF18B86D),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekCalendarCard extends StatelessWidget {
  const _WeekCalendarCard({
    required this.selectedDate,
    required this.items,
    required this.onSelectDate,
  });

  final DateTime selectedDate;
  final List<CalendarItem> items;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final dates = _weekDates(selectedDate);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8ECF4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF08164A).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_monthName(selectedDate.month)} ${selectedDate.year}',
                  style: const TextStyle(
                    color: Color(0xFF08164A),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF08164A)),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.calendar_month_outlined, size: 19),
                label: const Text('Month'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF08164A),
                  side: const BorderSide(color: Color(0xFFDDE6F4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: dates
                .map(
                  (date) => Expanded(
                    child: _DayCell(
                      date: date,
                      selected: _isSameDay(date, selectedDate),
                      dots: _dotsForDate(date, items),
                      onTap: () => onSelectDate(date),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.selected,
    required this.dots,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final List<Color> dots;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _weekdayShort(date.weekday),
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF3F4D70),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${date.day}',
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF08164A),
            fontSize: selected ? 25 : 20,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: dots.take(2).map((color) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            );
          }).toList(),
        ),
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 96,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: selected
            ? BoxDecoration(
                color: const Color(0xFF126BFF),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF126BFF).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              )
            : null,
        child: child,
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final _CalendarFilter selected;
  final ValueChanged<_CalendarFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = [
      _FilterSpec(
        _CalendarFilter.all,
        'All',
        Icons.grid_view_rounded,
        const Color(0xFF126BFF),
      ),
      _FilterSpec(
        _CalendarFilter.classes,
        'Classes',
        Icons.school_rounded,
        const Color(0xFF18B86D),
      ),
      _FilterSpec(
        _CalendarFilter.events,
        'Events',
        Icons.event_available_rounded,
        const Color(0xFFFF7A00),
      ),
      _FilterSpec(
        _CalendarFilter.counselling,
        'Counselling',
        Icons.chat_bubble_rounded,
        const Color(0xFF8B5CF6),
      ),
      _FilterSpec(
        _CalendarFilter.reminders,
        'Reminders',
        Icons.notifications_none_rounded,
        const Color(0xFFFF9800),
      ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips
            .map(
              (chip) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _FilterChipButton(
                  spec: chip,
                  selected: selected == chip.filter,
                  onTap: () => onChanged(chip.filter),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _FilterSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? spec.color.withValues(alpha: 0.12)
              : spec.color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? spec.color.withValues(alpha: 0.55)
                : spec.color.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: [
            Icon(spec.icon, color: spec.color, size: 21),
            const SizedBox(width: 8),
            Text(
              spec.label,
              style: const TextStyle(
                color: Color(0xFF08164A),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSpec {
  const _FilterSpec(this.filter, this.label, this.icon, this.color);
  final _CalendarFilter filter;
  final String label;
  final IconData icon;
  final Color color;
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF08164A),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onAction,
          label: Text(actionLabel),
          icon: const Icon(Icons.chevron_right_rounded),
          iconAlignment: IconAlignment.end,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF126BFF),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.item,
    required this.onTap,
    this.onOpenMeet,
  });

  final CalendarItem item;
  final VoidCallback onTap;
  final VoidCallback? onOpenMeet;

  @override
  Widget build(BuildContext context) {
    final meta = _itemMeta(item);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 0, 14, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8ECF4)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF08164A).withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: meta.color,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(18),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(meta.icon, color: meta.color, size: 34),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF08164A),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (item.subtitle != null &&
                          item.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF263862),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            _isSameDay(item.startsAt, DateTime.now())
                                ? Icons.schedule_rounded
                                : Icons.calendar_today_outlined,
                            color: const Color(0xFF4A587C),
                            size: 17,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _dateTimeLabel(item),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF4A587C),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (onOpenMeet != null)
                OutlinedButton.icon(
                  onPressed: onOpenMeet,
                  icon: const Icon(Icons.video_camera_front_rounded, size: 18),
                  label: const Text('Google Meet'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF126BFF),
                    side: const BorderSide(color: Color(0xFFCFE3FF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else
                _StatusPill(item: item, color: meta.color),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.item, required this.color});

  final CalendarItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = _relativeLabel(item.startsAt);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RemindersPanel extends StatelessWidget {
  const _RemindersPanel({
    required this.reminders,
    required this.onAdd,
    required this.onToggle,
  });

  final List<CalendarItem> reminders;
  final VoidCallback onAdd;
  final void Function(CalendarItem item, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCFE3FF)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Reminders',
                  style: TextStyle(
                    color: Color(0xFF08164A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_rounded),
                label: const Text('Add Reminder'),
                iconAlignment: IconAlignment.end,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF126BFF),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (reminders.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'No reminders yet.',
                style: TextStyle(
                  color: Color(0xFF4A587C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...reminders.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF126BFF).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF126BFF),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF08164A),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _dateTimeLabel(item),
                            style: const TextStyle(
                              color: Color(0xFF4A587C),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: item.isDone,
                      activeThumbColor: const Color(0xFF126BFF),
                      onChanged: (value) => onToggle(item, value),
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

class _EmptyCalendarCard extends StatelessWidget {
  const _EmptyCalendarCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF4)),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_busy_rounded, color: AppColors.muted, size: 38),
          SizedBox(height: 10),
          Text(
            'No scheduled items for this filter.',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet();

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 16, minute: 0);
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  DateTime get _scheduledAt =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await CalendarRepository.createReminder(
        title: _titleCtrl.text.trim(),
        scheduledAt: _scheduledAt,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create reminder.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6DCEA),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Add Reminder',
                style: TextStyle(
                  color: Color(0xFF08164A),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Reminder title',
                  prefixIcon: const Icon(Icons.notifications_none_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF7FAFF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a reminder title'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(_dateOnlyLabel(_date)),
                      style: _sheetButtonStyle(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _pickTime,
                      icon: const Icon(Icons.schedule_rounded),
                      label: Text(
                        _timeLabelFromParts(_time.hour, _time.minute),
                      ),
                      style: _sheetButtonStyle(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF126BFF),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Reminder',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _sheetButtonStyle() => OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF08164A),
    side: const BorderSide(color: Color(0xFFDDE6F4)),
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}

class _ItemMeta {
  const _ItemMeta(this.icon, this.color);
  final IconData icon;
  final Color color;
}

_ItemMeta _itemMeta(CalendarItem item) {
  final color = item.colorHex == null ? null : _colorFromHex(item.colorHex!);
  return switch (item.type) {
    CalendarItemType.classItem => _ItemMeta(
      Icons.school_rounded,
      color ?? const Color(0xFF126BFF),
    ),
    CalendarItemType.quiz => _ItemMeta(
      Icons.emoji_events_rounded,
      color ?? const Color(0xFFFF7A00),
    ),
    CalendarItemType.workshop => _ItemMeta(
      Icons.event_available_rounded,
      color ?? const Color(0xFF18B86D),
    ),
    CalendarItemType.counselling => _ItemMeta(
      Icons.videocam_rounded,
      color ?? const Color(0xFF8B5CF6),
    ),
    CalendarItemType.reminder => _ItemMeta(
      Icons.notifications_none_rounded,
      color ?? const Color(0xFFFF9800),
    ),
    CalendarItemType.event => _ItemMeta(
      Icons.calendar_month_rounded,
      color ?? const Color(0xFF126BFF),
    ),
  };
}

Color _colorFromHex(String hex) {
  final normalized = hex.replaceFirst('#', '');
  if (normalized.length != 6) return const Color(0xFF126BFF);
  return Color(int.parse('0xFF$normalized'));
}

List<Color> _dotsForDate(DateTime date, List<CalendarItem> items) {
  final colors = <Color>[];
  for (final item in items) {
    if (_isSameDay(item.startsAt, date)) {
      colors.add(_itemMeta(item).color);
    }
  }
  return colors;
}

List<DateTime> _weekDates(DateTime selected) {
  final start = _startOfDay(
    selected,
  ).subtract(Duration(days: selected.weekday % 7));
  return List.generate(7, (index) => start.add(Duration(days: index)));
}

DateTime _startOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _dateTimeLabel(CalendarItem item) {
  final time = _timeRange(item.startsAt, item.endsAt);
  if (_isSameDay(item.startsAt, DateTime.now())) return time;
  return '${_dateOnlyLabel(item.startsAt)} - $time';
}

String _timeRange(DateTime start, DateTime? end) {
  final startText = _timeLabel(start);
  if (end == null) return startText;
  return '$startText - ${_timeLabel(end)}';
}

String _timeLabel(DateTime date) => _timeLabelFromParts(date.hour, date.minute);

String _timeLabelFromParts(int hour, int minute) {
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  final displayMinute = minute.toString().padLeft(2, '0');
  final suffix = hour < 12 ? 'AM' : 'PM';
  return '$displayHour:$displayMinute $suffix';
}

String _dateOnlyLabel(DateTime date) =>
    '${_monthName(date.month)} ${date.day}, ${date.year}';

String _relativeLabel(DateTime date) {
  final today = _startOfDay(DateTime.now());
  final target = _startOfDay(date);
  if (target == today) return 'Today';
  if (target == today.add(const Duration(days: 1))) return 'Tomorrow';
  return 'Upcoming';
}

String _monthName(int month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return months[month - 1];
}

String _weekdayShort(int weekday) {
  const names = {
    DateTime.monday: 'Mon',
    DateTime.tuesday: 'Tue',
    DateTime.wednesday: 'Wed',
    DateTime.thursday: 'Thu',
    DateTime.friday: 'Fri',
    DateTime.saturday: 'Sat',
    DateTime.sunday: 'Sun',
  };
  return names[weekday]!;
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'S';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}
