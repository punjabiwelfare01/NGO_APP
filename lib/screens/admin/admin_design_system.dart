import 'package:flutter/material.dart';

import '../../core/colors.dart';

/// Typography scale for the Admin module. Sizes follow the mobile-readability
/// spec: page title 26-30, section title 20-22, card title 17-18, primary
/// stat 24-28, button 16, body 15-16, secondary/status 13-14.
class AdminText {
  const AdminText._();

  static const pageTitle = TextStyle(
    fontSize: 27,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.2,
  );
  static const sectionTitle = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.25,
  );
  static const cardTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.3,
  );
  static const statValue = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );
  static const buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static const body = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
    height: 1.4,
  );
  static const bodyStrong = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.35,
  );
  static const secondary = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
    height: 1.35,
  );
  static const statusLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
}

/// 8px spacing grid + shared radii/touch-target sizes for the Admin module.
class AdminSpacing {
  const AdminSpacing._();

  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  static const cardRadius = 18.0;
  static const chipRadius = 22.0;

  /// Minimum touch target per accessibility guidance (48x48).
  static const minTouch = 48.0;
}

BoxDecoration adminCardDecoration({Color? borderColor}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(AdminSpacing.cardRadius),
  border: Border.all(
    color: borderColor ?? AppColors.muted.withValues(alpha: .12),
  ),
);

/// A colored dot + label badge for statuses (🟢 New, 🟡 Pending, 🔵 Verified,
/// 🟣 Draft, 🔴 Rejected, …). Color is inferred from the label text unless
/// explicitly given, so existing status strings from view-models "just work."
class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({required this.label, this.color, super.key});

  final String label;
  final Color? color;

  static Color colorFor(String label) {
    final l = label.toLowerCase();
    if (l.contains('new')) return const Color(0xFF2E7D32);
    if (l.contains('pending') || l.contains('waiting') || l.contains('review')) {
      return const Color(0xFFF57F17);
    }
    if (l.contains('verified') || l.contains('approved') || l.contains('active') ||
        l.contains('issued') || l.contains('published') || l.contains('completed')) {
      return const Color(0xFF1565C0);
    }
    if (l.contains('draft')) return const Color(0xFF6A1B9A);
    if (l.contains('reject') || l.contains('block') || l.contains('declin')) {
      return const Color(0xFFC62828);
    }
    return AppColors.muted;
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? colorFor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(AdminSpacing.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: AdminText.statusLabel.copyWith(color: c)),
        ],
      ),
    );
  }
}

/// A large "value over label" statistic block that scales the number down
/// (never up) to guarantee it never overflows its column, however many
/// columns share the row and however large the value gets.
class AdminStatBlock extends StatelessWidget {
  const AdminStatBlock({
    required this.label,
    required this.value,
    this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: AdminText.statValue.copyWith(
              color: valueColor ?? AppColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AdminText.secondary,
        ),
      ],
    );
  }
}

/// Full-width (or wrapped) primary action button meeting the 48-52px
/// minimum height / 16px text / consistent radius requirements.
class AdminPrimaryButton extends StatelessWidget {
  const AdminPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      minimumSize: const Size(double.infinity, 50),
      textStyle: AdminText.buttonText,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: style,
        icon: Icon(icon, size: 20),
        label: Text(label),
      );
    }
    return FilledButton(onPressed: onPressed, style: style, child: Text(label));
  }
}

/// Outlined counterpart of [AdminPrimaryButton], same sizing rules.
class AdminSecondaryButton extends StatelessWidget {
  const AdminSecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.foregroundColor,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      foregroundColor: foregroundColor,
      minimumSize: const Size(double.infinity, 50),
      textStyle: AdminText.buttonText,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        style: style,
        icon: Icon(icon, size: 20),
        label: Text(label),
      );
    }
    return OutlinedButton(onPressed: onPressed, style: style, child: Text(label));
  }
}
