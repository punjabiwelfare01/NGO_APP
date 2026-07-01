import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/event_manager_models.dart';
import '../../viewmodels/event_manager_viewmodel.dart';

class EMEditActivityScreen extends StatefulWidget {
  const EMEditActivityScreen({
    required this.activity,
    this.vm,
    this.onSaved,
    super.key,
  });

  final EMActivity activity;
  final EventManagerViewModel? vm;
  final VoidCallback? onSaved;

  @override
  State<EMEditActivityScreen> createState() => _EMEditActivityScreenState();
}

class _EMEditActivityScreenState extends State<EMEditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _location;
  late final TextEditingController _expectedWork;
  late final TextEditingController _workInstructions;
  late final TextEditingController _rewardHours;
  late final TextEditingController _maxStudents;
  late String _category;
  late String _status;
  late bool _certificateEligible;
  DateTime? _startDate;
  DateTime? _endDate;

  static const _categories = [
    'education_support',
    'awareness_programs',
    'school_partner',
    'donation_drives',
    'event_organization',
    'digital_branding',
    'documentation',
  ];

  static const _statuses = ['draft', 'active', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    final a = widget.activity;
    _title = TextEditingController(text: a.title);
    _description = TextEditingController(text: a.description ?? '');
    _location = TextEditingController(text: a.location ?? '');
    _expectedWork = TextEditingController(text: a.expectedWork ?? '');
    _workInstructions =
        TextEditingController(text: a.workInstructions ?? '');
    _rewardHours =
        TextEditingController(text: a.rewardHours.toString());
    _maxStudents =
        TextEditingController(text: a.maxStudents?.toString() ?? '');
    _category = _categories.contains(a.category) ? a.category : _categories.first;
    _status = _statuses.contains(a.status.name) ? a.status.name : 'active';
    _certificateEligible = a.certificateEligible;
    _startDate = a.startDate;
    _endDate = a.endDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _expectedWork.dispose();
    _workInstructions.dispose();
    _rewardHours.dispose();
    _maxStudents.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'title': _title.text.trim(),
        'description': _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        'category': _category,
        'location':
            _location.text.trim().isEmpty ? null : _location.text.trim(),
        'expected_work': _expectedWork.text.trim().isEmpty
            ? null
            : _expectedWork.text.trim(),
        'work_instructions': _workInstructions.text.trim().isEmpty
            ? null
            : _workInstructions.text.trim(),
        'reward_hours': double.tryParse(_rewardHours.text) ?? 0.0,
        'max_students': int.tryParse(_maxStudents.text),
        'certificate_eligible': _certificateEligible,
        'status': _status,
        if (_startDate != null) 'start_date': _startDate!.toIso8601String().split('T').first,
        if (_endDate != null) 'end_date': _endDate!.toIso8601String().split('T').first,
      };

      if (widget.vm != null) {
        await widget.vm!.editActivity(widget.activity.id, payload);
      }
      widget.onSaved?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity updated successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Activity'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Warning for completed activities ──────────────────────────
            if (widget.activity.status == ActivityStatus.completed)
              _WarningBanner(
                message:
                    'This activity is completed. Editing may affect related records.',
              ),
            if (widget.activity.certificatesGenerated > 0)
              _WarningBanner(
                message:
                    'Certificates have been generated. Changing the title or hours may cause inconsistencies.',
                color: const Color(0xFFFFF3E0),
                iconColor: const Color(0xFFE65100),
              ),

            _sectionLabel('Basic Information'),
            _field(
              controller: _title,
              label: 'Activity Title',
              icon: Icons.title_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _description,
              label: 'Description',
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            _sectionLabel('Category & Status'),
            _dropdown(
              label: 'Category',
              value: _category,
              items: _categories,
              icon: Icons.category_rounded,
              onChanged: (v) => setState(() => _category = v!),
              display: (v) => v.replaceAll('_', ' ').toUpperCase(),
            ),
            const SizedBox(height: 12),
            _dropdown(
              label: 'Status',
              value: _status,
              items: _statuses,
              icon: Icons.flag_rounded,
              onChanged: (v) => setState(() => _status = v!),
              display: (v) => v[0].toUpperCase() + v.substring(1),
            ),
            const SizedBox(height: 12),

            _sectionLabel('Location & Dates'),
            _field(
              controller: _location,
              label: 'Location',
              icon: Icons.place_rounded,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _dateTile(
                    label: 'Start Date',
                    date: _startDate,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dateTile(
                    label: 'End Date',
                    date: _endDate,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _sectionLabel('Work Details'),
            _field(
              controller: _expectedWork,
              label: 'Expected Work',
              icon: Icons.work_outline_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _workInstructions,
              label: 'Work Instructions',
              icon: Icons.list_alt_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            _sectionLabel('Hours & Capacity'),
            Row(
              children: [
                Expanded(
                  child: _field(
                    controller: _rewardHours,
                    label: 'Reward Hours',
                    icon: Icons.access_time_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _field(
                    controller: _maxStudents,
                    label: 'Max Students',
                    icon: Icons.people_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _sectionLabel('Certificate'),
            SwitchListTile(
              value: _certificateEligible,
              onChanged: (v) => setState(() => _certificateEligible = v),
              title: const Text('Certificate Eligible',
                  style: TextStyle(
                      color: AppColors.ink, fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'Students completing this activity may receive a certificate',
                  style: TextStyle(fontSize: 12)),
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Saving…' : 'Save Changes'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      );

  static Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );

  static Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
    required String Function(String) display,
  }) =>
      DropdownButtonFormField<String>(
        initialValue: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        items: items
            .map((v) => DropdownMenuItem(value: v, child: Text(display(v))))
            .toList(),
      );

  Widget _dateTile({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final txt = date != null
        ? '${date.day} ${months[date.month - 1]} ${date.year}'
        : 'Not set';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.muted.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 16, color: AppColors.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  Text(txt,
                      style: TextStyle(
                          color: date != null ? AppColors.ink : AppColors.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({
    required this.message,
    this.color = const Color(0xFFFFF8E1),
    this.iconColor = const Color(0xFFF57F17),
  });

  final String message;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: TextStyle(color: iconColor, fontSize: 12)),
            ),
          ],
        ),
      );
}
