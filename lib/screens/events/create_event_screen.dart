import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/event_manager_models.dart';
import '../../models/unified_event.dart';
import '../../viewmodels/events_viewmodel.dart';

/// Dedicated full-page Create/Edit Event screen for the Event Manager
/// workflow — replaces the old modal `CreateEventSheet` bottom sheet. Pass
/// [existingEvent] to edit an event already on record (draft or published);
/// omit it to create a brand-new one (always saved as a draft).
class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({required this.vm, this.existingEvent, super.key});

  final EventsViewModel vm;
  final UnifiedEvent? existingEvent;

  bool get isEditing => existingEvent != null;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _schoolCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _maxVolCtrl;
  late final TextEditingController _eligibilityCtrl;
  late final TextEditingController _expectedWorkCtrl;
  late final TextEditingController _proofCtrl;

  late EventCategory _category;
  late DateTime _date;
  late bool _certificate;
  late bool _donation;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEvent?.event;
    _titleCtrl = TextEditingController(text: existing?.title ?? '');
    _locationCtrl = TextEditingController(text: existing?.location ?? '');
    _schoolCtrl = TextEditingController(text: existing?.partnerSchool ?? '');
    _descCtrl = TextEditingController(text: existing?.description ?? '');
    _maxVolCtrl =
        TextEditingController(text: '${existing?.maxVolunteers ?? 20}');
    _eligibilityCtrl =
        TextEditingController(text: existing?.studentEligibility ?? '');
    _expectedWorkCtrl =
        TextEditingController(text: existing?.expectedWork ?? '');
    _proofCtrl = TextEditingController(text: existing?.proofRequired ?? '');
    _category = existing?.category ?? EventCategory.workshop;
    _date = existing?.date ?? DateTime.now().add(const Duration(days: 7));
    _certificate = existing?.certificateEligible ?? true;
    _donation = existing?.donationEligible ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _schoolCtrl.dispose();
    _descCtrl.dispose();
    _maxVolCtrl.dispose();
    _eligibilityCtrl.dispose();
    _expectedWorkCtrl.dispose();
    _proofCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final title = _titleCtrl.text.trim();
    try {
      if (widget.isEditing) {
        await widget.vm.updateEventDetails(
          widget.existingEvent!,
          title: title,
          description: _descCtrl.text.trim(),
          date: _date,
          location: _locationCtrl.text.trim(),
          maxVolunteers: int.tryParse(_maxVolCtrl.text.trim()) ?? 20,
          certificateEligible: _certificate,
        );
      } else {
        final event = NGOEvent(
          id: 0,
          title: title,
          category: _category,
          status: EventStatus.draft,
          date: _date,
          location: _locationCtrl.text.trim(),
          partnerSchool: _schoolCtrl.text.trim().isEmpty
              ? null
              : _schoolCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          maxVolunteers: int.tryParse(_maxVolCtrl.text.trim()) ?? 20,
          studentEligibility: _eligibilityCtrl.text.trim().isEmpty
              ? null
              : _eligibilityCtrl.text.trim(),
          expectedWork: _expectedWorkCtrl.text.trim().isEmpty
              ? null
              : _expectedWorkCtrl.text.trim(),
          proofRequired:
              _proofCtrl.text.trim().isEmpty ? null : _proofCtrl.text.trim(),
          certificateEligible: _certificate,
          donationEligible: _donation,
          createdAt: DateTime.now(),
        );
        await widget.vm.createEvent(event);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing
              ? 'Could not save changes: $e'
              : 'Could not create event: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isEditing
            ? 'Event "$title" updated'
            : 'Event "$title" created as Draft'),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Event' : 'Create Event',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              18, 18, 18, 28 + MediaQuery.of(context).viewInsets.bottom),
          children: [
            _label('Event Title *'),
            _field(
              _titleCtrl,
              'e.g. Cyber Safety Awareness Camp',
              required: true,
              textInputAction: TextInputAction.next,
              onEditingComplete: () => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 14),
            _label('Category *'),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: EventCategory.values
                  .map(
                    (c) => ChoiceChip(
                      label: Text(c.label, style: const TextStyle(fontSize: 11)),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                      avatar: Icon(c.icon, size: 12),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            _label('Date *'),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.muted.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: Color(0xFF1565C0), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '${_date.day}/${_date.month}/${_date.year}',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _label('Location / Venue *'),
            _field(
              _locationCtrl,
              'e.g. Delhi Public School, Cantt',
              required: true,
              textInputAction: TextInputAction.next,
              onEditingComplete: () => FocusScope.of(context).nextFocus(),
            ),
            if (!widget.isEditing) ...[
              const SizedBox(height: 14),
              _label('Partner School / Organisation'),
              _field(
                _schoolCtrl,
                'Optional',
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
              ),
            ],
            const SizedBox(height: 14),
            _label('Description *'),
            _field(_descCtrl, 'What is this event about?',
                required: true, maxLines: 4),
            const SizedBox(height: 14),
            _label('Max Volunteers / Capacity *'),
            _field(
              _maxVolCtrl,
              'e.g. 25',
              required: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onEditingComplete: () => FocusScope.of(context).nextFocus(),
            ),
            if (!widget.isEditing) ...[
              const SizedBox(height: 14),
              _label('Student Eligibility'),
              _field(
                _eligibilityCtrl,
                'e.g. All enrolled volunteers',
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 14),
              _label('Expected Work'),
              _field(_expectedWorkCtrl, 'What will volunteers do?', maxLines: 3),
              const SizedBox(height: 14),
              _label('Proof Required'),
              _field(_proofCtrl, 'e.g. Photos, attendance sheet, report'),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ToggleTile(
                    icon: Icons.workspace_premium_rounded,
                    label: 'Certificate',
                    value: _certificate,
                    onChanged: (v) => setState(() => _certificate = v),
                  ),
                ),
                if (!widget.isEditing) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ToggleTile(
                      icon: Icons.payments_rounded,
                      label: 'Donation / Stipend',
                      value: _donation,
                      onChanged: (v) => setState(() => _donation = v),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        widget.isEditing ? 'Save Changes' : 'Save as Draft',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    VoidCallback? onEditingComplete,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onEditingComplete: onEditingComplete,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: AppColors.muted.withValues(alpha: 0.6), fontSize: 13),
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        validator:
            required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      );
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFF1565C0).withValues(alpha: 0.06)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? const Color(0xFF1565C0).withValues(alpha: 0.3)
              : AppColors.muted.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? const Color(0xFF1565C0) : AppColors.muted, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: value ? const Color(0xFF1565C0) : AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF1565C0),
            activeTrackColor: const Color(0xFF1565C0).withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}
