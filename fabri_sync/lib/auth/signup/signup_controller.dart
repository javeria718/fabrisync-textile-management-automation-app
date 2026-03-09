// import 'package:flutter/material.dart';
// import 'package:fabri_sync/Model/userModel.dart';
// import 'package:fabri_sync/singleton/singleton.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class SignUpController {
//    SignUpController({required String role}) {
//     selectedRole = role; // 'admin' or 'manager'
//   }
//   final TextEditingController fullNameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController mobileController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController =
//       TextEditingController();

//   bool showPassword = false;
//   bool showConfirmPassword = false;
//   bool isLoading = false;

//   bool hasUpper = false;
//   bool hasLower = false;
//   bool hasNumber = false;
//   bool hasSpecial = false;
//   bool hasMinLength = false;

//   String selectedRole = 'manager';
//   String? selectedDepartment;

//   final List<String> departments = [
//     'Cutting',
//     'Stitching',
//     'Threading',
//     'Quality_Control',
//     'Packing',
//     'Inspection',
//   ];

//   final supabase = Supabase.instance.client;

//   void checkPassword(String password) {
//     hasUpper = RegExp(r'[A-Z]').hasMatch(password);
//     hasLower = RegExp(r'[a-z]').hasMatch(password);
//     hasNumber = RegExp(r'[0-9]').hasMatch(password);
//     hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password);
//     hasMinLength = password.length >= 8;
//   }

//   void showError(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }

//   Future<void> signUp(BuildContext context) async {
//     final email = emailController.text.trim();
//     final password = passwordController.text.trim();
//     final fullName = fullNameController.text.trim();
//     final mobile = mobileController.text.trim();

//     if (selectedRole == 'manager' && selectedDepartment == null) {
//       showError(context, "Please select a department");
//       return;
//     }

//     try {
//       isLoading = true;

//       final formattedMobile = '+92$mobile';
//       final role = selectedRole.toLowerCase();
//       final dept = selectedDepartment; // ✅ keep as-is

//       final response = await supabase.auth.signUp(
//         email: email,
//         password: password,
//         data: {
//           'full_name': fullName,
//           'phone_number': formattedMobile,
//           'role': role,
//           'department': dept ?? '',
//         },
//       );

//       final user = response.user;
//       if (user == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Signup successful! Please verify your email."),
//             backgroundColor: Colors.green,
//           ),
//         );
//         if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
//         return;
//       }

//       final uid = user.id;

//       final payload = {
//         'id': uid, // ✅ must for RLS
//         'full_name': fullName,
//         'email': email,
//         'phone_number': formattedMobile,
//         'role': role,
//         'department': role == 'manager' ? dept : null,
//       };

//       // ✅ Prefer INSERT for first-time profile creation
//       // If profile already exists (due to trigger or retry), fallback to UPDATE
//       try {
//         await supabase.from('profiles').insert(payload);
//       } on PostgrestException catch (e) {
//         // 23505 = unique violation (already exists)
//         if (e.code == '23505') {
//           await supabase.from('profiles').update(payload).eq('id', uid);
//         } else {
//           rethrow;
//         }
//       }

//       UserSingleton().userModel = UserModel(
//         uid: uid,
//         name: fullName,
//         email: email,
//         phoneNumber: formattedMobile,
//         role: role,
//         department: role == 'manager' ? dept : null,
//       );

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Signup Successful!'),
//           backgroundColor: Colors.green,
//         ),
//       );

//       if (context.mounted) {
//         Navigator.pushReplacementNamed(context, '/login');
//       }
//     } on PostgrestException catch (e) {
//       showError(context, "Signup failed: ${e.message} (code: ${e.code})");
//     } catch (e) {
//       showError(context, "Signup failed: ${e.toString()}");
//     } finally {
//       isLoading = false;
//     }
//   }

//   void validateAndSignUp(BuildContext context) {
//     final fullName = fullNameController.text.trim();
//     final email = emailController.text.trim();
//     final mobile = mobileController.text.trim();
//     final password = passwordController.text.trim();
//     final confirmPassword = confirmPasswordController.text.trim();

//     final emailRegex = RegExp(
//       r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
//     );

//     if (fullName.isEmpty ||
//         email.isEmpty ||
//         mobile.isEmpty ||
//         password.isEmpty ||
//         confirmPassword.isEmpty) {
//       showError(context, "Please fill all fields.");
//       return;
//     }

//     if (!emailRegex.hasMatch(email)) {
//       showError(context, "Please enter a valid email address.");
//       return;
//     }

//     if (mobile.length != 10 || !mobile.startsWith('3')) {
//       showError(
//         context,
//         "Enter a valid mobile number starting with 3xx, without 0",
//       );
//       return;
//     }

