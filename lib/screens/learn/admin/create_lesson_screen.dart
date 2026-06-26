import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/course.dart';
import '../../../repositories/course_repository.dart';

class CreateLessonScreen extends StatefulWidget {
  const CreateLessonScreen({
    required this.courseId,
    required this.courseType,
    this.courseTitle,
    this.classLevel,
    this.subject,
    this.skillCategory,
    this.nextOrder = 0,
    super.key,
  });

  final int courseId;
  final String courseType;
  final String? courseTitle;
  final String? classLevel;
  final String? subject;
  final String? skillCategory;
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
  final _orderCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _chapterCtrl = TextEditingController();

  _PickedUpload? _videoUpload;
  _PickedUpload? _notesUpload;
  late String _classLevel;
  late String _subject;
  bool _saving = false;

  bool get _isAcademic => widget.courseType == CourseType.academic;

  @override
  void initState() {
    super.initState();
    _classLevel = widget.classLevel ?? '8';
    _subject = widget.subject ?? 'Science';
    _subjectCtrl.text = widget.subject ?? '';
    _orderCtrl.text = '${widget.nextOrder + 1}';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _learningOutcomesCtrl.dispose();
    _videoUrlCtrl.dispose();
    _pdfUrlCtrl.dispose();
    _notesUrlCtrl.dispose();
    _durationCtrl.dispose();
    _orderCtrl.dispose();
    _subjectCtrl.dispose();
    _chapterCtrl.dispose();
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

  Future<void> _saveAs({required bool publish}) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasAnyContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add at least a video, PDF, notes, or learning outcomes.',
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

      final lesson = await CourseRepository.createLesson(
        widget.courseId,
        title: _titleCtrl.text.trim(),
        description: _emptyToNull(_descCtrl.text),
        contentType: 'mixed',
        contentUrl: videoUrl ?? _emptyToNull(_pdfUrlCtrl.text),
        contentText: _emptyToNull(_learningOutcomesCtrl.text),
        classLevel: null,
        subject: _emptyToNull(_subjectCtrl.text),
        chapter: _emptyToNull(_chapterCtrl.text),
        order: int.tryParse(_orderCtrl.text.trim()) ?? widget.nextOrder,
        durationMinutes: int.tryParse(_durationCtrl.text.trim()),
        isPublished: publish,
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
        type: 'pdf_notes',
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

  String get _appBarSubtitle {
    return widget.skillCategory ?? 'Free Course';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Lesson',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            Text(
              _appBarSubtitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            // ── Course context banner ─────────────────────────────────────
            _CourseContextCard(
              courseTitle: widget.courseTitle,
              courseType: widget.courseType,
              classLevel: _isAcademic ? _classLevel : null,
              subject: _isAcademic ? _subject : null,
              skillCategory: widget.skillCategory,
            ),
            const SizedBox(height: 20),

            // ── Lesson details ────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.edit_note_rounded,
              title: 'Lesson Details',
              color: const Color(0xFF2678F4),
            ),
            const SizedBox(height: 12),
            _FieldLabel('Lesson Title *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleCtrl,
              decoration: _inputDeco('e.g. Introduction to Variables'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel('Description (optional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descCtrl,
              decoration: _inputDeco(
                'Short description of what this lesson covers',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _FieldLabel('Lesson Order'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _orderCtrl,
              decoration: _inputDeco('e.g. 1'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            _SectionHeader(
              icon: Icons.account_tree_rounded,
              title: 'Subject & Chapter',
              color: const Color(0xFF6A1B9A),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _subjectCtrl,
                    decoration: _inputDeco('Subject, e.g. Mathematics'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Subject is required'
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _chapterCtrl,
                    decoration: _inputDeco('Chapter, e.g. Algebra'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Chapter is required'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Video content ─────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.play_circle_outline_rounded,
              title: 'Video Lesson',
              color: const Color(0xFF2FAE65),
            ),
            const SizedBox(height: 12),
            _FieldLabel('Video URL (YouTube, Google Drive, or direct link)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _videoUrlCtrl,
              decoration: _inputDeco('https://...'),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            _UploadField(
              icon: Icons.video_file_outlined,
              label: _videoUpload?.name ?? 'Upload video from device',
              selected: _videoUpload != null,
              onPick: _pickVideo,
              onClear: _videoUpload == null
                  ? null
                  : () => setState(() => _videoUpload = null),
            ),
            const SizedBox(height: 24),

            // ── Learning outcomes ─────────────────────────────────────────
            _SectionHeader(
              icon: Icons.lightbulb_outline_rounded,
              title: 'What Students Will Learn',
              color: const Color(0xFFFF8A00),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _learningOutcomesCtrl,
              decoration: _inputDeco(
                'e.g. Understand variables, write simple code, complete a mini task…',
              ),
              minLines: 4,
              maxLines: 8,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // ── PDF notes & resources ─────────────────────────────────────
            _SectionHeader(
              icon: Icons.note_add_outlined,
              title: 'PDF Notes & Resources',
              color: const Color(0xFF7045D9),
            ),
            const SizedBox(height: 12),
            _FieldLabel('PDF Notes URL'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _pdfUrlCtrl,
              decoration: _inputDeco('https://… (direct PDF link)'),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            _FieldLabel('Additional Notes Link (optional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _notesUrlCtrl,
              decoration: _inputDeco('https://… (Google Docs, Notion, etc.)'),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            _UploadField(
              icon: Icons.upload_file_rounded,
              label: _notesUpload?.name ?? 'Upload PDF / TXT / DOCX file',
              selected: _notesUpload != null,
              onPick: _pickNotesFile,
              onClear: _notesUpload == null
                  ? null
                  : () => setState(() => _notesUpload = null),
            ),
            const SizedBox(height: 24),

            // ── Duration ─────────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.schedule_rounded,
              title: 'Duration',
              color: AppColors.muted,
            ),
            const SizedBox(height: 12),
            _FieldLabel('Duration in minutes (optional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _durationCtrl,
              decoration: _inputDeco('e.g. 15'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 28),

            // ── Publish actions ───────────────────────────────────────────
            _PublishActions(
              saving: _saving,
              onSaveDraft: () => _saveAs(publish: false),
              onPublish: () => _saveAs(publish: true),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
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

// ─── Course context card ──────────────────────────────────────────────────────

class _CourseContextCard extends StatelessWidget {
  const _CourseContextCard({
    required this.courseTitle,
    required this.courseType,
    required this.classLevel,
    required this.subject,
    required this.skillCategory,
  });

  final String? courseTitle;
  final String courseType;
  final String? classLevel;
  final String? subject;
  final String? skillCategory;

  bool get _isAcademic => courseType == CourseType.academic;

  @override
  Widget build(BuildContext context) {
    final accentColor = _isAcademic
        ? const Color(0xFF2678F4)
        : const Color(0xFF2FAE65);
    final bgColor = _isAcademic
        ? const Color(0xFFEAF3FF)
        : const Color(0xFFEDFFF5);
    final typeLabel = _isAcademic ? 'Academic Course' : 'Skill Course';
    final contextLabel = _isAcademic
        ? 'Class $classLevel · $subject'
        : skillCategory ?? 'Skill Course';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isAcademic ? Icons.school_rounded : Icons.star_rounded,
              color: accentColor,
              size: 26,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (courseTitle != null) ...[
                  Text(
                    courseTitle!,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Icon(
                      _isAcademic
                          ? Icons.menu_book_rounded
                          : Icons.category_rounded,
                      size: 14,
                      color: accentColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      contextLabel,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _isAcademic
                      ? 'This lesson will be visible to Class $classLevel students studying $subject.'
                      : 'This lesson will be added to the ${skillCategory ?? 'skill'} course.',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Publish actions ──────────────────────────────────────────────────────────

class _PublishActions extends StatelessWidget {
  const _PublishActions({
    required this.saving,
    required this.onSaveDraft,
    required this.onPublish,
  });

  final bool saving;
  final VoidCallback onSaveDraft;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: saving ? null : onPublish,
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.publish_rounded, size: 18),
          label: const Text('Publish Lesson'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2FAE65),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: saving ? null : onSaveDraft,
          icon: const Icon(Icons.save_outlined, size: 18),
          label: const Text('Save as Draft'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Draft lessons are not visible to students.',
            style: TextStyle(
              color: AppColors.muted.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

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

class _PickedUpload {
  const _PickedUpload(this.name, this.bytes);

  final String name;
  final List<int> bytes;

  String get extension {
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot + 1).toLowerCase();
  }

  String get resourceType => extension == 'pdf' ? 'pdf_notes' : 'note';

  String get title =>
      extension == 'pdf' ? 'Uploaded PDF Notes' : 'Uploaded Notes';
}
