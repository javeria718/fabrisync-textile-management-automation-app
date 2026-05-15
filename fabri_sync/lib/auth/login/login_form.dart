import 'package:fabri_sync/auth/Forgotpass/screen1.dart';
import 'package:fabri_sync/auth/signup/signup_page.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/widgets/custombutton.dart';
import 'package:fabri_sync/widgets/textfields.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_controller.dart';

class LoginForm extends StatefulWidget {
  final String expectedRole;
  final LoginController controller;
  final VoidCallback togglePassword;
  final VoidCallback onLoginPressed;

  const LoginForm({
    super.key,
    required this.controller,
    required this.expectedRole,
    required this.togglePassword,
    required this.onLoginPressed,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late final FocusNode _emailFocusNode;

  @override
  void initState() {
    super.initState();
    _emailFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<List<String>> _getSavedEmails() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('login_emails') ?? <String>[];
  }

  String get _roleTitle {
    switch (widget.expectedRole.toLowerCase().trim()) {
      case 'admin':
        return 'Admin Login';
      case 'manager':
        return 'Manager Login';
      case 'employee_head':
        return 'Employee Head Login';
      default:
        return 'Login';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWebWide = constraints.maxWidth >= 600;

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWebWide ? 0 : 4,
              vertical: 4,
            ),
            child: Column(
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
                  _roleTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign in to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 22),
                FutureBuilder<List<String>>(
                  future: _getSavedEmails(),
                  builder: (context, snapshot) {
                    final emails = snapshot.data ?? <String>[];

                    return RawAutocomplete<String>(
                      textEditingController: widget.controller.emailController,
                      focusNode: _emailFocusNode,
                      optionsBuilder: (TextEditingValue value) {
                        if (emails.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        final query = value.text.trim().toLowerCase();
                        if (query.isEmpty) return emails;
                        return emails.where(
                          (e) => e.toLowerCase().contains(query),
                        );
                      },
                      onSelected: (selection) {
                        widget.controller.emailController.text = selection;
                      },
                      fieldViewBuilder:
                          (
                            context,
                            textController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            return CustomTextFormField(
                              controller: textController,
                              focusNode: focusNode,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              frostedStyle: true,
                            );
                          },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              constraints: const BoxConstraints(
                                maxHeight: 220,
                                maxWidth: 420,
                              ),
                              decoration: AppDecorations.surface(radius: 12),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      option,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 14),
                CustomTextFormField(
                  controller: widget.controller.passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: !widget.controller.showPassword,
                  suffix: IconButton(
                    icon: Icon(
                      widget.controller.showPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      size: 20,
                    ),
                    onPressed: widget.togglePassword,
                  ),
                  frostedStyle: true,
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 46,
                  child: CustomButton(
                    width: double.infinity,
                    label: widget.controller.isLoading ? "" : "Sign In",
                    onPressed: widget.onLoginPressed,
                    child: widget.controller.isLoading
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
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SignUpPage(expectedRole: widget.expectedRole),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        "Sign Up",
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
            ),
          ),
        );
      },
    );
  }
}
