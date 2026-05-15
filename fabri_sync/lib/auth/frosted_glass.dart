import 'package:fabri_sync/utils/customcolors.dart';
import 'package:flutter/material.dart';

class FrostedGlassCard extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  const FrostedGlassCard({
    super.key,
    required this.child,
    this.maxWidth = 440,
    this.padding = const EdgeInsets.all(28),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 600;
        final horizontal = isNarrow ? 18.0 : 0.0;

        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Container(
                padding: padding,
                decoration: AppDecorations.surface(radius: 28),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
