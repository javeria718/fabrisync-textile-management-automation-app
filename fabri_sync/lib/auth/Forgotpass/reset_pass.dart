// import 'package:fabri_sync/auth/frosted_glass.dart';
// import 'package:fabri_sync/auth/Forgotpass/password_updated.dart';
// import 'package:fabri_sync/services/auth_services.dart';
// import 'package:fabri_sync/utils/customcolors.dart';
// import 'package:fabri_sync/widgets/custombutton.dart';
// import 'package:fabri_sync/widgets/textfields.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class ResetPasswordScreen extends StatefulWidget {
//   const ResetPasswordScreen({super.key});

//   @override
//   State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
// }

// class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
//   final TextEditingController pass1 = TextEditingController();
//   final TextEditingController pass2 = TextEditingController();
//   bool loading = false;

//   String? _extractCode() {
//     final uri = Uri.base;

//     final q = uri.queryParameters['code'];
//     if (q != null && q.isNotEmpty) return q;

//     final frag = uri.fragment;
//     final idx = frag.indexOf('?');
//     if (idx != -1) {
//       final fragQuery = Uri.splitQueryString(frag.substring(idx + 1));
//       final c = fragQuery['code'];
//       if (c != null && c.isNotEmpty) return c;
//     }
//     return null;
//   }

//   void _showMsg(String msg, {bool error = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: error ? Colors.red : Colors.black87,
//       ),
//     );
//   }

//   bool _isStrongPassword(String p) {
//     // at least 8 chars + letter + number + symbol
//     final hasLetter = RegExp(r'[A-Za-z]').hasMatch(p);
//     final hasNumber = RegExp(r'\d').hasMatch(p);
//     final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(p);
//     return p.length >= 8 && hasLetter && hasNumber && hasSymbol;
//   }

//   Future<void> _reset() async {
//     final p1 = pass1.text.trim();
//     final p2 = pass2.text.trim();

//     if (p1.isEmpty || p2.isEmpty) {
//       _showMsg("Password cannot be empty.", error: true);
//       return;
//     }
//     if (p1 != p2) {
//       _showMsg("Passwords do not match.", error: true);
//       return;
//     }
//     if (!_isStrongPassword(p1)) {
//       _showMsg(
//         "Password must be at least 8 characters and include letters, numbers & symbols.",
//         error: true,
//       );
//       return;
//     }

//     setState(() => loading = true);

//     try {
//       final supabase = Supabase.instance.client;

//       // Web: ensure recovery session
//       if (supabase.auth.currentUser == null && kIsWeb) {
//         final code = _extractCode();
//         if (code != null) {
//           await supabase.auth.exchangeCodeForSession(code);
//         }
//       }

//       final user = supabase.auth.currentUser;
//       if (user == null) {
//         _showMsg(
//           "Recovery session not found. Please open the reset link again.",
//           error: true,
//         );
//         return;
//       }

//       await AuthService.updatePassword(p1);

//       if (!mounted) return;

//       // Optional: sign out after updating password
//       await AuthService.signOut();

//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const PasswordUpdatedScreen()),
//       );
//     } on AuthException catch (e) {
//       if (!mounted) return;
//       _showMsg(e.message, error: true);
//     } catch (e) {
//       if (!mounted) return;
//       _showMsg("Error: $e", error: true);
//     } finally {
//       if (mounted) setState(() => loading = false);
//     }
//   }

//   @override
//   void dispose() {
//     pass1.dispose();
//     pass2.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       body: gradientOrderBackground(
//         child: SafeArea(
//           child: Stack(
//             children: [
//               Positioned(
//                 left: 8,
//                 top: 8,
//                 child: IconButton(
//                   icon: const Icon(Icons.arrow_back_ios_new),
//                   color: Colors.white.withOpacity(0.9),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//               ),
//               Center(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.symmetric(vertical: 28),
//                   child: FrostedGlassCard(
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 6,
//                         vertical: 4,
//                       ),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         crossAxisAlignment: CrossAxisAlignment.stretch,
//                         children: [
//                           Icon(
//                             Icons.lock_reset,
//                             size: 70,
//                             color: Colors.white.withOpacity(0.95),
//                           ),
//                           const SizedBox(height: 10),
//                           Text(
//                             "Set new password",
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               fontSize: 22,
//                               fontWeight: FontWeight.w800,
//                               color: Colors.white.withOpacity(0.95),
//                             ),
//                           ),
//                           const SizedBox(height: 6),
//                           Text(
//                             "Must be at least 8 characters long with a mix of\nletters, numbers, and symbols.",
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               fontSize: 13,
//                               color: Colors.white.withOpacity(0.70),
//                               fontWeight: FontWeight.w600,
//                               height: 1.25,
//                             ),
//                           ),
//                           const SizedBox(height: 18),
//                           CustomTextFormField(
//                             controller: pass1,
//                             label: "New Password",
//                             icon: Icons.lock_outline,
//                             keyboardType: TextInputType.visiblePassword,
//                             obscureText: true,
//                             frostedStyle: true,
//                           ),
//                           const SizedBox(height: 14),
//                           CustomTextFormField(
//                             controller: pass2,
//                             label: "Confirm Password",
//                             icon: Icons.lock,
//                             keyboardType: TextInputType.visiblePassword,
//                             obscureText: true,
//                             frostedStyle: true,
//                           ),
//                           const SizedBox(height: 16),
//                           SizedBox(
//                             height: 46,
//                             child: CustomButton(
//                               width: double.infinity,
//                               label: loading ? "" : "Update Password",
//                               onPressed: loading ? null : _reset,
//                               child: loading
//                                   ? const SizedBox(
//                                       height: 22,
//                                       width: 22,
//                                       child: CircularProgressIndicator(
//                                         strokeWidth: 2,
//                                         color: Color(0xFF2563EB),
//                                       ),
//                                     )
//                                   : null,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// ignore_for_file: deprecated_member_use

