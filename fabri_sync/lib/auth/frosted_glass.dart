import 'dart:ui';
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
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                // web par height zyada na feel ho; mobile par scroll friendly
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: padding,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.14),
                          Colors.white.withOpacity(0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
