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
      width: 240,
      height: 44,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showTick) ...[
                    const Icon(Icons.check, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
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
