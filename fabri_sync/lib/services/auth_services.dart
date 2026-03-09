// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:supabase_flutter/supabase_flutter.dart';

// // Web-only import
// // ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;

// class AuthService {
//   static final SupabaseClient _supabase = Supabase.instance.client;

//   static const String kHostedResetPage =
//       'https://fabrisync-d4a57.web.app/reset.html';

//   static Future<void> sendPasswordRecoveryEmail(String email) async {
//     String redirectTo;

//     if (kIsWeb) {
//       final origin = html.window.location.origin;
//       redirectTo = '$origin/#/reset-password';
//     } else {
//       redirectTo = kHostedResetPage;
//     }

//     await _supabase.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
//   }

//   static Future<void> updatePassword(String newPassword) async {
//     await _supabase.auth.updateUser(UserAttributes(password: newPassword));
//   }

//   static Future<void> signOut() async {
//     await _supabase.auth.signOut();
//   }
// }
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<void> sendPasswordRecoveryEmail(String email) async {
    // ✅ NO redirectTo -> Supabase default hosted reset page will be used
    await _supabase.auth.resetPasswordForEmail(email);
  }

  static Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
