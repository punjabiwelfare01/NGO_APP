import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/course.dart';
import '../../models/creator_content.dart';
import '../../models/creator_post.dart';
import '../../models/event_models.dart';
import '../../models/quiz_models.dart';
import '../../repositories/course_repository.dart';
import '../../repositories/creator_repository.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    this.courses = const [],
    this.events = const [],
    this.quizzes = const [],
    super.key,
  });

  final List<Course> courses;
  final List<EventModel> events;
  final List<QuizSummary> quizzes;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  CreatorPostType _postType = CreatorPostType.learningPost;
  String _category = creatorPostCategories.first;
  CreatorPostVisibility _visibility = CreatorPostVisibility.allStudents;
  CreatorPostStatus _status = CreatorPostStatus.draft;
  _AttachmentOption? _attachment;
  _PickedUpload? _banner;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  List<_AttachmentOption> get _attachments => [
    for (final course in widget.courses)
      _AttachmentOption('course', course.id, course.title),
    for (final event in widget.events)
      _AttachmentOption('event', event.id, event.title),
    for (final quiz in widget.quizzes)
      _AttachmentOption('quiz', quiz.id, quiz.title),
  ];

  Future<void> _pickBanner() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return;
    setState(() => _banner = _PickedUpload(file!.name, file.bytes!.toList()));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final imageUrl = _banner == null
          ? null
          : await CourseRepository.uploadFile(
              bytes: _banner!.bytes,
              fileName: _banner!.name,
            );

      final post = await CreatorRepository.createPost(
        CreatorPostDraft(
          postType: _postType,
          title: _titleCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
          category: _category,
          visibility: _visibility,
          status: _status,
          imageUrl: imageUrl,
          attachedCourseId: _attachment?.type == 'course'
              ? _attachment!.id
              : null,
          attachedEventId: _attachment?.type == 'event'
              ? _attachment!.id
              : null,
          attachedQuizId: _attachment?.type == 'quiz' ? _attachment!.id : null,
        ),
      );
      if (mounted) Navigator.of(context).pop<CreatorContentItem>(post);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not create post. Please try again.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachments = _attachments;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: const Text(
          'Create Post',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
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
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            _FormCard(
              children: [
                _FieldLabel('Post Type'),
                DropdownButtonFormField<CreatorPostType>(
                  initialValue: _postType,
                  decoration: _inputDecoration(),
                  items: CreatorPostType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(
                    () => _postType = value ?? CreatorPostType.learningPost,
                  ),
                ),
                const SizedBox(height: 16),
                _FieldLabel('Title'),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: _inputDecoration(hint: 'Post title'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 16),
                _FieldLabel('Description'),
                TextFormField(
                  controller: _descriptionCtrl,
                  minLines: 4,
                  maxLines: 7,
                  decoration: _inputDecoration(hint: 'Write the post details'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: 16),
                _FieldLabel('Category'),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: _inputDecoration(),
                  items: creatorPostCategories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _category = value ?? _category),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FormCard(
              children: [
                _FieldLabel('Upload Image / Banner'),
                OutlinedButton.icon(
                  onPressed: _pickBanner,
                  icon: const Icon(Icons.image_rounded),
                  label: Text(_banner?.name ?? 'Choose banner'),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _FieldLabel('Attach Course / Event / Quiz'),
                DropdownButtonFormField<_AttachmentOption>(
                  initialValue: _attachment,
                  decoration: _inputDecoration(hint: 'Optional attachment'),
                  items: attachments
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text('${item.label} (${item.typeLabel})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _attachment = value),
                ),
                const SizedBox(height: 16),
                _FieldLabel('Visibility'),
                DropdownButtonFormField<CreatorPostVisibility>(
                  initialValue: _visibility,
                  decoration: _inputDecoration(),
                  items: CreatorPostVisibility.values
                      .map(
                        (visibility) => DropdownMenuItem(
                          value: visibility,
                          child: Text(visibility.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(
                    () => _visibility =
                        value ?? CreatorPostVisibility.allStudents,
                  ),
                ),
                const SizedBox(height: 16),
                _FieldLabel('Status'),
                DropdownButtonFormField<CreatorPostStatus>(
                  initialValue: _status,
                  decoration: _inputDecoration(),
                  items: CreatorPostStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(
                    () => _status = value ?? CreatorPostStatus.draft,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.10)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.10)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
    ),
  );
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AttachmentOption {
  const _AttachmentOption(this.type, this.id, this.label);

  final String type;
  final int id;
  final String label;

  String get typeLabel => switch (type) {
    'course' => 'Course',
    'event' => 'Event',
    _ => 'Quiz',
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _AttachmentOption && other.type == type && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);
}

class _PickedUpload {
  const _PickedUpload(this.name, this.bytes);

  final String name;
  final List<int> bytes;
}
