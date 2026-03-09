// import 'dart:ui';

// import 'package:fabri_sync/auth/login/login_page.dart';

// import 'package:fabri_sync/utils/customcolors.dart';
// import 'package:flutter/material.dart';

// class SelectRoleScreen extends StatefulWidget {
//   const SelectRoleScreen({super.key});

//   @override
//   State<SelectRoleScreen> createState() => _SelectRoleScreenState();
// }

// class _SelectRoleScreenState extends State<SelectRoleScreen> {
//   int? pressedIndex;
//   @override
//   Widget build(BuildContext context) {
//     final double screenWidth = MediaQuery.of(context).size.width;

//     double cardWidth = screenWidth < 600
//         ? screenWidth * 0.85
//         : screenWidth * 0.45;

//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.transparent,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         centerTitle: true,
//         title: const Text(
//           "SELECT YOUR ROLE",
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             letterSpacing: 0.6,
//           ),
//         ),
//       ),

//       /// 🌌 SAME GRADIENT BACKGROUND AS PREVIOUS SCREENS
//       body: gradientOrderBackground(
//         child: Center(
//           child: Wrap(
//             spacing: 40,
//             runSpacing: 40,
//             alignment: WrapAlignment.center,
//             children: [
//               _glassRoleCard(
//                 context,
//                 index: 0,
//                 width: cardWidth,
//                 icon: Icons.security,
//                 title: "Admin",
//                 subtitle: "Full access to manage the system",
//                 onTap: () => Navigator.push(
//   context,
//   MaterialPageRoute(builder: (_) => const LoginPage(expectedRole: 'admin')),
// ),

//               ),

//               _glassRoleCard(
//                 context,
//                 index: 1,
//                 width: cardWidth,
//                 icon: Icons.work,
//                 title: "Manager",
//                 subtitle: "Manage department workflows",
//               onTap: () => Navigator.push(
//   context,
//   MaterialPageRoute(builder: (_) => const LoginPage(expectedRole: 'manager')),
// ),

//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// 🧊 FROSTED GLASS ROLE CARD
//   Widget _glassRoleCard(
//     BuildContext context, {
//     required int index,
//     required double width,
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required VoidCallback onTap,
//   }) {
//     final bool isPressed = pressedIndex == index;

//     return GestureDetector(
//       onTapDown: (_) {
//         setState(() => pressedIndex = index);
//       },
//       onTapUp: (_) async {
//         setState(() => pressedIndex = null);
//         await Future.delayed(const Duration(milliseconds: 90));
//         onTap();
//       },
//       onTapCancel: () {
//         setState(() => pressedIndex = null);
//       },
//       child: AnimatedScale(
//         scale: isPressed ? 0.97 : 1.0,
//         duration: const Duration(milliseconds: 150),
//         curve: Curves.easeOut,
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(24),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 150),
//               width: width,
//               padding: const EdgeInsets.all(26),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.12),
//                 borderRadius: BorderRadius.circular(24),
//                 border: Border.all(color: Colors.white.withOpacity(0.25)),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(isPressed ? 0.55 : 0.35),
//                     blurRadius: isPressed ? 36 : 28,
//                     offset: const Offset(0, 18),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   CircleAvatar(
//                     radius: 34,
//                     backgroundColor: Colors.white.withOpacity(0.2),
//                     child: Icon(icon, size: 34, color: Colors.white),
//                   ),
//                   const SizedBox(height: 18),
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     subtitle,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 15,
//                       color: Colors.white.withOpacity(0.75),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:ui';
import 'package:fabri_sync/auth/login/login_page.dart';
import 'package:fabri_sync/onboarding/welcome.dart';
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

    double cardWidth = screenWidth < 600
        ? screenWidth * 0.85
        : screenWidth * 0.45;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
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
            color: Colors.white,
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
              _glassRoleCard(
                context,
                index: 0,
                width: cardWidth,
                icon: Icons.security,
                title: "Admin",
                subtitle: "Full access to manage the system",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(expectedRole: 'admin'),
                  ),
                ),
              ),
              _glassRoleCard(
                context,
                index: 1,
                width: cardWidth,
                icon: Icons.work,
                title: "Manager",
                subtitle: "Manage department workflows",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(expectedRole: 'manager'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassRoleCard(
    BuildContext context, {
    required int index,
    required double width,
    required IconData icon,
    required String title,
    required String subtitle,
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: width,
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isPressed ? 0.55 : 0.35),
                    blurRadius: isPressed ? 36 : 28,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Icon(icon, size: 34, color: Colors.white),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
