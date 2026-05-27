import 'package:flutter/material.dart';
import '../core/colors.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(18),
    super.key,
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
