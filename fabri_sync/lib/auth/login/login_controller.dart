import 'package:fabri_sync/Model/userModel.dart';
import 'package:fabri_sync/services/auth_navigation_service.dart';
import 'package:fabri_sync/singleton/singleton.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginController {
  final String expectedRole; // ✅ 'admin', 'manager', or 'employee_head'
  LoginController({required this.expectedRole});

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool showPassword = false;

  final supabase = Supabase.instance.client;

  void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> login(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      isLoading = true;

      final expected = expectedRole.toLowerCase().trim();
      if (expected.isEmpty) {
        showError(
          context,
          'Login route is missing an expected role. Please select your role first.',
        );
        return;
      }

      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        showError(context, "User not found.");
        return;
      }

      // ✅ Fetch profile safely
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        await supabase.auth.signOut();
        if (!context.mounted) return;
        showError(
          context,
          "Profile not found. Please sign up again or contact admin.",
        );
        return;
      }

      final userModel = UserModel.fromJson(profile);
      final profileRole = userModel.role.toLowerCase().trim();

      // ✅ STRICT ROLE MATCH
      if (profileRole != expected) {
        await supabase.auth.signOut();
        if (!context.mounted) return;
        showError(
          context,
          "Access denied. You can only login as ${expectedRole.toUpperCase()} here.",
        );
        return;
      }

      UserSingleton().userModel = userModel;
      await saveEmailLocally(email);

      // ✅ role-based navigation
      if (!context.mounted) return;

      switch (profileRole) {
        case 'admin':
          Navigator.pushReplacementNamed(
            context,
            AuthNavigationService.adminDashboardRoute,
          );
          break;
        case 'manager':
          Navigator.pushReplacementNamed(
            context,
            AuthNavigationService.managerDashboardRoute,
          );
          break;
        case 'employee_head':
          Navigator.pushReplacementNamed(
            context,
            AuthNavigationService.employeeHeadDashboardRoute,
          );
          break;
        default:
          await supabase.auth.signOut();
          if (!context.mounted) return;
          showError(context, "Unsupported role: $profileRole");
      }
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid') || msg.contains('credentials')) {
        showError(context, "Invalid email or password.");
        return;
      }
      showError(context, e.message);
    } catch (e) {
      showError(context, "Login failed: ${e.toString()}");
    } finally {
      isLoading = false;
    }
  }

  void validateAndLogin(BuildContext context) {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    final emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );

    if (email.isEmpty || password.isEmpty) {
      showError(context, "Please fill all fields.");
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      showError(context, "Please enter a valid email address.");
      return;
    }

    login(context, email, password);
  }

  Future<void> saveEmailLocally(String email) async {
    final prefs = await SharedPreferences.getInstance();

    final existingEmails = prefs.getStringList('login_emails') ?? [];

    if (!existingEmails.contains(email)) {
      existingEmails.add(email);
      await prefs.setStringList('login_emails', existingEmails);
    }
  }
}
