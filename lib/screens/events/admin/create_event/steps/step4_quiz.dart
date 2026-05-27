import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../../core/colors.dart';
import '../../../../../models/quiz_models.dart';
import '../../../../../viewmodels/create_event_viewmodel.dart';
import '../quiz/create_quiz_screen.dart';

class QuizStep extends StatelessWidget {
  const QuizStep({required this.vm, super.key});

  final CreateEventViewModel vm;

  Future<void> _openCreator(BuildContext context) async {
    final created = await Navigator.of(context).push<QuizSummary>(
      MaterialPageRoute(
        builder: (_) => CreateQuizScreen(
          initialTitle: vm.quizTitle.isNotEmpty
              ? vm.quizTitle
              : vm.title.isNotEmpty
              ? '${vm.title} Quiz'
              : null,
          headerTitle: 'Create Event Quiz',
          headerSubtitle: 'Build the quiz that will be attached to this event.',
        ),
      ),
    );
    if (created == null) return;
    vm.setCreatedQuiz(created);
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    vm.setPickedFile(file.bytes!.toList(), file.name);
    await vm.uploadQuizFile();
    if (context.mounted && vm.uploadError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.uploadError!),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quiz Setup',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: 20),
              _MethodCard(
                method: 'create',
                selected: vm.quizAttachmentMethod,
                title: 'Create Quiz',
                description: 'Build a new quiz from scratch',
                icon: Icons.add_circle_outline_rounded,
                onTap: () => vm.setQuizAttachmentMethod('create'),
              ),
              const SizedBox(height: 10),
              _MethodCard(
                method: 'upload',
                selected: vm.quizAttachmentMethod,
                title: 'Upload File',
                description: 'CSV or JSON — auto-creates questions',
                icon: Icons.upload_file_rounded,
                onTap: () => vm.setQuizAttachmentMethod('upload'),
              ),
              const SizedBox(height: 10),
              _MethodCard(
                method: 'existing',
                selected: vm.quizAttachmentMethod,
                title: 'Attach Existing',
                description: 'Link a quiz by its ID',
                icon: Icons.link_rounded,
                onTap: () => vm.setQuizAttachmentMethod('existing'),
              ),
              const SizedBox(height: 20),

              if (vm.quizAttachmentMethod == 'create') ...[
                if (vm.createdQuiz != null)
                  _CreatedQuizPanel(vm: vm)
                else
                  TextFormField(
                    initialValue: vm.quizTitle,
                    decoration: const InputDecoration(
                      labelText: 'Quiz Title',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: vm.setQuizTitle,
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openCreator(context),
                    icon: Icon(
                      vm.createdQuiz == null
                          ? Icons.add_task_rounded
                          : Icons.edit_note_rounded,
                    ),
                    label: Text(
                      vm.createdQuiz == null
                          ? 'Build Quiz Questions'
                          : 'Replace Created Quiz',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ] else if (vm.quizAttachmentMethod == 'upload') ...[
                _UploadPanel(vm: vm, onPick: () => _pickAndUpload(context)),
              ] else if (vm.quizAttachmentMethod == 'existing') ...[
                TextFormField(
                  initialValue: vm.quizTitle,
                  decoration: const InputDecoration(
                    labelText: 'Quiz ID',
                    hintText: 'Enter the numeric quiz ID',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: vm.setQuizTitle,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CreatedQuizPanel extends StatelessWidget {
  const _CreatedQuizPanel({required this.vm});

  final CreateEventViewModel vm;

  @override
  Widget build(BuildContext context) {
    final quiz = vm.createdQuiz!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Quiz ID: ${quiz.id}  ·  ${quiz.questionCount} questions  ·  Ready to attach',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadPanel extends StatelessWidget {
  const _UploadPanel({required this.vm, required this.onPick});

  final CreateEventViewModel vm;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Format hint
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Supported formats',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'CSV  —  columns: text, option_a, option_b, option_c, option_d, correct_index, explanation, points',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              const Text(
                'JSON  —  array of { "text", "options": [], "correct_index", "explanation", "points" }',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Pick button / status
        if (vm.uploadingFile)
          const Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text(
                'Uploading…',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          )
        else if (vm.uploadReady) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vm.uploadFileName ?? 'File uploaded',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Quiz ID: ${vm.uploadedQuizId}  ·  Ready to attach',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onPick,
                  child: const Text('Replace', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ] else ...[
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.attach_file_rounded),
            label: Text(
              vm.uploadFileName != null
                  ? vm.uploadFileName!
                  : 'Choose File  (.csv or .json)',
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          if (vm.uploadFileName != null && !vm.uploadReady) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: vm.uploadingFile
                    ? null
                    : () async {
                        await vm.uploadQuizFile();
                        if (context.mounted && vm.uploadError != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(vm.uploadError!),
                              backgroundColor: AppColors.softRed,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.cloud_upload_rounded),
                label: const Text('Upload Quiz Questions'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.method,
    required this.selected,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String method;
  final String selected;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = method == selected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.muted.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.muted,
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.ink,
                    ),
                  ),
                  Text(
                    description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppColors.primary : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
