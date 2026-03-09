import 'package:flutter/material.dart';

class WhiteButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final bool showArrow;

  const WhiteButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = 150,
    this.height = 45,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xff004AAD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 2,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            if (showArrow) ...[
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

// ------------------- Reusable Rounded Textfield -------------------
Widget roundedTextField({required TextEditingController controller}) {
  return Container(
    height: 40,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: TextField(
      controller: controller,
      decoration: const InputDecoration(border: InputBorder.none),
    ),
  );
}

// ------------------- Reusable Dropdown Box -------------------
Widget dropdownBox({
  required String label,
  required String value,
  required List<String> items,
  required Function(String?) onChanged,
}) {
  return Column(
    children: [
      Container(
        width: 95,
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          underline: const SizedBox(),
          onChanged: onChanged,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    ],
  );
}

/// ---------------- CARD CONTAINER ----------------
Widget buildCard({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}
