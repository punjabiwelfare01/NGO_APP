import 'package:flutter/material.dart';

import '../core/colors.dart';

/// Shared "profile page" visual system, established by the School Partner
/// portal's Profile tab and reused across every role's profile screen for
/// consistency: an uppercase muted section label above a white card, each
/// row showing an icon, a label, and a right-aligned value, separated by
/// hairline dividers.
class ProfileSection extends StatelessWidget {
  const ProfileSection({required this.title, required this.rows, super.key});
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: .6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 8),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < rows.length; i++) ...[
                rows[i],
                if (i < rows.length - 1) const Divider(height: 1, indent: 52),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One icon + label + right-aligned value row inside a [ProfileSection].
class ProfileRow extends StatelessWidget {
  const ProfileRow(
    this.icon,
    this.label,
    this.value, {
    this.accentColor = const Color(0xFF1565C0),
    super.key,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 18),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// One tappable icon + label (+ chevron) row inside the "Account Actions"
/// [ProfileSection] — e.g. Edit Profile, Change Password, Logout.
class ProfileActionTile extends StatelessWidget {
  const ProfileActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    super.key,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: .5), size: 18),
          ],
        ),
      ),
    );
  }
}

/// Wraps a list of [ProfileActionTile]s in the same white-card container as
/// [ProfileSection], under an "Account Actions" label — kept separate from
/// [ProfileSection] because its rows are tappable actions, not read-only
/// label/value pairs.
class ProfileActionsCard extends StatelessWidget {
  const ProfileActionsCard({required this.actions, this.title = 'Account Actions', super.key});
  final List<Widget> actions;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: .6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 8),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < actions.length; i++) ...[
                actions[i],
                if (i < actions.length - 1) const Divider(height: 1, indent: 52),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Shared avatar + name + ID/status-pill identity header, matching the
/// School Partner Profile tab's top block.
class ProfileIdentityHeader extends StatelessWidget {
  const ProfileIdentityHeader({
    required this.name,
    this.photoUrl,
    this.fallbackIcon = Icons.person_rounded,
    this.pills = const [],
    this.accentColor = const Color(0xFF1565C0),
    super.key,
  });
  final String name;
  final String? photoUrl;
  final IconData fallbackIcon;
  final List<({String label, Color color})> pills;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withValues(alpha: .2), width: 3),
              color: accentColor.withValues(alpha: .08),
            ),
            child: photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(fallbackIcon, color: accentColor, size: 36),
                    ),
                  )
                : Icon(fallbackIcon, color: accentColor, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          if (pills.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final pill in pills) ...[
                  if (pill != pills.first) const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: pill.color.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: pill.color.withValues(alpha: .25)),
                    ),
                    child: Text(
                      pill.label,
                      style: TextStyle(color: pill.color, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
