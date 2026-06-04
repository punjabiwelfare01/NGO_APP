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
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 70,
            height: 74,
            decoration: BoxDecoration(
              color: course.color,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(course.icon, color: AppColors.ink, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
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
                  course.lessonCount > 0
                      ? '${course.duration} · ${course.level} · ${course.lessonCount} lessons'
                      : '${course.duration} · ${course.level}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
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
            ),
          ),
          const SizedBox(width: 12),
          if (onEdit != null || onDelete != null) ...[
            PopupMenuButton<String>(
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
            ),
            const SizedBox(width: 4),
          ],
          FilledButton(
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
          ),
        ],
      ),
    );
  }
}
