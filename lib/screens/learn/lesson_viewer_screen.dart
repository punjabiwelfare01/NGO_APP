import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/lesson.dart';
import '../../repositories/api_client.dart';
import '../../repositories/course_repository.dart';
import '../../utils/platform_video.dart';

class LessonViewerScreen extends StatefulWidget {
  const LessonViewerScreen({
    required this.lesson,
    required this.courseId,
    super.key,
  });

  final Lesson lesson;
  final int courseId;

  @override
  State<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends State<LessonViewerScreen> {
  late bool _completed;
  bool _marking = false;

  @override
  void initState() {
    super.initState();
    _completed = widget.lesson.completed;
  }

  Future<void> _markComplete() async {
    setState(() => _marking = true);
    try {
      await CourseRepository.markLessonComplete(
        widget.courseId,
        widget.lesson.id,
      );
      if (mounted) {
        setState(() {
          _completed = true;
          _marking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lesson completed!'),
            backgroundColor: AppColors.secondary,
          ),
        );
        // Pop with true so CourseDetailScreen can update its local state.
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _marking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save progress. Try again.'),
            backgroundColor: AppColors.softRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Text(
          lesson.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta row
                  Row(
                    children: [
                      _Badge(
                        _contentIcon(lesson.contentType),
                        _contentLabel(lesson.contentType),
                      ),
                      if (lesson.durationLabel.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        _Badge(Icons.timer_outlined, lesson.durationLabel),
                      ],
                      if (_completed) ...[
                        const SizedBox(width: 10),
                        _Badge(
                          Icons.check_circle_rounded,
                          'Completed',
                          color: AppColors.secondary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Description
                  if (lesson.description != null &&
                      lesson.description!.isNotEmpty) ...[
                    Text(
                      lesson.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),
                  ],
                  if (lesson.contentType == 'video') ...[
                    _VideoContent(url: lesson.contentUrl),
                  ] else if (lesson.contentType == 'mixed') ...[
                    if (lesson.contentUrl != null &&
                        lesson.contentUrl!.trim().isNotEmpty) ...[
                      _VideoContent(url: lesson.contentUrl),
                    ] else
                      const _EmptyLessonMessage(
                        'No video available for this lesson.',
                      ),
                  ] else
                    _TextContent(text: lesson.contentText),
                ],
              ),
            ),
          ),
          // Bottom action bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _completed || _marking ? null : _markComplete,
                  icon: _marking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _completed
                              ? Icons.check_circle_rounded
                              : Icons.check_rounded,
                        ),
                  label: Text(_completed ? 'Completed' : 'Mark as Complete'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _completed
                        ? AppColors.secondary
                        : AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _contentIcon(String type) => switch (type) {
    'video' => Icons.play_circle_outline_rounded,
    'mixed' => Icons.dynamic_feed_rounded,
    _ => Icons.article_outlined,
  };

  String _contentLabel(String type) => switch (type) {
    'video' => 'Video',
    'mixed' => 'Mixed',
    _ => 'Text',
  };
}

class _EmptyLessonMessage extends StatelessWidget {
  const _EmptyLessonMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          style: const TextStyle(color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _TextContent extends StatelessWidget {
  const _TextContent({this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    if (text == null || text!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No content available for this lesson.',
            style: TextStyle(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Text(
        text!,
        style: const TextStyle(fontSize: 15, color: AppColors.ink, height: 1.7),
      ),
    );
  }
}

class _VideoContent extends StatelessWidget {
  const _VideoContent({this.url});

  final String? url;

  static String? _extractVideoId(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final v = uri.queryParameters['v'];
    if (v != null && v.isNotEmpty) return v;
    if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'embed') {
      return uri.pathSegments[1];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final videoId = _extractVideoId(url);
    if (videoId != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: buildYouTubeEmbed(videoId),
      );
    }
    final resolvedUrl = _resolvedVideoUrl;
    if (resolvedUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: buildNetworkVideo(resolvedUrl),
      );
    }
    // Fallback for non-YouTube or missing URLs
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.play_circle_outline_rounded,
            size: 56,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          if (url != null && url!.isNotEmpty) ...[
            Text(
              url!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Copy the link above to watch in your browser.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ] else
            const Text(
              'No video URL provided.',
              style: TextStyle(color: AppColors.muted),
            ),
        ],
      ),
    );
  }

  String? get _resolvedVideoUrl {
    final value = url?.trim();
    if (value == null || value.isEmpty) return null;
    return ApiClient.resolveUrl(value);
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.icon, this.label, {this.color = AppColors.muted});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
