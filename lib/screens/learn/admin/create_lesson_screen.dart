import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../repositories/course_repository.dart';

class CreateLessonScreen extends StatefulWidget {
  const CreateLessonScreen({
    required this.courseId,
    this.nextOrder = 0,
    super.key,
  });

  final int courseId;
  final int nextOrder;

  @override
  State<CreateLessonScreen> createState() => _CreateLessonScreenState();
}

class _CreateLessonScreenState extends State<CreateLessonScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _learningOutcomesCtrl = TextEditingController();
  final _videoUrlCtrl = TextEditingController();
  final _pdfUrlCtrl = TextEditingController();
  final _notesUrlCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();

  _PickedUpload? _videoUpload;
  _PickedUpload? _notesUpload;
  bool _isPublished = true;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _learningOutcomesCtrl.dispose();
    _videoUrlCtrl.dispose();
    _pdfUrlCtrl.dispose();
    _notesUrlCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return;
    setState(() {
      _videoUpload = _PickedUpload(file!.name, file.bytes!.toList());
    });
  }

  Future<void> _pickNotesFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'txt', 'docx'],
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return;
    setState(() {
      _notesUpload = _PickedUpload(file!.name, file.bytes!.toList());
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasAnyContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add a video, PDF, notes file, URL, or learning outcomes.',
          ),
          backgroundColor: AppColors.softRed,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final uploadedVideoUrl = _videoUpload == null
          ? null
          : await CourseRepository.uploadFile(
              bytes: _videoUpload!.bytes,
              fileName: _videoUpload!.name,
            );
      final uploadedNotesUrl = _notesUpload == null
          ? null
          : await CourseRepository.uploadFile(
              bytes: _notesUpload!.bytes,
              fileName: _notesUpload!.name,
            );
      final videoUrl = uploadedVideoUrl ?? _emptyToNull(_videoUrlCtrl.text);
      final learningOutcomes = _emptyToNull(_learningOutcomesCtrl.text);

      final lesson = await CourseRepository.createLesson(
        widget.courseId,
        title: _titleCtrl.text.trim(),
        description: _emptyToNull(_descCtrl.text),
        contentType: 'mixed',
        contentUrl: videoUrl ?? _emptyToNull(_pdfUrlCtrl.text),
        contentText: learningOutcomes,
        order: widget.nextOrder,
        durationMinutes: int.tryParse(_durationCtrl.text.trim()),
        isPublished: _isPublished,
      );

      await _createResources(
        lessonId: lesson.id,
        videoUrl: videoUrl,
        pdfUrl: _emptyToNull(_pdfUrlCtrl.text),
        notesUrl: _emptyToNull(_notesUrlCtrl.text),
        uploadedNotesUrl: uploadedNotesUrl,
      );

      if (mounted) Navigator.of(context).pop(lesson);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not create lesson. Please try again.'),
            backgroundColor: AppColors.softRed,
          ),
        );
      }
    }
  }

  Future<void> _createResources({
    required int lessonId,
    required String? videoUrl,
    required String? pdfUrl,
    required String? notesUrl,
    required String? uploadedNotesUrl,
  }) async {
    if (videoUrl != null) {
      await CourseRepository.createResource(
        widget.courseId,
        lessonId,
        type: 'video',
        title: 'Lesson Video',
        fileUrl: videoUrl,
      );
    }
    if (pdfUrl != null) {
      await CourseRepository.createResource(
        widget.courseId,
        lessonId,
        type: 'pdf',
        title: 'PDF Notes',
        fileUrl: pdfUrl,
      );
    }
    if (notesUrl != null) {
      await CourseRepository.createResource(
        widget.courseId,
        lessonId,
        type: 'link',
        title: 'Notes Link',
        fileUrl: notesUrl,
      );
    }
    if (uploadedNotesUrl != null && _notesUpload != null) {
      await CourseRepository.createResource(
        widget.courseId,
        lessonId,
        type: _notesUpload!.resourceType,
        title: _notesUpload!.title,
        fileUrl: uploadedNotesUrl,
      );
    }
  }

  bool get _hasAnyContent =>
      _videoUpload != null ||
      _notesUpload != null ||
      _videoUrlCtrl.text.trim().isNotEmpty ||
      _pdfUrlCtrl.text.trim().isNotEmpty ||
      _notesUrlCtrl.text.trim().isNotEmpty ||
      _learningOutcomesCtrl.text.trim().isNotEmpty;

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: const Text(
          'New Lesson',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _SectionTitle(
              icon: Icons.dynamic_feed_rounded,
              title: 'Mixed Lesson Content',
            ),
            const SizedBox(height: 16),
            _SectionLabel('Title'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleCtrl,
              decoration: _inputDecoration('e.g. Introduction to Variables'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 20),
            _SectionLabel('Description (optional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descCtrl,
              decoration: _inputDecoration('Short description of this lesson'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            const _SectionTitle(
              icon: Icons.play_circle_outline_rounded,
              title: 'Video',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _videoUrlCtrl,
              decoration: _inputDecoration('Video URL'),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            _UploadField(
              icon: Icons.video_file_outlined,
              label: _videoUpload?.name ?? 'Upload video from local storage',
              selected: _videoUpload != null,
              onPick: _pickVideo,
              onClear: _videoUpload == null
                  ? null
                  : () => setState(() => _videoUpload = null),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(
              icon: Icons.sticky_note_2_outlined,
              title: 'What the student will learn',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _learningOutcomesCtrl,
              decoration: _inputDecoration(
                'e.g. Understand variables, write simple code, and complete a mini task',
              ),
              minLines: 4,
              maxLines: 8,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            const _SectionTitle(
              icon: Icons.note_add_outlined,
              title: 'Notes & Resources',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pdfUrlCtrl,
              decoration: _inputDecoration('PDF notes URL'),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesUrlCtrl,
              decoration: _inputDecoration('Notes link URL'),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            _UploadField(
              icon: Icons.upload_file_rounded,
              label: _notesUpload?.name ?? 'Upload PDF/TXT/DOCX notes',
              selected: _notesUpload != null,
              onPick: _pickNotesFile,
              onClear: _notesUpload == null
                  ? null
                  : () => setState(() => _notesUpload = null),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Duration (minutes, optional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _durationCtrl,
              decoration: _inputDecoration('e.g. 15'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.muted.withValues(alpha: 0.15),
                ),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Publish immediately',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                subtitle: const Text(
                  'Students will see this lesson right away',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                value: _isPublished,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _isPublished = v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

class _PickedUpload {
  const _PickedUpload(this.name, this.bytes);

  final String name;
  final List<int> bytes;

  String get extension {
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot + 1).toLowerCase();
  }

  String get resourceType => extension == 'pdf' ? 'pdf' : 'note';

  String get title =>
      extension == 'pdf' ? 'Uploaded PDF Notes' : 'Uploaded Notes';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    );
  }
}

class _UploadField extends StatelessWidget {
  const _UploadField({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPick,
    this.onClear,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? AppColors.primary
              : AppColors.muted.withValues(alpha: 0.2),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        onTap: onPick,
        leading: Icon(
          selected ? Icons.check_circle_rounded : icon,
          color: selected ? AppColors.primary : AppColors.muted,
        ),
        title: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        trailing: onClear == null
            ? const Icon(Icons.upload_rounded, color: AppColors.muted)
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Remove file',
              ),
      ),
    );
  }
}
