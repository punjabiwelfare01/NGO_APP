import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../../core/colors.dart';
import '../../../models/api_models.dart';
import '../../../repositories/wellness_repository.dart';
import '../../../widgets/app_card.dart';

class BookingFlowCard extends StatefulWidget {
  const BookingFlowCard({super.key});

  @override
  State<BookingFlowCard> createState() => _BookingFlowCardState();
}

class _BookingFlowCardState extends State<BookingFlowCard> {
  final _topic = TextEditingController(text: 'Counselling support');
  List<ApiCounsellingSlot> _slots = [];
  ApiCounsellingSlot? _selectedSlot;
  ApiCounsellingSession? _bookedSession;
  bool _loading = true;
  bool _booking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final slots = await WellnessRepository.getAvailableSlots(AppState.userId);
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _selectedSlot = slots.isEmpty ? null : slots.first;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load mentor availability.';
      });
    }
  }

  Future<void> _book() async {
    final slot = _selectedSlot;
    if (slot == null || _booking) return;
    setState(() => _booking = true);
    try {
      final session = await WellnessRepository.bookAvailabilitySlot(
        AppState.userId,
        slotId: slot.id,
        topic: _topic.text.trim().isEmpty
            ? slot.topic ?? 'Counselling support'
            : _topic.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _bookedSession = session;
        _booking = false;
      });
      await _loadSlots();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _booking = false;
        _error = 'Could not book this slot. Please try another time.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Book Counselling',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_slots.isEmpty)
            const Text(
              'No mentor slots are open right now.',
              style: TextStyle(color: AppColors.muted),
            )
          else ...[
            TextField(
              controller: _topic,
              decoration: const InputDecoration(
                labelText: 'Topic',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ApiCounsellingSlot>(
              initialValue: _selectedSlot,
              decoration: const InputDecoration(
                labelText: 'Available mentor slot',
                border: OutlineInputBorder(),
              ),
              items: _slots
                  .map(
                    (slot) => DropdownMenuItem(
                      value: slot,
                      child: Text('${slot.mentorName} · ${slot.formattedTime}'),
                    ),
                  )
                  .toList(),
              onChanged: (slot) => setState(() => _selectedSlot = slot),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _booking ? null : _book,
                icon: const Icon(Icons.event_available_rounded),
                label: Text(_booking ? 'Booking...' : 'Book Slot'),
              ),
            ),
          ],
          if (_bookedSession != null) ...[
            const SizedBox(height: 12),
            _SessionConfirmation(session: _bookedSession!),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.softRed)),
          ],
        ],
      ),
    );
  }
}

class _SessionConfirmation extends StatelessWidget {
  const _SessionConfirmation({required this.session});

  final ApiCounsellingSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booked with ${session.counsellorName} · ${session.formattedTime}',
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (session.hasMeetingLink) ...[
            const SizedBox(height: 6),
            Text(
              'Join link: ${session.meetingUrl}',
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class MentorCalendarCard extends StatefulWidget {
  const MentorCalendarCard({super.key});

  @override
  State<MentorCalendarCard> createState() => _MentorCalendarCardState();
}

class _MentorCalendarCardState extends State<MentorCalendarCard> {
  final _topic = TextEditingController(text: 'Open counselling');
  List<ApiCounsellingSlot> _slots = [];
  List<ApiCounsellingSession> _sessions = [];
  DateTime _startsAt = DateTime.now().add(const Duration(hours: 1));
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
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
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load mentor calendar.';
      });
    }
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (time == null) return;
    setState(() {
      _startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _createSlot() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await WellnessRepository.createAvailabilitySlot(
        AppState.userId,
        startsAt: _startsAt,
        endsAt: _startsAt.add(const Duration(minutes: 45)),
        topic: _topic.text.trim().isEmpty ? null : _topic.text.trim(),
        // meetingUrl is omitted — the backend auto-generates a Google Meet link.
      );
      if (!mounted) return;
      setState(() => _saving = false);
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not create this slot.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mentor Calendar',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _topic,
            decoration: const InputDecoration(
              labelText: 'Slot topic',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text(_formatDateTime(_startsAt))),
              IconButton.filledTonal(
                onPressed: _pickStart,
                icon: const Icon(Icons.calendar_month_rounded),
                tooltip: 'Pick time',
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _createSlot,
              icon: const Icon(Icons.add_rounded),
              label: Text(_saving ? 'Saving...' : 'Add Slot'),
            ),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            Text(
              '${_slots.length} slots · ${_sessions.length} bookings',
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ..._sessions.take(3).map(
                  (session) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${session.topic} · ${session.formattedTime}',
                          style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w600),
                        ),
                        if (session.meetingUrl != null)
                          Row(
                            children: [
                              const Icon(Icons.videocam_rounded,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  session.meetingUrl!,
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.softRed)),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final h = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final m = value.minute.toString().padLeft(2, '0');
    final ampm = value.hour < 12 ? 'AM' : 'PM';
    return '${value.day}/${value.month}/${value.year}, $h:$m $ampm';
  }
}
