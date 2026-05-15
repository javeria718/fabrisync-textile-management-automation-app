// import 'package:fabri_sync/auth/Forgotpass/screen5.dart';
// import 'package:fabri_sync/onboarding/role_selection_screen.dart';
// import 'package:fabri_sync/onboarding/splash.dart';

// import 'package:fabri_sync/view/dashboards/admin.dart';
// import 'package:fabri_sync/view/dashboards/manager.dart';
// import 'package:flutter/material.dart';

// import 'package:app_links/app_links.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   // --- ADD SUPABASE INITIALIZATION HERE ---
//   await Supabase.initialize(
//     url: 'https://wjfcmvdeilrmerqwwyxi.supabase.co',
//     anonKey:
//         'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndqZmNtdmRlaWxybWVycXd3eXhpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU2MjYyOTQsImV4cCI6MjA4MTIwMjI5NH0.In6wRMUygjY6gj3-MqJdeqyMdUUgTBBO3BOg2IEJYdg', // Replace with your Supabase ANON KEY
//   );
//   runApp(const FabriSyncApp());
// }

// class FabriSyncApp extends StatefulWidget {
//   const FabriSyncApp({super.key});

//   @override
//   State<FabriSyncApp> createState() => _FabriSyncAppState();
// }

// class _FabriSyncAppState extends State<FabriSyncApp> {
//   final AppLinks _appLinks = AppLinks();

//   @override
//   void initState() {
//     super.initState();

//     // LISTEN FOR APP LINKS (when app is already running)
//     _appLinks.uriLinkStream.listen((uri) {
//       _handleIncomingLink(uri);
//     });

//     // CHECK INITIAL LINK (when app is launched from email)
//     _checkInitialLink();
//   }

//   Future<void> _checkInitialLink() async {
//     final uri = await _appLinks.getInitialLink();
//     if (uri != null) {
//       _handleIncomingLink(uri);
//     }
//   }

//   void _handleIncomingLink(Uri uri) {
//     final params = uri.queryParameters;
//     if (params.containsKey('oobCode')) {
//       final oobCode = params['oobCode'];
//       if (oobCode != null && navigatorKey.currentState != null) {
//         navigatorKey.currentState!.push(
//           MaterialPageRoute(
//             builder: (_) => ResetPasswordScreen(oobCode: oobCode),
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       navigatorKey: navigatorKey,
//       theme: ThemeData(useMaterial3: true, fontFamily: 'Poppins'),
//       debugShowCheckedModeBanner: false,
//       title: "FabriSync",

//       home: SplashScreen(),
//       // home: const AdminDashboardScreen(),
//       routes: {
//         '/role_selection': (_) => const SelectRoleScreen(),
//         '/admin_dashboard': (context) => const AdminDashboardScreen(),
//         '/manager_panel': (context) => const ManagerPanel(),
//         // '/manager_panel': (context) =>
//         //     const ManagerPanel(department: 'Cutting'),
//       },
//     );
//   }
// }

// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// import 'dart:async';
// import 'package:fabri_sync/auth/Forgotpass/reset_pass.dart';
// import 'package:fabri_sync/onboarding/role_selection_screen.dart';
// import 'package:fabri_sync/onboarding/splash.dart';

// import 'package:fabri_sync/view/dashboards/admin.dart';
// import 'package:fabri_sync/view/dashboards/manager.dart';
// import 'package:flutter/material.dart';

// import 'package:app_links/app_links.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await Supabase.initialize(
//     url: 'https://wjfcmvdeilrmerqwwyxi.supabase.co',
//     anonKey:
//         'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndqZmNtdmRlaWxybWVycXd3eXhpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU2MjYyOTQsImV4cCI6MjA4MTIwMjI5NH0.In6wRMUygjY6gj3-MqJdeqyMdUUgTBBO3BOg2IEJYdg',
//   );

//   runApp(const FabriSyncApp());
// }

// class FabriSyncApp extends StatefulWidget {
//   const FabriSyncApp({super.key});

//   @override
//   State<FabriSyncApp> createState() => _FabriSyncAppState();
// }

// class _FabriSyncAppState extends State<FabriSyncApp> {
//   final AppLinks _appLinks = AppLinks();

//   StreamSubscription<AuthState>? _authSub;
//   StreamSubscription<Uri>? _linkSub;

//   @override
//   void initState() {
//     super.initState();

//     // ✅ 1) Listen for Supabase auth events (THIS is the correct password recovery trigger)
//     _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
//       final event = data.event;

//       // When user opens recovery link from email, Supabase emits passwordRecovery
//       if (event == AuthChangeEvent.passwordRecovery) {
//         navigatorKey.currentState?.push(
//           MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
//         );
//       }
//     });

