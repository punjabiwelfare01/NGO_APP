import 'package:flutter/material.dart';

import '../../../../../core/colors.dart';
import '../../../../../viewmodels/create_event_viewmodel.dart';

class RulesStep extends StatelessWidget {
  const RulesStep({required this.vm, super.key});

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
              Text(
                'Participation Rules',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: 20),
              Text(
                'Age Range',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: vm.ageMin != null ? '${vm.ageMin}' : '',
                      decoration: const InputDecoration(
                        labelText: 'Min Age *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => vm.setAgeMin(int.tryParse(v)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: vm.ageMax != null ? '${vm.ageMax}' : '',
                      decoration: const InputDecoration(
                        labelText: 'Max Age *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => vm.setAgeMax(int.tryParse(v)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: vm.minQuizScore != null
                    ? '${vm.minQuizScore}'
                    : '',
                decoration: const InputDecoration(
                  labelText: 'Minimum Quiz Score *',
                  hintText: 'e.g. 70.0',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (v) => vm.setMinQuizScore(double.tryParse(v)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: '${vm.requiredChallenges}',
                decoration: const InputDecoration(
                  labelText: 'Required Challenges Completed *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    vm.setRequiredChallenges(int.tryParse(v) ?? 0),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: vm.maxParticipants != null
                    ? '${vm.maxParticipants}'
                    : '',
                decoration: const InputDecoration(
                  labelText: 'Max Participants * (0 = unlimited)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => vm.setMaxParticipants(int.tryParse(v.trim())),
              ),
            ],
          ),
        );
      },
    );
  }
}
