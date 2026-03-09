// import 'package:fabri_sync/auth/frosted_glass.dart';
// import 'package:flutter/material.dart';
// import 'package:fabri_sync/auth/signup/build.dart';
// import 'package:fabri_sync/auth/signup/signup_controller.dart';
// import 'package:fabri_sync/widgets/textfields.dart';
// import 'package:fabri_sync/widgets/custombutton.dart';

// class SignUpPage extends StatefulWidget {
//   const SignUpPage({super.key});

//   @override
//   State<SignUpPage> createState() => _SignUpPageState();
// }

// class _SignUpPageState extends State<SignUpPage> {
//   final SignUpController controller = SignUpController();

//   Widget gradientOrderBackground({required Widget child}) {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [Color(0xFF0F172A), Color(0xFF111827)],
//         ),
//       ),
//       child: child,
//     );
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
//                     maxWidth: 560,
//                     padding: const EdgeInsets.all(28),
//                     child: _SignUpFormContent(
//                       controller: controller,
//                       onRebuild: () => setState(() {}),
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

// class _SignUpFormContent extends StatelessWidget {
//   final SignUpController controller;
//   final VoidCallback onRebuild;

//   const _SignUpFormContent({required this.controller, required this.onRebuild});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         Text(
//           'FabriSync',
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontSize: 30,
//             fontWeight: FontWeight.w800,
//             color: Colors.white.withOpacity(0.95),
//             letterSpacing: 1,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Text(
//           'Create your account',
//           textAlign: TextAlign.center,
//           style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.70)),
//         ),
//         const SizedBox(height: 26),

//         // Full Name
//         CustomTextFormField(
//           controller: controller.fullNameController,
//           keyboardType: TextInputType.name,
//           label: 'Full Name',
//           icon: Icons.person_outline,
//           frostedStyle: true,
//         ),
//         const SizedBox(height: 16),

//         // Email
//         CustomTextFormField(
//           controller: controller.emailController,
//           label: 'Email',
//           icon: Icons.email_outlined,
//           keyboardType: TextInputType.emailAddress,
//           frostedStyle: true,
//         ),
//         const SizedBox(height: 16),

//         // ✅ Select Role (was Sign up as)
//         FrostedDropdown(
//           value: controller.selectedRole,
//           label: 'Select Role',
//           icon: Icons.badge_outlined,
//           hintText: 'Choose role',
//           items: const [
//             DropdownMenuItem(value: 'admin', child: Text('Admin')),
//             DropdownMenuItem(value: 'manager', child: Text('Manager')),
//           ],
//           onChanged: (value) {
//             controller.selectedRole = value!;
//             controller.selectedDepartment = null;
//             onRebuild();
//           },
//         ),

//         // Department (ONLY for Manager)
//         if (controller.selectedRole == 'manager') ...[
//           const SizedBox(height: 16),
//           FrostedDropdown(
//             value: controller.selectedDepartment,
//             label: 'Select Department',
//             icon: Icons.apartment_outlined,
//             hintText: 'Choose department',
//             items: controller.departments
//                 .map((dept) => DropdownMenuItem(value: dept, child: Text(dept)))
//                 .toList(),
//             onChanged: (value) {
//               controller.selectedDepartment = value;
//               onRebuild();
//             },
//           ),
//         ],

//         const SizedBox(height: 16),

//         // Mobile Number
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 14,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.10),
//                     borderRadius: BorderRadius.circular(14),
//                     border: Border.all(color: Colors.white.withOpacity(0.18)),
//                   ),
//                   child: Text(
//                     '+92',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                       color: Colors.white.withOpacity(0.90),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: CustomTextFormField(
//                     controller: controller.mobileController,
//                     keyboardType: TextInputType.number,
//                     label: 'Mobile Number',
//                     icon: Icons.phone_outlined,
//                     frostedStyle: true,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 6),
//             Text(
//               'Enter number starting from 3xx, without 0',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.white.withOpacity(0.65),
//               ),
//             ),
//           ],
//         ),

//         const SizedBox(height: 16),

