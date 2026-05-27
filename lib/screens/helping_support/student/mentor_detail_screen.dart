import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/api_models.dart';
import '../../../models/counselling_models.dart';
import '../../../repositories/counselling_repository.dart';
import '../../../viewmodels/view_state.dart';
import '../../../widgets/app_card.dart';
import 'chat_screen.dart';
import 'slot_booking_screen.dart';

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
      final slots = await CounsellingRepository.getMentorSlots(widget.mentor.userId);
      if (!mounted) return;
      setState(() {
        _slots = slots.where((s) => s.isAvailable).toList();
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

  @override
  Widget build(BuildContext context) {
    final mentor = widget.mentor;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(mentor.displayName,
            style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: AppColors.ink),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    otherUserId: mentor.userId,
                    otherUserName: mentor.displayName,
                  ),
                ),
              ),
              icon: const Icon(Icons.chat_rounded, size: 18),
              label: const Text('Chat'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.ink,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
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
                      style: const TextStyle(color: AppColors.muted, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          const Text('Available Slots',
              style: TextStyle(
                  color: AppColors.ink, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (_state == ViewState.loading)
            const Center(child: CircularProgressIndicator())
          else if (_state == ViewState.error)
            Text(_error ?? 'Error', style: const TextStyle(color: AppColors.muted))
          else if (_slots.isEmpty)
            const Text('No slots available right now.',
                style: TextStyle(color: AppColors.muted))
          else
            ..._slots.map((slot) => _SlotTile(slot: slot, onBook: () => _openBooking(slot))),
        ],
      ),
    );
  }

  void _openBooking(ApiCounsellingSlot slot) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SlotBookingScreen(slot: slot, mentor: widget.mentor),
      ),
    );
  }
}

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
                        style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(mentor.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            color: AppColors.ink, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 12),
                    const Icon(Icons.people_rounded, size: 16, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text('${mentor.sessionCount} sessions',
                        style: const TextStyle(color: AppColors.muted, fontSize: 13)),
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
    if (mentor.profileImageUrl != null && mentor.profileImageUrl!.isNotEmpty) {
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
        mentor.displayName.isNotEmpty ? mentor.displayName[0].toUpperCase() : '?',
        style: const TextStyle(
            color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 24),
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot, required this.onBook});

  final ApiCounsellingSlot slot;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_today_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slot.formattedTime,
                      style: const TextStyle(
                          color: AppColors.ink, fontWeight: FontWeight.w700)),
                  if (slot.topic != null)
                    Text(slot.topic!,
                        style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  Text('${slot.availableCount} of ${slot.capacity} spots left',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
            FilledButton(
              onPressed: onBook,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
