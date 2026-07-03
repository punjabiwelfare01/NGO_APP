import 'package:flutter/material.dart';

import '../../../../../core/colors.dart';
import '../../../../../viewmodels/create_event_viewmodel.dart';
import '../../../../../models/event_models.dart';

class BasicInfoStep extends StatelessWidget {
  const BasicInfoStep({required this.vm, super.key});

  final CreateEventViewModel vm;

  static const _swatches = [
    Color(0xFF41A7F5),
    Color(0xFF70D98B),
    Color(0xFFFFA23A),
    Color(0xFFE9E2FF),
    Color(0xFFFF7D7D),
    Color(0xFFBDF4D1),
  ];

  static const _swatchHex = [
    '#41A7F5',
    '#70D98B',
    '#FFA23A',
    '#E9E2FF',
    '#FF7D7D',
    '#BDF4D1',
  ];

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
              Text('Basic Information',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppColors.ink)),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: vm.title,
                textInputAction: TextInputAction.next,
                onEditingComplete: () =>
                    FocusScope.of(context).nextFocus(),
                decoration: const InputDecoration(
                  labelText: 'Event Title *',
                  border: OutlineInputBorder(),
                ),
                onChanged: vm.setTitle,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: vm.subtitle,
                textInputAction: TextInputAction.next,
                onEditingComplete: () =>
                    FocusScope.of(context).nextFocus(),
                decoration: const InputDecoration(
                  labelText: 'Subtitle',
                  border: OutlineInputBorder(),
                ),
                onChanged: vm.setSubtitle,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: vm.description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                onChanged: vm.setDescription,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EventType>(
                initialValue: vm.selectedEventType,
                decoration: const InputDecoration(
                  labelText: 'Event Type',
                  border: OutlineInputBorder(),
                ),
                items: EventType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.displayName),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) vm.setEventType(v);
                },
              ),
              const SizedBox(height: 20),
              Text('Theme Color',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.ink)),
              const SizedBox(height: 12),
              Row(
                children: List.generate(_swatches.length, (i) {
                  final isSelected = vm.themeColor == _swatchHex[i];
                  return GestureDetector(
                    onTap: () => vm.setThemeColor(_swatchHex[i]),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _swatches[i],
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: AppColors.ink, width: 3)
                            : Border.all(color: Colors.transparent, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: _swatches[i].withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 18, color: Colors.white)
                          : null,
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
