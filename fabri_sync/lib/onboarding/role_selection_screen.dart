import 'package:fabri_sync/onboarding/welcome.dart';
import 'package:fabri_sync/services/auth_navigation_service.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:flutter/material.dart';

class SelectRoleScreen extends StatefulWidget {
  const SelectRoleScreen({super.key});

  @override
  State<SelectRoleScreen> createState() => _SelectRoleScreenState();
}

class _SelectRoleScreenState extends State<SelectRoleScreen> {
  int? pressedIndex;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = screenWidth < 600
        ? screenWidth * 0.85
        : screenWidth < 900
        ? screenWidth * 0.45
        : screenWidth * 0.28;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.primaryText,
          ),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
            );
          },
        ),
        centerTitle: true,
        title: const Text(
          "SELECT YOUR ROLE",
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
      ),
      body: gradientOrderBackground(
        child: Center(
          child: Wrap(
            spacing: 40,
            runSpacing: 40,
            alignment: WrapAlignment.center,
            children: [
              _roleCard(
                context,
                index: 0,
                width: cardWidth,
                icon: Icons.security,
                title: "Admin",
                subtitle: "Full access to manage the system",
                accent: AppColors.primaryAccent,
                onTap: () => Navigator.pushNamed(
                  context,
                  AuthNavigationService.adminLoginRoute,
                ),
              ),
              _roleCard(
                context,
                index: 1,
                width: cardWidth,
                icon: Icons.work,
                title: "Manager",
                subtitle: "Manage department workflows",
                accent: AppColors.accentBlue,
                onTap: () => Navigator.pushNamed(
                  context,
                  AuthNavigationService.managerLoginRoute,
                ),
              ),
              _roleCard(
                context,
                index: 2,
                width: cardWidth,
                icon: Icons.engineering,
                title: "Employee Head",
                subtitle: "Update department production progress",
                accent: AppColors.accentGreen,
                onTap: () => Navigator.pushNamed(
                  context,
                  AuthNavigationService.employeeHeadLoginRoute,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard(
    BuildContext context, {
    required int index,
    required double width,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final bool isPressed = pressedIndex == index;

    return GestureDetector(
      onTapDown: (_) => setState(() => pressedIndex = index),
      onTapUp: (_) async {
        setState(() => pressedIndex = null);
        await Future.delayed(const Duration(milliseconds: 90));
        onTap();
      },
      onTapCancel: () => setState(() => pressedIndex = null),
      child: AnimatedScale(
        scale: isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: width,
          padding: const EdgeInsets.all(26),
          decoration: AppDecorations.surface(radius: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: accent.withOpacity(0.15),
                child: Icon(icon, size: 34, color: accent),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
