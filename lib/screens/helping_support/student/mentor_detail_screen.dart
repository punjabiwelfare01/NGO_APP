import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../../core/colors.dart';
import '../../../models/api_models.dart';
import '../../../models/counselling_models.dart';
import '../../../repositories/counselling_repository.dart';
import '../../../repositories/wellness_repository.dart';
import '../../../viewmodels/view_state.dart';
import '../../../widgets/app_card.dart';
import 'booking_success_screen.dart';

class MentorDetailScreen extends StatefulWidget {
  const MentorDetailScreen({required this.mentor, super.key});

  final MentorProfile mentor;

  @override
  State<MentorDetailScreen> createState() => _MentorDetailScreenState();
}

class _MentorDetailScreenState extends State<MentorDetailScreen> {
  ViewState _state = ViewState.loading;
  List<ApiCounsellingSlot> _slots = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _state = ViewState.loading;
      _error = null;
    });
    try {
      final slots =
          await CounsellingRepository.getMentorSlots(widget.mentor.userId);
      if (!mounted) return;
      setState(() {
        _slots = slots.where((s) => s.isAvailable).toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
        _state = ViewState.idle;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = ViewState.error;
        _error = 'Could not load slots.';
      });
    }
  }

  Map<DateTime, List<ApiCounsellingSlot>> get _slotsByDate {
    final map = <DateTime, List<ApiCounsellingSlot>>{};
    for (final slot in _slots) {
      final date = DateTime(
          slot.startsAt.year, slot.startsAt.month, slot.startsAt.day);
      map.putIfAbsent(date, () => []).add(slot);
    }
    return map;
  }

  Future<void> _openBooking(ApiCounsellingSlot slot) async {
    final session = await showModalBottomSheet<ApiCounsellingSession>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          _BookingConfirmSheet(slot: slot, mentor: widget.mentor),
    );

    if (session != null && mounted) {
      // Optimistic: remove booked slot from the local list.
      setState(() {
        _slots = _slots.where((s) => s.id != slot.id).toList();
      });
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              BookingSuccessScreen(session: session, mentor: widget.mentor),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mentor = widget.mentor;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(mentor.displayName,
            style: const TextStyle(
                color: AppColors.ink, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _MentorHeader(mentor: mentor),
            const SizedBox(height: 16),
            if (mentor.bio != null && mentor.bio!.isNotEmpty) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('About',
                        style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(mentor.bio!,
                        style: const TextStyle(
                            color: AppColors.muted, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            const Text('Available Slots',
                style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            _buildSlotSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotSection() {
    if (_state == ViewState.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_state == ViewState.error) {
      return Column(
        children: [
          Text(_error ?? 'Error',
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 12),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    }
    if (_slots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_busy_rounded, size: 48, color: AppColors.muted),
              SizedBox(height: 10),
              Text('No slots available right now.',
                  style: TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      );
    }

    final byDate = _slotsByDate;
    final sortedDates = byDate.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final date in sortedDates) ...[
          _DateHeader(date: date),
          const SizedBox(height: 8),
          ...byDate[date]!.map(
            (slot) => _SlotTile(slot: slot, onBook: () => _openBooking(slot)),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

// ─── Date Header ─────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});

  final DateTime date;

  String get _label {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    if (date == today) return 'Today';
    if (date == tomorrow) return 'Tomorrow';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_rounded,
              size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            _label,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mentor Header ────────────────────────────────────────────────────────────

class _MentorHeader extends StatelessWidget {
  const _MentorHeader({required this.mentor});

  final MentorProfile mentor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mentor.displayName,
                    style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
                if (mentor.expertise != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(mentor.expertise!,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 13)),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(mentor.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 12),
                    const Icon(Icons.people_rounded,
                        size: 16, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text('${mentor.sessionCount} sessions',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (mentor.profileImageUrl != null &&
        mentor.profileImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 36,
        backgroundImage: NetworkImage(mentor.profileImageUrl!),
        backgroundColor: AppColors.lavender,
      );
    }
    return CircleAvatar(
      radius: 36,
      backgroundColor: AppColors.lavender,
      child: Text(
        mentor.displayName.isNotEmpty
            ? mentor.displayName[0].toUpperCase()
            : '?',
        style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
            fontSize: 24),
      ),
    );
  }
}

// ─── Slot Tile ────────────────────────────────────────────────────────────────

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot, required this.onBook});

  final ApiCounsellingSlot slot;
  final VoidCallback onBook;

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${slot.startsAt.hour % 12 == 0 ? 12 : slot.startsAt.hour % 12}',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16),
                  ),
                  Text(
                    slot.startsAt.hour < 12 ? 'AM' : 'PM',
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatTime(slot.startsAt)} – ${_formatTime(slot.endsAt)}',
                    style: const TextStyle(
                        color: AppColors.ink, fontWeight: FontWeight.w700),
                  ),
                  if (slot.topic != null)
                    Text(slot.topic!,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 13)),
                  Row(
                    children: [
                      const Icon(Icons.people_rounded,
                          size: 12, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text(
                        '${slot.availableCount} of ${slot.capacity} spots',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12),
                      ),
                      if (slot.hasMeetingLink) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.videocam_rounded,
                            size: 12, color: AppColors.secondary),
                        const SizedBox(width: 3),
                        const Text('Meet',
                            style: TextStyle(
                                color: AppColors.secondary, fontSize: 11)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: onBook,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Book', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Booking Confirmation Bottom Sheet ───────────────────────────────────────

class _BookingConfirmSheet extends StatefulWidget {
  const _BookingConfirmSheet({required this.slot, required this.mentor});

  final ApiCounsellingSlot slot;
  final MentorProfile mentor;

  @override
  State<_BookingConfirmSheet> createState() => _BookingConfirmSheetState();
}

class _BookingConfirmSheetState extends State<_BookingConfirmSheet> {
  final _topicController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      setState(
          () => _error = "Please describe what you'd like to discuss.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await WellnessRepository.bookAvailabilitySlot(
        AppState.userId,
        slotId: widget.slot.id,
        topic: topic,
      );
      if (!mounted) return;
      Navigator.of(context).pop(session);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not book this slot. It may already be full.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    final mentor = widget.mentor;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Confirm Booking',
            style: TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),

          // Session summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lavender.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _InfoRow(
                    icon: Icons.person_rounded,
                    label: 'Mentor',
                    value: mentor.displayName),
                const SizedBox(height: 8),
                _InfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Time',
                    value: slot.formattedTime),
                if (slot.topic != null) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                      icon: Icons.label_rounded,
                      label: 'Topic',
                      value: slot.topic!),
                ],
                const SizedBox(height: 8),
                _InfoRow(
                    icon: Icons.people_rounded,
                    label: 'Spots left',
                    value: '${slot.availableCount} of ${slot.capacity}'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'What would you like to discuss?',
            style: TextStyle(
                color: AppColors.ink, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _topicController,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText:
                  'e.g. exam stress, career advice, personal challenges…',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(
                    color: AppColors.softRed, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _confirm,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.event_available_rounded),
              label: Text(_loading ? 'Confirming…' : 'Confirm Booking'),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.muted),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 13),
          ),
        ),
      ],
    );
  }
}
