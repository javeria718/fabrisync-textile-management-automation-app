// import 'package:fabri_sync/auth/build.dart';
// import 'package:fabri_sync/auth/login/login_page.dart';
// import 'package:fabri_sync/utils/customcolors.dart';
// import 'package:fabri_sync/widgets/textfields.dart';
// import 'package:fabri_sync/widgets/custombutton.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fabri_sync/Model/userModel.dart';
// import 'package:fabri_sync/singleton/singleton.dart';

// class SignUpPage extends StatefulWidget {
//   const SignUpPage({super.key});

//   @override
//   State<SignUpPage> createState() => _SignUpPageState();
// }

// class _SignUpPageState extends State<SignUpPage> {
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
//   void checkPassword(String password) {
//     setState(() {
//       hasUpper = RegExp(r'[A-Z]').hasMatch(password);
//       hasLower = RegExp(r'[a-z]').hasMatch(password);
//       hasNumber = RegExp(r'[0-9]').hasMatch(password);
//       hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password);
//       hasMinLength = password.length >= 8;
//     });
//   }

//   void showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }

//   // *** SIGN UP FUNCTION ***
//   Future<void> signUp(
//     String email,
//     String password,
//     String fullName,
//     String mobile,
//   ) async {
//     try {
//       setState(() => isLoading = true);

//       // Prepend +92 to the phone number
//       final formattedMobile = '+92$mobile';

//       UserCredential userCredential = await FirebaseAuth.instance
//           .createUserWithEmailAndPassword(email: email, password: password);

//       final uid = userCredential.user!.uid;

//       final userModel = UserModel(
//         uid: uid,
//         name: fullName,
//         email: email,
//         phoneNumber: formattedMobile,
//       );

//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(uid)
//           .set(userModel.toJson());

//       UserSingleton().userModel = userModel;

//       await userCredential.user?.updateDisplayName(fullName);

//       if (!mounted) return;

//       // Show success SnackBar
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Signup Successful! Redirecting to Login...'),
//           backgroundColor: Colors.green,
//           duration: Duration(seconds: 2),
//         ),
//       );

//       await Future.delayed(const Duration(seconds: 2));

//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const LoginPage()),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       showError("Signup failed: ${e.toString()}");
//     } finally {
//       if (mounted) setState(() => isLoading = false);
//     }
//   }

//   void validateAndSignUp() {
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
//       showError("Please fill all fields.");
//       return;
//     }
//     if (!emailRegex.hasMatch(email)) {
//       showError("Please enter a valid email address.");
//       return;
//     }
//     if (mobile.length != 10 || !mobile.startsWith('3')) {
//       showError("Enter a valid mobile number starting with 3xx, without 0");
//       return;
//     }
//     if (!hasUpper || !hasLower || !hasNumber || !hasSpecial || !hasMinLength) {
//       showError(
//         "Password must be at least 8 characters and include uppercase, lowercase, number, and special character.",
//       );
//       return;
//     }
//     if (password != confirmPassword) {
//       showError("Passwords do not match.");
//       return;
//     }

//     // Call signUp with the validated mobile
//     signUp(email, password, fullName, mobile);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // backgroundColor: const Color(0xFFF2F4F7),
//       backgroundColor: AppColors.customBgColor,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 const SizedBox(height: 50),
//                 Text(
//                   'FabriSync',
//                   style: TextStyle(
//                     fontSize: 36, // slightly bigger
//                     fontWeight: FontWeight.bold, // strong look
//                     fontFamily: 'Poppins', // modern font
//                     letterSpacing: 1.5,

//                     // gradient text
//                     foreground: Paint()
//                       ..shader = AppTextStyles.gradientBlueShader,

//                     // shadows
//                     shadows: AppTextStyles.textShadows,
//                   ),
//                 ),

//                 SizedBox(height: 20),

//                 /// Title
//                 Text(
//                   'Create Account',
//                   style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//                 ),

