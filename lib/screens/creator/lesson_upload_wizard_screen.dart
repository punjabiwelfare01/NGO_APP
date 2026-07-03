import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/course.dart';
import '../../repositories/course_repository.dart';
import '../../utils/logger.dart';
import '../learn/course_detail_screen.dart';

class LessonUploadWizardScreen extends StatefulWidget {
  const LessonUploadWizardScreen({
    required this.courses,
    this.notesFirst = false,
    super.key,
  });

  final List<Course> courses;
  final bool notesFirst;

  @override
  State<LessonUploadWizardScreen> createState() =>
      _LessonUploadWizardScreenState();
}

class _LessonUploadWizardScreenState extends State<LessonUploadWizardScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _outcomesCtrl = TextEditingController(
    text:
        'What is light\nSources of light\nProperties of light\nHow light travels',
  );
  final _orderCtrl = TextEditingController(text: '1');
  final _durationCtrl = TextEditingController(text: '15');
  final _videoUrlCtrl = TextEditingController();

  int _step = 0;
  String _courseType = CourseType.academic;
  String _classLevel = '8';
  String _subject = 'Science';
  Course? _course;
  bool _useUploadVideo = true;
  _PickedUpload? _video;
  String? _videoUrl;
  _PickedUpload? _pdfNotes;
  String? _pdfNotesUrl;
  final List<_PickedUpload> _resources = [];
  String _publishStatus = 'draft';
  bool _saving = false;
  bool _uploadingVideo = false;
  bool _videoUploadFailed = false;
  // 0.0–1.0 during upload; null when idle/complete.
  double? _videoUploadProgress;
  bool _uploadingPdf = false;

  @override
  void initState() {
    super.initState();
    if (widget.notesFirst) _step = 3;
    final academic = widget.courses.where((course) => course.isAcademic);
    if (academic.isNotEmpty) {
      final first = academic.first;
      _course = first;
      _classLevel = first.classLevel ?? _classLevel;
      _subject = first.subject ?? _subject;
    } else if (widget.courses.isNotEmpty) {
      _courseType = widget.courses.first.courseType;
      _course = widget.courses.first;
    }
    _ensureValidSubject();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _outcomesCtrl.dispose();
    _orderCtrl.dispose();
    _durationCtrl.dispose();
    _videoUrlCtrl.dispose();
    super.dispose();
  }

  List<Course> get _mappedCourses {
    return widget.courses.where((course) {
      if (course.courseType != _courseType) return false;
      if (_courseType == CourseType.academic) {
        return course.classLevel == _classLevel &&
            (course.subject == null || course.subject == _subject);
      }
      return true;
    }).toList();
  }

  bool get _canSave =>
      _course != null &&
      _titleCtrl.text.trim().isNotEmpty &&
      (_videoUrl != null || _videoUrlCtrl.text.trim().isNotEmpty);

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      // Never load all bytes into memory — for 100 MB+ files on web this would
      // allocate a flat Uint8List and crash the browser tab.
      withData: false,
      // Stream on ALL platforms:
      //   Android/iOS: opens the file descriptor immediately so Android cannot
      //     GC the temp-cache file mid-upload.
      //   Web: reads via FileReader.readAsArrayBuffer in 1 MB chunks, letting
      //     the GC free each chunk before the next one arrives.
      withReadStream: true,
    );
    if (result == null) return;
    final file = result.files.single;

    // On web file.path is always null; on Android/iOS it is the cache path.
    final bool hasStream = file.readStream != null;
    final bool hasPath = !kIsWeb && file.path != null;
    final bool hasBytes = false; // withData:false — bytes never loaded

    if (!hasStream && !hasPath && !hasBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not read video file. Try again or choose a different file.',
          ),
          backgroundColor: AppColors.softRed,
        ),
      );
      return;
    }

    final upload = _PickedUpload(
      file.name,
      const [],
      filePath: hasPath ? file.path : null,
      readStream: hasStream ? file.readStream : null,
      sizeBytes: file.size,
    );
    setState(() {
      _video = upload;
      _videoUrl = null;
      _videoUploadFailed = false;
      _uploadingVideo = true;
      _videoUploadProgress = 0.0;
    });
    await _runVideoUpload(upload);
  }

  /// Re-run upload for the same file without re-picking it.
  /// readStream is single-use, so retry uses the cached file path instead.
  Future<void> _retryVideoUpload() async {
    final upload = _video;
    if (upload == null) return;
    setState(() {
      _videoUrl = null;
      _videoUploadFailed = false;
      _uploadingVideo = true;
      _videoUploadProgress = 0.0;
    });
    // Intentionally drop readStream — it's already consumed. The path-only
    // retry re-opens the cache file; if that file was cleaned up by Android
    // the upload fails again and the user can pick a fresh file.
    final retryUpload = _PickedUpload(
      upload.name,
      upload.bytes,
      filePath: upload.filePath,
      sizeBytes: upload.fileSize > 0 ? upload.fileSize : null,
    );
    await _runVideoUpload(retryUpload);
  }

  Future<void> _runVideoUpload(_PickedUpload upload) async {
    var lastProgressPct = -1;
    try {
      final storedUrl = await CourseRepository.uploadVideo(
        bytes: upload.bytes.isNotEmpty ? upload.bytes : null,
        filePath: upload.filePath,
        readStream: upload.readStream,
        fileSize: upload.fileSize,
        fileName: upload.name,
        onProgress: (sent, total) {
          if (!mounted || total <= 0) return;
          // Throttle: one setState per 1 % to avoid ~1600 rebuilds for 100 MB.
          final pct = (sent * 100 ~/ total);
          if (pct == lastProgressPct) return;
          lastProgressPct = pct;
          setState(() => _videoUploadProgress = sent / total);
        },
      );
      if (!mounted) return;
      setState(() {
        _videoUrl = storedUrl;
        _uploadingVideo = false;
        _videoUploadFailed = false;
        _videoUploadProgress = null;
      });
      await _showUploadSuccessDialog(
        title: 'Video uploaded successfully',
        message: 'Your lesson video has been stored on the server.',
        icon: Icons.video_file_rounded,
        color: const Color(0xFF216DF4),
        file: upload,
      );
    } catch (e) {
      if (!mounted) return;
      AppLogger.error('Video upload failed', tag: 'Upload', error: e);
      setState(() {
        _videoUrl = null;
        _uploadingVideo = false;
        _videoUploadFailed = true;
        _videoUploadProgress = null;
      });
    }
  }

  Future<void> _pickPdfNotes() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (result == null) return;
    final file = result.files.single;
    if (file.bytes == null || file.bytes!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not read PDF file. The file may be too large or unsupported.',
          ),
          backgroundColor: AppColors.softRed,
        ),
      );
      return;
    }
    final upload = _PickedUpload(file.name, file.bytes!.toList());
    setState(() {
      _pdfNotes = upload;
      _pdfNotesUrl = null;
      _uploadingPdf = true;
    });
    try {
      final storedUrl = await CourseRepository.uploadFile(
        bytes: upload.bytes,
        fileName: upload.name,
      );
      if (!mounted) return;
      setState(() {
        _pdfNotes = upload;
        _pdfNotesUrl = storedUrl;
        _uploadingPdf = false;
      });
      await _showUploadSuccessDialog(
        title: 'PDF notes uploaded successfully',
        message: 'Your notes PDF has been stored on the server.',
        icon: Icons.picture_as_pdf_rounded,
        color: const Color(0xFFEA580C),
        file: upload,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pdfNotes = null;
        _pdfNotesUrl = null;
        _uploadingPdf = false;
      });
      _showValidationMessage('Could not upload PDF notes. Please try again.');
    }
  }

  Future<void> _pickResource() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    final file = result?.files.single;
    if (file?.bytes == null) return;
    setState(
      () => _resources.add(_PickedUpload(file!.name, file.bytes!.toList())),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final error = _validationMessageForStep(4) ?? _firstBlockingMessage();
    if (error != null) {
      _showValidationMessage(error);
      return;
    }
    if (!_canSave || _course == null) return;
    setState(() => _saving = true);
    try {
      String? videoUrl = _videoUrlCtrl.text.trim().isEmpty
          ? null
          : _videoUrlCtrl.text.trim();
      if (_video != null) videoUrl = _videoUrl;

      final lesson = await CourseRepository.createLesson(
        _course!.id,
        title: _titleCtrl.text.trim(),
        description: _emptyToNull(_descCtrl.text),
        contentType: 'mixed',
        contentUrl: videoUrl,
        contentText: _emptyToNull(_outcomesCtrl.text),
        classLevel: _courseType == CourseType.academic ? _classLevel : null,
        subject: _courseType == CourseType.academic ? _subject : null,
        order: int.tryParse(_orderCtrl.text.trim()) ?? _course!.lessonCount,
        durationMinutes: int.tryParse(_durationCtrl.text.trim()),
        isPublished: _publishStatus == 'publish',
      );

      if (videoUrl != null) {
        await CourseRepository.createResource(
          _course!.id,
          lesson.id,
          type: 'video',
          title: 'Lesson Video',
          fileUrl: videoUrl,
        );
      }
      if (_pdfNotes != null) {
        await CourseRepository.createResource(
          _course!.id,
          lesson.id,
          type: 'pdf_notes',
          title: _pdfNotes!.name,
          fileUrl: _pdfNotesUrl,
        );
      }
      for (final resource in _resources) {
        final url = await CourseRepository.uploadFile(
          bytes: resource.bytes,
          fileName: resource.name,
        );
        await CourseRepository.createResource(
          _course!.id,
          lesson.id,
          type: resource.resourceType,
          title: resource.name,
          fileUrl: url,
        );
      }
      if (!mounted) return;
      await _showSuccessSheet(
        hasVideo: videoUrl != null,
        hasPdf: _pdfNotes != null,
        resourceCount: _resources.length,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _uploadingVideo = false;
        _uploadingPdf = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save lesson. Please try again.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }

  Future<void> _showSuccessSheet({
    required bool hasVideo,
    required bool hasPdf,
    required int resourceCount,
  }) {
    final (title, subtitle, icon, color) = switch (_publishStatus) {
      'publish' => (
        'Lesson Published!',
        'Students can now view this lesson.',
        Icons.check_circle_rounded,
        const Color(0xFF16A34A),
      ),
      'review' => (
        'Submitted for Review',
        'An admin will review and publish it soon.',
        Icons.rate_review_rounded,
        const Color(0xFFF59E0B),
      ),
      _ => (
        'Draft Saved',
        'Your lesson has been saved as a draft.',
        Icons.save_rounded,
        const Color(0xFF6366F1),
      ),
    };

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _SuccessSheet(
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
        lessonTitle: _titleCtrl.text.trim(),
        courseName: _course?.title ?? '',
        hasVideo: hasVideo,
        hasPdf: hasPdf,
        resourceCount: resourceCount,
        onDone: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _next() {
    final error = _validationMessageForStep(_step);
    if (error != null) {
      _showValidationMessage(error);
      return;
    }
    if (_step < 4) setState(() => _step += 1);
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step -= 1);
  }

  void _setClass(String level) {
    setState(() {
      _classLevel = level;
      _ensureValidSubject();
      _course = _mappedCourses.firstOrNull;
    });
  }

  void _setSubject(String subject) {
    setState(() {
      _subject = subject;
      _course = _mappedCourses.firstOrNull;
    });
  }

  void _ensureValidSubject() {
    final subjects = academicSubjectsForClass(_classLevel, includeAll: false);
    if (!subjects.contains(_subject)) _subject = subjects.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        leading: IconButton(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
        ),
        title: Text(
          _stepTitle,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
          children: [
            _StepDots(current: _step),
            const SizedBox(height: 22),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: switch (_step) {
                0 => _mappingStep(),
                1 => _lessonInfoStep(),
                2 => _videoStep(),
                3 => _resourcesStep(),
                _ => _publishStep(),
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 10, 18, 16),
        child: FilledButton(
          onPressed: _saving ? null : (_step == 4 ? _save : _next),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF216DF4),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          child: _saving
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    if (_uploadingVideo) ...[
                      const SizedBox(width: 10),
                      const Text(
                        'Uploading video…',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ] else if (_uploadingPdf) ...[
                      const SizedBox(width: 10),
                      const Text(
                        'Uploading PDF…',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                )
              : Text(_step == 4 ? _saveLabel : 'Next: $_nextLabel  →'),
        ),
      ),
    );
  }

  String get _stepTitle => switch (_step) {
    0 => 'Add Lesson',
    1 => 'Lesson Information',
    2 => 'Video Content',
    3 => 'Notes & Resources',
    _ => 'Publishing Options',
  };

  String get _nextLabel => switch (_step) {
    0 => 'Lesson Info',
    1 => 'Video Content',
    2 => 'Notes & Resources',
    3 => 'Publishing Options',
    _ => 'Save',
  };

  String get _saveLabel => switch (_publishStatus) {
    'review' => 'Submit for Review',
    'publish' => 'Publish Lesson',
    _ => 'Save as Draft',
  };

  Widget _mappingStep() {
    return _WizardSection(
      key: const ValueKey('mapping'),
      title: 'Course Mapping',
      children: [
        const _FieldLabel('Course Type'),
        _SegmentedChoice(
          left: 'Academic',
          right: 'Skill',
          selectedLeft: _courseType == CourseType.academic,
          onLeft: () => setState(() {
            _courseType = CourseType.academic;
            _course = _mappedCourses.firstOrNull;
          }),
          onRight: () => setState(() {
            _courseType = CourseType.skill;
            _course = _mappedCourses.firstOrNull;
          }),
        ),
        if (_courseType == CourseType.academic) ...[
          const _FieldLabel('Class Level *'),
          _PickerTile(
            value: 'Class $_classLevel',
            onTap: () => _showStringPicker(
              title: 'Class Level',
              values: academicClasses.map((level) => 'Class $level').toList(),
              onSelected: (value) => _setClass(value.replaceAll('Class ', '')),
            ),
          ),
          const _FieldLabel('Subject *'),
          _PickerTile(
            value: _subject,
            onTap: () => _showStringPicker(
              title: 'Subject',
              values: academicSubjectsForClass(_classLevel, includeAll: false),
              onSelected: _setSubject,
            ),
          ),
        ],
        const _FieldLabel('Course *'),
        _PickerTile(
          value: _course?.title ?? 'Select a course',
          onTap: () => _showCoursePicker(),
        ),
        _InfoPanel(
          text: _courseType == CourseType.academic
              ? 'This lesson will be available to Class $_classLevel $_subject students.'
              : 'This lesson will be available in the selected skill course.',
        ),
      ],
    );
  }

  Widget _lessonInfoStep() {
    return _WizardSection(
      key: const ValueKey('info'),
      title: 'Lesson Information',
      children: [
        _TextInput(
          label: 'Lesson Title *',
          controller: _titleCtrl,
          hint: 'Introduction to Light',
          textInputAction: TextInputAction.next,
          onEditingComplete: () => FocusScope.of(context).nextFocus(),
        ),
        _TextInput(
          label: 'Short Description',
          controller: _descCtrl,
          hint: 'In this lesson, students will learn...',
          maxLines: 5,
        ),
        _TextInput(
          label: 'What students will learn',
          controller: _outcomesCtrl,
          hint: 'Add one outcome per line',
          maxLines: 6,
        ),
        _TextInput(
          label: 'Lesson Order',
          controller: _orderCtrl,
          hint: '1',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          onEditingComplete: () => FocusScope.of(context).nextFocus(),
        ),
        _TextInput(
          label: 'Duration (minutes)',
          controller: _durationCtrl,
          hint: '15',
          keyboardType: TextInputType.number,
          prefixIcon: Icons.schedule_rounded,
        ),
      ],
    );
  }

  Widget _videoStep() {
    return _WizardSection(
      key: const ValueKey('video'),
      title: 'Video Content',
      children: [
        const _FieldLabel('Video Source'),
        Row(
          children: [
            Expanded(
              child: _SelectBox(
                label: 'Upload Video',
                selected: _useUploadVideo,
                onTap: () => setState(() => _useUploadVideo = true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SelectBox(
                label: 'Video URL',
                selected: !_useUploadVideo,
                onTap: () => setState(() => _useUploadVideo = false),
              ),
            ),
          ],
        ),
        if (_useUploadVideo)
          _UploadPreviewCard(
            title: _video?.name ?? 'Upload lesson video',
            subtitle: _video == null
                ? 'MP4, MOV, WebM'
                : _video!.sizeLabel,
            icon: Icons.video_file_rounded,
            onPick: _pickVideo,
            onRemove: (_video == null || _uploadingVideo)
                ? null
                : () => setState(() {
                    _video = null;
                    _videoUrl = null;
                    _uploadingVideo = false;
                    _videoUploadFailed = false;
                  }),
            isUploading: _uploadingVideo,
            uploadProgress: _videoUploadProgress,
            hasError: _videoUploadFailed,
            onRetry: _retryVideoUpload,
          )
        else
          _TextInput(
            label: 'Video URL',
            controller: _videoUrlCtrl,
            hint: 'https://...',
            keyboardType: TextInputType.url,
          ),
        const _InfoPanel(
          text: 'Supported formats: MP4, MOV, WebM. Max file size: 500MB.',
        ),
      ],
    );
  }

  Widget _resourcesStep() {
    return _WizardSection(
      key: const ValueKey('resources'),
      title: 'Notes & Resources',
      children: [
        const _FieldLabel('PDF Notes (Optional)'),
        _UploadPreviewCard(
          title: _pdfNotes?.name ?? 'Upload PDF notes',
          subtitle: _pdfNotes == null
              ? 'PDF notes, worksheets'
              : _uploadingPdf
              ? 'Uploading to server...'
              : _pdfNotes!.sizeLabel,
          icon: Icons.picture_as_pdf_rounded,
          onPick: _pickPdfNotes,
          onRemove: _pdfNotes == null
              ? null
              : () => setState(() {
                  _pdfNotes = null;
                  _pdfNotesUrl = null;
                  _uploadingPdf = false;
                }),
          isUploading: _uploadingPdf,
        ),
        const _FieldLabel('Additional Resources (Optional)'),
        for (final resource in _resources)
          _FileRow(
            file: resource,
            onRemove: () => setState(() => _resources.remove(resource)),
          ),
        OutlinedButton.icon(
          onPressed: _pickResource,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add More Resource'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            foregroundColor: const Color(0xFF216DF4),
            side: const BorderSide(color: Color(0xFFB8D4FF)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _publishStep() {
    return _WizardSection(
      key: const ValueKey('publish'),
      title: 'Publishing Options',
      children: [
        const _FieldLabel('Status *'),
        _RadioCard(
          value: 'draft',
          groupValue: _publishStatus,
          title: 'Draft',
          subtitle: 'Save as draft',
          onChanged: (value) => setState(() => _publishStatus = value),
        ),
        _RadioCard(
          value: 'review',
          groupValue: _publishStatus,
          title: 'Submit for Review',
          subtitle: 'Send for admin approval',
          onChanged: (value) => setState(() => _publishStatus = value),
        ),
        _RadioCard(
          value: 'publish',
          groupValue: _publishStatus,
          title: 'Publish',
          subtitle: 'Publish now',
          onChanged: (value) => setState(() => _publishStatus = value),
        ),
        const _FieldLabel('Visibility *'),
        _InfoPanel(
          text: _courseType == CourseType.academic
              ? 'Public to Class $_classLevel students. Lesson will be visible to all Class $_classLevel $_subject students when published.'
              : 'Public to students browsing this skill course when published.',
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _course == null ? null : _previewStudent,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Preview as Student'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _showChecklist,
                icon: const Icon(Icons.checklist_rounded),
                label: const Text('Checklist'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showStringPicker({
    required String title,
    required List<String> values,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _PickerSheet(title: title, values: values, onSelected: onSelected),
    );
  }

  void _showCoursePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CoursePickerSheet(
        courses: _mappedCourses,
        onSelected: (course) => setState(() => _course = course),
      ),
    );
  }

  void _previewStudent() {
    if (_course == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourseDetailScreen(course: _course!)),
    );
  }

  void _showChecklist() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChecklistSheet(
        items: [
          ('Course selected', _course != null),
          (
            'Class & subject selected',
            _courseType == CourseType.skill || _subject.isNotEmpty,
          ),
          ('Lesson title added', _titleCtrl.text.trim().isNotEmpty),
          (
            'Video content added',
            _videoUrl != null || _videoUrlCtrl.text.trim().isNotEmpty,
          ),
          ('Status selected', _publishStatus.isNotEmpty),
          ('Description optional', true),
          ('Outcomes optional', true),
          ('Duration optional', true),
          ('Notes optional', true),
        ],
      ),
    );
  }

  String? _validationMessageForStep(int step) {
    return switch (step) {
      0 => _course == null ? 'Please select a course first.' : null,
      1 =>
        _titleCtrl.text.trim().isEmpty
            ? 'Please enter the lesson title.'
            : null,
      2 =>
        _uploadingVideo
            ? 'Please wait until the video upload finishes.'
            : _videoUrl == null && _videoUrlCtrl.text.trim().isEmpty
            ? 'Please upload a video or add a video URL.'
            : null,
      3 =>
        _uploadingPdf
            ? 'Please wait until the PDF notes upload finishes.'
            : null,
      _ => null,
    };
  }

  String? _firstBlockingMessage() {
    for (var step = 0; step <= 4; step += 1) {
      final message = _validationMessageForStep(step);
      if (message != null) return message;
    }
    return null;
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.softRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _showUploadSuccessDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    required _PickedUpload file,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (_) => _UploadSuccessDialog(
        title: title,
        message: message,
        icon: icon,
        color: color,
        file: file,
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final active = index <= current;
        return Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: active
                    ? const Color(0xFF216DF4)
                    : const Color(0xFFEFF4FA),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (index != 4)
                Expanded(
                  child: Container(
                    height: 1.5,
                    color: active
                        ? const Color(0xFFBBD4FF)
                        : const Color(0xFFDDE7F2),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _WizardSection extends StatelessWidget {
  const _WizardSection({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF216DF4),
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 24),
        for (final child in children) ...[child, const SizedBox(height: 16)],
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
        color: AppColors.ink,
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SegmentedChoice extends StatelessWidget {
  const _SegmentedChoice({
    required this.left,
    required this.right,
    required this.selectedLeft,
    required this.onLeft,
    required this.onRight,
  });

  final String left;
  final String right;
  final bool selectedLeft;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE7F2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SelectBox(
              label: left,
              selected: selectedLeft,
              onTap: onLeft,
            ),
          ),
          Expanded(
            child: _SelectBox(
              label: right,
              selected: !selectedLeft,
              onTap: onRight,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectBox extends StatelessWidget {
  const _SelectBox({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF3FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF216DF4) : AppColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE7F2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.prefixIcon,
    this.textInputAction,
    this.onEditingComplete,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onEditingComplete: onEditingComplete,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDDE7F2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDDE7F2)),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF216DF4)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF1D4F91),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadPreviewCard extends StatelessWidget {
  const _UploadPreviewCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onPick,
    this.onRemove,
    this.onRetry,
    this.isUploading = false,
    this.uploadProgress,
    this.hasError = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onPick;
  final VoidCallback? onRemove;
  final VoidCallback? onRetry;
  final bool isUploading;
  /// 0.0–1.0 when real progress is known; null for indeterminate.
  final double? uploadProgress;
  final bool hasError;

  bool get _hasFile => onRemove != null || isUploading || hasError;

  @override
  Widget build(BuildContext context) {
    // ── Uploading state ────────────────────────────────────────────────────────
    if (isUploading) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF216DF4).withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF216DF4).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.cloud_upload_rounded,
                      color: Color(0xFF216DF4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1D4F91),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          uploadProgress != null
                              ? '$subtitle  •  ${(uploadProgress! * 100).toInt()}%'
                              : '$subtitle  •  Uploading…',
                          style: const TextStyle(
                            color: Color(0xFF3B6EC8),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF216DF4),
                    ),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(13),
              ),
              child: LinearProgressIndicator(
                value: uploadProgress,
                minHeight: 8,
                backgroundColor: const Color(0xFF216DF4).withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF216DF4),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Error state ────────────────────────────────────────────────────────────
    if (hasError) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.softRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: AppColors.softRed),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Upload failed — check connection and retry',
                    style: TextStyle(
                      color: AppColors.softRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.softRed,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 20),
              color: AppColors.muted,
            ),
          ],
        ),
      );
    }

    // ── Empty (no file chosen) ─────────────────────────────────────────────────
    if (!_hasFile) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F9FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF216DF4).withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF216DF4)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF216DF4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.upload_rounded, size: 17, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Choose File',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Success (file uploaded) ────────────────────────────────────────────────
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF16A34A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onPick, child: const Text('Replace')),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 20),
            tooltip: 'Remove',
            color: AppColors.muted,
          ),
        ],
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.onRemove});

  final _PickedUpload file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _UploadPreviewCard(
      title: file.name,
      subtitle: file.sizeLabel,
      icon: file.resourceType == 'image'
          ? Icons.image_rounded
          : Icons.insert_drive_file_rounded,
      onPick: () {},
      onRemove: onRemove,
    );
  }
}

