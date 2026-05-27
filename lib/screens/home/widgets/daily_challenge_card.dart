import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../../../models/quiz_models.dart';
import '../../../widgets/app_card.dart';

class DailyChallengeCard extends StatelessWidget {
  const DailyChallengeCard({
    required this.challenge,
    required this.onTap,
    super.key,
  });

  final DailyChallengeModel? challenge;
  final VoidCallback? onTap;

  String _formatTime(int? seconds) {
    if (seconds == null || seconds <= 0) return 'Ended';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours hr${hours > 1 ? 's' : ''} $minutes min${minutes != 1 ? 's' : ''} left';
    }
    return '$minutes min${minutes != 1 ? 's' : ''} left';
  }

  Color _difficultyColor(String? diff) {
    switch (diff?.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (challenge == null) {
      return const AppCard(
        color: Color(0xFFFFF8EC),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.quiz_outlined, color: AppColors.muted),
              SizedBox(width: 12),
              Text(
                'No daily challenge is active today.',
                style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    final bool completed = challenge!.completed;
    final String title = challenge!.title ?? 'Daily Challenge';
    final String difficulty = challenge!.difficulty ?? 'medium';
    final int xp = challenge!.xpReward ?? 100;
    final int participants = challenge!.participantsCount ?? 0;
    final int? remaining = challenge!.timeRemainingSeconds;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: const Color(0xFFFFECE0),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFECE0).withValues(alpha: 0.8),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  completed ? Icons.check_circle_rounded : Icons.local_fire_department_rounded,
                  color: completed ? Colors.green : const Color(0xFFFF6B4A),
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'DAILY CHALLENGE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFF6B4A).withValues(alpha: 0.8),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (completed)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'COMPLETED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.green,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Live Stats Row
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _StatBadge(
                          icon: Icons.flash_on_rounded,
                          label: '+$xp XP',
                          color: const Color(0xFFFF9F1C),
                        ),
                        _StatBadge(
                          icon: Icons.star_rounded,
                          label: difficulty.toUpperCase(),
                          color: _difficultyColor(difficulty),
                        ),
                        if (participants > 0)
                          _StatBadge(
                            icon: Icons.people_rounded,
                            label: '$participants joined',
                            color: AppColors.primary,
                          ),
                        if (remaining != null && remaining > 0 && !completed)
                          _StatBadge(
                            icon: Icons.timer_rounded,
                            label: _formatTime(remaining),
                            color: Colors.redAccent,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: AppColors.ink.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
