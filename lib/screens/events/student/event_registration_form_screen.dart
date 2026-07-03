import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/event_models.dart';
import '../../../repositories/event_repository.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_scroll_view.dart';
import '../../../widgets/top_header.dart';

class EventRegistrationFormScreen extends StatefulWidget {
  const EventRegistrationFormScreen({required this.event, super.key});

  final EventModel event;

  @override
  State<EventRegistrationFormScreen> createState() =>
      _EventRegistrationFormScreenState();
}

class _EventRegistrationFormScreenState
    extends State<EventRegistrationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentName = TextEditingController();
  final _age = TextEditingController();
  final _guardianName = TextEditingController();
  final _guardianContact = TextEditingController();
  final _school = TextEditingController();
  final _motivation = TextEditingController();
  bool _consent = false;
  bool _submitting = false;

  @override
  void dispose() {
    _studentName.dispose();
    _age.dispose();
    _guardianName.dispose();
    _guardianContact.dispose();
    _school.dispose();
    _motivation.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _ageValidator(String? value) {
    final age = int.tryParse(value?.trim() ?? '');
    if (age == null) return 'Enter age';
    final min = widget.event.ageMin;
    final max = widget.event.ageMax;
    if (min != null && age < min) return 'Minimum age is $min';
    if (max != null && age > max) return 'Maximum age is $max';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_consent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guardian consent is required.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await EventRepository.registerForEvent(
        widget.event.id,
        formData: {
          'student_name': _studentName.text.trim(),
          'age': int.parse(_age.text.trim()),
          'guardian_name': _guardianName.text.trim(),
          'guardian_contact': _guardianContact.text.trim(),
          'school': _school.text.trim(),
          'motivation': _motivation.text.trim(),
          'guardian_consent': _consent,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration submitted.'),
          backgroundColor: AppColors.secondary,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration failed. Please try again.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
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
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ],
              ),
              TopHeader(
                title: 'Event Registration',
                subtitle: event.title,
                actionIcon: Icons.how_to_reg_rounded,
              ),
              AppCard(
                color: event.themeColorValue.withValues(alpha: 0.12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.event_available,
                        color: event.themeColorValue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.eventType.displayName,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _ruleSummary(event),
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _studentName,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Student name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _age,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      validator: _ageValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _guardianName,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Parent / guardian name',
                        prefixIcon: Icon(Icons.family_restroom_rounded),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _guardianContact,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Guardian contact',
                        prefixIcon: Icon(Icons.call_outlined),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _school,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'School / learning center',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _motivation,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Why do you want to participate?',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _consent,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'I have parent / guardian consent to participate.',
                      ),
                      onChanged: (value) =>
                          setState(() => _consent = value ?? false),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _submitting ? 'Submitting...' : 'Submit Registration',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ruleSummary(EventModel event) {
    final parts = <String>[];
    if (event.ageMin != null || event.ageMax != null) {
      parts.add('Age ${event.ageMin ?? 'any'}-${event.ageMax ?? 'any'}');
    }
    if (event.maxParticipants != null) {
      parts.add('${event.maxParticipants} seats');
    }
    return parts.isEmpty ? 'Open participation' : parts.join(' • ');
  }
}
