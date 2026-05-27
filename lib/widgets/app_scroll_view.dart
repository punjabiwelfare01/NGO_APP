import 'package:flutter/material.dart';

class AppScrollView extends StatelessWidget {
  const AppScrollView({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      children: [
        for (final child in children) ...[child, const SizedBox(height: 16)],
      ],
    );
  }
}
