import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/bank_info.dart';
import '../../models/ngo_profile.dart';
import '../../repositories/admin_settings_repository.dart';
import '../../repositories/bank_repository.dart';
import '../../repositories/ngo_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../profile/profile_view.dart';

/// Admin Settings tab: change password, edit the NGO contact/registration
/// details and donation UPI/bank details shown across every role's home and
/// donation screens, and logout. Deliberately minimal — every other admin
/// settings module (roles, audit logs, announcements, app settings) was
/// removed per product decision to keep this screen to just these three
/// things.
class AdminSettingsView extends StatefulWidget {
  const AdminSettingsView({super.key});

  @override
  State<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends State<AdminSettingsView> {
  final _authVm = AuthViewModel();

  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  String? _error;

  Map<String, dynamic> _ngoProfile = {};
  Map<String, dynamic> _bank = {};

  final _phoneCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _acctCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _regCtrl.dispose();
    _locationCtrl.dispose();
    _holderCtrl.dispose();
    _bankNameCtrl.dispose();
    _acctCtrl.dispose();
    _ifscCtrl.dispose();
    _upiCtrl.dispose();
    _authVm.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        AdminSettingsRepository.ngoProfile(),
        AdminSettingsRepository.bank(),
      ]);
      _ngoProfile = results[0];
      _bank = results[1];
      _phoneCtrl.text =
          (_ngoProfile['phone'] as String?) ?? NGOProfile.fallback.phone ?? '';
      _regCtrl.text = (_ngoProfile['registration_number'] as String?) ??
          NGOProfile.fallback.registrationNumber ??
          '';
      _locationCtrl.text = (_ngoProfile['address'] as String?) ?? '';
      _holderCtrl.text = (_bank['account_holder'] as String?) ??
          BankInfo.fallback.accountHolder ??
          '';
      _bankNameCtrl.text =
          (_bank['bank_name'] as String?) ?? BankInfo.fallback.bankName ?? '';
      _acctCtrl.text = (_bank['account_number'] as String?) ??
          BankInfo.fallback.accountNumber ??
          '';
      _ifscCtrl.text =
          (_bank['ifsc_code'] as String?) ?? BankInfo.fallback.ifscCode ?? '';
      _upiCtrl.text =
          (_bank['upi_id'] as String?) ?? BankInfo.fallback.upiId ?? '';
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$e';
        });
      }
    }
  }

  Future<void> _confirmAndSave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save changes?'),
        content: const Text(
          'These details are shown to every volunteer, student, and event '
          'manager for donations and contact. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true) await _save();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AdminSettingsRepository.updateNgoProfile({
        ..._ngoProfile,
        'phone': _phoneCtrl.text.trim(),
        'registration_number': _regCtrl.text.trim(),
        'address': _locationCtrl.text.trim(),
      });
      await AdminSettingsRepository.updateBank({
        'account_holder': _holderCtrl.text.trim(),
        'bank_name': _bankNameCtrl.text.trim(),
        'account_number': _acctCtrl.text.trim(),
        'ifsc_code': _ifscCtrl.text.trim(),
        'upi_id': _upiCtrl.text.trim(),
        'qr_url': _bank['qr_url'],
      });
      NGORepository.clearCache();
      BankRepository.clearCache();
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NGO & donation details updated.'),
            backgroundColor: Color(0xFF18B86D),
          ),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.softRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancelEdit() async {
    setState(() => _editing = false);
    await _load();
  }

  Future<void> _openChangePassword() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangePasswordSheet(
        onSave: (currentPw, newPw) async {
          final error = await _authVm.changePassword(
            currentPassword: currentPw,
            newPassword: newPw,
          );
          if (!mounted) return;
          if (error == null) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password changed successfully.'),
                backgroundColor: Color(0xFF18B86D),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: AppColors.softRed),
            );
          }
        },
      ),
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _authVm.logout();
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: TextButton(
          onPressed: _load,
          child: Text('Retry\n$_error', textAlign: TextAlign.center),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Admin Settings',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 27,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Account security and NGO / donation details shared across the app.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),

        _SectionCard(
          icon: Icons.lock_outline_rounded,
          title: 'Account Security',
          subtitle: 'Change your admin password using your current password.',
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openChangePassword,
              icon: const Icon(Icons.password_rounded),
              label: const Text('Change Password'),
            ),
          ),
        ),
        const SizedBox(height: 16),

        _SectionCard(
          icon: Icons.corporate_fare_rounded,
          title: 'NGO & Donation Details',
          subtitle:
              'Shown on every role\'s home screen and on the Volunteer '
              'donation page. Pre-filled with the details currently in use.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetField(
                controller: _phoneCtrl,
                label: 'Contact Phone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                enabled: _editing,
              ),
              const SizedBox(height: 12),
              SheetField(
                controller: _regCtrl,
                label: 'Registration Number',
                icon: Icons.badge_outlined,
                enabled: _editing,
              ),
              const SizedBox(height: 12),
              SheetField(
                controller: _locationCtrl,
                label: 'Location / Address',
                icon: Icons.location_on_outlined,
                enabled: _editing,
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 18),
              const Text(
                'Official Donation Account',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const SizedBox(height: 12),
              SheetField(
                controller: _holderCtrl,
                label: 'Account Holder',
                icon: Icons.person_outline_rounded,
                enabled: _editing,
              ),
              const SizedBox(height: 12),
              SheetField(
                controller: _bankNameCtrl,
                label: 'Bank Name',
                icon: Icons.account_balance_outlined,
                enabled: _editing,
              ),
              const SizedBox(height: 12),
              SheetField(
                controller: _acctCtrl,
                label: 'Account Number',
                icon: Icons.pin_outlined,
                enabled: _editing,
              ),
              const SizedBox(height: 12),
              SheetField(
                controller: _ifscCtrl,
                label: 'IFSC Code',
                icon: Icons.tag_outlined,
                enabled: _editing,
              ),
              const SizedBox(height: 12),
              SheetField(
                controller: _upiCtrl,
                label: 'UPI ID',
                icon: Icons.smartphone_outlined,
                enabled: _editing,
              ),
              const SizedBox(height: 18),
              if (_editing) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : _cancelEdit,
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _confirmAndSave,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(_saving ? 'Saving…' : 'Save Changes'),
                      ),
                    ),
                  ],
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _editing = true),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Details'),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded, color: Colors.red),
          label: const Text('Logout', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
