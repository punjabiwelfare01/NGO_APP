import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/counselling_models.dart';
import '../../../widgets/app_card.dart';

class MentorCard extends StatelessWidget {
  const MentorCard({
    required this.mentor,
    this.onBook,
    this.onTap,
    super.key,
  });

  final MentorProfile mentor;
  final VoidCallback? onBook;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            _MentorAvatar(imageUrl: mentor.profileImageUrl, name: mentor.displayName),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mentor.displayName,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  if (mentor.expertise != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      mentor.expertise!,
                      style: const TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (mentor.category != null)
                        _CategoryChip(label: mentor.category!),
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.accent),
                      const SizedBox(width: 3),
                      Text(
                        mentor.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${mentor.sessionCount} sessions',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: onBook,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.ink,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

class _MentorAvatar extends StatelessWidget {
  const _MentorAvatar({required this.imageUrl, required this.name});

  final String? imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: AppColors.lavender,
      );
    }
    return CircleAvatar(
      radius: 30,
      backgroundColor: AppColors.lavender,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
