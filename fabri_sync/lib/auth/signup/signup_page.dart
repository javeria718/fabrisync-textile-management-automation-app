import 'package:fabri_sync/auth/frosted_glass.dart';
import 'package:fabri_sync/auth/signup/build.dart';
import 'package:fabri_sync/auth/signup/signup_controller.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/widgets/custombutton.dart';
import 'package:fabri_sync/widgets/textfields.dart';
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  final String expectedRole;
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
          color: AppColors.primaryText,
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
    String roleTitle;
    if (controller.selectedRole == 'manager') {
      roleTitle = 'Create Manager account';
    } else if (controller.selectedRole == 'employee_head') {
      roleTitle = 'Create Employee Head account';
    } else {
      roleTitle = 'Create Admin account';
    }
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
          roleTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
        ),
        const SizedBox(height: 26),
        CustomTextFormField(
          controller: controller.fullNameController,
          keyboardType: TextInputType.name,
          label: 'Full Name',
          icon: Icons.person_outline,
          frostedStyle: true,
        ),
        const SizedBox(height: 16),
        CustomTextFormField(
          controller: controller.emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          frostedStyle: true,
        ),
        const SizedBox(height: 16),
        if (controller.selectedRole == 'manager' ||
            controller.selectedRole == 'employee_head') ...[
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
                  decoration: AppDecorations.softPanel(radius: 14),
                  child: const Text(
                    '+92',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
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
            const Text(
              'Enter number starting from 3xx, without 0',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Already have an account?',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/role_selection');
              },
              child: const Text(
                'Login',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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
