import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/course.dart';
import '../../../models/skill_category.dart';
import '../../../repositories/course_repository.dart';
import '../../../utils/icon_mapper.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({this.initialCourse, super.key});

  final Course? initialCourse;

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();

  String _level = 'Beginner';
  String _iconName = 'code_rounded';
  String _colorHex = '#DDF1FF';
  int? _categoryId;

  List<SkillCategory> _categories = [];
  bool _saving = false;

  static const _levels = ['Beginner', 'Intermediate', 'Advanced'];

  static const _iconOptions = <String, IconData>{
    'code_rounded': Icons.code_rounded,
    'devices_rounded': Icons.devices_rounded,
    'shield_rounded': Icons.shield_rounded,
    'record_voice_over_rounded': Icons.record_voice_over_rounded,
    'account_balance_wallet_rounded': Icons.account_balance_wallet_rounded,
    'palette_rounded': Icons.palette_rounded,
    'music_note_rounded': Icons.music_note_rounded,
    'language_rounded': Icons.language_rounded,
    'campaign_rounded': Icons.campaign_rounded,
    'security_rounded': Icons.security_rounded,
    'bolt_rounded': Icons.bolt_rounded,
    'psychology_rounded': Icons.psychology_rounded,
    'explore_rounded': Icons.explore_rounded,
    'brush_rounded': Icons.brush_rounded,
  };

  static const _colorOptions = [
    '#DDF1FF',
    '#FFE7C8',
    '#E0F8E8',
    '#F5E0FF',
    '#FFF3D0',
    '#D0EDFF',
    '#FFE0E0',
    '#E0FFE0',
  ];

  @override
  void initState() {
    super.initState();
    final course = widget.initialCourse;
    if (course != null) {
      _titleCtrl.text = course.title;
      _durationCtrl.text = course.duration;
      _level = course.level;
      _iconName = course.iconName;
      _colorHex = course.colorHex;
      _categoryId = course.categoryId;
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await CourseRepository.getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final initial = widget.initialCourse;
      final title = _titleCtrl.text.trim();
      final duration = _durationCtrl.text.trim().isEmpty
          ? '1h'
          : _durationCtrl.text.trim();
      final course = initial == null
          ? await CourseRepository.createCourse(
              title: title,
              duration: duration,
              level: _level,
              iconName: _iconName,
              colorHex: _colorHex,
              categoryId: _categoryId,
            )
          : await CourseRepository.updateCourse(
              initial.id,
              title: title,
              duration: duration,
              level: _level,
              iconName: _iconName,
              colorHex: _colorHex,
              categoryId: _categoryId,
            );
      if (mounted) Navigator.of(context).pop(course);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not create course. Please try again.'),
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
        title: Text(
          widget.initialCourse == null ? 'New Course' : 'Edit Course',
          style: const TextStyle(
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
                  : Text(widget.initialCourse == null ? 'Create' : 'Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Preview card
            _PreviewCard(
              title: _titleCtrl.text.isEmpty ? 'Course Title' : _titleCtrl.text,
              level: _level,
              duration: _durationCtrl.text.isEmpty ? '1h' : _durationCtrl.text,
              iconName: _iconName,
              colorHex: _colorHex,
            ),
            const SizedBox(height: 24),

            // Title
            _Label('Title'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleCtrl,
              decoration: _deco('e.g. Web Development Basics'),
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 20),

            // Duration
            _Label('Duration (e.g. 2h 30m)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _durationCtrl,
              decoration: _deco('e.g. 2h 30m'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            // Level
            _Label('Level'),
            const SizedBox(height: 8),
            Row(
              children: _levels
                  .map(
                    (l) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: l != _levels.last ? 8 : 0,
                        ),
                        child: _SelectChip(
                          label: l,
                          selected: _level == l,
                          onTap: () => setState(() => _level = l),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),

            // Category (optional)
            if (_categories.isNotEmpty) ...[
              _Label('Category (optional)'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SelectChip(
                    label: 'None',
                    selected: _categoryId == null,
                    onTap: () => setState(() => _categoryId = null),
                  ),
                  ..._categories.map(
                    (c) => _SelectChip(
                      label: c.title,
                      selected: _categoryId == c.id,
                      onTap: () => setState(() => _categoryId = c.id),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Icon picker
            _Label('Icon'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _iconOptions.entries.map((e) {
                final selected = _iconName == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _iconName = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : Colors.white,
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.muted.withValues(alpha: 0.2),
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      e.value,
                      size: 26,
                      color: selected ? AppColors.primary : AppColors.muted,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Color picker
            _Label('Color'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colorOptions.map((hex) {
                final selected = _colorHex == hex;
                final color = IconMapper.colorFromHex(hex);
                return GestureDetector(
                  onTap: () => setState(() => _colorHex = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.muted.withValues(alpha: 0.3),
                        width: selected ? 3 : 1,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: AppColors.ink,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  InputDecoration _deco(String hint) => InputDecoration(
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

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
  );
}

class _SelectChip extends StatelessWidget {
  const _SelectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.title,
    required this.level,
    required this.duration,
    required this.iconName,
    required this.colorHex,
  });

  final String title;
  final String level;
  final String duration;
  final String iconName;
  final String colorHex;

  @override
  Widget build(BuildContext context) {
    final color = IconMapper.colorFromHex(colorHex);
    final icon = IconMapper.fromName(iconName);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 30, color: AppColors.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$duration · $level',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
