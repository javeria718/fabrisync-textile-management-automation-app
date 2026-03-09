import 'package:flutter/material.dart';

class AppColors {
  static const Color customAppThemeColor = Color(0xFFd87089);
  static const Color customRedColor = Color.fromARGB(202, 236, 7, 7);
  static const Color customBlueColor = Color(0xFF0A4DAB);
  static const Color customBgColor = Color(0xFFF2F4F7);
}

class AppGradients {
  static const adminAppBar = [Color(0xFF0F172A), Color(0xFF111827)];
  static const adminAccent = [Color(0xFF0EA5E9), Color(0xFF2563EB)];
}

class AppTextStyles {
  // -------------------------------
  // Gradient shader for primary title
  // -------------------------------
  static Shader gradientBlueShader = const LinearGradient(
    colors: <Color>[
      Color.fromARGB(255, 139, 169, 224), // lighter blue
      Color(0xFF2A5298), // rich deep blue
    ],
  ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));

  // -------------------------------
  // Title Shadows
  // -------------------------------
  static const List<Shadow> textShadows = [
    Shadow(offset: Offset(2, 2), blurRadius: 3, color: Colors.black26),
    Shadow(offset: Offset(-1, -1), blurRadius: 2, color: Colors.white24),
  ];

  // -------------------------------
  // Main Title TextStyle (FabriSync)
  // -------------------------------
  // static TextStyle titleStyle = TextStyle(
  //   fontSize: 36,
  //   fontWeight: FontWeight.bold,
  //   fontFamily: 'Poppins',
  //   letterSpacing: 1.5,
  //   foreground: Paint()..shader = gradientBlueShader,
  //   shadows: textShadows,
  // );

  // // -------------------------------
  // // Subtitle TextStyle (Responsive suggestion)
  // // -------------------------------
  // static TextStyle subtitleStyle = TextStyle(
  //   fontSize: 15,
  //   height: 1.4,
  //   fontFamily: 'Poppins',
  //   color: Colors.grey.shade700,
  //   letterSpacing: 0.5,
  // );
  // -------------------------------
  // Title TextStyle – Premium Gradient
  // -------------------------------
  static TextStyle titleStyleW = TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.w700,
    fontFamily: 'Poppins',
    letterSpacing: 1.6,
    foreground: Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF7DD3FC), // light cyan
          Color(0xFF38BDF8), // sky blue
          Color(0xFF818CF8), // soft indigo
        ],
      ).createShader(const Rect.fromLTWH(0, 0, 300, 80)),
    shadows: const [
      Shadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 4)),
    ],
  );

  // -------------------------------
  // Subtitle TextStyle – Soft Elegant Contrast
  // -------------------------------
  static TextStyle subtitleStyleW = TextStyle(
    fontSize: 15.5,
    height: 1.5,
    fontFamily: 'Poppins',
    letterSpacing: 0.4,
    color: Colors.white.withOpacity(0.75),
  );
}

// Widget gradientBackground({required Widget child}) {
//   return Container(
//     decoration: const BoxDecoration(
//       gradient: LinearGradient(
//         colors: [Color(0xFF0A2E6F), Color(0xFF1E5AA8), Color(0xFF4C8ED9)],
//         begin: Alignment.topCenter,
//         end: Alignment.bottomCenter,
//       ),
//     ),
//     child: child,
//   );
// }

// Widget gradientOrderBackground({required Widget child}) {
//   // const blue = Color(0xFF0A4DAB);

//   return Container(
//     decoration: BoxDecoration(
//       gradient: LinearGradient(
//         begin: Alignment.topCenter,
//         end: Alignment.bottomCenter,
//         colors: [Color(0xFF0F172A), Color(0xFF111827)],
//       ),
//       // gradient: LinearGradient(
//       //   begin: Alignment.topLeft,
//       //   end: Alignment.bottomRight,
//       //   colors: [
//       //     const Color(0xFF0B1220),
//       //     blue.withOpacity(0.22),
//       //     const Color(0xFF0B1220),
//       //   ],
//       // ),
//     ),
//     child: child,
//   );
// }
Widget gradientOrderBackground({required Widget child}) {
  return Container(
    // ✅ ensures gradient fills whole screen even if child is small
    constraints: const BoxConstraints.expand(),
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
