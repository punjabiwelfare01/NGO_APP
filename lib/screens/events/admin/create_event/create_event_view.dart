import 'package:flutter/material.dart';

import '../../../../core/colors.dart';
import '../../../../viewmodels/create_event_viewmodel.dart';
import '../../../../viewmodels/view_state.dart';
import 'steps/step1_basic_info.dart';
import 'steps/step2_timeline.dart';
import 'steps/step3_rules.dart';
import 'steps/step4_quiz.dart';
import 'steps/step5_selection.dart';
import 'steps/step6_rewards.dart';
import 'steps/step7_notifications.dart';
import 'steps/step8_preview.dart';

class CreateEventView extends StatefulWidget {
  const CreateEventView({super.key});

  @override
  State<CreateEventView> createState() => _CreateEventViewState();
}

class _CreateEventViewState extends State<CreateEventView> {
  late final CreateEventViewModel _vm;
  late final PageController _pageController;
  int _currentStep = 0;
  static const int _totalSteps = 8;

  @override
  void initState() {
    super.initState();
    _vm = CreateEventViewModel();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _vm.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentStep == 1) {
      final errors = _vm.getTimelineErrors();
      if (errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errors.values.first),
            backgroundColor: AppColors.softRed,
          ),
        );
        return;
      }
    }
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _submit() async {
    final success = await _vm.submit();
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(_vm.createdEvent);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event created!'),
          backgroundColor: AppColors.secondary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_vm.errorMessage ?? 'Failed to create event.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Create Event',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppColors.ink),
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      body: Column(
        children: [
          // Step indicator
          _StepIndicator(current: _currentStep, total: _totalSteps),
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                BasicInfoStep(vm: _vm),
                TimelineStep(vm: _vm),
                RulesStep(vm: _vm),
                QuizStep(vm: _vm),
                SelectionStep(vm: _vm),
                RewardsStep(vm: _vm),
                NotificationsStep(vm: _vm),
                PreviewStep(vm: _vm),
              ],
            ),
          ),
          // Bottom navigation
          ListenableBuilder(
            listenable: _vm,
            builder: (context, _) {
              final isLoading = _vm.state == ViewState.loading;
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading ? null : _goBack,
                            child: const Text('Back'),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 12),
                      Expanded(
                        child: _currentStep < _totalSteps - 1
                            ? FilledButton(
                                onPressed: isLoading ? null : _goNext,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                                child: const Text('Next'),
                              )
                            : FilledButton(
                                onPressed: isLoading ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Publish Event'),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: List.generate(total * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = i ~/ 2;
            final active = stepIndex < current;
            return Expanded(
              child: Container(
                height: 2,
                color: active
                    ? AppColors.primary
                    : AppColors.muted.withValues(alpha: 0.2),
              ),
            );
          }
          // Step circle
          final stepIndex = i ~/ 2;
          final isDone = stepIndex < current;
          final isCurrent = stepIndex == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.primary
                  : isCurrent
                  ? AppColors.primary
                  : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone || isCurrent
                    ? AppColors.primary
                    : AppColors.muted.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text(
                      '${stepIndex + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isCurrent ? Colors.white : AppColors.muted,
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }
}
