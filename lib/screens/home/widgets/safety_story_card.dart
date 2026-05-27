import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/safety_awareness.dart';
import '../../../viewmodels/safety_awareness_viewmodel.dart';
import '../../../widgets/app_card.dart';

class SafetyStoryCard extends StatefulWidget {
  const SafetyStoryCard({super.key});

  @override
  State<SafetyStoryCard> createState() => _SafetyStoryCardState();
}

class _SafetyStoryCardState extends State<SafetyStoryCard> {
  late final SafetyAwarenessViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = SafetyAwarenessViewModel();
    _vm.loadQuestion();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.softRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.security_rounded,
                        color: AppColors.softRed, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Safety Awareness',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Body based on state
              if (_vm.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_vm.state == SafetyState.error)
                _ErrorRetry(onRetry: _vm.loadQuestion)
              else if (_vm.state == SafetyState.empty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "You've answered all today's questions. Check back tomorrow!",
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (_vm.question != null)
                _QuestionBody(vm: _vm),
            ],
          ),
        );
      },
    );
  }
}

class _QuestionBody extends StatelessWidget {
  const _QuestionBody({required this.vm});
  final SafetyAwarenessViewModel vm;

  @override
  Widget build(BuildContext context) {
    final q = vm.question!;
    final result = vm.result;
    final answered = vm.isAnswered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question text
        Text(
          q.questionText,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),

        // Options
        Row(
          children: [
            _OptionPill(
              label: q.optionA,
              optionKey: 'a',
              selected: vm.selectedOption,
              correctOption: result?.correctOption,
              answered: answered,
              onTap: answered ? null : () => vm.submitAnswer('a'),
            ),
            const SizedBox(width: 8),
            _OptionPill(
              label: q.optionB,
              optionKey: 'b',
              selected: vm.selectedOption,
              correctOption: result?.correctOption,
              answered: answered,
              onTap: answered ? null : () => vm.submitAnswer('b'),
            ),
            const SizedBox(width: 8),
            _OptionPill(
              label: q.optionC,
              optionKey: 'c',
              selected: vm.selectedOption,
              correctOption: result?.correctOption,
              answered: answered,
              onTap: answered ? null : () => vm.submitAnswer('c'),
            ),
          ],
        ),

        // Result feedback
        if (answered) ...[
          const SizedBox(height: 14),
          _ResultFeedback(result: result, explanation: q.explanation),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: vm.loadNext,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Next Question'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OptionPill extends StatelessWidget {
  const _OptionPill({
    required this.label,
    required this.optionKey,
    required this.selected,
    required this.correctOption,
    required this.answered,
    required this.onTap,
  });

  final String label;
  final String optionKey;
  final String? selected;
  final String? correctOption;
  final bool answered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color color;
    bool highlight = false;

    if (answered) {
      if (optionKey == correctOption) {
        color = AppColors.secondary;
        highlight = true;
      } else if (optionKey == selected && selected != correctOption) {
        color = AppColors.softRed;
        highlight = true;
      } else {
        color = AppColors.muted;
      }
    } else {
      color = AppColors.primary;
    }

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: highlight
                ? color.withValues(alpha: 0.18)
                : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlight
                  ? color.withValues(alpha: 0.7)
                  : color.withValues(alpha: 0.25),
              width: highlight ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: highlight ? color : AppColors.ink,
              fontSize: 12,
              fontWeight:
                  highlight ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultFeedback extends StatelessWidget {
  const _ResultFeedback({required this.result, required this.explanation});

  final AnswerResult? result;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final correct = result?.correct ?? false;
    final xp = result?.xpEarned ?? 0;
    final color = correct ? AppColors.secondary : AppColors.softRed;
    final icon = correct ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final label = correct ? 'Correct!' : 'Not quite!';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              if (correct && xp > 0) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+$xp XP',
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            result?.explanation ?? explanation,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Text('Could not load question.',
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const Spacer(),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
