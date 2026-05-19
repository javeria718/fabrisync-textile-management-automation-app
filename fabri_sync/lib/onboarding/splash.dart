import 'package:fabri_sync/onboarding/welcome.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 30).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    _navigateToNext();
  }

  void _navigateToNext() async {
    // ✅ If current URL is reset-password (hash routing), don't auto-redirect
    final frag = Uri.base.fragment; // e.g. "/reset-password"
    if (frag.contains('reset-password')) {
      return;
    }

    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // White background
      body: Container(
        color: Colors.white,
        child: LayoutBuilder(
          builder: (context, constraints) {
            double logoSize = constraints.maxWidth * 0.58;
            if (logoSize > 400) logoSize = 400;

            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SizedBox(
                      width: logoSize,
                      child: Image.asset(
                        "assets/images/NEW APP ICON.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
