import 'package:flutter/material.dart';
import '../core/colors.dart';

class TopHeader extends StatelessWidget {
  const TopHeader({
    required this.title,
    required this.subtitle,
    required this.actionIcon,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (canPop)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.ink,
              tooltip: 'Back',
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () {},
          icon: Icon(actionIcon),
          tooltip: 'Open action',
        ),
      ],
    );
  }
}