//     // ✅ 2) Keep AppLinks listener (optional). We no longer parse firebase oobCode.
//     _linkSub = _appLinks.uriLinkStream.listen((uri) {
//       _handleIncomingLink(uri);
//     });

//     _checkInitialLink();
//   }

//   Future<void> _checkInitialLink() async {
//     final uri = await _appLinks.getInitialLink();
//     if (uri != null) {
//       _handleIncomingLink(uri);
//     }
//   }

//   void _handleIncomingLink(Uri uri) async {
//     try {
//       await Supabase.instance.client.auth.getSessionFromUrl(uri);
//     } catch (_) {}
//   }

//   @override
//   void dispose() {
//     _authSub?.cancel();
//     _linkSub?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // return MaterialApp(
//     //   navigatorKey: navigatorKey,
//     //   theme: ThemeData(useMaterial3: true, fontFamily: 'Poppins'),
//     //   debugShowCheckedModeBanner: false,
//     //   title: "FabriSync",
//     //   home: const SplashScreen(),
//     //   routes: {
//     //     '/role_selection': (_) => const SelectRoleScreen(),
//     //     '/reset-password': (_) => const ResetPasswordScreen(),
//     //     // ✅ Role Guarded Screens
//     //     '/admin_dashboard': (_) => const RoleGuard(
//     //       requiredRole: 'admin',
//     //       child: AdminDashboardScreen(),
//     //     ),

//     //     '/manager_panel': (_) =>
//     //         const RoleGuard(requiredRole: 'manager', child: ManagerPanel()),
//     //   },
//     // );
//     return MaterialApp(
//       navigatorKey: navigatorKey,
//       theme: ThemeData(useMaterial3: true, fontFamily: 'Poppins'),
//       debugShowCheckedModeBanner: false,
//       title: "FabriSync",

//       // ✅ home REMOVE
//       // home: const SplashScreen(),

//       // ✅ Make Splash your "/" route
//       initialRoute: '/',

//       routes: {
//         '/': (_) => const SplashScreen(),

//         // ✅ IMPORTANT: this must exist for web deep link
//         '/reset-password': (_) => const ResetPasswordScreen(),

//         '/role_selection': (_) => const SelectRoleScreen(),

//         '/admin_dashboard': (_) => const RoleGuard(
//           requiredRole: 'admin',
//           child: AdminDashboardScreen(),
//         ),

//         '/manager_panel': (_) =>
//             const RoleGuard(requiredRole: 'manager', child: ManagerPanel()),
//       },
//     );
//   }
// }

// /// ✅ ROLE GUARD WIDGET (prevents wrong dashboard access)
// class RoleGuard extends StatefulWidget {
//   final String requiredRole; // 'admin' or 'manager'
//   final Widget child;

//   const RoleGuard({super.key, required this.requiredRole, required this.child});

//   @override
//   State<RoleGuard> createState() => _RoleGuardState();
// }

// class _RoleGuardState extends State<RoleGuard> {
//   final supabase = Supabase.instance.client;

//   bool loading = true;
//   String? error;

//   @override
//   void initState() {
//     super.initState();
//     _checkAccess();
//   }

//   Future<void> _checkAccess() async {
//     try {
//       final user = supabase.auth.currentUser;

//       // ✅ No session -> go role selection
//       if (user == null) {
//         _redirectToRoleSelection();
//         return;
//       }

//       // ✅ Fetch profile safely (avoid 0 rows crash)
//       final profile = await supabase
//           .from('profiles')
//           .select('role, department')
//           .eq('id', user.id)
//           .maybeSingle();

//       if (profile == null) {
//         // profile missing -> signout + redirect
//         await supabase.auth.signOut();
//         _redirectToRoleSelection();
//         return;
//       }

//       final role = (profile['role'] ?? '').toString().toLowerCase().trim();

//       // ✅ Strict role access
//       if (role != widget.requiredRole.toLowerCase().trim()) {
//         _redirectToRoleSelection();
//         return;
//       }

//       // ✅ Manager must have department
//       if (role == 'manager') {
//         final dept = (profile['department'] ?? '').toString().trim();
//         if (dept.isEmpty) {
//           _redirectToRoleSelection();
//           return;
//         }
//       }

//       if (!mounted) return;
//       setState(() => loading = false);
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         loading = false;
//         error = e.toString();
//       });
//     }
//   }

//   void _redirectToRoleSelection() {
//     if (!mounted) return;
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       navigatorKey.currentState?.pushNamedAndRemoveUntil(
//         '/role_selection',
//         (route) => false,
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (loading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     if (error != null) {
//       return Scaffold(
//         body: Center(
//           child: Text(
//             "Access check failed:\n$error",
//             textAlign: TextAlign.center,
//           ),
//         ),
//       );
//     }

//     return widget.child;
//   }
// }
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

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw StateError(
      'Missing Supabase env vars (SUPABASE_URL, SUPABASE_ANON_KEY)',
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