class _RadioCard extends StatelessWidget {
  const _RadioCard({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final String value;
  final String groupValue;
  final String title;
  final String subtitle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = groupValue == value;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF3FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE7F2)),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? const Color(0xFF216DF4) : AppColors.muted,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF216DF4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.values,
    required this.onSelected,
  });

  final String title;
  final List<String> values;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return _BottomSheetShell(
      title: title,
      child: Column(
        children: values
            .map(
              (value) => ListTile(
                title: Text(value),
                onTap: () {
                  onSelected(value);
                  Navigator.of(context).pop();
                },
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CoursePickerSheet extends StatelessWidget {
  const _CoursePickerSheet({required this.courses, required this.onSelected});

  final List<Course> courses;
  final ValueChanged<Course> onSelected;

  @override
  Widget build(BuildContext context) {
    return _BottomSheetShell(
      title: 'Select Course',
      child: courses.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(18),
              child: Text('No matching course found. Create a course first.'),
            )
          : Column(
              children: courses
                  .map(
                    (course) => ListTile(
                      leading: Icon(
                        course.icon,
                        color: const Color(0xFF216DF4),
                      ),
                      title: Text(course.title),
                      subtitle: Text(course.audienceLabel),
                      onTap: () {
                        onSelected(course);
                        Navigator.of(context).pop();
                      },
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _ChecklistSheet extends StatelessWidget {
  const _ChecklistSheet({required this.items});

  final List<(String, bool)> items;

  @override
  Widget build(BuildContext context) {
    final ready = items.every((item) => item.$2);
    return _BottomSheetShell(
      title: 'Lesson Checklist',
      child: Column(
        children: [
          Container(
            width: 118,
            height: 118,
            decoration: const BoxDecoration(
              color: Color(0xFFE1F7EA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_turned_in_rounded,
              color: AppColors.secondary,
              size: 64,
            ),
          ),
          const SizedBox(height: 18),
          ...items.map(
            (item) => ListTile(
              dense: true,
              leading: Icon(
                item.$2
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: item.$2 ? AppColors.secondary : AppColors.muted,
              ),
              title: Text(item.$1),
            ),
          ),
          const SizedBox(height: 12),
          _InfoPanel(
            text: ready
                ? 'You are ready to publish this lesson!'
                : 'Complete the missing required items before publishing.',
          ),
        ],
      ),
    );
  }
}

class _SuccessSheet extends StatelessWidget {
  const _SuccessSheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.lessonTitle,
    required this.courseName,
    required this.hasVideo,
    required this.hasPdf,
    required this.resourceCount,
    required this.onDone,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String lessonTitle;
  final String courseName;
  final bool hasVideo;
  final bool hasPdf;
  final int resourceCount;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final uploads = [
      if (hasVideo)
        (Icons.video_file_rounded, 'Video uploaded', const Color(0xFF216DF4)),
      if (hasPdf)
        (
          Icons.picture_as_pdf_rounded,
          'PDF notes uploaded',
          const Color(0xFFEA580C),
        ),
      if (resourceCount > 0)
        (
          Icons.attach_file_rounded,
          '$resourceCount resource${resourceCount > 1 ? 's' : ''} added',
          const Color(0xFF7F5AF0),
        ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 42),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F9FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lessonTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (courseName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.school_rounded,
                          size: 14,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            courseName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (uploads.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: uploads
                    .map(
                      (u) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: u.$3.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(u.$1, size: 15, color: u.$3),
                            const SizedBox(width: 6),
                            Text(
                              u.$2,
                              style: TextStyle(
                                color: u.$3,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onDone,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadSuccessDialog extends StatelessWidget {
  const _UploadSuccessDialog({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.file,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final _PickedUpload file;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, color: color, size: 44),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F9FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDDE7F2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          file.sizeLabel,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomSheetShell extends StatelessWidget {
  const _BottomSheetShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _PickedUpload {
  const _PickedUpload(
    this.name,
    this.bytes, {
    this.filePath,
    this.readStream,
    int? sizeBytes,
  }) : _sizeBytes = sizeBytes;

  final String name;
  final List<int> bytes;

  /// File system path — available on mobile/desktop (cache path on Android).
  /// Used as fallback when [readStream] has already been consumed (retry).
  final String? filePath;

  /// Immediately-opened stream from file_picker's withReadStream:true.
  /// The file descriptor stays alive even if Android later cleans the cache,
  /// so this is preferred over [filePath] for first-attempt uploads.
  final Stream<List<int>>? readStream;

  final int? _sizeBytes;
  int get fileSize => _sizeBytes ?? bytes.length;

  String get sizeLabel {
    final size = _sizeBytes ?? bytes.length;
    final kb = size / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  String get extension {
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot + 1).toLowerCase();
  }

  String get resourceType {
    if (extension == 'pdf') return 'pdf_notes';
    if (['png', 'jpg', 'jpeg', 'webp'].contains(extension)) return 'image';
    if (extension == 'zip') return 'zip';
    if (['py', 'js', 'dart', 'html', 'css', 'json'].contains(extension)) {
      return 'code_file';
    }
    return 'note';
  }
}
