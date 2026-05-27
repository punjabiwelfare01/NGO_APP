import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../../core/colors.dart';
import '../../../models/api_models.dart';
import '../../../models/counselling_models.dart';
import '../../../repositories/wellness_repository.dart';
import '../../../widgets/app_card.dart';

class SlotBookingScreen extends StatefulWidget {
  const SlotBookingScreen({required this.slot, this.mentor, super.key});

  final ApiCounsellingSlot slot;
  final MentorProfile? mentor;

  @override
  State<SlotBookingScreen> createState() => _SlotBookingScreenState();
}

class _SlotBookingScreenState extends State<SlotBookingScreen> {
  final _topicController = TextEditingController();
  bool _loading = false;
  ApiCounsellingSession? _booked;
  String? _error;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      setState(() => _error = 'Please enter a topic for your session.');
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
      setState(() {
        _booked = session;
        _loading = false;
      });
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Book Session',
            style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SlotSummaryCard(slot: widget.slot, mentor: widget.mentor),
          const SizedBox(height: 20),
          if (_booked == null) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Session Topic',
                      style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _topicController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'What would you like to discuss?',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    Text(_error!,
                        style: const TextStyle(color: AppColors.softRed)),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _confirm,
                      icon: const Icon(Icons.event_available_rounded),
                      label: Text(_loading ? 'Confirming...' : 'Confirm Booking'),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            _BookingConfirmation(session: _booked!),
        ],
      ),
    );
  }
}

class _SlotSummaryCard extends StatelessWidget {
  const _SlotSummaryCard({required this.slot, this.mentor});

  final ApiCounsellingSlot slot;
  final MentorProfile? mentor;

  @override
  Widget build(BuildContext context) {
    final mentorName = mentor?.displayName ?? slot.mentorName;
    return AppCard(
      color: AppColors.lavender.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Session Details',
              style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.person_rounded, label: 'Mentor', value: mentorName),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.schedule_rounded, label: 'Time', value: slot.formattedTime),
          if (slot.topic != null) ...[
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.label_rounded, label: 'Topic', value: slot.topic!),
          ],
          const SizedBox(height: 8),
          _InfoRow(
              icon: Icons.people_rounded,
              label: 'Spots',
              value: '${slot.availableCount} available'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}

class _BookingConfirmation extends StatelessWidget {
  const _BookingConfirmation({required this.session});

  final ApiCounsellingSession session;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.secondary.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.secondary),
              SizedBox(width: 10),
              Text('Booking Confirmed!',
                  style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          Text('With ${session.counsellorName}',
              style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(session.formattedTime,
              style: const TextStyle(color: AppColors.muted)),
          if (session.hasMeetingLink) ...[
            const SizedBox(height: 12),
            const Text('Join link will appear here before the session.',
                style: TextStyle(color: AppColors.muted, fontSize: 13)),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Back to Home'),
            ),
          ),
        ],
      ),
    );
  }
}
