import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/event_manager_models.dart';
import '../../viewmodels/event_manager_viewmodel.dart';

/// Full-page form for creating a new volunteer activity.
///
/// When [eventId] is provided, the activity is linked to that event and the
/// event name is shown in the header. When [eventId] is null the activity is
/// standalone (not attached to any event).
class EMCreateActivityScreen extends StatefulWidget {
  const EMCreateActivityScreen({
    required this.vm,
    this.eventId,
    this.eventTitle,
    super.key,
  });

  final EventManagerViewModel vm;
  final int? eventId;
  final String? eventTitle;

  @override
  State<EMCreateActivityScreen> createState() => _EMCreateActivityScreenState();
}

class _EMCreateActivityScreenState extends State<EMCreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _expectedWorkCtrl = TextEditingController();
  final _workInstructionsCtrl = TextEditingController();
  final _proofCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController(text: '2');
  final _maxStudentsCtrl = TextEditingController(text: '20');

  String _category = 'event_organization';
  String _status = 'active';
  bool _certificateEligible = true;
  DateTime? _startDate;
  DateTime? _endDate;

  // null = standalone; non-null = linked to this event
  int? _selectedEventId;
  String? _selectedEventTitle;

  @override
  void initState() {
    super.initState();
    _selectedEventId = widget.eventId;
    _selectedEventTitle = widget.eventTitle;
  }

  static const _categories = [
    ('education_support', 'Education Support', Icons.menu_book_rounded),
    ('awareness_programs', 'Awareness Programs', Icons.campaign_rounded),
    ('school_partner', 'School Partner', Icons.school_rounded),
    ('donation_drives', 'Donation Drives', Icons.favorite_rounded),
    ('event_organization', 'Event Organization', Icons.event_rounded),
    ('digital_branding', 'Digital Branding', Icons.public_rounded),
    ('documentation', 'Documentation', Icons.description_rounded),
  ];

  static const _statusOptions = [
    ('active', 'Active', Color(0xFF2E7D32)),
    ('draft', 'Draft', Color(0xFF757575)),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _expectedWorkCtrl.dispose();
    _workInstructionsCtrl.dispose();
    _proofCtrl.dispose();
    _hoursCtrl.dispose();
    _maxStudentsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 1)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final created = await widget.vm.createActivity(
        title: _titleCtrl.text.trim(),
        category: _category,
        eventId: _selectedEventId,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        expectedWork: _expectedWorkCtrl.text.trim().isEmpty ? null : _expectedWorkCtrl.text.trim(),
        workInstructions: _workInstructionsCtrl.text.trim().isEmpty ? null : _workInstructionsCtrl.text.trim(),
        proofRequired: _proofCtrl.text.trim().isEmpty ? null : _proofCtrl.text.trim(),
        rewardHours: double.tryParse(_hoursCtrl.text.trim()) ?? 2.0,
        maxStudents: int.tryParse(_maxStudentsCtrl.text.trim()) ?? 20,
        certificateEligible: _certificateEligible,
        startDate: _startDate,
        endDate: _endDate,
        status: _status,
      );
      if (!mounted) return;
      Navigator.of(context).pop(created);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Activity "${created.title}" created successfully!',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create activity: $e'),
          backgroundColor: AppColors.softRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Activity',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink),
            ),
            if (widget.eventTitle != null)
              Text(
                'For: ${widget.eventTitle}',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          if (!_saving)
            TextButton(
              onPressed: _submit,
              child: const Text(
                'Save',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 15),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // ── Event Selector ─────────────────────────────────────────────
            _SectionHeader('Link to Event'),
            const SizedBox(height: 10),
            if (widget.eventId != null)
              // Pre-locked when opened from an event detail sheet — read-only
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_rounded,
                        color: Color(0xFF1565C0), size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedEventTitle ?? 'Event #${widget.eventId}',
                        style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(Icons.lock_outline_rounded,
                        size: 14, color: Color(0xFF1565C0)),
                  ],
                ),
              )
            else
              // Editable dropdown — shown when opened from the Activities tab
              _EventDropdown(
                events: widget.vm.events,
                selectedId: _selectedEventId,
                onChanged: (NGOEvent? event) => setState(() {
                  _selectedEventId = event?.id;
                  _selectedEventTitle = event?.title;
                }),
              ),
            const SizedBox(height: 20),

            // ── Basic Info ─────────────────────────────────────────────────
            _SectionHeader('Basic Information'),
            const SizedBox(height: 12),
            _FormField(
              controller: _titleCtrl,
              label: 'Activity Title *',
              hint: 'e.g. Awareness Drive Registration Desk',
              icon: Icons.assignment_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            _FormField(
              controller: _descCtrl,
              label: 'Description',
              hint: 'What is this activity about?',
              icon: Icons.description_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _FormField(
              controller: _locationCtrl,
              label: 'Location',
              hint: 'e.g. School Main Hall, Room 5',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 20),

            // ── Category ───────────────────────────────────────────────────
            _SectionHeader('Category'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((rec) {
                final (value, label, icon) = rec;
                final selected = _category == value;
                return GestureDetector(
                  onTap: () => setState(() => _category = value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.10)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : AppColors.muted.withValues(alpha: 0.3),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 14,
                          color: selected
                              ? AppColors.primary
                              : AppColors.muted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            color: selected
                                ? AppColors.primary
                                : AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Scheduling ─────────────────────────────────────────────────
            _SectionHeader('Schedule'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DatePickerButton(
                    label: 'Start Date',
                    date: _startDate,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DatePickerButton(
                    label: 'End Date',
                    date: _endDate,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Capacity & Rewards ─────────────────────────────────────────
            _SectionHeader('Capacity & Rewards'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FormField(
                    controller: _maxStudentsCtrl,
                    label: 'Max Students',
                    hint: '20',
                    icon: Icons.people_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 1) return 'Enter a valid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FormField(
                    controller: _hoursCtrl,
                    label: 'Reward Hours',
                    hint: '2',
                    icon: Icons.timer_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = double.tryParse(v.trim());
                      if (n == null || n < 0) return 'Enter valid hours';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Work Details ───────────────────────────────────────────────
            _SectionHeader('Work Details'),
            const SizedBox(height: 12),
            _FormField(
              controller: _expectedWorkCtrl,
              label: 'Expected Work',
              hint: 'What tasks will volunteers perform?',
              icon: Icons.checklist_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _FormField(
              controller: _workInstructionsCtrl,
              label: 'Work Instructions',
              hint: 'Specific instructions for this activity…',
              icon: Icons.list_alt_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _FormField(
              controller: _proofCtrl,
              label: 'Proof Required',
              hint: 'e.g. Photo, attendance sheet, report',
              icon: Icons.upload_file_rounded,
            ),
            const SizedBox(height: 20),

            // ── Settings ───────────────────────────────────────────────────
            _SectionHeader('Settings'),
            const SizedBox(height: 12),

            // Status
            Row(
              children: _statusOptions.map((rec) {
                final (value, label, color) = rec;
                final selected = _status == value;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _status = value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? color.withValues(alpha: 0.4)
                                : AppColors.muted.withValues(alpha: 0.25),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: selected ? color : AppColors.muted,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: TextStyle(
                                color: selected ? color : AppColors.muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Certificate eligibility toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _certificateEligible
                    ? const Color(0xFF1565C0).withValues(alpha: 0.06)
                    : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _certificateEligible
                      ? const Color(0xFF1565C0).withValues(alpha: 0.3)
                      : AppColors.muted.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: _certificateEligible
                        ? const Color(0xFF1565C0)
                        : AppColors.muted,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Certificate Eligible',
                          style: TextStyle(
                            color: _certificateEligible
                                ? const Color(0xFF1565C0)
                                : AppColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'Students can earn a certificate upon completion',
                          style: TextStyle(
                              color: AppColors.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _certificateEligible,
                    onChanged: (v) =>
                        setState(() => _certificateEligible = v),
                    activeThumbColor: const Color(0xFF1565C0),
                    activeTrackColor:
                        const Color(0xFF1565C0).withValues(alpha: 0.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Submit Button ──────────────────────────────────────────────
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add_task_rounded),
              label: Text(
                _saving ? 'Creating…' : 'Create Activity',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      );
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textInputAction:
              maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: AppColors.muted.withValues(alpha: 0.55), fontSize: 13),
            prefixIcon: Icon(icon, color: AppColors.muted, size: 18),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.muted.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.muted.withValues(alpha: 0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.softRed, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.softRed, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  static String _fmt(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.muted.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: date != null
                      ? AppColors.primary
                      : AppColors.muted,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null ? _fmt(date!) : 'Select date',
                    style: TextStyle(
                      color: date != null ? AppColors.ink : AppColors.muted,
                      fontSize: 13,
                      fontWeight: date != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EventDropdown extends StatelessWidget {
  const _EventDropdown({
    required this.events,
    required this.selectedId,
    required this.onChanged,
  });

  final List<NGOEvent> events;
  final int? selectedId;
  final ValueChanged<NGOEvent?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedId != null
              ? const Color(0xFF1565C0).withValues(alpha: 0.4)
              : AppColors.muted.withValues(alpha: 0.25),
          width: selectedId != null ? 1.5 : 1.0,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: selectedId,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded, color: AppColors.muted),
          hint: const Row(
            children: [
              Icon(Icons.event_outlined, size: 16, color: AppColors.muted),
              SizedBox(width: 8),
              Text(
                'No Event (Standalone)',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.link_off_rounded,
                      size: 16, color: AppColors.muted),
                  SizedBox(width: 8),
                  Text(
                    'No Event (Standalone)',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ...events.map(
              (e) => DropdownMenuItem<int?>(
                value: e.id,
                child: Row(
                  children: [
                    Icon(e.category.icon, size: 15, color: e.status.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: e.status.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        e.status.label,
                        style: TextStyle(
                          color: e.status.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (id) {
            final event =
                id == null ? null : events.firstWhere((e) => e.id == id);
            onChanged(event);
          },
        ),
      ),
    );
  }
}
