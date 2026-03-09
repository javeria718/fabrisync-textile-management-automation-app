import 'package:flutter/material.dart';

BoxDecoration glassCardDecoration() {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    color: Colors.white.withOpacity(0.05),
    border: Border.all(color: Colors.white.withOpacity(0.12)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
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
