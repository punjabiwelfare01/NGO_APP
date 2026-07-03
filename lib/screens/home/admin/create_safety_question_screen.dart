import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/safety_awareness.dart';
import '../../../repositories/safety_awareness_repository.dart';

class CreateSafetyQuestionScreen extends StatefulWidget {
  const CreateSafetyQuestionScreen({this.existing, super.key});

  final SafetyQuestionAdmin? existing;

  @override
  State<CreateSafetyQuestionScreen> createState() =>
      _CreateSafetyQuestionScreenState();
}

class _CreateSafetyQuestionScreenState
    extends State<CreateSafetyQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _questionCtrl;
  late final TextEditingController _optionACtrl;
  late final TextEditingController _optionBCtrl;
  late final TextEditingController _optionCCtrl;
  late final TextEditingController _explanationCtrl;
  late final TextEditingController _categoryCtrl;
  String _correctOption = 'a';
  bool _isActive = true;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _questionCtrl = TextEditingController(text: e?.questionText ?? '');
    _optionACtrl = TextEditingController(text: e?.optionA ?? '');
    _optionBCtrl = TextEditingController(text: e?.optionB ?? '');
    _optionCCtrl = TextEditingController(text: e?.optionC ?? '');
    _explanationCtrl = TextEditingController(text: e?.explanation ?? '');
    _categoryCtrl = TextEditingController(text: e?.category ?? 'general');
    _correctOption = e?.correctOption ?? 'a';
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _optionACtrl.dispose();
    _optionBCtrl.dispose();
    _optionCCtrl.dispose();
    _explanationCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await SafetyAwarenessRepository.updateQuestion(
          widget.existing!.id,
          {
            'question_text': _questionCtrl.text.trim(),
            'option_a': _optionACtrl.text.trim(),
            'option_b': _optionBCtrl.text.trim(),
            'option_c': _optionCCtrl.text.trim(),
            'correct_option': _correctOption,
            'explanation': _explanationCtrl.text.trim(),
            'category': _categoryCtrl.text.trim(),
            'is_active': _isActive,
          },
        );
      } else {
        await SafetyAwarenessRepository.createQuestion(
          questionText: _questionCtrl.text.trim(),
          optionA: _optionACtrl.text.trim(),
          optionB: _optionBCtrl.text.trim(),
          optionC: _optionCCtrl.text.trim(),
          correctOption: _correctOption,
          explanation: _explanationCtrl.text.trim(),
          category: _categoryCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to save question.'),
        backgroundColor: AppColors.softRed,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
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
          _isEdit ? 'Edit Question' : 'New Question',
          style: const TextStyle(
              fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEdit ? 'Update' : 'Create'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(
                controller: _questionCtrl,
                label: 'Question / Scenario',
                hint: 'Your online friend asks for private photos.',
                maxLines: 3,
                required: true,
              ),
              const SizedBox(height: 16),
              const _SectionLabel('Options'),
              const SizedBox(height: 8),
              _OptionField(
                controller: _optionACtrl,
                optionKey: 'a',
                selectedCorrect: _correctOption,
                onSelectCorrect: (v) => setState(() => _correctOption = v),
              ),
              const SizedBox(height: 10),
              _OptionField(
                controller: _optionBCtrl,
                optionKey: 'b',
                selectedCorrect: _correctOption,
                onSelectCorrect: (v) => setState(() => _correctOption = v),
              ),
              const SizedBox(height: 10),
              _OptionField(
                controller: _optionCCtrl,
                optionKey: 'c',
                selectedCorrect: _correctOption,
                onSelectCorrect: (v) => setState(() => _correctOption = v),
              ),
              const SizedBox(height: 16),
              _field(
                controller: _explanationCtrl,
                label: 'Explanation',
                hint: 'Best choice: tell a trusted adult.',
                maxLines: 3,
                required: true,
              ),
              const SizedBox(height: 16),
              _field(
                controller: _categoryCtrl,
                label: 'Category',
                hint: 'e.g. online_safety, bullying, privacy',
              ),
              const SizedBox(height: 16),
              if (_isEdit) ...[
                const _SectionLabel('Visibility'),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: const Text('Active',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink)),
                  subtitle: const Text(
                      'Inactive questions are hidden from students.',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.muted)),
                  activeThumbColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }
}

class _OptionField extends StatelessWidget {
  const _OptionField({
    required this.controller,
    required this.optionKey,
    required this.selectedCorrect,
    required this.onSelectCorrect,
  });

  final TextEditingController controller;
  final String optionKey;
  final String selectedCorrect;
  final ValueChanged<String> onSelectCorrect;

  @override
  Widget build(BuildContext context) {
    final isCorrect = selectedCorrect == optionKey;
    return Row(
      children: [
        GestureDetector(
          onTap: () => onSelectCorrect(optionKey),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCorrect
                  ? AppColors.secondary
                  : AppColors.muted.withValues(alpha: 0.15),
              border: Border.all(
                color: isCorrect
                    ? AppColors.secondary
                    : AppColors.muted.withValues(alpha: 0.4),
              ),
            ),
            child: Center(
              child: Text(
                optionKey.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isCorrect ? Colors.white : AppColors.muted,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            textInputAction: TextInputAction.next,
            onEditingComplete: () => FocusScope.of(context).nextFocus(),
            decoration: InputDecoration(
              labelText: 'Option ${optionKey.toUpperCase()}',
              border: const OutlineInputBorder(),
              suffixIcon: isCorrect
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.secondary)
                  : null,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
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
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