//         // Password
//         CustomTextFormField(
//           controller: controller.passwordController,
//           keyboardType: TextInputType.visiblePassword,
//           label: 'Password',
//           icon: Icons.lock_outline,
//           obscureText: !controller.showPassword,
//           onChanged: (value) {
//             controller.checkPassword(value);
//             onRebuild();
//           },
//           suffix: IconButton(
//             icon: Icon(
//               controller.showPassword ? Icons.visibility : Icons.visibility_off,
//               size: 20,
//             ),
//             onPressed: () {
//               controller.showPassword = !controller.showPassword;
//               onRebuild();
//             },
//           ),
//           frostedStyle: true,
//         ),

//         const SizedBox(height: 12),

//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             buildPasswordRule("Uppercase letter", controller.hasUpper),
//             buildPasswordRule("Lowercase letter", controller.hasLower),
//             buildPasswordRule("Number", controller.hasNumber),
//             buildPasswordRule(
//               "Special character (e.g. !?<>@#\$%)",
//               controller.hasSpecial,
//             ),
//             buildPasswordRule("8 characters or more", controller.hasMinLength),
//           ],
//         ),

//         const SizedBox(height: 16),

//         // Confirm Password
//         CustomTextFormField(
//           controller: controller.confirmPasswordController,
//           keyboardType: TextInputType.visiblePassword,
//           label: 'Confirm Password',
//           icon: Icons.lock_outline,
//           obscureText: !controller.showConfirmPassword,
//           suffix: IconButton(
//             icon: Icon(
//               controller.showConfirmPassword
//                   ? Icons.visibility
//                   : Icons.visibility_off,
//               size: 20,
//             ),
//             onPressed: () {
//               controller.showConfirmPassword = !controller.showConfirmPassword;
//               onRebuild();
//             },
//           ),
//           frostedStyle: true,
//         ),

//         const SizedBox(height: 18),

//         // Sign Up Button (same logic)
//         SizedBox(
//           height: 46,
//           child: CustomButton(
//             width: double.infinity,
//             label: controller.isLoading ? "" : 'Sign Up',
//             onPressed: controller.isLoading
//                 ? null
//                 : () async {
//                     controller.isLoading = true;
//                     onRebuild();
//                     await controller.signUp(
//                       context,
//                     ); // make validateAndSignUp Future OR call signUp directly after validations
//                     controller.isLoading = false;
//                     onRebuild();
//                   },

//             child: controller.isLoading
//                 ? const SizedBox(
//                     height: 22,
//                     width: 22,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: Color(0xFF2563EB),
//                     ),
//                   )
//                 : null,
//           ),
//         ),

//         const SizedBox(height: 14),

//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'Already have an account?',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.white.withOpacity(0.75),
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.pushReplacementNamed(context, '/role_selection');
//               },
//               child: Text(
//                 'Login',
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.white.withOpacity(0.92),
//                   decoration: TextDecoration.underline,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }
import 'package:fabri_sync/auth/frosted_glass.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:flutter/material.dart';
import 'package:fabri_sync/auth/signup/build.dart';
import 'package:fabri_sync/auth/signup/signup_controller.dart';
import 'package:fabri_sync/widgets/textfields.dart';
import 'package:fabri_sync/widgets/custombutton.dart';

class SignUpPage extends StatefulWidget {
  final String expectedRole; // 'admin' or 'manager'
  const SignUpPage({super.key, required this.expectedRole});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  late final SignUpController controller;

  @override
  void initState() {
    super.initState();
    controller = SignUpController(role: widget.expectedRole);
  }

