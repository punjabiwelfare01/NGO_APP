import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/course.dart';
import '../../../widgets/app_card.dart';
import '../course_detail_screen.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({
    required this.course,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final Course course;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final hasNotes =
        course.skillTags?.any(
          (tag) =>
              tag.toLowerCase().contains('note') ||
              tag.toLowerCase().contains('pdf'),
        ) ??
        true;

    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 430;
          final leading = Container(
            width: 70,
            height: 74,
            decoration: BoxDecoration(
              color: course.color,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(course.icon, color: AppColors.ink, size: 32),
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _metaLine,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _CourseBadge(
                    icon: Icons.volunteer_activism_outlined,
                    label: 'Free by NGO',
                  ),
                  const _CourseBadge(
                    icon: Icons.play_circle_outline_rounded,
                    label: 'Video',
                  ),
                  if (hasNotes)
                    const _CourseBadge(
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'Notes',
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: course.progress,
                  backgroundColor: AppColors.background,
                  color: AppColors.primary,
                ),
              ),
            ],
          );
          final manageMenu = onEdit != null || onDelete != null
              ? PopupMenuButton<String>(
                  tooltip: 'Manage course',
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (_) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.softRed,
                            ),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                  ],
                )
              : null;
          final action = FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CourseDetailScreen(course: course),
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              course.progress > 0 ? 'Continue' : 'Start',
              style: const TextStyle(fontSize: 13),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    leading,
                    const SizedBox(width: 12),
                    Expanded(child: details),
                    ?manageMenu,
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: action),
              ],
            );
          }

          return Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(child: details),
              const SizedBox(width: 12),
              if (manageMenu != null) ...[manageMenu, const SizedBox(width: 4)],
              action,
            ],
          );
        },
      ),
    );
  }

  String get _metaLine {
    final lessonLabel = course.lessonCount > 0
        ? ' · ${course.lessonCount} lessons'
        : '';
    return '${course.duration} · ${course.level}$lessonLabel · Videos + Notes + Quiz';
  }
}

class _CourseBadge extends StatelessWidget {
  const _CourseBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
