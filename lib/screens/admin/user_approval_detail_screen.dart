import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/api_models.dart';
import '../../repositories/admin_repository.dart';
import '../../viewmodels/admin_viewmodel.dart';

/// Full profile review page for a pending user.
/// Admin can assign a role or reject the request here.
/// Returns `true` to the caller when any change was made.
class UserApprovalDetailScreen extends StatefulWidget {
  const UserApprovalDetailScreen({
    required this.userId,
    required this.vm,
    super.key,
  });

  final int userId;
  final AdminViewModel vm;

  @override
  State<UserApprovalDetailScreen> createState() =>
      _UserApprovalDetailScreenState();
}

class _UserApprovalDetailScreenState extends State<UserApprovalDetailScreen> {
  final _noteCtrl = TextEditingController();
  String? _selectedRole;
  bool _loading = false;
  bool _changed = false;
  AppUser? _user;
  String? _loadError;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);
    try {
      final user = await AdminRepository.getUserDetail(widget.userId);
      if (mounted) {
        final requestedRole = user.requestedRole == 'counsellor'
            ? 'mentor'
            : user.requestedRole;
        const assignableRoles = {
          'student',
          'mentor',
          'content_creator',
          'event_manager',
          'support_staff',
          'school_partner',
        };
        setState(() {
          _user = user;
          _selectedRole = assignableRoles.contains(requestedRole)
              ? requestedRole
              : null;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadError = 'Could not load user profile.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: BackButton(color: AppColors.ink, onPressed: _close),
          title: const Text(
            'Review Profile',
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? _ErrorBody(error: _loadError!, onRetry: _loadUser)
            : _buildBody(),
      ),
    );
  }

  void _close([bool? result]) {
    if (_closing || !mounted) return;
    _closing = true;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(result ?? _changed);
    } else {
      navigator.pushReplacementNamed('/home');
    }
  }

  Widget _buildBody() {
    final user = _user!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Profile card ─────────────────────────────────────────────
          _ProfileCard(user: user),
          const SizedBox(height: 20),

          // ── Requested role banner ────────────────────────────────────
          if (user.requestedRole != null) ...[
            _SectionLabel('Requested Access'),
            const SizedBox(height: 8),
            _RequestedRoleBanner(role: user.requestedRole!),
            const SizedBox(height: 20),
          ],

          // ── Role assignment ──────────────────────────────────────────
          _SectionLabel('Assign Role'),
          const SizedBox(height: 8),
          _RoleSelector(
            selected: _selectedRole,
            onChanged: (v) => setState(() => _selectedRole = v),
          ),
          const SizedBox(height: 20),

          // ── Verification note ────────────────────────────────────────
          _SectionLabel('Verification Note (optional)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g. Verified by NGO coordinator',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Action buttons ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _reject,
                  icon: const Icon(
                    Icons.cancel_outlined,
                    size: 18,
                    color: AppColors.softRed,
                  ),
                  label: const Text(
                    'Reject Request',
                    style: TextStyle(color: AppColors.softRed),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: AppColors.softRed.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loading || _selectedRole == null
                      ? null
                      : _approve,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                        ),
                  label: const Text('Approve & Assign'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approve() async {
    if (_selectedRole == null) return;
    final confirmed = await _confirm(
      title: 'Approve as ${_roleLabel(_selectedRole!)}?',
      body:
          '${_user!.name} will be granted access to the ${_roleLabel(_selectedRole!)} dashboard.',
      confirmLabel: 'Approve',
      confirmColor: AppColors.accent,
    );
    if (!confirmed || !mounted) return;

    setState(() => _loading = true);
    final ok = await widget.vm.assignRole(
      userId: widget.userId,
      role: _selectedRole!,
      verificationNote: _noteCtrl.text.trim().isEmpty
          ? null
          : _noteCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      _changed = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_user!.name} approved as ${_roleLabel(_selectedRole!)}.',
          ),
          backgroundColor: AppColors.accent,
        ),
      );
      _close(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.vm.errorMessage ?? 'Failed to assign role.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }

  Future<void> _reject() async {
    final confirmed = await _confirm(
      title: 'Reject request?',
      body: "${_user!.name}'s access request will be marked as rejected.",
      confirmLabel: 'Reject',
      confirmColor: AppColors.softRed,
    );
    if (!confirmed || !mounted) return;

    setState(() => _loading = true);
    final ok = await widget.vm.rejectUser(widget.userId);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      _changed = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request rejected.')));
      _close(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.vm.errorMessage ?? 'Failed to reject.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Text(body, style: const TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static String _roleLabel(String role) => switch (role) {
    'mentor' || 'counsellor' => 'Counsellor',
    'content_creator' => 'Content Creator',
    'event_manager' => 'Event Manager',
    'support_staff' => 'Support Staff',
    'school_partner' => 'School Partner',
    'admin' => 'Admin',
    _ => 'Student Volunteer',
  };
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.muted,
        fontWeight: FontWeight.w800,
        fontSize: 11,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: (user.role ?? 'student').replaceAll('_', ' '),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          _DetailGrid(user: user),
        ],
      ),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String?)>[
      (Icons.class_outlined, 'Class', user.className),
      (Icons.apartment_outlined, 'School', user.schoolName),
      (Icons.location_on_outlined, 'Location', user.location),
      (Icons.phone_outlined, 'Phone', user.phone),
      (Icons.cake_outlined, 'Age', user.age?.toString()),
      (Icons.family_restroom_outlined, 'Parent Email', user.parentEmail),
    ];

    final filled = items
        .where((e) => e.$3 != null && e.$3!.isNotEmpty)
        .toList();
    if (filled.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: filled
          .map((e) => _InfoRow(icon: e.$1, label: '${e.$2}: ${e.$3}'))
          .toList(),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _RequestedRoleBanner extends StatelessWidget {
  const _RequestedRoleBanner({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      'mentor' => AppColors.secondary,
      'content_creator' => AppColors.accent,
      _ => AppColors.primary,
    };
    final label = switch (role) {
      'mentor' => 'Mentor',
      'content_creator' => 'Content Creator',
      _ => 'Student',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.how_to_reg_outlined, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'User requested: $label access',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.selected, required this.onChanged});
  final String? selected;
  final ValueChanged<String?> onChanged;

  static const _roles = [
    ('student', 'Student', Icons.school_outlined, AppColors.primary),
    ('mentor', 'Counsellor', Icons.psychology_outlined, AppColors.secondary),
    (
      'content_creator',
      'Content Creator',
      Icons.edit_note_outlined,
      AppColors.accent,
    ),
    (
      'event_manager',
      'Event Manager',
      Icons.event_available_rounded,
      Color(0xFF6B48FF),
    ),
    (
      'support_staff',
      'Support Staff',
      Icons.support_agent_rounded,
      Color(0xFF009688),
    ),
    (
      'school_partner',
      'School Partner',
      Icons.account_balance_rounded,
      Color(0xFF1565C0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _roles.map((r) {
        final (value, label, icon, color) = r;
        final isSelected = selected == value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? color
                      : AppColors.muted.withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected ? color : AppColors.muted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? color : AppColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded, size: 18, color: color),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.muted,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