//                 const SizedBox(height: 40),

//                 /// Full Name
//                 CustomTextFormField(
//                   controller: fullNameController,
//                   keyboardType: TextInputType.name,
//                   label: 'Full Name',
//                   icon: Icons.person,
//                 ),
//                 const SizedBox(height: 20),

//                 /// Email
//                 CustomTextFormField(
//                   controller: emailController,
//                   label: 'Email',
//                   icon: Icons.email,
//                   keyboardType: TextInputType.emailAddress,
//                 ),
//                 const SizedBox(height: 20),

//                 /// Mobile Number
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         /// Fixed Country Code Box
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 13,
//                           ),
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Colors.grey.shade400),
//                             borderRadius: BorderRadius.circular(5),
//                             color: Colors.grey.shade100,
//                           ),
//                           child: const Text(
//                             '+92',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 10),

//                         /// Remaining number input using CustomTextFormField
//                         Expanded(
//                           child: CustomTextFormField(
//                             controller: mobileController,
//                             keyboardType: TextInputType.number,
//                             label: 'Mobile Number',
//                             icon: Icons.phone,
//                             // No validator here because we will validate in validateAndSignUp()
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 5),

//                     /// Helper Text Below Field
//                     const Text(
//                       'Enter number starting from 3xx, without 0',
//                       style: TextStyle(fontSize: 12, color: Colors.grey),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 20),

//                 /// Password
//                 CustomTextFormField(
//                   keyboardType: TextInputType.visiblePassword,
//                   controller: passwordController,
//                   label: 'Password',
//                   icon: Icons.lock,
//                   obscureText: !showPassword,
//                   onChanged: (value) => checkPassword(value),
//                   suffix: IconButton(
//                     icon: Icon(
//                       showPassword ? Icons.visibility : Icons.visibility_off,
//                       size: 20,
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         showPassword = !showPassword;
//                       });
//                     },
//                   ),
//                 ),
//                 const SizedBox(height: 10),

//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     buildPasswordRule("Uppercase letter", hasUpper),
//                     buildPasswordRule("Lowercase letter", hasLower),
//                     buildPasswordRule("Number", hasNumber),
//                     buildPasswordRule(
//                       "Special character (e.g. !?<>@#\$%)",
//                       hasSpecial,
//                     ),
//                     buildPasswordRule("8 characters or more", hasMinLength),
//                   ],
//                 ),

//                 const SizedBox(height: 20),

//                 /// Confirm Password
//                 CustomTextFormField(
//                   keyboardType: TextInputType.visiblePassword,
//                   controller: confirmPasswordController,
//                   label: 'Confirm Password',
//                   icon: Icons.lock,
//                   obscureText: !showConfirmPassword,
//                   suffix: IconButton(
//                     icon: Icon(
//                       showConfirmPassword
//                           ? Icons.visibility
//                           : Icons.visibility_off,
//                       size: 20,
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         showConfirmPassword = !showConfirmPassword;
//                       });
//                     },
//                   ),
//                 ),

//                 const SizedBox(height: 30),

//                 /// Sign Up Button
//                 CustomButton(
//                   label: 'Sign Up',
//                   onPressed: isLoading ? null : validateAndSignUp,
//                   child: isLoading
//                       ? const SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             color: Colors.white,
//                             strokeWidth: 2,
//                           ),
//                         )
//                       : null,
//                 ),
//                 const SizedBox(height: 20),

//                 /// Divider
//                 Container(height: 1, width: 200, color: Colors.grey.shade300),

//                 const SizedBox(height: 10),

//                 /// Already have account → Login
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text(
//                       'Already have an account?',
//                       style: TextStyle(fontSize: 12),
//                     ),
//                     TextButton(
//                       onPressed: () {
//                         Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(builder: (_) => const LoginPage()),
//                         );
//                       },
//                       child: const Text(
//                         'Login',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: AppColors.customBlueColor,
//                           decoration: TextDecoration.underline,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