  Widget gradientOrderBackground({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F172A), Color(0xFF111827)],
        ),
      ),
      child: child,
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isManager = controller.selectedRole == 'manager';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: Colors.white.withOpacity(0.9),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: gradientOrderBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: FrostedGlassCard(
                maxWidth: 560,
                padding: const EdgeInsets.all(28),
                child: _SignUpFormContent(
                  controller: controller,
                  isManager: isManager,
                  onRebuild: () => setState(() {}),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignUpFormContent extends StatelessWidget {
  final SignUpController controller;
  final bool isManager;
  final VoidCallback onRebuild;

  const _SignUpFormContent({
    required this.controller,
    required this.isManager,
    required this.onRebuild,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'FabriSync',

          textAlign: TextAlign.center,
          style: AppTextStyles.titleStyleW,
        ),
        const SizedBox(height: 12),
        Text(
          isManager ? 'Create Manager account' : 'Create Admin account',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.70)),
        ),
        const SizedBox(height: 26),

        // Full Name
        CustomTextFormField(
          controller: controller.fullNameController,
          keyboardType: TextInputType.name,
          label: 'Full Name',
          icon: Icons.person_outline,
          frostedStyle: true,
        ),
        const SizedBox(height: 16),

        // Email
        CustomTextFormField(
          controller: controller.emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          frostedStyle: true,
        ),
        const SizedBox(height: 16),

        // ✅ Department (ONLY for Manager)
        if (isManager) ...[
          FrostedDropdown(
            value: controller.selectedDepartment,
            label: 'Select Department',
            icon: Icons.apartment_outlined,
            hintText: 'Choose department',
            items: controller.departments
                .map((dept) => DropdownMenuItem(value: dept, child: Text(dept)))
                .toList(),
            onChanged: (value) {
              controller.selectedDepartment = value;
              onRebuild();
            },
          ),
          const SizedBox(height: 16),
        ],

        // Mobile Number
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Text(
                    '+92',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.90),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomTextFormField(
                    controller: controller.mobileController,
                    keyboardType: TextInputType.number,
                    label: 'Mobile Number',
                    icon: Icons.phone_outlined,
                    frostedStyle: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Enter number starting from 3xx, without 0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.65),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Password
        CustomTextFormField(
          controller: controller.passwordController,
          keyboardType: TextInputType.visiblePassword,
          label: 'Password',
          icon: Icons.lock_outline,
          obscureText: !controller.showPassword,
          onChanged: (value) {
            controller.checkPassword(value);
            onRebuild();
          },
          suffix: IconButton(
            icon: Icon(
              controller.showPassword ? Icons.visibility : Icons.visibility_off,
              size: 20,
            ),
            onPressed: () {
              controller.showPassword = !controller.showPassword;
              onRebuild();
            },
          ),
          frostedStyle: true,
        ),

        const SizedBox(height: 12),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildPasswordRule("Uppercase letter", controller.hasUpper),
            buildPasswordRule("Lowercase letter", controller.hasLower),
            buildPasswordRule("Number", controller.hasNumber),
            buildPasswordRule(
              "Special character (e.g. !?<>@#\$%)",
              controller.hasSpecial,
            ),
            buildPasswordRule("8 characters or more", controller.hasMinLength),
          ],
        ),

        const SizedBox(height: 16),

        // Confirm Password
        CustomTextFormField(
          controller: controller.confirmPasswordController,
          keyboardType: TextInputType.visiblePassword,
          label: 'Confirm Password',
          icon: Icons.lock_outline,
          obscureText: !controller.showConfirmPassword,
          suffix: IconButton(
            icon: Icon(
              controller.showConfirmPassword
                  ? Icons.visibility
                  : Icons.visibility_off,
              size: 20,
            ),
            onPressed: () {
              controller.showConfirmPassword = !controller.showConfirmPassword;
              onRebuild();
            },
          ),
          frostedStyle: true,
        ),

        const SizedBox(height: 18),

        // ✅ Sign Up Button (await + validation)
        SizedBox(
          height: 46,
          child: CustomButton(
            width: double.infinity,
            label: controller.isLoading ? "" : 'Sign Up',
            onPressed: controller.isLoading
                ? null
                : () async {
                    controller.isLoading = true;
                    onRebuild();
                    await controller.validateAndSignUp(context);
                    controller.isLoading = false;
                    onRebuild();
                  },
            child: controller.isLoading
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

        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account?',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.75),
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/role_selection');
              },
              child: Text(
                'Login',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.92),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
