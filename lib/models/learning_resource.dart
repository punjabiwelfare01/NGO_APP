import 'package:flutter/material.dart';

class LearningResource {
  const LearningResource({
    required this.id,
    required this.lessonId,
    required this.type,
    required this.title,
    required this.createdAt,
    this.fileUrl,
    this.textContent,
    this.uploadedBy,
  });

  final int id;
  final int lessonId;
  final String type; // video | pdf | image | note | link
  final String title;
  final String? fileUrl;
  final String? textContent;
  final int? uploadedBy;
  final DateTime createdAt;

  factory LearningResource.fromJson(Map<String, dynamic> j) => LearningResource(
        id: j['id'] as int,
        lessonId: j['lesson_id'] as int,
        type: j['type'] as String,
        title: j['title'] as String,
        fileUrl: j['file_url'] as String?,
        textContent: j['text_content'] as String?,
        uploadedBy: j['uploaded_by'] as int?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  IconData get icon => switch (type) {
        'video'  => Icons.play_circle_outline_rounded,
        'pdf'    => Icons.picture_as_pdf_outlined,
        'image'  => Icons.image_outlined,
        'note'   => Icons.sticky_note_2_outlined,
        'link'   => Icons.link_rounded,
        _        => Icons.attach_file_rounded,
      };

  String get typeLabel => switch (type) {
        'video' => 'Video',
        'pdf'   => 'PDF',
        'image' => 'Image',
        'note'  => 'Note',
        'link'  => 'Link',
        _       => type,
      };
}
