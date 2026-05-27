import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/quiz_models.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scroll_view.dart';
import '../../widgets/top_header.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({required this.quiz, required this.result, super.key});

  final QuizModel quiz;
  final AttemptResult result;

  void _goBack(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final score = result.score.round();
    return Scaffold(
      body: SafeArea(
        child: AppScrollView(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton.filledTonal(
                onPressed: () => _goBack(context),
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
              ),
            ),
            TopHeader(
              title: '$score% Score',
              subtitle:
                  '${result.correctCount}/${result.totalQuestions} correct • ${result.xpEarned} XP earned',
              actionIcon: Icons.emoji_events_rounded,
            ),
            AppCard(
              color: const Color(0xFFE0F8E8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz.title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: result.score / 100,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.secondary,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => _goBack(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back'),
                  ),
                ],
              ),
            ),
            ...result.answerResults.map(
              (answer) => _AnswerReview(answer: answer),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerReview extends StatelessWidget {
  const _AnswerReview({required this.answer});

  final AnswerResult answer;

  @override
  Widget build(BuildContext context) {
    final skipped = answer.selectedIndex < 0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                answer.isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: answer.isCorrect
                    ? AppColors.secondary
                    : AppColors.softRed,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  answer.questionText,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            skipped
                ? 'Skipped • correct answer: option ${answer.correctIndex + 1}'
                : 'Your answer: option ${answer.selectedIndex + 1} • correct: option ${answer.correctIndex + 1}',
            style: const TextStyle(color: AppColors.muted),
          ),
          if (answer.explanation != null && answer.explanation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              answer.explanation!,
              style: const TextStyle(color: AppColors.ink),
            ),
          ],
        ],
      ),
    );
  }
}
