import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/volunteer_models.dart';
import '../../repositories/volunteer_repository.dart';
import '../../viewmodels/volunteer_viewmodel.dart';

class WorkSubmissionScreen extends StatefulWidget {
  const WorkSubmissionScreen({
    required this.vm,
    this.assignment,
    this.preselectedActivity,
    this.existingSubmission,
    super.key,
  });
  final VolunteerViewModel vm;
  final ActivityAssignment? assignment;
  final VolunteerActivity? preselectedActivity;
  /// When set, pre-fills the form with previous submission data for editing.
  final WorkSubmission? existingSubmission;

  @override
  State<WorkSubmissionScreen> createState() => _WorkSubmissionScreenState();
}

class _WorkSubmissionScreenState extends State<WorkSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController(text: '1');
  final _peopleCtrl = TextEditingController(text: '0');
  final _donationCtrl = TextEditingController(text: '0');
  final _txnCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  VolunteerActivity? _selectedActivity;
  bool _submitting = false;
  bool _submitted = false;

  // Proof files: list of {name, url} after upload
  final List<({String name, String url})> _proofFiles = [];
  bool _uploadingProof = false;

  bool get _isEditing => widget.existingSubmission != null;

  @override
  void initState() {
    super.initState();
    final pre = widget.preselectedActivity ?? widget.assignment?.activity;
    if (pre != null) {
      // Sync to the same instance in the assigned-activities list so the
      // DropdownButton equality check (now based on id) finds exactly one match.
      _selectedActivity = _assignedActivities
          .firstWhere((a) => a.id == pre.id, orElse: () => pre);
    }
    // Pre-fill form with existing submission data when editing.
    final existing = widget.existingSubmission;
    if (existing != null) {
      _titleCtrl.text = existing.title;
      _descCtrl.text = existing.description;
      _hoursCtrl.text = existing.hoursWorked.toString();
      _peopleCtrl.text = existing.peopleReached.toString();
      _donationCtrl.text = existing.donationCollected.toString();
      _txnCtrl.text = existing.transactionId ?? '';
      _remarksCtrl.text = existing.remarks ?? '';
      // Restore previously uploaded proof file URLs.
      if (existing.proofFiles != null && existing.proofFiles!.isNotEmpty) {
        try {
          final urls = (jsonDecode(existing.proofFiles!) as List)
              .whereType<String>()
              .toList();
          for (final url in urls) {
            final name = url.split('/').last;
            _proofFiles.add((name: name, url: url));
          }
        } catch (_) {}
      }
    }
  }

  // Only show activities the student is assigned to; fallback to all if none loaded.
  List<VolunteerActivity> get _assignedActivities {
    final assigned = widget.vm.assignments
        .map((a) => a.activity)
        .whereType<VolunteerActivity>()
        .toList();
    return assigned.isNotEmpty ? assigned : widget.vm.activities;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _hoursCtrl.dispose();
    _peopleCtrl.dispose();
    _donationCtrl.dispose();
    _txnCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadProof() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'mp4', 'mov'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    setState(() => _uploadingProof = true);
    int uploaded = 0;
    for (final file in result.files) {
      if (file.bytes == null) continue;
      try {
        final url = await VolunteerRepository.uploadProofFile(
          bytes: file.bytes!,
          fileName: file.name,
        );
        setState(() {
          _proofFiles.add((name: file.name, url: url));
          uploaded++;
        });
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload ${file.name}'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
    if (mounted) setState(() => _uploadingProof = false);
    if (uploaded > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$uploaded file${uploaded > 1 ? 's' : ''} uploaded'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedActivity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an activity')),
      );
      return;
    }
    setState(() => _submitting = true);
    final proofFilesJson = _proofFiles.isEmpty
        ? null
        : jsonEncode(_proofFiles.map((f) => f.url).toList());
    final result = await widget.vm.submitWork(
      activityId: _selectedActivity!.id,
      assignmentId: widget.assignment?.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      hoursWorked: double.tryParse(_hoursCtrl.text) ?? 0,
      peopleReached: int.tryParse(_peopleCtrl.text) ?? 0,
      donationCollected: double.tryParse(_donationCtrl.text) ?? 0,
      transactionId: _txnCtrl.text.trim().isEmpty ? null : _txnCtrl.text.trim(),
      remarks: _remarksCtrl.text.trim().isEmpty ? null : _remarksCtrl.text.trim(),
      proofFiles: proofFilesJson,
    );
    setState(() {
      _submitting = false;
      _submitted = result != null;
    });
    if (result == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Update Submission' : 'Submit Work',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: _submitted ? _SuccessView(onDone: () => Navigator.of(context).pop(), isUpdate: _isEditing) : _formBody(),
    );
  }

  Widget _formBody() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Activity selector — locked when coming from an assignment card
          _SectionLabel(label: 'Activity *'),
          if (widget.assignment != null && _selectedActivity != null)
            _ActivityLockedTile(activity: _selectedActivity!)
          else
            _ActivityDropdown(
              activities: _assignedActivities,
              selected: _selectedActivity,
              onChanged: (a) => setState(() => _selectedActivity = a),
            ),
          const SizedBox(height: 14),

          _SectionLabel(label: 'Work Title *'),
          _Field(
            controller: _titleCtrl,
            hint: 'e.g. Cyber Safety Awareness Camp',
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
          ),
          const SizedBox(height: 14),

          _SectionLabel(label: 'Description *'),
          _Field(
            controller: _descCtrl,
            hint: 'What work did you do? How did it help?',
            maxLines: 4,
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(label: 'Hours Worked'),
                    _Field(
                      controller: _hoursCtrl,
                      hint: '0',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(label: 'People Reached'),
                    _Field(
                      controller: _peopleCtrl,
                      hint: '0',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _SectionLabel(label: 'Donation Collected (₹)'),
          _Field(
            controller: _donationCtrl,
            hint: '0',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),

          _SectionLabel(label: 'Transaction ID (UPI/Bank)'),
          _Field(
            controller: _txnCtrl,
            hint: 'Optional — UPI ref or bank transfer ID',
          ),
          const SizedBox(height: 14),

          _SectionLabel(label: 'Remarks'),
          _Field(
            controller: _remarksCtrl,
            hint: 'Any notes for the reviewer',
            maxLines: 2,
          ),
          const SizedBox(height: 14),

          // ── Proof Upload ────────────────────────────────────────────────────
          _ProofUploadSection(
            files: _proofFiles,
            uploading: _uploadingProof,
            disabled: _submitting,
            onPickFiles: _pickAndUploadProof,
            onRemove: (i) => setState(() => _proofFiles.removeAt(i)),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Submitted → Under Review → Approved / Rejected → Certificate Eligible',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: (_submitting || _uploadingProof) ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_submitting
                ? (_isEditing ? 'Updating…' : 'Submitting…')
                : (_isEditing ? 'Update & Resubmit' : 'Submit Work')),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Proof Upload Section ──────────────────────────────────────────────────────

class _ProofUploadSection extends StatelessWidget {
  const _ProofUploadSection({
    required this.files,
    required this.uploading,
    required this.disabled,
    required this.onPickFiles,
    required this.onRemove,
  });

  final List<({String name, String url})> files;
  final bool uploading;
  final bool disabled;
  final VoidCallback onPickFiles;
  final void Function(int index) onRemove;

  IconData _iconFor(String name) {
    final ext = name.split('.').last.toLowerCase();
    if ({'jpg', 'jpeg', 'png', 'webp'}.contains(ext)) return Icons.image_rounded;
    if (ext == 'pdf') return Icons.picture_as_pdf_rounded;
    if ({'mp4', 'mov'}.contains(ext)) return Icons.videocam_rounded;
    return Icons.attach_file_rounded;
  }

  Color _colorFor(String name) {
    final ext = name.split('.').last.toLowerCase();
    if ({'jpg', 'jpeg', 'png', 'webp'}.contains(ext)) return Colors.teal;
    if (ext == 'pdf') return Colors.red.shade700;
    if ({'mp4', 'mov'}.contains(ext)) return Colors.purple;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionLabel(label: 'Proof / Evidence'),
            ),
            Text(
              'Photo · PDF · Video',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.muted.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Uploaded file chips
        if (files.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(files.length, (i) {
              final f = files[i];
              return Container(
                constraints: const BoxConstraints(maxWidth: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _colorFor(f.name).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _colorFor(f.name).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_iconFor(f.name), size: 15, color: _colorFor(f.name)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        f.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _colorFor(f.name),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (!disabled)
                      GestureDetector(
                        onTap: () => onRemove(i),
                        child: Icon(Icons.close_rounded,
                            size: 14, color: _colorFor(f.name)),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
        ],
        // Pick files button
        InkWell(
          onTap: (disabled || uploading) ? null : onPickFiles,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: uploading
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.muted.withValues(alpha: 0.3),
                width: uploading ? 1.5 : 1,
              ),
            ),
            child: uploading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Uploading…',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_file_rounded,
                        size: 20,
                        color: AppColors.muted.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        files.isEmpty
                            ? 'Attach proof files (optional)'
                            : 'Add more files',
                        style: TextStyle(
                          color: AppColors.muted.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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

// ── Supporting widgets ────────────────────────────────────────────────────────

class _ActivityLockedTile extends StatelessWidget {
  const _ActivityLockedTile({required this.activity});
  final VolunteerActivity activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.muted.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              activity.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          Icon(Icons.lock_outline_rounded,
              size: 15, color: AppColors.muted.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}

class _ActivityDropdown extends StatelessWidget {
  const _ActivityDropdown({
    required this.activities,
    required this.selected,
    required this.onChanged,
  });
  final List<VolunteerActivity> activities;
  final VolunteerActivity? selected;
  final ValueChanged<VolunteerActivity?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<VolunteerActivity>(
      initialValue: selected,
      hint: const Text('Select activity'),
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppColors.muted.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppColors.muted.withValues(alpha: 0.3)),
        ),
      ),
      items: activities
          .map((a) => DropdownMenuItem(
                value: a,
                child: Text(a.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: AppColors.muted.withValues(alpha: 0.6), fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppColors.muted.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppColors.muted.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.onDone, this.isUpdate = false});
  final VoidCallback onDone;
  final bool isUpdate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  size: 56, color: AppColors.secondary),
            ),
            const SizedBox(height: 20),
            Text(
              isUpdate ? 'Submission Updated!' : 'Work Submitted!',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUpdate
                  ? 'Your submission has been updated and sent back for review.'
                  : 'Your work has been submitted for review. The event manager will verify it and update your profile.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(200, 46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
