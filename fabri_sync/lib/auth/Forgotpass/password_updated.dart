import 'package:fabri_sync/auth/frosted_glass.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/widgets/custombutton.dart';
import 'package:flutter/material.dart';

class PasswordUpdatedScreen extends StatelessWidget {
  const PasswordUpdatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: gradientOrderBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: FrostedGlassCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 62,
                        width: 62,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.withOpacity(0.15),
                        ),
                        child: const Icon(
                          Icons.verified,
                          size: 34,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Password updated!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Your account is secure. You can now sign in\nwith your new password and start exploring.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.70),
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 46,
                        child: CustomButton(
                          width: double.infinity,
                          label: "Back to Sign In",
                          onPressed: () {
                            // App ke start / login screen tak wapas
                            Navigator.popUntil(
                              context,
                              (route) => route.isFirst,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
