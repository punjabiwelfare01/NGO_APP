import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../../core/colors.dart';
import '../../../models/api_models.dart';
import '../../../repositories/wellness_repository.dart';
import '../../../viewmodels/view_state.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/top_header.dart';

class MentorScheduleScreen extends StatefulWidget {
  const MentorScheduleScreen({super.key});

  @override
  State<MentorScheduleScreen> createState() => _MentorScheduleScreenState();
}

class _MentorScheduleScreenState extends State<MentorScheduleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  ViewState _state = ViewState.loading;
  List<ApiCounsellingSlot> _slots = [];
  List<ApiCounsellingSession> _sessions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _state = ViewState.loading;
      _error = null;
    });
    try {
      final results = await Future.wait([
        WellnessRepository.getMentorSlots(AppState.userId),
        WellnessRepository.getMentorSessions(AppState.userId),
      ]);
      if (!mounted) return;
      setState(() {
        _slots = results[0] as List<ApiCounsellingSlot>;
        _sessions = results[1] as List<ApiCounsellingSession>;
        _state = ViewState.idle;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = ViewState.error;
        _error = 'Could not load your schedule.';
      });
    }
  }

  void _openCreateSheet() {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CreateSlotSheet(
        onCreated: () {
          _load();
          messenger.showSnackBar(
            const SnackBar(content: Text('Slot created! Students can now book it.')),
          );
        },
      ),
    );
  }

  Future<void> _deleteSlot(ApiCounsellingSlot slot) async {
    final messenger = ScaffoldMessenger.of(context);
    final action = slot.bookedCount == 0 ? 'Delete' : 'Deactivate';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Slot?'),
        content: Text(
          slot.bookedCount == 0
              ? 'This slot has no bookings and will be permanently deleted.'
              : 'This slot has ${slot.bookedCount} booking(s). It will be deactivated — existing bookings are kept.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.softRed),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await WellnessRepository.deleteAvailabilitySlot(AppState.userId, slot.id);
      await _load();
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Failed to remove slot.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Session Slot'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const TopHeader(
              title: 'My Schedule',
              subtitle: 'Create slots and track student bookings',
              actionIcon: Icons.calendar_month_rounded,
            ),
            if (_state == ViewState.loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_state == ViewState.error)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error ?? 'Error',
                          style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else ...[
              Container(
                margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabs,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.ink,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: 'My Slots (${_slots.length})'),
                    Tab(text: 'Bookings (${_sessions.length})'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _SlotsTab(
                        slots: _slots,
                        onDelete: _deleteSlot,
                        onRefresh: _load),
                    _SessionsTab(sessions: _sessions, onRefresh: _load),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Slots Tab ──────────────────────────────────────────────────────────────────

class _SlotsTab extends StatelessWidget {
  const _SlotsTab(
      {required this.slots,
      required this.onDelete,
      required this.onRefresh});

  final List<ApiCounsellingSlot> slots;
  final void Function(ApiCounsellingSlot) onDelete;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_rounded,
                size: 56, color: AppColors.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text('No slots yet.',
                style: TextStyle(color: AppColors.muted, fontSize: 15)),
            const SizedBox(height: 6),
            const Text('Tap + New Session Slot to create one.',
                style: TextStyle(color: AppColors.muted, fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: slots.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) =>
            _SlotCard(slot: slots[i], onDelete: () => onDelete(slots[i])),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.slot, required this.onDelete});

  final ApiCounsellingSlot slot;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isFull = slot.bookedCount >= slot.capacity;
    final statusColor = !slot.isActive
        ? AppColors.muted
        : isFull
            ? AppColors.accent
            : AppColors.secondary;
    final statusLabel = !slot.isActive
        ? 'Inactive'
        : isFull
            ? 'Full'
            : 'Open';

    return AppCard(
      padding: const EdgeInsets.all(16),
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
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.topic ?? 'Open Counselling',
                      style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 13, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Text(slot.formattedTime,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.softRed, size: 22),
                tooltip: slot.bookedCount == 0 ? 'Delete slot' : 'Deactivate slot',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                icon: Icons.people_rounded,
                label: '${slot.bookedCount}/${slot.capacity} booked',
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.circle,
                label: statusLabel,
                color: statusColor,
              ),
              if (slot.hasMeetingLink) ...[
                const SizedBox(width: 8),
                const _InfoChip(
                  icon: Icons.videocam_rounded,
                  label: 'Meet link',
                  color: AppColors.secondary,
                ),
              ],
            ],
          ),
          if (slot.hasMeetingLink) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.link_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    slot.meetingUrl!,
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Sessions Tab ───────────────────────────────────────────────────────────────

class _SessionsTab extends StatelessWidget {
  const _SessionsTab(
      {required this.sessions, required this.onRefresh});

  final List<ApiCounsellingSession> sessions;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 56, color: AppColors.secondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text('No bookings yet.',
                style: TextStyle(color: AppColors.muted, fontSize: 15)),
            const SizedBox(height: 6),
            const Text('Students will appear here after booking your slots.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: sessions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _SessionCard(session: sessions[i]),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final ApiCounsellingSession session;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (session.status) {
      'upcoming' => AppColors.primary,
      'completed' => AppColors.secondary,
      _ => AppColors.muted,
    };
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                child: const Icon(Icons.person_rounded,
                    color: AppColors.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.topic,
                      style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                    Text(
                      session.formattedTime,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  session.status,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (session.hasMeetingLink) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.videocam_rounded,
                    size: 14, color: AppColors.secondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    session.meetingUrl!,
                    style: const TextStyle(
                        color: AppColors.secondary, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Create Slot Bottom Sheet ───────────────────────────────────────────────────

class _CreateSlotSheet extends StatefulWidget {
  const _CreateSlotSheet({required this.onCreated});

  final VoidCallback onCreated;

  @override
  State<_CreateSlotSheet> createState() => _CreateSlotSheetState();
}

class _CreateSlotSheetState extends State<_CreateSlotSheet> {
  final _formKey = GlobalKey<FormState>();
  final _topic = TextEditingController();
  final _meetingUrl = TextEditingController();

  DateTime _date = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _time = TimeOfDay.fromDateTime(
      DateTime.now().add(const Duration(hours: 1)));
  int _durationMinutes = 45;
  int _capacity = 1;
  bool _saving = false;
  String? _error;

  static const _durations = [30, 45, 60, 90];

  @override
  void dispose() {
    _topic.dispose();
    _meetingUrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  DateTime get _startsAt => DateTime(
      _date.year, _date.month, _date.day, _time.hour, _time.minute);

  DateTime get _endsAt =>
      _startsAt.add(Duration(minutes: _durationMinutes));

  String _formatDateTime() {
    final h = _time.hourOfPeriod == 0 ? 12 : _time.hourOfPeriod;
    final m = _time.minute.toString().padLeft(2, '0');
    final period = _time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${_date.day}/${_date.month}/${_date.year}  $h:$m $period';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_startsAt.isBefore(DateTime.now())) {
      setState(() => _error = 'Please choose a future date and time.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await WellnessRepository.createAvailabilitySlot(
        AppState.userId,
        startsAt: _startsAt,
        endsAt: _endsAt,
        topic: _topic.text.trim().isEmpty ? null : _topic.text.trim(),
        capacity: _capacity,
        meetingUrl: _meetingUrl.text.trim().isEmpty
            ? null
            : _meetingUrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCreated();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not create slot. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: const [
                  Icon(Icons.event_available_rounded,
                      color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Create Session Slot',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Topic
              TextFormField(
                controller: _topic,
                decoration: const InputDecoration(
                  labelText: 'Session Topic (optional)',
                  hintText: 'e.g. Career Guidance, Mental Wellness',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_rounded),
                ),
              ),
              const SizedBox(height: 14),

              // Date + Time row
              const Text('Date & Time',
                  style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(
                          '${_date.day}/${_date.month}/${_date.year}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time_rounded, size: 16),
                      label: Text(_formatDateTime().split('  ').last),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Duration
              const Text('Duration',
                  style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _durations.map((d) {
                  final selected = _durationMinutes == d;
                  return ChoiceChip(
                    label: Text('${d}m'),
                    selected: selected,
                    onSelected: (_) => setState(() => _durationMinutes = d),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: selected ? AppColors.primary : AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Capacity
              const Text('Capacity (max students)',
                  style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.outlined(
                    onPressed: _capacity > 1
                        ? () => setState(() => _capacity--)
                        : null,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '$_capacity',
                      style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton.outlined(
                    onPressed: _capacity < 10
                        ? () => setState(() => _capacity++)
                        : null,
                    icon: const Icon(Icons.add_rounded),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _capacity == 1 ? 'student' : 'students',
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Meeting URL (optional)
              TextFormField(
                controller: _meetingUrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Meeting URL (optional)',
                  hintText: 'https://meet.google.com/...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.videocam_rounded),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: const TextStyle(
                        color: AppColors.softRed, fontSize: 13)),
              ],
              const SizedBox(height: 20),

              // Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Session: ${_topic.text.trim().isEmpty ? 'Open Counselling' : _topic.text.trim()}\n'
                  '${_formatDateTime()}  ·  ${_durationMinutes}min  ·  up to $_capacity student${_capacity > 1 ? 's' : ''}',
                  style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.5),
                ),
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded),
                  label: Text(_saving ? 'Creating...' : 'Create Slot'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
