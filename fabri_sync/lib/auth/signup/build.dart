import 'package:flutter/material.dart';

Widget buildPasswordRule(String text, bool isValid) {
  final okColor = Colors.greenAccent.shade200;
  final idleColor = Colors.white.withOpacity(0.70);

  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isValid ? okColor : idleColor,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isValid ? okColor : idleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
