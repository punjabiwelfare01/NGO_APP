import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/counsellor_models.dart';
import '../../viewmodels/counsellor_viewmodel.dart';

class CounsellorAdminScreen extends StatefulWidget {
  const CounsellorAdminScreen({super.key});

  @override
  State<CounsellorAdminScreen> createState() => _CounsellorAdminScreenState();
}

class _CounsellorAdminScreenState extends State<CounsellorAdminScreen> {
  final _vm = CounsellorViewModel.shared;

  @override
  void initState() {
    super.initState();
    _vm.load();
    _vm.loadAllAdminRequests();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Counsellor Administration'),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      actions: [
        IconButton(
          onPressed: () => _showAddForm(context),
          tooltip: 'Add counsellor',
          icon: const Icon(Icons.person_add_alt_1_rounded),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _showAddForm(context),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add Counsellor'),
    ),
    body: ListenableBuilder(
      listenable: _vm,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 96),
        children: [
          _privacyBanner(),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _stat(
                'Total',
                _vm.adminCounsellors.length,
                Icons.groups_rounded,
                const Color(0xFF1565C0),
              ),
              _stat(
                'Verified',
                _vm.adminCounsellors.where((c) => c.isVerified).length,
                Icons.verified_rounded,
                const Color(0xFF2E7D32),
              ),
              _stat(
                'Pending',
                _vm.adminCounsellors
                    .where(
                      (c) => c.verificationStatus == VerificationStatus.pending,
                    )
                    .length,
                Icons.pending_actions_rounded,
                const Color(0xFFF57F17),
              ),
              _stat(
                'Requests',
                _vm.allAdminRequests.length,
                Icons.event_note_rounded,
                const Color(0xFF6A1B9A),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Counsellor Profiles',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          for (final c in _vm.adminCounsellors) ...[
            _profileCard(context, c),
            const SizedBox(height: 12),
          ],
        ],
      ),
    ),
  );

  Widget _privacyBanner() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF2E7D32)),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Restricted admin area. Verification documents are for internal review only. Never publish Aadhaar, PAN, service IDs, phone numbers or home addresses.',
            style: TextStyle(
              color: Color(0xFF1B5E20),
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _stat(String label, int value, IconData icon, Color color) =>
      Container(
        width: 150,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _profileCard(BuildContext context, CounsellorProfile c) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(
        color: c.verificationStatus.color.withValues(alpha: .2),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: c.category.color.withValues(alpha: .12),
              child: Text(
                c.initialsAvatar,
                style: TextStyle(
                  color: c.category.color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.ngoVerificationId,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            _statusChip(c.verificationStatus),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          c.category.label,
          style: TextStyle(
            color: c.category.color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          c.designation,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _flag(
              c.isActive ? 'Public' : 'Hidden',
              c.isActive
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
            ),
            if (c.isFeatured) _flag('Featured', Icons.star_rounded),
            _flag(
              c.availableThisWeek ? 'Available' : 'Not this week',
              Icons.calendar_today_rounded,
            ),
            _flag(
              '${_vm.requestsForCounsellor(c.id).length} requests',
              Icons.event_note_rounded,
            ),
          ],
        ),
        const Divider(height: 24),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (!c.isVerified)
              FilledButton.icon(
                onPressed: () => _verify(c),
                icon: const Icon(Icons.verified_rounded, size: 17),
                label: const Text('Verify'),
              ),
            OutlinedButton.icon(
              onPressed: () =>
                  _vm.updateCounsellor(c.copyWith(isActive: !c.isActive)),
              icon: Icon(
                c.isActive
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 17,
              ),
              label: Text(c.isActive ? 'Hide' : 'Approve Public'),
            ),
            OutlinedButton.icon(
              onPressed: () => _vm.toggleFeatured(c.id),
              icon: const Icon(Icons.star_outline_rounded, size: 17),
              label: const Text('Featured'),
            ),
            OutlinedButton.icon(
              onPressed: () => _manageAvailability(context, c),
              icon: const Icon(Icons.schedule_rounded, size: 17),
              label: const Text('Availability'),
            ),
            OutlinedButton.icon(
              onPressed: () => _showRequests(context, c),
              icon: const Icon(Icons.inbox_rounded, size: 17),
              label: const Text('Requests'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _statusChip(VerificationStatus status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: status.color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(status.icon, size: 13, color: status.color),
        const SizedBox(width: 4),
        Text(
          status.label,
          style: TextStyle(
            color: status.color,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _flag(String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
      ],
    ),
  );

  void _verify(CounsellorProfile c) {
    _vm.updateCounsellor(
      c.copyWith(verificationStatus: VerificationStatus.verified),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Designation and qualification marked verified. Public service status still requires counsellor consent.',
        ),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  Future<void> _manageAvailability(
    BuildContext context,
    CounsellorProfile c,
  ) async {
    final controller = TextEditingController(text: c.availableSlots.join('\n'));
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Availability — ${c.name}'),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
          child: SingleChildScrollView(
            child: TextField(
              controller: controller,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'One public time slot per line',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) {
      _vm.updateCounsellor(
        c.copyWith(
          availableSlots: result
              .split('\n')
              .where((e) => e.trim().isNotEmpty)
              .toList(),
          availableThisWeek: result.trim().isNotEmpty,
        ),
      );
    }
  }

  void _showRequests(BuildContext context, CounsellorProfile c) {
    final requests = _vm.requestsForCounsellor(c.id);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Requests for ${c.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              if (requests.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No school requests yet.'),
                )
              else
                for (final r in requests)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: r.status.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.school_rounded,
                          color: r.status.color, size: 18),
                    ),
                    title: Text(r.schoolName,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${r.topic} • ${r.preferredDate.day}/${r.preferredDate.month}/${r.preferredDate.year}',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: r.status.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        r.status.label,
                        style: TextStyle(
                          color: r.status.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddForm(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddCounsellorSheet(vm: _vm),
  );
}

class _AddCounsellorSheet extends StatefulWidget {
  const _AddCounsellorSheet({required this.vm});
  final CounsellorViewModel vm;
  @override
  State<_AddCounsellorSheet> createState() => _AddCounsellorSheetState();
}

class _AddCounsellorSheetState extends State<_AddCounsellorSheet> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _designation = TextEditingController();
  final _qualification = TextEditingController();
  final _expertise = TextEditingController();
  final _languages = TextEditingController(text: 'Punjabi, Hindi, English');
  final _bio = TextEditingController();
  CounsellorCategory _category = CounsellorCategory.careerGuidanceCounsellor;
  SessionMode _mode = SessionMode.both;
  String? _profilePhoto;
  final List<String> _privateDocuments = [];

  @override
  void dispose() {
    for (final c in [
      _name,
      _designation,
      _qualification,
      _expertise,
      _languages,
      _bio,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(bool privateDocument) async {
    final result = await FilePicker.platform.pickFiles(
      type: privateDocument ? FileType.custom : FileType.image,
      allowedExtensions: privateDocument ? ['pdf', 'jpg', 'jpeg', 'png'] : null,
    );
    if (result == null) return;
    setState(() {
      if (privateDocument) {
        _privateDocuments.add(result.files.single.name);
      } else {
        _profilePhoto = result.files.single.name;
      }
    });
  }

  void _save() {
    if (!_key.currentState!.validate()) return;
    final id = DateTime.now().millisecondsSinceEpoch;
    widget.vm.addCounsellor(
      CounsellorProfile(
        id: id,
        ngoVerificationId:
            'PWT-COUN-2026-${(widget.vm.adminCounsellors.length + 1).toString().padLeft(3, '0')}',
        name: _name.text.trim(),
        category: _category,
        designation: _designation.text.trim(),
        serviceBackground: _designation.text.trim(),
        shortBio: _bio.text.trim(),
        qualifications: [_qualification.text.trim()],
        expertiseAreas: _expertise.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        sessionTopics: _expertise.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        languages: _languages.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        sessionMode: _mode,
        availableSlots: const [],
        yearsOfExperience: 0,
        schoolSessionsCompleted: 0,
        studentsGuided: 0,
        recognitionProof: const [],
        verificationStatus: VerificationStatus.pending,
        isActive: false,
      ),
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile saved as pending. ${_privateDocuments.length} private document(s) queued for admin review; none are public.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: .92,
    maxChildSize: .96,
    builder: (_, scroll) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _key,
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(20, 20, 20,
              20 + MediaQuery.of(context).viewInsets.bottom),
          children: [
            const Text(
              'Add Counsellor Profile',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'New profiles stay hidden until verification and public approval.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            _field(_name, 'Full name'),
            DropdownButtonFormField<CounsellorCategory>(
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Counsellor category',
                border: OutlineInputBorder(),
              ),
              items: CounsellorCategory.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            _field(_designation, 'Designation / service background'),
            _field(_qualification, 'Qualification'),
            _field(_expertise, 'Expertise areas, comma separated'),
            _field(_languages, 'Languages, comma separated'),
            _field(_bio, 'Professional bio', lines: 3),
            DropdownButtonFormField<SessionMode>(
              initialValue: _mode,
              decoration: const InputDecoration(
                labelText: 'Session mode',
                border: OutlineInputBorder(),
              ),
              items: SessionMode.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => setState(() => _mode = v!),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => _pick(false),
              icon: const Icon(Icons.add_a_photo_rounded),
              label: Text(_profilePhoto ?? 'Upload profile photo'),
            ),
            OutlinedButton.icon(
              onPressed: () => _pick(true),
              icon: const Icon(Icons.lock_rounded),
              label: Text(
                _privateDocuments.isEmpty
                    ? 'Upload private verification documents'
                    : '${_privateDocuments.length} private document(s) selected',
              ),
            ),
            const Text(
              'Private documents remain admin-only and are never attached to the public profile.',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save for Verification'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _field(TextEditingController c, String label, {int lines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          maxLines: lines,
          textInputAction: lines == 1 ? TextInputAction.next : null,
          onEditingComplete:
              lines == 1 ? () => FocusScope.of(context).nextFocus() : null,
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );
}
