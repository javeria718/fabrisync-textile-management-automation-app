import 'dart:async';
import 'package:fabri_sync/onboarding/role_selection_screen.dart';
import 'package:fabri_sync/onboarding/splash.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/auth/login/login_page.dart';

import 'package:fabri_sync/view/dashboards/admin.dart';
import 'package:fabri_sync/view/dashboards/employee_head.dart';
import 'package:fabri_sync/view/dashboards/manager.dart';
import 'package:fabri_sync/services/auth_navigation_service.dart';
import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Supabase credentials from build-time environment variables (dart-define)
  // This approach prevents credentials from being exposed in the web build
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Missing Supabase env vars. Build with: '
      'flutter build web '
      '--dart-define=SUPABASE_URL=<url> '
      '--dart-define=SUPABASE_ANON_KEY=<key>',
    );
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const FabriSyncApp());
}

class FabriSyncApp extends StatefulWidget {
  const FabriSyncApp({super.key});

  @override
  State<FabriSyncApp> createState() => _FabriSyncAppState();
}

class _FabriSyncAppState extends State<FabriSyncApp> {
  // ✅ Option 1: Supabase default reset page use ho raha hai,
  // isliye deep links / getSessionFromUrl / passwordRecovery navigation ki zaroorat nahi.

  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();

    // ✅ Keep only if you need general auth monitoring
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      // No password recovery handling here (Option 1)
      // You can still handle signedIn/signedOut if needed.
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      // theme: baseTheme.copyWith(
      //   textTheme: textTheme,
      //   primaryTextTheme: textTheme,
      // ),
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      title: "FabriSync",

      // ✅ Splash as "/" route
      initialRoute: '/',

      routes: {
        '/': (_) => const SplashScreen(),

        '/role_selection': (_) => const SelectRoleScreen(),
        AuthNavigationService.adminLoginRoute: (_) =>
            const LoginPage(expectedRole: 'admin'),
        AuthNavigationService.managerLoginRoute: (_) =>
            const LoginPage(expectedRole: 'manager'),
        AuthNavigationService.employeeHeadLoginRoute: (_) =>
            const LoginPage(expectedRole: 'employee_head'),

        // ✅ Role Guarded Screens
        AuthNavigationService.adminDashboardRoute: (_) => const RoleGuard(
          requiredRole: 'admin',
          child: AdminDashboardScreen(),
        ),

        AuthNavigationService.managerDashboardRoute: (_) =>
            const RoleGuard(requiredRole: 'manager', child: ManagerPanel()),

        AuthNavigationService.employeeHeadDashboardRoute: (_) =>
            const RoleGuard(
              requiredRole: 'employee_head',
              child: EmployeeHeadPanel(),
            ),
      },
    );
  }
}

/// ✅ ROLE GUARD WIDGET (prevents wrong dashboard access)
class RoleGuard extends StatefulWidget {
  final String requiredRole; // 'admin', 'manager', or 'employee_head'
  final Widget child;

  const RoleGuard({super.key, required this.requiredRole, required this.child});

  @override
  State<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends State<RoleGuard> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    try {
      final user = supabase.auth.currentUser;

      // ✅ No session -> go role selection
      if (user == null) {
        _redirectToRoleSelection();
        return;
      }

      // ✅ Fetch profile safely (avoid 0 rows crash)
      final profile = await supabase
          .from('profiles')
          .select('role, department')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        // profile missing -> signout + redirect
        await supabase.auth.signOut();
        _redirectToRoleSelection();
        return;
      }

      final role = (profile['role'] ?? '').toString().toLowerCase().trim();

      // ✅ Strict role access
      if (role != widget.requiredRole.toLowerCase().trim()) {
        _redirectToRoleSelection();
        return;
      }

      // ✅ Manager must have department
      if (role == 'manager' || role == 'employee_head') {
        final dept = (profile['department'] ?? '').toString().trim();
        if (dept.isEmpty) {
          _redirectToRoleSelection();
          return;
        }
      }

      if (!mounted) return;
      setState(() => loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  void _redirectToRoleSelection() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AuthNavigationService.roleSelectionRoute,
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            "Access check failed:\n$error",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return widget.child;
  }
}
