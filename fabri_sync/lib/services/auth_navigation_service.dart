import 'package:fabri_sync/auth/login/login_page.dart';
import 'package:fabri_sync/singleton/singleton.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthNavigationService {
  AuthNavigationService._();

  static const String adminLoginRoute = '/admin_login';
  static const String managerLoginRoute = '/manager_login';
  static const String employeeHeadLoginRoute = '/employee_head_login';
  static const String roleSelectionRoute = '/role_selection';

  static const String adminDashboardRoute = '/admin_dashboard';
  static const String managerDashboardRoute = '/manager_panel';
  static const String employeeHeadDashboardRoute = '/employee_head_panel';

  static String normalizedRole(String role) => role.toLowerCase().trim();

  static String loginRouteForRole(String role) {
    switch (normalizedRole(role)) {
      case 'admin':
        return adminLoginRoute;
      case 'manager':
        return managerLoginRoute;
      case 'employee_head':
        return employeeHeadLoginRoute;
      default:
        return roleSelectionRoute;
    }
  }

  static Widget loginScreenForRole(String role) {
    switch (normalizedRole(role)) {
      case 'admin':
        return const LoginPage(expectedRole: 'admin');
      case 'manager':
        return const LoginPage(expectedRole: 'manager');
      case 'employee_head':
        return const LoginPage(expectedRole: 'employee_head');
      default:
        return const LoginPage(expectedRole: 'admin');
    }
  }

  static Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } finally {
      UserSingleton().clear();
    }
  }

  static Future<void> logoutAndNavigate(
    BuildContext context,
    String role,
  ) async {
    await signOut();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(loginRouteForRole(role), (route) => false);
  }

  static void goToRoleSelection(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(roleSelectionRoute, (route) => false);
  }
}
