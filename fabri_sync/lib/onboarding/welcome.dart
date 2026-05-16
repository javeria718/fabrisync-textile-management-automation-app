import 'package:fabri_sync/onboarding/role_selection_screen.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: gradientOrderBackground(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.26),

                // ---- Title ----
                Text(
                  'FabriSync',
                  style: AppTextStyles.titleStyleW,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // ---- Subtitle ----
                Text(
                  "Manage textile production more smartly\nwith simplified workflow",
                  style: AppTextStyles.subtitleStyleW,
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: size.height * 0.10),

                primaryButton(
                  context: context,
                  text: "Get Started",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SelectRoleScreen(),
                      ),
                    );
                  },
                ),

                SizedBox(height: size.height * 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
