import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../../core/colors.dart';
import '../../../models/course.dart';
import '../../../repositories/course_repository.dart';

class CreateFreeCourseScreen extends StatefulWidget {
  const CreateFreeCourseScreen({this.initialCourse, super.key});
  final Course? initialCourse;

  @override
  State<CreateFreeCourseScreen> createState() => _CreateFreeCourseScreenState();
}

class _CreateFreeCourseScreenState extends State<CreateFreeCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _duration;
  late final TextEditingController _audience;
  late final TextEditingController _language;
  late final TextEditingController _creator;
  String _category = 'NDA';
  String _level = 'Beginner';
  String _status = 'Published';
  final List<_SubjectDraft> _subjects = [];
  bool _hasNotes = true;
  bool _hasQuiz = true;
  bool _saving = false;
  String? _thumbnailName;
  String? _thumbnailUrl;

  @override
  void initState() {
    super.initState();
    final course = widget.initialCourse;
    _title = TextEditingController(text: course?.title ?? '');
    _description = TextEditingController(text: course?.courseDescription ?? '');
    _duration = TextEditingController(text: course?.duration ?? '');
    _audience = TextEditingController(
      text: course?.targetAudience ?? 'Students',
    );
    _language = TextEditingController(
      text: course?.language ?? 'Hindi / English',
    );
    _creator = TextEditingController(
      text: course?.createdBy ?? _defaultCreator(),
    );
    _category = course?.freeCategory ?? 'NDA';
    _level = course?.level ?? 'Beginner';
    _status = course == null || course.isPublished ? 'Published' : 'Draft';
    _hasNotes = course?.hasNotes ?? true;
    _hasQuiz = course?.hasQuiz ?? true;
    _thumbnailUrl = course?.thumbnailUrl;
    for (final subject in course?.subjects ?? const <String>[]) {
      _subjects.add(_SubjectDraft(name: subject));
    }
    if (_subjects.isEmpty) _subjects.add(_SubjectDraft());
  }

  String _defaultCreator() {
    if (AppState.role.isMentor) return 'Mentor';
    if (AppState.role.isContentCreator) return 'Content Creator';
    return 'NGO Team';
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _description,
      _duration,
      _audience,
      _language,
      _creator,
    ]) {
      controller.dispose();
    }
    for (final subject in _subjects) {
      subject.dispose();
    }
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null) return;
    final file = result.files.single;
    setState(() => _thumbnailName = file.name);
    if (file.bytes != null) {
      try {
        _thumbnailUrl = await CourseRepository.uploadFile(
          bytes: file.bytes!,
          fileName: file.name,
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Thumbnail selected. Upload will retry when saving.',
              ),
            ),
          );
        }
      }
    }
  }

  void _addSubject() => setState(() => _subjects.add(_SubjectDraft()));

  void _removeSubject(int index) => setState(() {
    _subjects[index].dispose();
    _subjects.removeAt(index);
  });

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final subjectNames = _subjects
        .map((s) => s.name.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final tags = <String>[
      'creator:${_creator.text.trim()}',
      'audience:${_audience.text.trim()}',
      'language:${_language.text.trim()}',
      for (final subject in subjectNames) 'subject:$subject',
      for (final subject in _subjects)
        for (final chapter in subject.chapters)
          if (chapter.text.trim().isNotEmpty)
            'chapter:${subject.name.text.trim()}|${chapter.text.trim()}',
      if (_thumbnailUrl != null) 'thumbnail:$_thumbnailUrl',
      if (_hasNotes) 'notes',
      if (_hasQuiz) 'quiz',
      if (_status == 'Archived') 'archived',
    ];
    final learnItems = _subjects
        .expand(
          (subject) => subject.chapters
              .where((chapter) => chapter.text.trim().isNotEmpty)
              .map(
                (chapter) =>
                    '${subject.name.text.trim()}: ${chapter.text.trim()}',
              ),
        )
        .toList();
    try {
      final existing = widget.initialCourse;
      final Course saved;
      if (existing == null) {
        saved = await CourseRepository.createCourse(
          title: _title.text.trim(),
          duration: _duration.text.trim(),
          level: _level,
          iconName: _iconForCategory(_category),
          colorHex: _colorForCategory(_category),
          courseType: CourseType.skill,
          skillCategory: _category,
          isPublished: _status == 'Published',
          courseDescription: _description.text.trim(),
          skillTags: tags,
          learnItems: learnItems,
        );
      } else {
        saved = await CourseRepository.updateCourse(
          existing.id,
          title: _title.text.trim(),
          duration: _duration.text.trim(),
          level: _level,
          iconName: existing.iconName,
          colorHex: existing.colorHex,
          categoryId: existing.categoryId,
          courseType: CourseType.skill,
          skillCategory: _category,
          isPublished: _status == 'Published',
          courseDescription: _description.text.trim(),
          skillTags: tags,
          learnItems: learnItems,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, saved);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the free course.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: Text(
        widget.initialCourse == null
            ? 'Create Free Course'
            : 'Edit Free Course',
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _intro(),
          _field(_title, 'Course title', 'e.g. NDA Exam Full Course'),
          _dropdown(
            'Course category',
            _category,
            freeCourseCategories.where((item) => item != 'All').toList(),
            (value) => setState(() => _category = value),
          ),
          _field(
            _description,
            'Short description',
            'What will students learn?',
            lines: 3,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: OutlinedButton.icon(
              onPressed: _pickThumbnail,
              icon: const Icon(Icons.image_outlined),
              label: Text(
                _thumbnailName ??
                    (_thumbnailUrl == null
                        ? 'Upload course thumbnail'
                        : 'Thumbnail uploaded'),
              ),
            ),
          ),
          _field(_creator, 'Created by', 'Content Creator / Mentor / NGO Team'),
          _field(
            _audience,
            'Target audience',
            'e.g. NDA aspirants, all students',
          ),
          _field(_duration, 'Estimated duration', 'e.g. 12 hours'),
          _field(_language, 'Course language', 'e.g. Punjabi, Hindi, English'),
          _dropdown('Course level', _level, const [
            'Beginner',
            'Intermediate',
            'Advanced',
          ], (value) => setState(() => _level = value)),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Subjects & Chapters',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _addSubject,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Subject'),
              ),
            ],
          ),
          const Text(
            'Organise the course first; lessons, videos, notes and quizzes are added inside these chapters.',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < _subjects.length; i++) _subjectEditor(i),
          SwitchListTile.adaptive(
            value: _hasNotes,
            onChanged: (v) => setState(() => _hasNotes = v),
            title: const Text('Notes PDF included'),
            secondary: const Icon(Icons.picture_as_pdf_outlined),
          ),
          SwitchListTile.adaptive(
            value: _hasQuiz,
            onChanged: (v) => setState(() => _hasQuiz = v),
            title: const Text('Quiz / practice test included'),
            secondary: const Icon(Icons.quiz_outlined),
          ),
          _dropdown('Publish status', _status, const [
            'Draft',
            'Published',
            'Archived',
          ], (value) => setState(() => _status = value)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(
              _status == 'Published'
                  ? 'Save & Publish Free Course'
                  : 'Save Free Course',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _intro() => Container(
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(15),
    ),
    child: const Row(
      children: [
        Icon(Icons.volunteer_activism_rounded, color: Color(0xFF2E7D32)),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'One unified flow for NGO, mentor and content-creator courses. Every published course is free for students.',
            style: TextStyle(
              color: Color(0xFF1B5E20),
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _subjectEditor(int index) {
    final subject = _subjects[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primary.withValues(alpha: .15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: subject.name,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Subject name required'
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    hintText: 'e.g. Mathematics',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              if (_subjects.length > 1)
                IconButton(
                  onPressed: () => _removeSubject(index),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.softRed,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (var j = 0; j < subject.chapters.length; j++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: subject.chapters[j],
                      textInputAction:
                          (index == _subjects.length - 1 &&
                              j == subject.chapters.length - 1)
                          ? TextInputAction.done
                          : TextInputAction.next,
                      onEditingComplete:
                          (index == _subjects.length - 1 &&
                              j == subject.chapters.length - 1)
                          ? null
                          : () => FocusScope.of(context).nextFocus(),
                      decoration: InputDecoration(
                        labelText: 'Chapter ${j + 1}',
                        hintText: 'e.g. Algebra',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      subject.chapters[j].dispose();
                      subject.chapters.removeAt(j);
                    }),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => subject.chapters.add(TextEditingController())),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Chapter'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: TextFormField(
      controller: controller,
      maxLines: lines,
      textInputAction: lines <= 1 ? TextInputAction.next : null,
      onEditingComplete: lines <= 1
          ? () => FocusScope.of(context).nextFocus()
          : null,
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  Widget _dropdown(
    String label,
    String value,
    List<String> values,
    ValueChanged<String> changed,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: values
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (item) {
        if (item != null) changed(item);
      },
    ),
  );

  String _iconForCategory(String category) => switch (category) {
    'NDA' => 'military_tech_rounded',
    'Government Exams' => 'account_balance_rounded',
    'Career Guidance' => 'trending_up_rounded',
    'Spoken English' => 'record_voice_over_rounded',
    'Computer Basics' => 'computer_rounded',
    'Volunteer Training' => 'volunteer_activism_rounded',
    _ => 'shield_rounded',
  };
  String _colorForCategory(String category) => switch (category) {
    'NDA' => '#DDEEFF',
    'Government Exams' => '#E8E1FF',
    'Career Guidance' => '#E0F8E8',
    'Spoken English' => '#FFF0D8',
    'Computer Basics' => '#DDF5FF',
    'Volunteer Training' => '#E8F5E9',
    _ => '#FFF3E0',
  };
}

class _SubjectDraft {
  _SubjectDraft({String name = ''}) : name = TextEditingController(text: name);
  final TextEditingController name;
  final List<TextEditingController> chapters = [TextEditingController()];
  void dispose() {
    name.dispose();
    for (final chapter in chapters) {
      chapter.dispose();
    }
  }
}
