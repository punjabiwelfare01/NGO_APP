import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/colors.dart';

class ContentCreatorProfileView extends StatelessWidget {
  const ContentCreatorProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      children: const [
        _ProfileHeader(),
        SizedBox(height: 18),
        _CreatorHeroCard(),
        SizedBox(height: 16),
        _ProfileStats(),
        SizedBox(height: 16),
        _InfoSection(),
        SizedBox(height: 16),
        _ActivitySection(),
        SizedBox(height: 16),
        _SupportSection(),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Profile',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.ink,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        IconButton.filledTonal(
          onPressed: () {},
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}

class _CreatorHeroCard extends StatelessWidget {
  const _CreatorHeroCard();

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 380;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aarav Sharma',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 9),
              const _RoleBadge(),
              const SizedBox(height: 12),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mail_outline_rounded,
                    color: AppColors.muted,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'aarav@careskill.org',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
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
                onPressed: () {},
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
                    const _CreatorAvatar(size: 92),
                    const SizedBox(width: 14),
                    Expanded(child: details),
                  ],
                ),
                const SizedBox(height: 16),
                const Center(child: _ProfileCompletion()),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _CreatorAvatar(size: 116),
              const SizedBox(width: 18),
              Expanded(child: details),
              const SizedBox(width: 12),
              const _ProfileCompletion(),
            ],
          );
        },
      ),
    );
  }
}

class _CreatorAvatar extends StatelessWidget {
  const _CreatorAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.person_rounded,
            color: AppColors.ink.withValues(alpha: 0.70),
            size: size * 0.52,
          ),
          Positioned(
            bottom: size * 0.12,
            child: Container(
              width: size * 0.46,
              height: size * 0.18,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.70),
                borderRadius: BorderRadius.circular(size * 0.10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCompletion extends StatelessWidget {
  const _ProfileCompletion();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 84,
          height: 84,
          child: CustomPaint(
            painter: _ProgressRingPainter(progress: 0.85),
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
          child: const Text(
            'Profile 85% complete',
            style: TextStyle(
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
  const _RoleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Content Creator',
        style: TextStyle(
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
  const _ProfileStats();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 620 ? 3 : 1;
        final stats = const [
          _StatData(
            icon: Icons.description_rounded,
            label: 'Total Content',
            value: '24',
            helper: 'All time',
            color: AppColors.primary,
          ),
          _StatData(
            icon: Icons.task_alt_rounded,
            label: 'Published',
            value: '16',
            helper: '67% of total',
            color: AppColors.secondary,
          ),
          _StatData(
            icon: Icons.visibility_rounded,
            label: 'Total Views',
            value: '12.4K',
            helper: 'All time',
            color: Color(0xFF2E7CF6),
          ),
        ];

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
  const _InfoSection();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Personal Information',
      rows: [
        _ProfileRow(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: '+91 98765 43210',
          color: AppColors.primary,
        ),
        _ProfileRow(
          icon: Icons.location_on_outlined,
          label: 'Location',
          value: 'Jaipur, India',
          color: AppColors.primary,
        ),
        _ProfileRow(
          icon: Icons.apartment_rounded,
          label: 'Organization',
          value: 'CareSkill NGO',
          color: AppColors.primary,
        ),
        _ProfileRow(
          icon: Icons.calendar_month_outlined,
          label: 'Joined',
          value: 'May 2026',
          color: AppColors.primary,
          showDivider: false,
        ),
      ],
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'My Activity',
      rows: [
        _ProfileRow(
          icon: Icons.description_outlined,
          label: 'My Content',
          color: AppColors.primary,
          trailing: Icons.chevron_right_rounded,
        ),
        _ProfileRow(
          icon: Icons.schedule_rounded,
          label: 'Drafts & Pending Review',
          color: AppColors.accent,
          trailing: Icons.chevron_right_rounded,
        ),
        _ProfileRow(
          icon: Icons.bar_chart_rounded,
          label: 'Performance Reports',
          color: Color(0xFF7F5AF0),
          trailing: Icons.chevron_right_rounded,
          showDivider: false,
        ),
      ],
    );
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Account & Support',
      rows: [
        _ProfileRow(
          icon: Icons.notifications_rounded,
          label: 'Notifications',
          color: AppColors.primary,
          trailing: Icons.chevron_right_rounded,
        ),
        _ProfileRow(
          icon: Icons.shield_outlined,
          label: 'Privacy & Security',
          color: AppColors.secondary,
          trailing: Icons.chevron_right_rounded,
        ),
        _ProfileRow(
          icon: Icons.help_outline_rounded,
          label: 'Help & Support',
          color: Color(0xFF7F5AF0),
          trailing: Icons.chevron_right_rounded,
        ),
        _ProfileRow(
          icon: Icons.logout_rounded,
          label: 'Logout',
          color: AppColors.softRed,
          labelColor: Colors.red,
          trailing: Icons.chevron_right_rounded,
          showDivider: false,
        ),
      ],
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
    this.trailing,
    this.labelColor,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String? value;
  final IconData? trailing;
  final Color color;
  final Color? labelColor;
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
                  style: TextStyle(
                    color: labelColor ?? AppColors.ink,
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
              if (trailing != null)
                Icon(trailing, color: AppColors.ink, size: 24),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: AppColors.ink.withValues(alpha: 0.08)),
      ],
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
      math.pi * 2 * progress,
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
