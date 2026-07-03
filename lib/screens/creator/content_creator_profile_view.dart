import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/api_models.dart';
import '../../models/creator_content.dart';
import '../../repositories/creator_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/view_state.dart';

class ContentCreatorProfileView extends StatefulWidget {
  const ContentCreatorProfileView({super.key});

  @override
  State<ContentCreatorProfileView> createState() =>
      _ContentCreatorProfileViewState();
}

class _ContentCreatorProfileViewState extends State<ContentCreatorProfileView> {
  late final ProfileViewModel _vm;
  late final AuthViewModel _authVm;
  List<CreatorContentItem> _content = [];

  @override
  void initState() {
    super.initState();
    _vm = ProfileViewModel()..load();
    _authVm = AuthViewModel();
    _loadContentStats();
  }

  @override
  void dispose() {
    _vm.dispose();
    _authVm.dispose();
    super.dispose();
  }

  Future<void> _loadContentStats() async {
    try {
      final items = await CreatorRepository.getContent();
      if (mounted) setState(() => _content = items);
    } catch (_) {
      if (mounted) setState(() => _content = const []);
    }
  }

  Future<void> _logout() async {
    await _authVm.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _openEditProfile() async {
    final user = _vm.user;
    if (user == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditCreatorProfileSheet(
        user: user,
        onSave: (name, phone, location, organization) async {
          final ok = await _vm.updateProfile(
            name: name,
            phone: phone,
            location: location,
            schoolName: organization,
          );
          if (!mounted) return;
          if (ok) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully.')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_vm.updateError ?? 'Failed to update profile.'),
                backgroundColor: AppColors.softRed,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        if (_vm.state == ViewState.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_vm.state == ViewState.error) {
          return _ErrorView(message: _vm.errorMessage, onRetry: _vm.load);
        }

        final user = _vm.user;
        return RefreshIndicator(
          onRefresh: () async {
            await _vm.load();
            await _loadContentStats();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            children: [
              const _ProfileHeader(),
              const SizedBox(height: 18),
              _CreatorHeroCard(
                user: user,
                completion: _profileCompletion(user),
                onEditProfile: _openEditProfile,
              ),
              const SizedBox(height: 16),
              _ProfileStats(content: _content),
              const SizedBox(height: 16),
              _InfoSection(user: user),
              const SizedBox(height: 16),
              _LogoutCard(onLogout: _logout),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Profile',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: AppColors.ink,
        fontSize: 32,
        fontWeight: FontWeight.w900,
        height: 1,
      ),
    );
  }
}

class _CreatorHeroCard extends StatelessWidget {
  const _CreatorHeroCard({
    required this.user,
    required this.completion,
    required this.onEditProfile,
  });

  final AppUser? user;
  final int completion;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final name = _value(user?.name, fallback: 'Content Creator');
    final email = _value(user?.email, fallback: 'Email not added');
    return _SoftCard(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 380;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 9),
              _RoleBadge(role: user?.role),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.mail_outline_rounded,
                    color: AppColors.muted,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onEditProfile,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CreatorAvatar(size: 92, name: name),
                    const SizedBox(width: 14),
                    Expanded(child: details),
                  ],
                ),
                const SizedBox(height: 16),
                Center(child: _ProfileCompletion(percent: completion)),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CreatorAvatar(size: 116, name: name),
              const SizedBox(width: 18),
              Expanded(child: details),
              const SizedBox(width: 12),
              _ProfileCompletion(percent: completion),
            ],
          );
        },
      ),
    );
  }
}

class _CreatorAvatar extends StatelessWidget {
  const _CreatorAvatar({required this.size, required this.name});

