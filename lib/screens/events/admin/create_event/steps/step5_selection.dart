import 'package:flutter/material.dart';

import '../../../../../core/colors.dart';
import '../../../../../models/event_models.dart';
import '../../../../../viewmodels/create_event_viewmodel.dart';

class SelectionStep extends StatelessWidget {
  const SelectionStep({required this.vm, super.key});

  final CreateEventViewModel vm;

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
              Text('Selection Method',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppColors.ink)),
              const SizedBox(height: 20),
              _SelectionCard(
                method: SelectionMethod.luckyDraw,
                selected: vm.selectedSelectionMethod,
                title: 'Lucky Draw',
                description: 'Winners selected randomly from eligible pool',
                icon: Icons.casino_outlined,
                onTap: () => vm.setSelectionMethod(SelectionMethod.luckyDraw),
              ),
              const SizedBox(height: 10),
              _SelectionCard(
                method: SelectionMethod.manual,
                selected: vm.selectedSelectionMethod,
                title: 'Manual',
                description: 'Admin handpicks winners individually',
                icon: Icons.person_pin_outlined,
                onTap: () => vm.setSelectionMethod(SelectionMethod.manual),
              ),
              const SizedBox(height: 10),
              _SelectionCard(
                method: SelectionMethod.scoreBased,
                selected: vm.selectedSelectionMethod,
                title: 'Score Based',
                description: 'Top scorers are selected automatically',
                icon: Icons.leaderboard_outlined,
                onTap: () => vm.setSelectionMethod(SelectionMethod.scoreBased),
              ),
              const SizedBox(height: 10),
              _SelectionCard(
                method: SelectionMethod.hybrid,
                selected: vm.selectedSelectionMethod,
                title: 'Hybrid',
                description: 'Lucky draw with manual overrides',
                icon: Icons.merge_outlined,
                onTap: () => vm.setSelectionMethod(SelectionMethod.hybrid),
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue:
                    vm.maxSelections != null ? '${vm.maxSelections}' : '',
                decoration: const InputDecoration(
                  labelText: 'Max Selections',
                  hintText: 'Leave blank for no limit',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => vm.setMaxSelections(int.tryParse(v)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.method,
    required this.selected,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final SelectionMethod method;
  final SelectionMethod selected;
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
            Icon(icon,
                color: isSelected ? AppColors.primary : AppColors.muted,
                size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.ink,
                          )),
                  Text(description,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.muted)),
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
