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
  final String
  type; // video | pdf | pdf_notes | image | note | link | zip | code_file
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
    'video' => Icons.play_circle_outline_rounded,
    'pdf' => Icons.picture_as_pdf_outlined,
    'pdf_notes' => Icons.picture_as_pdf_outlined,
    'image' => Icons.image_outlined,
    'note' => Icons.sticky_note_2_outlined,
    'link' => Icons.link_rounded,
    'zip' => Icons.folder_zip_outlined,
    'code_file' => Icons.code_rounded,
    _ => Icons.attach_file_rounded,
  };

  String get typeLabel => switch (type) {
    'video' => 'Video',
    'pdf' => 'PDF',
    'pdf_notes' => 'PDF Notes',
    'image' => 'Image',
    'note' => 'Note',
    'link' => 'Link',
    'zip' => 'ZIP',
    'code_file' => 'Code File',
    _ => type,
  };
}