  final double size;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.secondary.withValues(alpha: 0.20),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ProfileCompletion extends StatelessWidget {
  const _ProfileCompletion({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 84,
          height: 84,
          child: CustomPaint(
            painter: _ProgressRingPainter(progress: percent / 100),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.muted,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Profile $percent% complete',
            style: const TextStyle(
              color: Color(0xFF17A34A),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String? role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _roleLabel(role),
        style: const TextStyle(
          color: Color(0xFF0966D8),
          fontSize: 13,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.content});

  final List<CreatorContentItem> content;

  @override
  Widget build(BuildContext context) {
    final published = content
        .where((item) => item.status == 'published')
        .length;
    final totalViews = content.fold<int>(0, (sum, item) => sum + item.views);
    final stats = [
      _StatData(
        icon: Icons.description_rounded,
        label: 'Total Content',
        value: '${content.length}',
        helper: 'All time',
        color: AppColors.primary,
      ),
      _StatData(
        icon: Icons.task_alt_rounded,
        label: 'Published',
        value: '$published',
        helper: '${_percent(published, content.length)}% of total',
        color: AppColors.secondary,
      ),
      _StatData(
        icon: Icons.visibility_rounded,
        label: 'Total Views',
        value: _shortNumber(totalViews),
        helper: 'All time',
        color: const Color(0xFF2E7CF6),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 620 ? 3 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 3 ? 1.45 : 3.3,
          ),
          itemBuilder: (context, index) => _ProfileStatCard(data: stats[index]),
        );
      },
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 23),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.value,
                  style: TextStyle(
                    color: data.color,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.helper,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Personal Information',
      rows: [
        _ProfileRow(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: _value(user?.phone),
          color: AppColors.primary,
        ),
        _ProfileRow(
          icon: Icons.location_on_outlined,
          label: 'Location',
          value: _value(user?.location),
          color: AppColors.primary,
        ),
        _ProfileRow(
          icon: Icons.apartment_rounded,
          label: 'Organization',
          value: _value(user?.schoolName, fallback: 'Punjabi Welfare Trust'),
          color: AppColors.primary,
        ),
        _ProfileRow(
          icon: Icons.verified_user_outlined,
          label: 'Status',
          value: _statusLabel(user?.accessStatus),
          color: AppColors.secondary,
        ),
        _ProfileRow(
          icon: Icons.calendar_month_outlined,
          label: 'Joined',
          value: _formatMonth(user?.createdAt),
          color: AppColors.primary,
          showDivider: false,
        ),
      ],
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onLogout,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.softRed.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.softRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.rows});

  final String title;
  final List<_ProfileRow> rows;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.color,
    this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Color color;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (value != null)
                Flexible(
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: AppColors.ink.withValues(alpha: 0.08)),
      ],
    );
  }
}

class _EditCreatorProfileSheet extends StatefulWidget {
  const _EditCreatorProfileSheet({required this.user, required this.onSave});

  final AppUser user;
  final Future<void> Function(
    String name,
    String phone,
    String location,
    String organization,
  )
  onSave;

  @override
  State<_EditCreatorProfileSheet> createState() =>
      _EditCreatorProfileSheetState();
}

class _EditCreatorProfileSheetState extends State<_EditCreatorProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _orgCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
    _locationCtrl = TextEditingController(text: widget.user.location ?? '');
    _orgCtrl = TextEditingController(text: widget.user.schoolName ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _orgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        18,
        18,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            _EditField(
              controller: _nameCtrl,
              label: 'Name',
              textInputAction: TextInputAction.next,
              onEditingComplete: () => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 12),
            _EditField(
              controller: _phoneCtrl,
              label: 'Phone',
              textInputAction: TextInputAction.next,
              onEditingComplete: () => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 12),
            _EditField(
              controller: _locationCtrl,
              label: 'Location',
              textInputAction: TextInputAction.next,
              onEditingComplete: () => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 12),
            _EditField(controller: _orgCtrl, label: 'Organization'),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        await widget.onSave(
                          _nameCtrl.text.trim(),
                          _phoneCtrl.text.trim(),
                          _locationCtrl.text.trim(),
                          _orgCtrl.text.trim(),
                        );
                        if (mounted) setState(() => _saving = false);
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.controller,
    required this.label,
    this.textInputAction,
    this.onEditingComplete,
  });

  final TextEditingController controller;
  final String label;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: textInputAction,
      onEditingComplete: onEditingComplete,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.muted,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message ?? 'Failed to load profile.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide * 0.08;
    final rect = Offset.zero & size;
    final ringRect = rect.deflate(strokeWidth / 2);
    final backgroundPaint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(ringRect, -math.pi / 2, math.pi * 2, false, backgroundPaint);
    canvas.drawArc(
      ringRect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _StatData {
  const _StatData({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String helper;
  final Color color;
}

int _profileCompletion(AppUser? user) {
  if (user == null) return 0;
  final fields = [
    user.name,
    user.email,
    user.phone,
    user.location,
    user.schoolName,
    user.role,
    user.accessStatus,
  ];
  final filled = fields
      .where((value) => value?.trim().isNotEmpty ?? false)
      .length;
  return ((filled / fields.length) * 100).round();
}

int _percent(int value, int total) {
  if (total == 0) return 0;
  return ((value / total) * 100).round();
}

String _value(String? value, {String fallback = 'Not added'}) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
}

String _roleLabel(String? role) => switch (role) {
  'content_creator' => 'Content Creator',
  'mentor' => 'Counsellor',
  'admin' => 'Admin',
  'super_admin' => 'Super Admin',
  'event_manager' => 'Event Manager',
  'support_staff' => 'Support Staff',
  'student' => 'Student',
  _ => 'Content Creator',
};

String _statusLabel(String? status) => switch (status) {
  'approved' => 'Approved',
  'pending' || 'pending_verification' => 'Pending Verification',
  'rejected' => 'Rejected',
  'deactivated' => 'Deactivated',
  _ => 'Unknown',
};

String _formatMonth(DateTime? date) {
  if (date == null) return 'Not available';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String _shortNumber(int value) {
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return '$value';
}
