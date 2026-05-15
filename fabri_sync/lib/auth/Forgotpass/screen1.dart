import 'package:fabri_sync/auth/Forgotpass/reset_pass.dart';
import 'package:fabri_sync/auth/frosted_glass.dart';
import 'package:fabri_sync/services/auth_services.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/widgets/custombutton.dart';
import 'package:fabri_sync/widgets/textfields.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _email = TextEditingController();
  late final FocusNode _emailFocusNode;
  bool _loading = false;

  void _showMsg(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.primaryText,
      ),
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );
    return emailRegex.hasMatch(email);
  }

  Future<List<String>> _getSavedEmails() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('login_emails') ?? <String>[];
  }

  Future<void> _submit() async {
    final input = _email.text.trim();

    if (input.isEmpty) {
      _showMsg("Please enter your email address.", error: true);
      return;
    }
    if (!_isValidEmail(input)) {
      _showMsg("Please enter a valid email address.", error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.sendPasswordRecoveryEmail(input);

      if (!mounted) return;
      _showMsg("Reset link sent! Please check your email.");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _showMsg(e.message, error: true);
    } catch (e) {
      if (!mounted) return;
      _showMsg("Error: $e", error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _emailFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _email.dispose();
    _emailFocusNode.dispose();
    super.dispose();
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
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: AppColors.primaryText,
                  ),
                  label: const Text(
                    "Back to login",
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                          const Icon(
                            Icons.lock_reset,
                            size: 70,
                            color: AppColors.primaryAccent,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Reset your password",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Enter your email and we will send you a link to\nget back into your account.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 48),
                          FutureBuilder<List<String>>(
                            future: _getSavedEmails(),
                            builder: (context, snapshot) {
                              final emails = snapshot.data ?? <String>[];

                              return RawAutocomplete<String>(
                                textEditingController: _email,
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
                                  _email.text = selection;
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
                                        label: "Email Address",
                                        icon: Icons.alternate_email,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        frostedStyle: true,
                                      );
                                    },
                                optionsViewBuilder:
                                    (context, onSelected, options) {
                                      return Align(
                                        alignment: Alignment.topLeft,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: Container(
                                            margin: const EdgeInsets.only(top: 6),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                            constraints: const BoxConstraints(
                                              maxHeight: 220,
                                              maxWidth: 420,
                                            ),
                                            decoration: AppDecorations.surface(
                                              radius: 12,
                                            ),
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
                          const SizedBox(height: 36),
                          SizedBox(
                            height: 46,
                            child: CustomButton(
                              width: double.infinity,
                              label: _loading ? "" : "Send Reset Link",
                              onPressed: _loading ? null : _submit,
                              child: _loading
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
