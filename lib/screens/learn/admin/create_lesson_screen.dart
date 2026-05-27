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
  final _contentTextCtrl = TextEditingController();
  final _contentUrlCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();

  String _contentType = 'text';
  bool _isPublished = true;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _contentTextCtrl.dispose();
    _contentUrlCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final lesson = await CourseRepository.createLesson(
        widget.courseId,
        title: _titleCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        contentType: _contentType,
        contentUrl: _contentType == 'video' &&
                _contentUrlCtrl.text.trim().isNotEmpty
            ? _contentUrlCtrl.text.trim()
            : null,
        contentText: _contentType == 'text' &&
                _contentTextCtrl.text.trim().isNotEmpty
            ? _contentTextCtrl.text.trim()
            : null,
        order: widget.nextOrder,
        durationMinutes: int.tryParse(_durationCtrl.text.trim()),
        isPublished: _isPublished,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8)),
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
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
            // Title
            _SectionLabel('Title'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleCtrl,
              decoration: _inputDecoration('e.g. Introduction to Variables'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 20),

            // Description (optional)
            _SectionLabel('Description (optional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descCtrl,
              decoration: _inputDecoration('Short description of this lesson'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Content type
            _SectionLabel('Content Type'),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeToggle(
                  icon: Icons.article_outlined,
                  label: 'Text',
                  selected: _contentType == 'text',
                  onTap: () => setState(() => _contentType = 'text'),
                ),
                const SizedBox(width: 12),
                _TypeToggle(
                  icon: Icons.play_circle_outline_rounded,
                  label: 'Video',
                  selected: _contentType == 'video',
                  onTap: () => setState(() => _contentType = 'video'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Content field
            if (_contentType == 'text') ...[
              _SectionLabel('Lesson Content'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _contentTextCtrl,
                decoration: _inputDecoration(
                    'Write the lesson content here…'),
                maxLines: 10,
                minLines: 5,
              ),
            ] else ...[
              _SectionLabel('Video URL'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _contentUrlCtrl,
                decoration:
                    _inputDecoration('https://youtube.com/watch?v=...'),
                keyboardType: TextInputType.url,
              ),
            ],
            const SizedBox(height: 20),

            // Duration
            _SectionLabel('Duration (minutes, optional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _durationCtrl,
              decoration: _inputDecoration('e.g. 15'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Publish toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.muted.withValues(alpha: 0.15)),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Publish immediately',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink),
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
        hintStyle:
            const TextStyle(color: AppColors.muted, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppColors.muted.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppColors.muted.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
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

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.white,
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.muted.withValues(alpha: 0.2),
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? AppColors.primary : AppColors.muted,
                  size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
