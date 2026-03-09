// import 'package:fabri_sync/auth/Forgotpass/screen1.dart';
// import 'package:fabri_sync/auth/signup.dart';
// import 'package:fabri_sync/onboarding/role_selection_screen.dart';

// import 'package:fabri_sync/utils/customcolors.dart';
// import 'package:fabri_sync/widgets/textfields.dart';
// import 'package:fabri_sync/widgets/custombutton.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fabri_sync/Model/userModel.dart';
// import 'package:fabri_sync/singleton/singleton.dart';

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();

//   bool isLoading = false;
//   bool showPassword = false;

//   void showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }

//   Future<void> login(String email, String password) async {
//     try {
//       setState(() => isLoading = true);

//       UserCredential credential = await FirebaseAuth.instance
//           .signInWithEmailAndPassword(email: email, password: password);

//       final uid = credential.user?.uid;
//       if (uid == null) throw Exception("User ID is null");

//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(uid)
//           .get();

//       if (!doc.exists) throw Exception("User data not found in Firestore");

//       final userModel = UserModel.fromJson(doc.data()!);

//       UserSingleton().userModel = userModel;

//       if (!mounted) return;

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => SelectRoleScreen()),
//       );
//     } catch (e) {
//       if (!mounted) return;

//       if (e is FirebaseAuthException) {
//         if (e.code == 'wrong-password') {
//           showError("Invalid password.");
//           return;
//         }
//         if (e.code == 'user-not-found') {
//           showError("No user found with this email.");
//           return;
//         }
//       }

//       showError("Login failed: ${e.toString()}");
//     }
//   }

//   void validateAndLogin() {
//     final email = emailController.text.trim();
//     final password = passwordController.text.trim();

//     // Strict email regex
//     final emailRegex = RegExp(
//       r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
//     );

//     if (email.isEmpty || password.isEmpty) {
//       showError("Please fill all fields.");
//       return;
//     }

//     if (!emailRegex.hasMatch(email)) {
//       showError("Please enter a valid email address.");
//       return;
//     }

//     // 👉 No password REGEX here
//     // Firebase will tell if password is wrong

//     login(email, password);
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
//                 const SizedBox(height: 80),

//                 /// Title
//                 Text(
//                   'FabriSync',
//                   style: TextStyle(
//                     fontSize: 36, // slightly bigger
//                     fontWeight: FontWeight.bold, // strong, elegant look
//                     fontFamily: 'Poppins', // modern professional font
//                     letterSpacing: 1.5,

//                     // gradient text
//                     foreground: Paint()
//                       ..shader = AppTextStyles.gradientBlueShader,

//                     // shadows
//                     shadows: AppTextStyles.textShadows,
//                   ),
//                 ),

//                 const SizedBox(height: 60),

//                 /// Email Field
//                 CustomTextFormField(
//                   controller: emailController,
//                   label: 'Email',
//                   icon: Icons.email,
//                   keyboardType: TextInputType.emailAddress,
//                 ),

//                 const SizedBox(height: 20),

//                 /// Password – With eye toggle
//                 CustomTextFormField(
//                   controller: passwordController,
//                   label: 'Password',
//                   icon: Icons.lock,
//                   keyboardType: TextInputType.visiblePassword,
//                   obscureText: !showPassword,
//                   suffix: IconButton(
//                     icon: Icon(
//                       showPassword ? Icons.visibility : Icons.visibility_off,
//                       size: 20,
//                     ),
//                     onPressed: () {
//                       setState(() => showPassword = !showPassword);
//                     },
//                   ),
//                 ),

//                 const SizedBox(height: 8),

//                 /// Forgot Password
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const ForgotPasswordScreen(),
//                         ),
//                       );
//                     },
//                     child: const Text(
//                       'Forgot Password?',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                         color: AppColors.customBlueColor,
//                         decoration: TextDecoration.underline,
//                       ),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 20),

//                 /// Login Button
//                 CustomButton(
//                   label: isLoading ? "" : "Login", // empty label when loading
//                   onPressed: isLoading ? null : validateAndLogin,
//                   child: isLoading
//                       ? const SizedBox(
//                           height: 24,
//                           width: 24,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors
//                                 .white, // or custom color if your button is dark
//                           ),
//                         )
//                       : null,
//                 ),

//                 const SizedBox(height: 20),

//                 /// Sign Up
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text(
//                       "Don’t have an account?",
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     TextButton(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const SignUpPage(),
//                           ),
//                         );
//                       },
//                       child: const Text(
//                         "Sign Up",
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
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
