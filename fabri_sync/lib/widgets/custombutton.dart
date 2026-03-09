import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;
  final Widget? child;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: width ?? 180),
      child: SizedBox(
        height: 46, // ✅ thora taller = premium feel
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white, // ✅ white background
            elevation: 6,
            shadowColor: Colors.black.withOpacity(0.25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14), // ✅ modern radius
            ),
          ),
          onPressed: onPressed,
          child:
              child ??
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,

                  // ✅ login gradient ke saath match karta classy color
                  color: Color(0xFF2563EB), // blue-violet tone
                  letterSpacing: 0.4,
                ),
              ),
        ),
      ),
    );
  }
}
