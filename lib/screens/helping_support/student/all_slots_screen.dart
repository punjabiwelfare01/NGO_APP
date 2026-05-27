import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../../core/colors.dart';
import '../../../models/api_models.dart';
import '../../../repositories/wellness_repository.dart';
import '../../../viewmodels/view_state.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/top_header.dart';
import 'slot_booking_screen.dart';

class AllSlotsScreen extends StatefulWidget {
  const AllSlotsScreen({super.key});

  @override
  State<AllSlotsScreen> createState() => _AllSlotsScreenState();
}

class _AllSlotsScreenState extends State<AllSlotsScreen> {
  ViewState _state = ViewState.loading;
  List<ApiCounsellingSlot> _slots = [];
  List<ApiCounsellingSession> _mySessions = [];
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
      final results = await Future.wait([
        WellnessRepository.getAvailableSlots(AppState.userId),
        WellnessRepository.getCounsellingSessions(AppState.userId),
      ]);
      if (!mounted) return;
      setState(() {
        _slots = results[0] as List<ApiCounsellingSlot>;
        _mySessions = results[1] as List<ApiCounsellingSession>;
        _state = ViewState.idle;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = ViewState.error;
        _error = 'Could not load available sessions.';
      });
    }
  }

  Set<int> get _bookedSlotIds =>
      _mySessions.where((s) => s.slotId != null).map((s) => s.slotId!).toSet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const TopHeader(
              title: 'Counselling Sessions',
              subtitle: 'Browse and book an available session with a mentor.',
              actionIcon: Icons.calendar_month_rounded,
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_state == ViewState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_state == ViewState.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? 'Error', style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_slots.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded, size: 56, color: AppColors.muted),
            SizedBox(height: 14),
            Text(
              'No sessions available right now.',
              style: TextStyle(color: AppColors.muted, fontSize: 15),
            ),
            SizedBox(height: 6),
            Text(
              'Check back later or contact a mentor directly.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: _slots.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _SlotCard(
          slot: _slots[i],
          alreadyBooked: _bookedSlotIds.contains(_slots[i].id),
          onBook: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SlotBookingScreen(slot: _slots[i]),
              ),
            );
            _load();
          },
        ),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.alreadyBooked,
    required this.onBook,
  });

  final ApiCounsellingSlot slot;
  final bool alreadyBooked;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final isFull = !slot.isAvailable;
    final statusColor = alreadyBooked
        ? AppColors.secondary
        : isFull
            ? AppColors.muted
            : AppColors.primary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: mentor + status chip
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: statusColor.withValues(alpha: 0.15),
                child: Icon(Icons.person_rounded, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.mentorName,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      slot.formattedTime,
                      style: const TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              _StatusChip(
                label: alreadyBooked ? 'Booked' : isFull ? 'Full' : 'Open',
                color: statusColor,
              ),
            ],
          ),

          if (slot.topic != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.label_rounded, size: 14, color: AppColors.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    slot.topic!,
                    style: const TextStyle(color: AppColors.ink, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),

          // Capacity row + join link badge
          Row(
            children: [
              const Icon(Icons.people_rounded, size: 14, color: AppColors.muted),
              const SizedBox(width: 6),
              Text(
                '${slot.availableCount} of ${slot.capacity} spot${slot.capacity == 1 ? '' : 's'} available',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              if (slot.hasMeetingLink) ...[
                const SizedBox(width: 10),
                const Icon(Icons.videocam_rounded,
                    size: 14, color: AppColors.secondary),
                const SizedBox(width: 4),
                const Text(
                  'Meet link included',
                  style: TextStyle(color: AppColors.secondary, fontSize: 12),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: alreadyBooked
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('Already Booked'),
                  )
                : isFull
                    ? OutlinedButton(
                        onPressed: null,
                        child: const Text('Session Full'),
                      )
                    : FilledButton.icon(
                        onPressed: onBook,
                        icon: const Icon(Icons.event_available_rounded, size: 16),
                        label: const Text('Book This Session'),
                      ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
