import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/safety_awareness.dart';
import '../../../repositories/safety_awareness_repository.dart';
import 'create_safety_question_screen.dart';

class SafetyAwarenessManagerScreen extends StatefulWidget {
  const SafetyAwarenessManagerScreen({super.key});

  @override
  State<SafetyAwarenessManagerScreen> createState() =>
      _SafetyAwarenessManagerScreenState();
}

class _SafetyAwarenessManagerScreenState
    extends State<SafetyAwarenessManagerScreen> {
  List<SafetyQuestionAdmin> _questions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await SafetyAwarenessRepository.getAllQuestions();
      if (mounted) setState(() => _questions = list);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load questions.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(SafetyQuestionAdmin q) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Question'),
        content: Text(
            'Delete "${q.questionText}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.softRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await SafetyAwarenessRepository.deleteQuestion(q.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Question deleted.')));
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to delete question.'),
        backgroundColor: AppColors.softRed,
      ));
    }
  }

  Future<void> _openForm({SafetyQuestionAdmin? existing}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CreateSafetyQuestionScreen(existing: existing),
      ),
    );
    if (saved == true) _load();
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
          'Safety Questions',
          style: TextStyle(
              fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Question'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!,
                      style: const TextStyle(color: AppColors.softRed)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                      onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : _questions.isEmpty
          ? const Center(
              child: Text(
                'No questions yet. Tap + to create one.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          : ListView.separated(
              padding:
                  const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _questions.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 10),
              itemBuilder: (_, i) =>
                  _QuestionTile(
                    question: _questions[i],
                    onEdit: () =>
                        _openForm(existing: _questions[i]),
                    onDelete: () => _delete(_questions[i]),
                  ),
            ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  final SafetyQuestionAdmin question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final q = question;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  q.questionText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusDot(active: q.isActive),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _OptionTag('A', q.optionA, q.correctOption == 'a'),
              _OptionTag('B', q.optionB, q.correctOption == 'b'),
              _OptionTag('C', q.optionC, q.correctOption == 'c'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            q.explanation,
            style: const TextStyle(
                color: AppColors.muted, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  q.category,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 14),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_rounded, size: 14),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.softRed),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionTag extends StatelessWidget {
  const _OptionTag(this.letter, this.text, this.isCorrect);
  final String letter;
  final String text;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.secondary : AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$letter: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            text,
            style: TextStyle(fontSize: 11, color: color),
          ),
          if (isCorrect) ...[
            const SizedBox(width: 4),
            Icon(Icons.check_circle_rounded, size: 12, color: color),
          ],
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.secondary : AppColors.muted,
      ),
    );
  }
}
