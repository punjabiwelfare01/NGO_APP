import 'package:flutter/material.dart';

import '../../../../../core/colors.dart';
import '../../../../../repositories/api_client.dart';
import '../../../../../repositories/quiz_repository.dart';
import '../../../../../widgets/app_card.dart';
import '../../../../../widgets/app_scroll_view.dart';
import '../../../../../widgets/top_header.dart';

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({
    this.initialTitle,
    this.headerTitle = 'Create Quiz',
    this.headerSubtitle = 'Add details, questions, answers, and XP.',
    super.key,
  });

  final String? initialTitle;
  final String headerTitle;
  final String headerSubtitle;

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  static const _minQuestionCount = 3;

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _category = TextEditingController(text: 'Cyber Safety');
  final _xpReward = TextEditingController(text: '80');
  final _timeLimit = TextEditingController(text: '240');
  final List<_QuestionDraft> _questions = List.generate(
    _minQuestionCount,
    (_) => _QuestionDraft(),
  );

  String _difficulty = 'easy';
  bool _setAsDaily = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initialTitle = widget.initialTitle?.trim();
    if (initialTitle != null && initialTitle.isNotEmpty) {
      _title.text = initialTitle;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _category.dispose();
    _xpReward.dispose();
    _timeLimit.dispose();
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() => _questions.add(_QuestionDraft()));
  }

  void _removeQuestion(int index) {
    if (_questions.length <= _minQuestionCount) return;
    final removed = _questions.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_questions.length < _minQuestionCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 3 questions.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final quiz = await QuizRepository.createQuiz(
        title: _title.text.trim(),
        description: _description.text.trim(),
        category: _category.text.trim(),
        difficulty: _difficulty,
        xpReward: int.parse(_xpReward.text.trim()),
        timeLimitSeconds: int.parse(_timeLimit.text.trim()),
      );

      for (var i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        await QuizRepository.addQuestion(
          quizId: quiz.id,
          text: question.text.text.trim(),
          options: question.options.map((c) => c.text.trim()).toList(),
          correctIndex: question.correctIndex,
          explanation: question.explanation.text.trim(),
          points: int.parse(question.points.text.trim()),
          orderIndex: i,
        );
      }

      if (_setAsDaily) {
        await QuizRepository.setDailyChallenge(
          quizId: quiz.id,
          date: DateTime.now(),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz created successfully.')),
      );
      Navigator.of(
        context,
      ).pop(quiz.copyWith(questionCount: _questions.length));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_createErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _positiveInt(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null || number <= 0) return 'Enter a valid number';
    return null;
  }

  String? _timeLimitValidator(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null) return 'Enter seconds';
    if (number < 30) return 'Minimum 30 seconds';
    return null;
  }

  String _createErrorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 422) {
        return 'Check quiz details: time limit must be at least 30 seconds.';
      }
      if (error.statusCode == 403) {
        return 'Only admin, mentor, or content creator accounts can create quizzes.';
      }
      return 'Could not create quiz: ${error.statusCode}';
    }
    return 'Could not create quiz.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: AppScrollView(
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Back',
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ],
              ),
              TopHeader(
                title: widget.headerTitle,
                subtitle: widget.headerSubtitle,
                actionIcon: Icons.add_task_rounded,
              ),
              AppCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _title,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Quiz title',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _category,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _difficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                        prefixIcon: Icon(Icons.speed_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'easy', child: Text('Easy')),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(value: 'hard', child: Text('Hard')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _difficulty = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _xpReward,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            onEditingComplete: () =>
                                FocusScope.of(context).nextFocus(),
                            decoration: const InputDecoration(
                              labelText: 'XP',
                              prefixIcon: Icon(Icons.star_rounded),
                            ),
                            validator: _positiveInt,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _timeLimit,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            onEditingComplete: () =>
                                FocusScope.of(context).nextFocus(),
                            decoration: const InputDecoration(
                              labelText: 'Seconds',
                              prefixIcon: Icon(Icons.timer_rounded),
                            ),
                            validator: _timeLimitValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _setAsDaily,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Set as today’s daily challenge'),
                      onChanged: (value) =>
                          setState(() => _setAsDaily = value ?? false),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Questions',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${_questions.length}/$_minQuestionCount required',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add'),
                  ),
                ],
              ),
              ...List.generate(
                _questions.length,
                (index) => _QuestionEditor(
                  index: index,
                  draft: _questions[index],
                  canRemove: _questions.length > _minQuestionCount,
                  onRemove: () => _removeQuestion(index),
                  requiredValidator: _required,
                  numberValidator: _positiveInt,
                  isLastQuestion: index == _questions.length - 1,
                ),
              ),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Saving...' : 'Save Quiz'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionEditor extends StatelessWidget {
  const _QuestionEditor({
    required this.index,
    required this.draft,
    required this.canRemove,
    required this.onRemove,
    required this.requiredValidator,
    required this.numberValidator,
    required this.isLastQuestion,
  });

  final int index;
  final _QuestionDraft draft;
  final bool canRemove;
  final VoidCallback onRemove;
  final FormFieldValidator<String> requiredValidator;
  final FormFieldValidator<String> numberValidator;
  final bool isLastQuestion;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Question ${index + 1}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove question',
                onPressed: canRemove ? onRemove : null,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          TextFormField(
            controller: draft.text,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Question text',
              prefixIcon: Icon(Icons.help_outline_rounded),
            ),
            validator: requiredValidator,
          ),
          const SizedBox(height: 12),
          ...List.generate(
            draft.options.length,
            (optionIndex) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextFormField(
                controller: draft.options[optionIndex],
                textInputAction: TextInputAction.next,
                onEditingComplete: () =>
                    FocusScope.of(context).nextFocus(),
                decoration: InputDecoration(
                  labelText: 'Option ${optionIndex + 1}',
                  prefixIcon: const Icon(Icons.list_alt_rounded),
                ),
                validator: requiredValidator,
              ),
            ),
          ),
          _CorrectAnswerPicker(draft: draft),
          const SizedBox(height: 12),
          TextFormField(
            controller: draft.explanation,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Explanation',
              prefixIcon: Icon(Icons.lightbulb_outline_rounded),
            ),
            validator: requiredValidator,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: draft.points,
            keyboardType: TextInputType.number,
            textInputAction:
                isLastQuestion ? TextInputAction.done : TextInputAction.next,
            onEditingComplete: isLastQuestion
                ? null
                : () => FocusScope.of(context).nextFocus(),
            decoration: const InputDecoration(
              labelText: 'Points',
              prefixIcon: Icon(Icons.control_point_rounded),
            ),
            validator: numberValidator,
          ),
        ],
      ),
    );
  }
}

class _CorrectAnswerPicker extends StatefulWidget {
  const _CorrectAnswerPicker({required this.draft});

  final _QuestionDraft draft;

  @override
  State<_CorrectAnswerPicker> createState() => _CorrectAnswerPickerState();
}

class _CorrectAnswerPickerState extends State<_CorrectAnswerPicker> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: List.generate(
        widget.draft.options.length,
        (index) => ChoiceChip(
          label: Text('Correct ${index + 1}'),
          selected: widget.draft.correctIndex == index,
          onSelected: (_) {
            setState(() => widget.draft.correctIndex = index);
          },
        ),
      ),
    );
  }
}

class _QuestionDraft {
  final text = TextEditingController();
  final options = List.generate(4, (_) => TextEditingController());
  final explanation = TextEditingController();
  final points = TextEditingController(text: '10');
  int correctIndex = 0;

  void dispose() {
    text.dispose();
    explanation.dispose();
    points.dispose();
    for (final option in options) {
      option.dispose();
    }
  }
}
