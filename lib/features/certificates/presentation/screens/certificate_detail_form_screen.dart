import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/colors.dart';
import '../../../../models/certificate_models.dart';
import '../../../../repositories/certificate_repository.dart';

/// Form for Admin / Event Manager to fill or edit certificate details
/// before (or after) PDF generation.
///
/// Pass [certificate] when editing an existing record.
/// Pass [prefill] when creating from a "Ready to generate" assignment row.
class CertificateDetailFormScreen extends StatefulWidget {
  const CertificateDetailFormScreen({
    super.key,
    this.certificate,
    this.prefill,
  });

  final Certificate? certificate;

  /// Prefill data from a ready-to-generate assignment.
  /// Keys: student_id, student_name, activity_id, activity_name,
  ///       assignment_id, event_id, hours_worked.
  final Map<String, dynamic>? prefill;

  @override
  State<CertificateDetailFormScreen> createState() =>
      _CertificateDetailFormScreenState();
}

class _CertificateDetailFormScreenState
    extends State<CertificateDetailFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // Core fields
  late final TextEditingController _activityCtrl;
  late final TextEditingController _eventNameCtrl;
  late final TextEditingController _programCtrl;
  late CertificateType _certType;

  // Student fields
  late final TextEditingController _studentIdNumCtrl; // roll number
  late final TextEditingController _studentRoleCtrl;

  // Work detail fields
  late final TextEditingController _workDescCtrl;
  late final TextEditingController _serviceHoursCtrl;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _issueDate;

  // Authority fields
  late final TextEditingController _signatoryNameCtrl;
  late final TextEditingController _signatoryTitleCtrl;
  late final TextEditingController _signatureUrlCtrl;

  // Meta fields
  late final TextEditingController _remarksCtrl;
  late final TextEditingController _impactSummaryCtrl;

  Certificate? get _cert => widget.certificate;
  Map<String, dynamic>? get _pre => widget.prefill;

  @override
  void initState() {
    super.initState();
    _activityCtrl = TextEditingController(
      text: _cert?.activityName ?? _pre?['activity_name'] as String? ?? '',
    );
    _eventNameCtrl = TextEditingController(text: _cert?.eventName ?? '');
    _programCtrl   = TextEditingController(text: _cert?.programName ?? '');
    _certType      = _cert?.certificateType ?? CertificateType.volunteer;

    _studentIdNumCtrl = TextEditingController(text: _cert?.studentIdNumber ?? '');
    _studentRoleCtrl  = TextEditingController(text: _cert?.studentRole ?? 'Volunteer');

    final prefillHours = _pre?['hours_worked'] as num?;
    _workDescCtrl     = TextEditingController(text: _cert?.workDescription ?? '');
    _serviceHoursCtrl = TextEditingController(
      text: _cert?.serviceHours?.toString() ??
          (prefillHours != null ? prefillHours.toStringAsFixed(1) : ''),
    );
    _startDate = _cert?.startDate;
    _endDate   = _cert?.endDate;
    _issueDate = _cert?.issueDate ?? DateTime.now();

    _signatoryNameCtrl  = TextEditingController(text: _cert?.signatoryName ?? '');
    _signatoryTitleCtrl = TextEditingController(text: _cert?.signatoryTitle ?? '');
    _signatureUrlCtrl   = TextEditingController(text: _cert?.signatureUrl ?? '');

    _remarksCtrl      = TextEditingController(text: _cert?.remarks ?? '');
    _impactSummaryCtrl = TextEditingController(
      text: _cert?.impactStorySummary ?? '',
    );
  }

  @override
  void dispose() {
    _activityCtrl.dispose();
    _eventNameCtrl.dispose();
    _programCtrl.dispose();
    _studentIdNumCtrl.dispose();
    _studentRoleCtrl.dispose();
    _workDescCtrl.dispose();
    _serviceHoursCtrl.dispose();
    _signatoryNameCtrl.dispose();
    _signatoryTitleCtrl.dispose();
    _signatureUrlCtrl.dispose();
    _remarksCtrl.dispose();
    _impactSummaryCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _pickDate(
    BuildContext ctx,
    DateTime? current,
    String label,
    void Function(DateTime) onPicked,
  ) async {
    final picked = await showDatePicker(
      context: ctx,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select $label',
    );
    if (picked != null) onPicked(picked);
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'Not set';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  Future<void> _save(BuildContext ctx) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final hours = double.tryParse(_serviceHoursCtrl.text.trim());
      final issueDateStr = _issueDate != null
          ? '${_issueDate!.year}-${_issueDate!.month.toString().padLeft(2, '0')}-${_issueDate!.day.toString().padLeft(2, '0')}'
          : null;
      final startStr = _startDate != null
          ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'
          : null;
      final endStr = _endDate != null
          ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
          : null;

      Certificate result;

      if (_cert != null) {
        // Update existing certificate
        result = await CertificateRepository.updateCertificate(
          _cert!.id,
          certificateType: _certType.name,
          activityName: _activityCtrl.text.trim(),
          eventName: _eventNameCtrl.text.trim().isEmpty ? null : _eventNameCtrl.text.trim(),
          programName: _programCtrl.text.trim().isEmpty ? null : _programCtrl.text.trim(),
          studentIdNumber: _studentIdNumCtrl.text.trim().isEmpty ? null : _studentIdNumCtrl.text.trim(),
          studentRole: _studentRoleCtrl.text.trim().isEmpty ? null : _studentRoleCtrl.text.trim(),
          workDescription: _workDescCtrl.text.trim().isEmpty ? null : _workDescCtrl.text.trim(),
          serviceHours: hours,
          startDate: startStr,
          endDate: endStr,
          issueDate: issueDateStr,
          signatoryName: _signatoryNameCtrl.text.trim().isEmpty ? null : _signatoryNameCtrl.text.trim(),
          signatoryTitle: _signatoryTitleCtrl.text.trim().isEmpty ? null : _signatoryTitleCtrl.text.trim(),
          signatureUrl: _signatureUrlCtrl.text.trim().isEmpty ? null : _signatureUrlCtrl.text.trim(),
          remarks: _remarksCtrl.text.trim().isEmpty ? null : _remarksCtrl.text.trim(),
          impactStorySummary: _impactSummaryCtrl.text.trim().isEmpty ? null : _impactSummaryCtrl.text.trim(),
        );
      } else {
        // Create new certificate from prefill data
        final studentId = _pre?['student_id'] as int?;
        if (studentId == null) throw Exception('Student ID missing from prefill data');
        result = await CertificateRepository.createCertificate(
          studentId: studentId,
          certificateType: _certType.name,
          activityName: _activityCtrl.text.trim(),
          eventName: _eventNameCtrl.text.trim().isEmpty ? null : _eventNameCtrl.text.trim(),
          programName: _programCtrl.text.trim().isEmpty ? null : _programCtrl.text.trim(),
          studentIdNumber: _studentIdNumCtrl.text.trim().isEmpty ? null : _studentIdNumCtrl.text.trim(),
          studentRole: _studentRoleCtrl.text.trim().isEmpty ? null : _studentRoleCtrl.text.trim(),
          workDescription: _workDescCtrl.text.trim().isEmpty ? null : _workDescCtrl.text.trim(),
          serviceHours: hours,
          startDate: startStr,
          endDate: endStr,
          issueDate: issueDateStr,
          signatoryName: _signatoryNameCtrl.text.trim().isEmpty ? null : _signatoryNameCtrl.text.trim(),
          signatoryTitle: _signatoryTitleCtrl.text.trim().isEmpty ? null : _signatoryTitleCtrl.text.trim(),
          signatureUrl: _signatureUrlCtrl.text.trim().isEmpty ? null : _signatureUrlCtrl.text.trim(),
          remarks: _remarksCtrl.text.trim().isEmpty ? null : _remarksCtrl.text.trim(),
          impactStorySummary: _impactSummaryCtrl.text.trim().isEmpty ? null : _impactSummaryCtrl.text.trim(),
          eventId: _pre?['event_id'] as int?,
          activityId: _pre?['activity_id'] as int?,
        );
      }

      if (!ctx.mounted) return;
      Navigator.of(ctx).pop(result);
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(_cert != null
            ? 'Certificate details updated.'
            : 'Certificate created — ID: ${result.certificateId}'),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('Save failed: $e'),
        backgroundColor: AppColors.softRed,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext ctx) {
    final studentName = _cert?.studentName ??
        _pre?['student_name'] as String? ??
        'Student';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _cert != null ? 'Edit Certificate Details' : 'New Certificate Details',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: AppColors.ink,
              ),
            ),
            Text(
              studentName,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton.icon(
              onPressed: () => _save(ctx),
              icon: const Icon(Icons.save_rounded, size: 16),
              label: const Text('Save'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Certificate Type ──────────────────────────────────────────
            _section('Certificate Type'),
            _card(
              child: DropdownButtonFormField<CertificateType>(
                initialValue: _certType,
                decoration: _dec('Certificate Type'),
                items: CertificateType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.displayName, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setState(() => _certType = v!),
              ),
            ),
            const SizedBox(height: 16),

            // ── Activity & Event ──────────────────────────────────────────
            _section('Activity & Event'),
            _card(
              child: Column(
                children: [
                  _field(_activityCtrl, 'Activity / Work Title *', required: true),
                  const SizedBox(height: 12),
                  _field(_eventNameCtrl, 'Event Name (optional)'),
                  const SizedBox(height: 12),
                  _field(_programCtrl, 'NGO Programme Name (optional)'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Student Details ───────────────────────────────────────────
            _section('Student Details'),
            _card(
              child: Column(
                children: [
                  _readonlyRow('Student Name', studentName),
                  const SizedBox(height: 12),
                  _field(_studentIdNumCtrl, 'Roll / Enrollment Number'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _studentRoleCtrl.text.isEmpty ? 'Volunteer' : _studentRoleCtrl.text,
                    decoration: _dec('Student Role'),
                    items: ['Volunteer', 'Intern', 'Student', 'Participant', 'Organizer']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _studentRoleCtrl.text = v;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Work Description ──────────────────────────────────────────
            _section('Work Description'),
            _card(
              child: Column(
                children: [
                  TextFormField(
                    controller: _workDescCtrl,
                    maxLines: 4,
                    decoration: _dec('Describe the work / contribution'),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _serviceHoursCtrl,
                    'Service Hours',
                    hint: 'e.g. 40',
                    inputType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Dates ─────────────────────────────────────────────────────
            _section('Service Dates'),
            _card(
              child: Column(
                children: [
                  _dateTile(ctx, 'Start Date', _startDate, (d) => setState(() => _startDate = d)),
                  const Divider(height: 1),
                  _dateTile(ctx, 'End Date', _endDate, (d) => setState(() => _endDate = d)),
                  const Divider(height: 1),
                  _dateTile(ctx, 'Issue Date *', _issueDate, (d) => setState(() => _issueDate = d), required: true),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Signatory ─────────────────────────────────────────────────
            _section('Authorized By'),
            _card(
              child: Column(
                children: [
                  _field(_signatoryNameCtrl, 'Approved By (Name)'),
                  const SizedBox(height: 12),
                  _field(_signatoryTitleCtrl, 'Designation / Title'),
                  const SizedBox(height: 12),
                  _field(
                    _signatureUrlCtrl,
                    'Signature Image URL',
                    hint: 'https://… or /uploads/…',
                    inputType: TextInputType.url,
                  ),
                  if (_signatureUrlCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _signatureUrlCtrl.text,
                        height: 60,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Text(
                          'Could not load signature preview',
                          style: TextStyle(color: AppColors.muted, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Remarks & Impact ──────────────────────────────────────────
            _section('Remarks & Impact Story'),
            _card(
              child: Column(
                children: [
                  TextFormField(
                    controller: _remarksCtrl,
                    maxLines: 2,
                    decoration: _dec('Certificate Remarks (optional)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _impactSummaryCtrl,
                    maxLines: 3,
                    decoration: _dec(
                      'Impact Story Summary',
                      hint: 'A short summary used when creating an impact story from this certificate…',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Save button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : () => _save(ctx),
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  _saving ? 'Saving…' : (_cert != null ? 'Update Certificate Details' : 'Save & Create Certificate'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Widget helpers ─────────────────────────────────────────────────────────

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.muted,
            letterSpacing: 1.2,
          ),
        ),
      );

  Widget _card({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      );

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        labelStyle: const TextStyle(fontSize: 13),
      );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    bool required = false,
    TextInputType? inputType,
    List<TextInputFormatter>? inputFormatters,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: inputType,
        inputFormatters: inputFormatters,
        decoration: _dec(label, hint: hint),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
            : null,
      );

  Widget _readonlyRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _dateTile(
    BuildContext ctx,
    String label,
    DateTime? value,
    void Function(DateTime) onPick, {
    bool required = false,
  }) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        dense: true,
        title: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _fmt(value),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: value != null ? AppColors.ink : AppColors.muted,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.muted),
          ],
        ),
        onTap: () => _pickDate(ctx, value, label, onPick),
      );
}