import 'package:fabri_sync/auth/frosted_glass.dart';
import 'package:fabri_sync/auth/Forgotpass/password_updated.dart';
import 'package:fabri_sync/services/auth_services.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/widgets/custombutton.dart';
import 'package:fabri_sync/widgets/textfields.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.prefilledEmail});

  // ✅ optional: if you want to pass email from forgot screen
  final String? prefilledEmail;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // ✅ never-null controllers
  late final TextEditingController emailCtrl;
  late final TextEditingController codeCtrl;
  late final TextEditingController pass1Ctrl;
  late final TextEditingController pass2Ctrl;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    emailCtrl = TextEditingController(text: widget.prefilledEmail ?? "");
    codeCtrl = TextEditingController();
    pass1Ctrl = TextEditingController();
    pass2Ctrl = TextEditingController();
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    codeCtrl.dispose();
    pass1Ctrl.dispose();
    pass2Ctrl.dispose();
    super.dispose();
  }

  void _showMsg(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.black87,
      ),
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );
    return emailRegex.hasMatch(email);
  }

  bool _isStrongPassword(String p) {
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(p);
    final hasNumber = RegExp(r'\d').hasMatch(p);
    final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(p);
    return p.length >= 8 && hasLetter && hasNumber && hasSymbol;
  }

  Future<void> _reset() async {
    final email = emailCtrl.text.trim();
    final code = codeCtrl.text.trim();
    final p1 = pass1Ctrl.text.trim();
    final p2 = pass2Ctrl.text.trim();

    if (email.isEmpty) {
      _showMsg("Please enter your email.", error: true);
      return;
    }
    if (!_isValidEmail(email)) {
      _showMsg("Please enter a valid email.", error: true);
      return;
    }
    if (code.isEmpty) {
      _showMsg("Please enter the reset code from email.", error: true);
      return;
    }
    if (p1.isEmpty || p2.isEmpty) {
      _showMsg("Password cannot be empty.", error: true);
      return;
    }
    if (p1 != p2) {
      _showMsg("Passwords do not match.", error: true);
      return;
    }
    if (!_isStrongPassword(p1)) {
      _showMsg(
        "Password must be at least 8 characters and include letters, numbers & symbols.",
        error: true,
      );
      return;
    }

    setState(() => loading = true);

    try {
      final supabase = Supabase.instance.client;

      // ✅ Step 1: verify the recovery code (OTP) using email + code
      await supabase.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.recovery,
      );

      // ✅ Step 2: update password (now session exists)
      await AuthService.updatePassword(p1);

      if (!mounted) return;

      // Optional: sign out after updating password
      await AuthService.signOut();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PasswordUpdatedScreen()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _showMsg(e.message, error: true);
    } catch (e) {
      if (!mounted) return;
      _showMsg("Error: $e", error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: gradientOrderBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: 8,
                top: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  color: Colors.white.withOpacity(0.9),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: FrostedGlassCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.lock_reset,
                            size: 70,
                            color: Colors.white.withOpacity(0.95),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Reset password",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Enter your email + the code from email, then set a new password.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.70),
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 28),

                          CustomTextFormField(
                            controller: emailCtrl,
                            label: "Email Address",
                            icon: Icons.alternate_email,
                            keyboardType: TextInputType.emailAddress,
                            frostedStyle: true,
                          ),
                          const SizedBox(height: 14),

                          CustomTextFormField(
                            controller: codeCtrl,
                            label: "Reset Code",
                            icon: Icons.verified,
                            keyboardType: TextInputType.number,
                            frostedStyle: true,
                          ),
                          const SizedBox(height: 14),

                          CustomTextFormField(
                            controller: pass1Ctrl,
                            label: "New Password",
                            icon: Icons.lock_outline,
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: true,
                            frostedStyle: true,
                          ),
                          const SizedBox(height: 14),

                          CustomTextFormField(
                            controller: pass2Ctrl,
                            label: "Confirm Password",
                            icon: Icons.lock,
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: true,
                            frostedStyle: true,
                          ),
                          const SizedBox(height: 26),

                          SizedBox(
                            height: 46,
                            child: CustomButton(
                              width: double.infinity,
                              label: loading ? "" : "Update Password",
                              onPressed: loading ? null : _reset,
                              child: loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF2563EB),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
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
