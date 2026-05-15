import 'package:fabri_sync/utils/customcolors.dart';
import 'package:flutter/material.dart';

BoxDecoration glassCardDecoration() {
  return AppDecorations.surface(radius: 20);
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: glassCardDecoration(),
      child: child,
    );
  }
}
