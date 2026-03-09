import 'package:fabri_sync/auth/frosted_glass.dart';
import 'package:fabri_sync/onboarding/role_selection_screen.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:flutter/material.dart';
import 'login_controller.dart';
import 'login_form.dart';

class LoginPage extends StatefulWidget {
  final String expectedRole;
  const LoginPage({super.key, required this.expectedRole});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final LoginController controller;

  @override
  void initState() {
    super.initState();
    controller = LoginController(expectedRole: widget.expectedRole);
  }

  void togglePassword() {
    setState(() => controller.showPassword = !controller.showPassword);
  }

  void handleLogin() {
    controller.validateAndLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: gradientOrderBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // ✅ back button (modern overlay)
              Positioned(
                left: 8,
                top: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  color: Colors.white.withOpacity(0.9),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const SelectRoleScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ),
              // ✅ center frosted card + responsive scrolling
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: FrostedGlassCard(
                    child: LoginForm(
                      expectedRole: widget.expectedRole,
                      controller: controller,
                      togglePassword: togglePassword,
                      onLoginPressed: handleLogin,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
