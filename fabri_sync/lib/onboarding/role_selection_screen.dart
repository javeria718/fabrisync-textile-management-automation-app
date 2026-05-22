import 'dart:math';

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
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "SELECT YOUR ROLE",
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
      body: gradientOrderBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;

              final isMobile = screenWidth < 600;
              final isTablet = screenWidth >= 600 && screenWidth < 1024;
              final isExtraSmallMobile = screenWidth < 380;

              final horizontalPadding = isExtraSmallMobile
                  ? 12.0
                  : isMobile
                  ? 16.0
                  : isTablet
                  ? 24.0
                  : 40.0;
              final verticalPadding = isExtraSmallMobile
                  ? 14.0
                  : isMobile
                  ? 18.0
                  : isTablet
                  ? 24.0
                  : 30.0;
              final cardSpacing = isMobile ? 12.0 : 18.0;
              final runSpacing = isMobile ? 14.0 : 20.0;
              final headingSpacing = isMobile ? 18.0 : 26.0;
              final headingFontSize = isMobile
                  ? 15.5
                  : isTablet
                  ? 16.5
                  : 18.0;

              final availableWidth = screenWidth - horizontalPadding * 2;
              final cardWidth = isMobile
                  ? availableWidth
                  : isTablet
                  ? min(380.0, (availableWidth - cardSpacing) / 2)
                  : min(340.0, (availableWidth - cardSpacing * 2) / 3);

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Choose the account role that matches your access level',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: headingFontSize,
                                color: AppColors.secondaryText,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: headingSpacing),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: cardSpacing,
                              runSpacing: runSpacing,
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  child: _roleCard(
                                    context,
                                    index: 0,
                                    icon: Icons.security,
                                    title: 'Admin',
                                    subtitle:
                                        'Full access to manage the system',
                                    accent: AppColors.primaryAccent,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      AuthNavigationService.adminLoginRoute,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _roleCard(
                                    context,
                                    index: 1,
                                    icon: Icons.work,
                                    title: 'Manager',
                                    subtitle: 'Manage department workflows',
                                    accent: AppColors.accentBlue,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      AuthNavigationService.managerLoginRoute,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _roleCard(
                                    context,
                                    index: 2,
                                    icon: Icons.engineering,
                                    title: 'Employee Head',
                                    subtitle:
                                        'Update department production progress',
                                    accent: AppColors.accentGreen,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      AuthNavigationService
                                          .employeeHeadLoginRoute,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _roleCard(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final bool isPressed = pressedIndex == index;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    final isMobileScreen = screenWidth < 600;

    final contentPadding = EdgeInsets.symmetric(
      horizontal: isSmallScreen
          ? 14
          : isMobileScreen
          ? 16
          : 20,
      vertical: isSmallScreen
          ? 16
          : isMobileScreen
          ? 18
          : 22,
    );
    final iconRadius = isSmallScreen
        ? 24.0
        : isMobileScreen
        ? 28.0
        : 32.0;
    final titleFontSize = isSmallScreen
        ? 16.5
        : isMobileScreen
        ? 18.5
        : 20.5;
    final subtitleFontSize = isSmallScreen
        ? 12.0
        : isMobileScreen
        ? 13.0
        : 14.0;

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
          padding: contentPadding,
          decoration: AppDecorations.surface(radius: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: iconRadius,
                backgroundColor: accent.withOpacity(0.14),
                child: Icon(icon, size: iconRadius, color: accent),
              ),
              SizedBox(height: isSmallScreen ? 10 : 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
