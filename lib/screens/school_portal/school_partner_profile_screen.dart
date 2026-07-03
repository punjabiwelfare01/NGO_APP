import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/colors.dart';
import '../../models/school_partner_models.dart';
import '../../repositories/api_client.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/school_partner_repository.dart';

class SchoolPartnerProfileScreen extends StatefulWidget {
  const SchoolPartnerProfileScreen({super.key});

  @override
  State<SchoolPartnerProfileScreen> createState() =>
      _SchoolPartnerProfileScreenState();
}

class _SchoolPartnerProfileScreenState
    extends State<SchoolPartnerProfileScreen> {
  // ── state ──────────────────────────────────────────────────────────────────
  SchoolPartnerProfile? _profile;
  bool _loading = true;
  String? _error;
  bool _isEditing = false;
  bool _saving = false;

  // ── controllers ────────────────────────────────────────────────────────────
  final _schoolNameCtrl      = TextEditingController();
  final _regNumberCtrl       = TextEditingController();
  final _addressCtrl         = TextEditingController();
  final _cityCtrl            = TextEditingController();
  final _stateCtrl           = TextEditingController();
  final _pinCodeCtrl         = TextEditingController();
  final _coordinatorNameCtrl = TextEditingController();
  final _designationCtrl     = TextEditingController();
  final _phoneCtrl           = TextEditingController();
  final _altPhoneCtrl        = TextEditingController();

  String? _schoolType;
  String? _schoolBoard;

  static const _schoolTypes  = ['Government', 'Private', 'Aided', 'International'];
  static const _schoolBoards = ['CBSE', 'ICSE', 'State Board', 'IB', 'Other'];

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _schoolNameCtrl.dispose();
    _regNumberCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pinCodeCtrl.dispose();
    _coordinatorNameCtrl.dispose();
    _designationCtrl.dispose();
    _phoneCtrl.dispose();
    _altPhoneCtrl.dispose();
    super.dispose();
  }

  // ── data ──────────────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await SchoolPartnerRepository.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
        _populateControllers(profile);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _populateControllers(SchoolPartnerProfile p) {
    _schoolNameCtrl.text      = p.schoolName ?? '';
    _regNumberCtrl.text       = p.registrationNumber ?? '';
    _addressCtrl.text         = p.address ?? '';
    _cityCtrl.text            = p.city ?? '';
    _stateCtrl.text           = p.state ?? '';
    _pinCodeCtrl.text         = p.pinCode ?? '';
    _coordinatorNameCtrl.text = p.coordinatorName ?? '';
    _designationCtrl.text     = p.coordinatorDesignation ?? '';
    _phoneCtrl.text           = p.phone ?? '';
    _altPhoneCtrl.text        = p.alternatePhone ?? '';
    _schoolType  = _schoolTypes.contains(p.schoolType) ? p.schoolType : null;
    _schoolBoard = _schoolBoards.contains(p.schoolBoard) ? p.schoolBoard : null;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await SchoolPartnerRepository.updateProfile({
        'name': _coordinatorNameCtrl.text.trim(),
        'school_name': _schoolNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        if (_schoolType != null) 'school_type': _schoolType,
        if (_schoolBoard != null) 'school_board': _schoolBoard,
        'registration_number': _regNumberCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'pin_code': _pinCodeCtrl.text.trim(),
        'coordinator_designation': _designationCtrl.text.trim(),
        'alternate_phone': _altPhoneCtrl.text.trim(),
      });
      if (mounted) {
        setState(() {
          _profile = updated;
          _isEditing = false;
          _saving = false;
        });
        _populateControllers(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully.'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.softRed,
          ),
        );
      }
    }
  }

  void _cancelEdit() {
    final p = _profile;
    if (p != null) _populateControllers(p);
    setState(() => _isEditing = false);
  }

  // ── photo upload ──────────────────────────────────────────────────────────

  bool _uploadingPhoto = false;

  Future<void> _pickAndUploadPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final file = result.files.single;
    if (file.bytes == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await SchoolPartnerRepository.uploadLogo(
        file.bytes!,
        file.name,
      );
      if (mounted) {
        setState(() {
          _profile = _profile?.copyWith(photoUrl: url);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Profile photo updated successfully!',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo upload failed: $e'),
            backgroundColor: AppColors.softRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  // ── logout ────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await AuthRepository.logout();
      } catch (_) {}
      AppState.clear();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
      }
    }
  }

  // ── change password ───────────────────────────────────────────────────────

  Future<void> _changePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew     = true;
    bool obscureConfirm = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.7),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentCtrl,
                    obscureText: obscureCurrent,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => FocusScope.of(ctx).nextFocus(),
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      suffixIcon: ExcludeFocus(
                        child: IconButton(
                          icon: Icon(obscureCurrent
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded),
                          onPressed: () => setDialogState(
                              () => obscureCurrent = !obscureCurrent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: newCtrl,
                    obscureText: obscureNew,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => FocusScope.of(ctx).nextFocus(),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      suffixIcon: ExcludeFocus(
                        child: IconButton(
                          icon: Icon(obscureNew
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded),
                          onPressed: () =>
                              setDialogState(() => obscureNew = !obscureNew),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: obscureConfirm,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      suffixIcon: ExcludeFocus(
                        child: IconButton(
                          icon: Icon(obscureConfirm
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded),
                          onPressed: () => setDialogState(
                              () => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    if (newCtrl.text != confirmCtrl.text) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New passwords do not match.'),
            backgroundColor: AppColors.softRed,
          ),
        );
      }
      return;
    }

    try {
      await AuthRepository.changePassword(
        currentPassword: currentCtrl.text,
        newPassword: newCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully.'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.softRed,
          ),
        );
      }
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('School Profile'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: _isEditing
            ? [
                TextButton(
                  onPressed: _saving ? null : _cancelEdit,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 4),
              ]
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.softRed, size: 48),
          const SizedBox(height: 12),
          Text(
            'Failed to load profile',
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _error ?? '',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  Widget _buildBody() {
    final p = _profile!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(p),
        const SizedBox(height: 18),
        _buildSection(
          title: 'School Details',
          icon: Icons.school_rounded,
          children: [
            _field('School Name', _schoolNameCtrl, enabled: _isEditing),
            const SizedBox(height: 12),
            _dropdownField(
              label: 'School Type',
              value: _schoolType,
              items: _schoolTypes,
              enabled: _isEditing,
              onChanged: (v) => setState(() => _schoolType = v),
            ),
            const SizedBox(height: 12),
            _dropdownField(
              label: 'School Board',
              value: _schoolBoard,
              items: _schoolBoards,
              enabled: _isEditing,
              onChanged: (v) => setState(() => _schoolBoard = v),
            ),
            const SizedBox(height: 12),
            _field('Registration Number', _regNumberCtrl, enabled: _isEditing),
            const SizedBox(height: 12),
            _field('Address', _addressCtrl,
                enabled: _isEditing, maxLines: 2),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _field('City', _cityCtrl, enabled: _isEditing)),
                const SizedBox(width: 10),
                Expanded(
                    child: _field('State', _stateCtrl, enabled: _isEditing)),
              ],
            ),
            const SizedBox(height: 12),
            _field('Pin Code', _pinCodeCtrl,
                enabled: _isEditing,
                keyboardType: TextInputType.number),
          ],
        ),
        const SizedBox(height: 14),
        _buildSection(
          title: 'Contact Person',
          icon: Icons.person_rounded,
          children: [
            _field('Coordinator Name', _coordinatorNameCtrl,
                enabled: _isEditing),
            const SizedBox(height: 12),
            _field('Designation', _designationCtrl, enabled: _isEditing),
            const SizedBox(height: 12),
            _field('Phone Number', _phoneCtrl,
                enabled: _isEditing,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _field('Alternate Phone', _altPhoneCtrl,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
                isLastField: true),
            const SizedBox(height: 12),
            _readOnlyRow('Email', p.email ?? '—'),
          ],
        ),
        const SizedBox(height: 14),
        _buildSection(
          title: 'Partnership Info',
          icon: Icons.verified_rounded,
          children: [
            _readOnlyRow('Partner ID', p.partnerId ?? '—'),
            const SizedBox(height: 10),
            _statusRow(p.accessStatus),
            if (p.joinedDate != null) ...[
              const SizedBox(height: 10),
              _readOnlyRow(
                  'Joined Date', _formatDate(p.joinedDate)),
            ],
            if (p.verificationNote != null &&
                p.verificationNote!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFF9A825).withValues(alpha: .3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFFF57F17), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.verificationNote!,
                        style: const TextStyle(
                          color: Color(0xFF795548),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        _buildSection(
          title: 'Account Actions',
          icon: Icons.settings_rounded,
          children: [
            // Edit / Save
            SizedBox(
              width: double.infinity,
              child: _isEditing
                  ? FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_saving ? 'Saving…' : 'Save Changes'),
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary),
                    )
                  : OutlinedButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit Profile'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side:
                              const BorderSide(color: AppColors.primary)),
                    ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _changePassword,
                icon: const Icon(Icons.lock_outline_rounded),
                label: const Text('Change Password'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: BorderSide(
                      color: AppColors.ink.withValues(alpha: .3)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.softRed,
                  side: BorderSide(
                      color: AppColors.softRed.withValues(alpha: .5)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(SchoolPartnerProfile p) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: .06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        // Avatar with upload button
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: AppColors.primary.withValues(alpha: .12),
              backgroundImage: (p.photoUrl != null && p.photoUrl!.isNotEmpty)
                  ? NetworkImage(ApiClient.resolveUrl(p.photoUrl!))
                  : null,
              child: _uploadingPhoto
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : (p.photoUrl == null || p.photoUrl!.isEmpty)
                      ? Text(
                          p.initials,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : null,
            ),
            GestureDetector(
              onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          p.schoolName ?? 'School Partner',
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        // Partner ID badge
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            p.partnerId ?? 'SP-0000',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Approval status chip
        _statusChip(p.accessStatus),
      ],
    ),
  );

  Widget _statusChip(String? status) {
    final Color color;
    final String label;
    switch (status) {
      case 'approved':
        color = const Color(0xFF2E7D32);
        label = 'Approved';
      case 'rejected':
        color = AppColors.softRed;
        label = 'Rejected';
      default:
        color = const Color(0xFFF57F17);
        label = 'Pending Approval';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 8),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section card ──────────────────────────────────────────────────────────

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: .05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      );

  // ── Field helpers ─────────────────────────────────────────────────────────

  Widget _field(
    String label,
    TextEditingController controller, {
    bool enabled = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool isLastField = false,
  }) =>
      TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textInputAction:
            (maxLines <= 1 && !isLastField) ? TextInputAction.next : null,
        onEditingComplete: (maxLines <= 1 && !isLastField)
            ? () => FocusScope.of(context).nextFocus()
            : null,
        style: const TextStyle(color: AppColors.ink, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
          filled: true,
          fillColor: enabled
              ? Colors.white
              : AppColors.background.withValues(alpha: .7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: AppColors.muted.withValues(alpha: .3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: AppColors.primary.withValues(alpha: .4)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: AppColors.muted.withValues(alpha: .2)),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required bool enabled,
    required ValueChanged<String?> onChanged,
  }) =>
      IgnorePointer(
        ignoring: !enabled,
        child: DropdownButtonFormField<String>(
          initialValue: value,
          hint: Text(label,
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            labelText: label,
            labelStyle:
                const TextStyle(color: AppColors.muted, fontSize: 13),
            filled: true,
            fillColor: enabled
                ? Colors.white
                : AppColors.background.withValues(alpha: .7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: AppColors.muted.withValues(alpha: .3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: AppColors.primary.withValues(alpha: .4)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: AppColors.muted.withValues(alpha: .2)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      );

  Widget _readOnlyRow(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 120,
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );

  Widget _statusRow(String? status) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(
        width: 120,
        child: Text(
          'Status',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      _statusChip(status),
    ],
  );

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')} '
        '${_monthName(dt.month)} ${dt.year}';
  }

  String _monthName(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m];
}