//     if (!hasUpper || !hasLower || !hasNumber || !hasSpecial || !hasMinLength) {
//       showError(
//         context,
//         "Password must be at least 8 characters and include uppercase, lowercase, number, and special character.",
//       );
//       return;
//     }

//     if (password != confirmPassword) {
//       showError(context, "Passwords do not match.");
//       return;
//     }

//     signUp(context);
//   }
// }
import 'package:flutter/material.dart';
import 'package:fabri_sync/Model/userModel.dart';
import 'package:fabri_sync/singleton/singleton.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpController {
  SignUpController({required String role}) {
    selectedRole = role.toLowerCase(); // 'admin' or 'manager'
  }

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool showPassword = false;
  bool showConfirmPassword = false;
  bool isLoading = false;

  bool hasUpper = false;
  bool hasLower = false;
  bool hasNumber = false;
  bool hasSpecial = false;
  bool hasMinLength = false;

  String selectedRole = 'manager';
  String? selectedDepartment;

  // ✅ Canonical keys (match DB)
  final List<String> departments = const [
    'CUTTING',
    'STITCHING',
    'THREADING',
    'QUALITY_CONTROL',
    'PACKING',
    'INSPECTION',
  ];

  final supabase = Supabase.instance.client;

  void checkPassword(String password) {
    hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    hasLower = RegExp(r'[a-z]').hasMatch(password);
    hasNumber = RegExp(r'[0-9]').hasMatch(password);
    hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password);
    hasMinLength = password.length >= 8;
  }

  void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ✅ validations async so UI can await
  Future<void> validateAndSignUp(BuildContext context) async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final mobile = mobileController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    final emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );

    if (fullName.isEmpty ||
        email.isEmpty ||
        mobile.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showError(context, "Please fill all fields.");
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      showError(context, "Please enter a valid email address.");
      return;
    }

    if (mobile.length != 10 || !mobile.startsWith('3')) {
      showError(
        context,
        "Enter a valid mobile number starting with 3xx, without 0",
      );
      return;
    }

    if (!hasUpper || !hasLower || !hasNumber || !hasSpecial || !hasMinLength) {
      showError(
        context,
        "Password must be at least 8 characters and include uppercase, lowercase, number, and special character.",
      );
      return;
    }

    if (password != confirmPassword) {
      showError(context, "Passwords do not match.");
      return;
    }

    // ✅ Manager must select dept
    if (selectedRole == 'manager' &&
        (selectedDepartment == null || selectedDepartment!.isEmpty)) {
      showError(context, "Please select a department");
      return;
    }

    // OPTIONAL: enforce single manager per dept at app-level too
    // if (selectedRole == 'manager') {
    //   final exists = await supabase
    //       .from('profiles')
    //       .select('id')
    //       .eq('role', 'manager')
    //       .eq('department', selectedDepartment!)
    //       .maybeSingle();
    //   if (exists != null) {
    //     showError(context, "A manager for this department already exists.");
    //     return;
    //   }
    // }

    await signUp(context);
  }

  Future<void> signUp(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final fullName = fullNameController.text.trim();
    final mobile = mobileController.text.trim();

    try {
      final formattedMobile = '+92$mobile';
      final role = selectedRole.toLowerCase();

      // ✅ dept only for manager
      final dept = role == 'manager'
          ? (selectedDepartment ?? '').toUpperCase()
          : '';

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone_number': formattedMobile,
          'role': role,
          'department': dept,
        },
      );

      final user = response.user;

      // If email confirmations ON -> you may get user but no session; trigger should handle profile creation anyway
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Signup successful! Please verify your email."),
            backgroundColor: Colors.green,
          ),
        );
        if (context.mounted)
          Navigator.pushReplacementNamed(context, '/role_selection');
        return;
      }

      final uid = user.id;

      // ✅ keep profile sync (works even if trigger exists)
      final payload = {
        'id': uid,
        'full_name': fullName,
        'email': email,
        'phone_number': formattedMobile,
        'role': role,
        'department': role == 'manager' ? dept : null,
      };

      try {
        await supabase.from('profiles').insert(payload);
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          await supabase.from('profiles').update(payload).eq('id', uid);
        } else {
          rethrow;
        }
      }

      UserSingleton().userModel = UserModel(
        uid: uid,
        name: fullName,
        email: email,
        phoneNumber: formattedMobile,
        role: role,
        department: role == 'manager' ? dept : null,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signup Successful!'),
          backgroundColor: Colors.green,
        ),
      );

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/role_selection');
      }
    } on AuthException catch (e) {
      showError(context, "Signup failed: ${e.message}");
    } on PostgrestException catch (e) {
      showError(context, "Signup failed: ${e.message} (code: ${e.code})");
    } catch (e) {
      showError(context, "Signup failed: ${e.toString()}");
    }
  }
}
