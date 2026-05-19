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
              fontSize: 24,
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

              // Enhanced responsive breakpoints
              final isExtraSmallMobile =
                  screenWidth < 380; // iPhone SE, small phones
              final isSmallMobile =
                  screenWidth >= 380 && screenWidth < 550; // iPhone 12/13/14
              final isMediumMobile =
                  screenWidth >= 550 && screenWidth < 640; // Large phones
              final isTablet =
                  screenWidth >= 640 && screenWidth < 1024; // iPad, tablets
              final isDesktop = screenWidth >= 1024; // Desktop, laptop
              final isLargeDesktop = screenWidth >= 1440; // Large monitors

              // Responsive settings with better granularity
              int crossAxisCount = 1; // Default for mobile
              double horizontalPadding = 12.0;
              double verticalPadding = 16.0;
              double childAspectRatio = 0.75;
              double crossAxisSpacing = 12.0;
              double mainAxisSpacing = 12.0;
              double fontSize = 14.0;

              if (isExtraSmallMobile) {
                // Extra small phones (320-380px)
                crossAxisCount = 1;
                horizontalPadding = 12.0;
                verticalPadding = 16.0;
                childAspectRatio = 0.75;
                crossAxisSpacing = 12.0;
                mainAxisSpacing = 12.0;
                fontSize = 13.0;
              } else if (isSmallMobile) {
                // Small phones (380-550px)
                crossAxisCount = 1;
                horizontalPadding = 14.0;
                verticalPadding = 18.0;
                childAspectRatio = 0.80;
                crossAxisSpacing = 14.0;
                mainAxisSpacing = 14.0;
                fontSize = 14.0;
              } else if (isMediumMobile) {
                // Medium/Large phones (550-640px)
                crossAxisCount = 1;
                horizontalPadding = 16.0;
                verticalPadding = 20.0;
                childAspectRatio = 0.85;
                crossAxisSpacing = 16.0;
                mainAxisSpacing = 16.0;
                fontSize = 14.5;
              } else if (isTablet) {
                // Tablets (640-1024px)
                crossAxisCount = 2;
                horizontalPadding = 24.0;
                verticalPadding = 28.0;
                childAspectRatio = 1.0;
                crossAxisSpacing = 20.0;
                mainAxisSpacing = 20.0;
                fontSize = 16.0;
              } else if (isLargeDesktop) {
                // Large desktops (1440px+)
                crossAxisCount = 3;
                horizontalPadding = 60.0;
                verticalPadding = 32.0;
                childAspectRatio = 1.15;
                crossAxisSpacing = 36.0;
                mainAxisSpacing = 36.0;
                fontSize = 16.5;
              } else {
                // Standard desktop (1024-1440px)
                crossAxisCount = 3;
                horizontalPadding = 40.0;
                verticalPadding = 28.0;
                childAspectRatio = 1.1;
                crossAxisSpacing = 28.0;
                mainAxisSpacing = 28.0;
                fontSize = 16.0;
              }

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
                                fontSize: fontSize,
                                color: AppColors.secondaryText,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(
                              height: isExtraSmallMobile
                                  ? 16
                                  : isMediumMobile
                                  ? 24
                                  : isTablet
                                  ? 32
                                  : 36,
                            ),
                            GridView.count(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: childAspectRatio,
                              crossAxisSpacing: crossAxisSpacing,
                              mainAxisSpacing: mainAxisSpacing,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _roleCard(
                                  context,
                                  index: 0,
                                  icon: Icons.security,
                                  title: 'Admin',
                                  subtitle: 'Full access to manage the system',
                                  accent: AppColors.primaryAccent,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AuthNavigationService.adminLoginRoute,
                                  ),
                                ),
                                _roleCard(
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
                                _roleCard(
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
    final isMobileScreen = screenWidth < 640;

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
          padding: EdgeInsets.all(
            isSmallScreen
                ? 16
                : isMobileScreen
                ? 20
                : 26,
          ),
          decoration: AppDecorations.surface(radius: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: isSmallScreen ? 28 : 34,
                backgroundColor: accent.withOpacity(0.15),
                child: Icon(icon, size: isSmallScreen ? 28 : 34, color: accent),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen
                      ? 18
                      : isMobileScreen
                      ? 20
                      : 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen
                      ? 12
                      : isMobileScreen
                      ? 14
                      : 15,
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
