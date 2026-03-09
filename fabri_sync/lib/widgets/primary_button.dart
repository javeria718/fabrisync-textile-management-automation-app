import 'package:fabri_sync/utils/customcolors.dart';
import 'package:flutter/material.dart';

Widget primaryButton({
  required BuildContext context,
  required String text,
  required VoidCallback onTap,
  bool loading = false,
  bool showTick = false,
}) {
  return Center(
    child: SizedBox(
      width: 240, // ✅ image-like fixed width
      height: 44, // ✅ compact height like pic
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white, // ❌ unchanged
          elevation: 1.5, // ✅ very subtle shadow
          shadowColor: Colors.black26,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // ✅ box-type corners
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showTick) ...[
                    const Icon(
                      Icons.check,
                      color: AppColors.customBlueColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: Colors.blueGrey.shade900,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}
