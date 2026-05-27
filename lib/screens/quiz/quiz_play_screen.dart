import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/quiz_models.dart';
import '../../viewmodels/quiz_play_viewmodel.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scroll_view.dart';
import '../../widgets/top_header.dart';
import 'quiz_result_screen.dart';

class QuizPlayScreen extends StatefulWidget {
  const QuizPlayScreen({required this.quizId, super.key});

  final int quizId;

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  late final QuizPlayViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = QuizPlayViewModel(widget.quizId);
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _vm,
          builder: (context, _) {
            if (_vm.state == ViewState.loading && _vm.quiz == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_vm.state == ViewState.error && _vm.quiz == null) {
              return _ErrorView(message: _vm.errorMessage!, onRetry: _vm.load);
            }
            final quiz = _vm.quiz!;
            if (quiz.questions.isEmpty) {
              return _EmptyQuizView(quizTitle: quiz.title);
            }
            final question = quiz.questions[_vm.currentIndex];
            return AppScrollView(
              children: [
                TopHeader(
                  title: quiz.title,
                  subtitle:
                      'Question ${_vm.currentIndex + 1} of ${quiz.questions.length}',
                  actionIcon: Icons.quiz_rounded,
                ),
                LinearProgressIndicator(
                  value: _vm.progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.text,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...List.generate(
                        question.options.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _OptionTile(
                            label: question.options[index],
                            selected: _vm.selectedIndex == index,
                            onTap: () => _vm.selectAnswer(index),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _vm.currentIndex == 0 ? null : _vm.goBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _vm.state == ViewState.loading
                            ? null
                            : () => _handlePrimary(quiz),
                        icon: Icon(
                          _vm.isLastQuestion
                              ? Icons.flag_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                        label: Text(_vm.isLastQuestion ? 'Submit' : 'Next'),
                      ),
                    ),
                  ],
                ),
                if (_vm.state == ViewState.error && _vm.quiz != null)
                  Text(
                    _vm.errorMessage ?? 'Something went wrong.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.softRed),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handlePrimary(QuizModel quiz) async {
    if (!_vm.isLastQuestion) {
      _vm.goNext();
      return;
    }
    final result = await _vm.submit();
    if (!mounted || result == null) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(quiz: quiz, result: result),
      ),
    );
  }
}

class _EmptyQuizView extends StatelessWidget {
  const _EmptyQuizView({required this.quizTitle});

  final String quizTitle;

  @override
  Widget build(BuildContext context) {
    return AppScrollView(
      children: [
        TopHeader(
          title: quizTitle,
          subtitle: 'No questions are attached yet.',
          actionIcon: Icons.quiz_rounded,
        ),
        AppCard(
          child: Column(
            children: [
              const Icon(
                Icons.assignment_late_rounded,
                size: 48,
                color: AppColors.muted,
              ),
              const SizedBox(height: 12),
              const Text(
                'This quiz does not have any questions yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
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
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.14)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
