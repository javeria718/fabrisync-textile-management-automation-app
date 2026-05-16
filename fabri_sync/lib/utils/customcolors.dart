// import 'package:flutter/material.dart';

// class AppColors {
//   static const Color appBackground = Color(0xFFF5F6FA);
//   static const Color appBackgroundSoft = Color(0xFFF8FAFC);
//   static const Color surface = Color(0xFFFFFFFF);
//   static const Color surfaceMuted = Color(0xFFF9FAFB);
//   static const Color border = Color(0xFFE5E7EB);
//   static const Color divider = Color(0xFFE5E7EB);

//   static const Color primaryText = Color(0xFF1F2937);
//   static const Color secondaryText = Color(0xFF6B7280);

//   static const Color primaryAccent = Color(0xFF7C4DFF);
//   static const Color accentBlue = Color(0xFF42A5F5);
//   static const Color accentPink = Color(0xFFFF6B9A);
//   static const Color accentGreen = Color(0xFF6FCF97);
//   static const Color accentYellow = Color(0xFFF2C94C);
//   static const Color accentOrange = Color(0xFFF2994A);

//   static const Color success = Color(0xFF27AE60);
//   static const Color warning = Color(0xFFF2994A);
//   static const Color error = Color(0xFFEB5757);
//   static const Color info = accentBlue;

//   static const Color shadow = Color(0x140F172A);

//   // Legacy aliases kept so existing code can migrate safely.
//   static const Color customAppThemeColor = primaryAccent;
//   static const Color customRedColor = error;
//   static const Color customBlueColor = primaryAccent;
//   static const Color customBgColor = appBackground;
// }

// class AppGradients {
//   static const adminAppBar = [Color(0xFFFFFFFF), Color(0xFFF8FAFC)];
//   static const adminAccent = [AppColors.primaryAccent, AppColors.accentBlue];
// }

// class AppShadows {
//   static const List<BoxShadow> card = [
//     BoxShadow(
//       color: AppColors.shadow,
//       blurRadius: 24,
//       offset: Offset(0, 10),
//     ),
//   ];

//   static const List<BoxShadow> subtle = [
//     BoxShadow(
//       color: AppColors.shadow,
//       blurRadius: 12,
//       offset: Offset(0, 4),
//     ),
//   ];
// }

// class AppDecorations {
//   static BoxDecoration surface({
//     double radius = 20,
//     Color color = AppColors.surface,
//     bool elevated = true,
//   }) {
//     return BoxDecoration(
//       color: color,
//       borderRadius: BorderRadius.circular(radius),
//       border: Border.all(color: AppColors.border),
//       boxShadow: elevated ? AppShadows.card : AppShadows.subtle,
//     );
//   }

//   static BoxDecoration softPanel({
//     double radius = 18,
//     Color color = AppColors.surfaceMuted,
//   }) {
//     return BoxDecoration(
//       color: color,
//       borderRadius: BorderRadius.circular(radius),
//       border: Border.all(color: AppColors.border),
//     );
//   }

//   static BoxDecoration accentFill(
//     Color color, {
//     double radius = 14,
//   }) {
//     return BoxDecoration(
//       color: color.withOpacity(0.14),
//       borderRadius: BorderRadius.circular(radius),
//       border: Border.all(color: color.withOpacity(0.22)),
//     );
//   }
// }

// class AppTextStyles {
//   static Shader gradientBlueShader = const LinearGradient(
//     colors: <Color>[
//       AppColors.primaryAccent,
//       AppColors.accentBlue,
//     ],
//   ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));

//   static const List<Shadow> textShadows = [];

//   static TextStyle titleStyleW = TextStyle(
//     fontSize: 38,
//     fontWeight: FontWeight.w700,
//     fontFamily: 'Poppins',
//     letterSpacing: 1.2,
//     color: AppColors.primaryText,
//   );

//   static TextStyle subtitleStyleW = const TextStyle(
//     fontSize: 15.5,
//     height: 1.5,
//     fontFamily: 'Poppins',
//     letterSpacing: 0.2,
//     color: AppColors.secondaryText,
//   );
// }

// class AppTheme {
//   static final ThemeData lightTheme = ThemeData(
//     useMaterial3: true,
//     fontFamily: 'Poppins',
//     scaffoldBackgroundColor: AppColors.appBackground,
//     colorScheme: ColorScheme.fromSeed(
//       seedColor: AppColors.primaryAccent,
//       primary: AppColors.primaryAccent,
//       secondary: AppColors.accentBlue,
//       surface: AppColors.surface,
//       error: AppColors.error,
//       brightness: Brightness.light,
//     ),
//     textTheme: const TextTheme(
//       bodyLarge: TextStyle(color: AppColors.primaryText),
//       bodyMedium: TextStyle(color: AppColors.primaryText),
//       bodySmall: TextStyle(color: AppColors.secondaryText),
//       titleLarge: TextStyle(color: AppColors.primaryText),
//       titleMedium: TextStyle(color: AppColors.primaryText),
//       titleSmall: TextStyle(color: AppColors.primaryText),
//     ),
//     appBarTheme: const AppBarTheme(
//       backgroundColor: AppColors.surface,
//       foregroundColor: AppColors.primaryText,
//       elevation: 0,
//       centerTitle: true,
//       scrolledUnderElevation: 0,
//       surfaceTintColor: Colors.transparent,
//       titleTextStyle: TextStyle(
//         fontFamily: 'Poppins',
//         fontSize: 20,
//         fontWeight: FontWeight.w700,
//         color: AppColors.primaryText,
//       ),
//       iconTheme: IconThemeData(color: AppColors.primaryText),
//     ),
//     cardTheme: const CardThemeData(
//       color: AppColors.surface,
//       surfaceTintColor: Colors.transparent,
//       elevation: 0,
//       margin: EdgeInsets.zero,
//     ),
//     dividerColor: AppColors.divider,
//     inputDecorationTheme: InputDecorationTheme(
//       filled: true,
//       fillColor: AppColors.surface,
//       hintStyle: const TextStyle(color: AppColors.secondaryText),
//       labelStyle: const TextStyle(color: AppColors.secondaryText),
//       floatingLabelStyle: const TextStyle(color: AppColors.primaryAccent),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(color: AppColors.border),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(color: AppColors.border),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(
//           color: AppColors.primaryAccent,
//           width: 1.2,
//         ),
//       ),
//       errorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(color: AppColors.error),
//       ),
//       focusedErrorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(color: AppColors.error),
//       ),
//     ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: AppColors.primaryAccent,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         shadowColor: Colors.transparent,
//         minimumSize: const Size(0, 46),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(14),
//         ),
//         textStyle: const TextStyle(
//           fontSize: 15,
//           fontWeight: FontWeight.w700,
//           fontFamily: 'Poppins',
//         ),
//       ),
//     ),
//     outlinedButtonTheme: OutlinedButtonThemeData(
//       style: OutlinedButton.styleFrom(
//         foregroundColor: AppColors.primaryText,
//         side: const BorderSide(color: AppColors.border),
//         backgroundColor: AppColors.surface,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(14),
//         ),
//         textStyle: const TextStyle(
//           fontSize: 15,
//           fontWeight: FontWeight.w600,
//           fontFamily: 'Poppins',
//         ),
//       ),
//     ),
//     textButtonTheme: TextButtonThemeData(
//       style: TextButton.styleFrom(
//         foregroundColor: AppColors.primaryAccent,
//         textStyle: const TextStyle(
//           fontSize: 13,
//           fontWeight: FontWeight.w600,
//           fontFamily: 'Poppins',
//         ),
//       ),
//     ),
//     snackBarTheme: SnackBarThemeData(
//       backgroundColor: AppColors.primaryText,
//       contentTextStyle: const TextStyle(color: Colors.white),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//       behavior: SnackBarBehavior.floating,
//     ),
//   );
// }

// Widget gradientOrderBackground({required Widget child}) {
//   return Container(
//     constraints: const BoxConstraints.expand(),
//     decoration: const BoxDecoration(
//       gradient: LinearGradient(
//         begin: Alignment.topCenter,
//         end: Alignment.bottomCenter,
//         colors: [AppColors.appBackgroundSoft, AppColors.appBackground],
//       ),
//     ),
//     child: child,
//   );
// }

//----------------------------------------------------------
// import 'package:flutter/material.dart';

// class AppColors {
//   // 🔥 UPDATED (cooler modern background)
//   static const Color appBackground = Color(0xFFF4F7FB);
//   static const Color appBackgroundSoft = Color(0xFFF8FAFD);

//   static const Color surface = Color(0xFFFFFFFF);
//   static const Color surfaceMuted = Color(0xFFF9FAFB);
//   static const Color border = Color(0xFFE5E7EB);
//   static const Color divider = Color(0xFFE5E7EB);

//   static const Color primaryText = Color(0xFF1F2937);
//   static const Color secondaryText = Color(0xFF6B7280);

//   static const Color primaryAccent = Color(0xFF7C4DFF);
//   static const Color accentBlue = Color(0xFF42A5F5);
//   static const Color accentPink = Color(0xFFFF6B9A);
//   static const Color accentGreen = Color(0xFF6FCF97);
//   static const Color accentYellow = Color(0xFFF2C94C);
//   static const Color accentOrange = Color(0xFFF2994A);

//   static const Color success = Color(0xFF27AE60);
//   static const Color warning = Color(0xFFF2994A);
//   static const Color error = Color(0xFFEB5757);
//   static const Color info = accentBlue;

//   // 🔥 UPDATED shadow (lighter + modern)
//   static const Color shadow = Color(0x1A0F172A);

//   // Legacy aliases
//   static const Color customAppThemeColor = primaryAccent;
//   static const Color customRedColor = error;
//   static const Color customBlueColor = primaryAccent;
//   static const Color customBgColor = appBackground;
// }

// class AppGradients {
//   static const adminAppBar = [Color(0xFFFFFFFF), Color(0xFFF8FAFC)];
//   static const adminAccent = [AppColors.primaryAccent, AppColors.accentBlue];
// }

// class AppShadows {
//   // 🔥 UPDATED (softer, less heavy)
//   static const List<BoxShadow> card = [
//     BoxShadow(
//       color: AppColors.shadow,
//       blurRadius: 18,
//       spreadRadius: -2,
//       offset: Offset(0, 10),
//     ),
//   ];

//   static const List<BoxShadow> subtle = [
//     BoxShadow(
//       color: AppColors.shadow,
//       blurRadius: 10,
//       spreadRadius: -2,
//       offset: Offset(0, 4),
//     ),
//   ];
// }

// class AppDecorations {
//   static BoxDecoration surface({
//     double radius = 20,
//     Color color = AppColors.surface,
//     bool elevated = true,
//   }) {
//     return BoxDecoration(
//       color: color,
//       borderRadius: BorderRadius.circular(radius),
//       border: Border.all(color: AppColors.border),
//       boxShadow: elevated ? AppShadows.card : AppShadows.subtle,
//     );
//   }

//   static BoxDecoration softPanel({
//     double radius = 18,
//     Color color = AppColors.surfaceMuted,
//   }) {
//     return BoxDecoration(
//       color: color,
//       borderRadius: BorderRadius.circular(radius),
//       border: Border.all(color: AppColors.border),
//     );
//   }

//   static BoxDecoration accentFill(Color color, {double radius = 14}) {
//     return BoxDecoration(
//       color: color.withOpacity(0.14),
//       borderRadius: BorderRadius.circular(radius),
//       border: Border.all(color: color.withOpacity(0.22)),
//     );
//   }
// }

// class AppTextStyles {
//   static Shader gradientBlueShader = const LinearGradient(
//     colors: <Color>[AppColors.primaryAccent, AppColors.accentBlue],
//   ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));

//   static const List<Shadow> textShadows = [];

//   static TextStyle titleStyleW = const TextStyle(
//     fontSize: 38,
//     fontWeight: FontWeight.w700,
//     fontFamily: 'Poppins',
//     letterSpacing: 1.2,
//     color: AppColors.primaryText,
//   );

//   static TextStyle subtitleStyleW = const TextStyle(
//     fontSize: 15.5,
//     height: 1.5,
//     fontFamily: 'Poppins',
//     letterSpacing: 0.2,
//     color: AppColors.secondaryText,
//   );
// }

// class AppTheme {
//   static final ThemeData lightTheme = ThemeData(
//     useMaterial3: true,
//     fontFamily: 'Poppins',

//     // 🔥 Keep base neutral (gradient handled separately)
//     scaffoldBackgroundColor: AppColors.appBackground,

//     colorScheme: ColorScheme.fromSeed(
//       seedColor: AppColors.primaryAccent,
//       primary: AppColors.primaryAccent,
//       secondary: AppColors.accentBlue,
//       surface: AppColors.surface,
//       error: AppColors.error,
//       brightness: Brightness.light,
//     ),

//     textTheme: const TextTheme(
//       bodyLarge: TextStyle(color: AppColors.primaryText),
//       bodyMedium: TextStyle(color: AppColors.primaryText),
//       bodySmall: TextStyle(color: AppColors.secondaryText),
//       titleLarge: TextStyle(color: AppColors.primaryText),
//       titleMedium: TextStyle(color: AppColors.primaryText),
//       titleSmall: TextStyle(color: AppColors.primaryText),
//     ),

//     appBarTheme: const AppBarTheme(
//       backgroundColor: AppColors.surface,
//       foregroundColor: AppColors.primaryText,
//       elevation: 0,
//       centerTitle: true,
//       scrolledUnderElevation: 0,
//       surfaceTintColor: Colors.transparent,
//       titleTextStyle: TextStyle(
//         fontFamily: 'Poppins',
//         fontSize: 20,
//         fontWeight: FontWeight.w700,
//         color: AppColors.primaryText,
//       ),
//       iconTheme: IconThemeData(color: AppColors.primaryText),
//     ),

//     cardTheme: const CardThemeData(
//       color: AppColors.surface,
//       surfaceTintColor: Colors.transparent,
//       elevation: 0,
//       margin: EdgeInsets.zero,
//     ),

//     dividerColor: AppColors.divider,

//     inputDecorationTheme: InputDecorationTheme(
//       filled: true,
//       fillColor: AppColors.surface,
//       hintStyle: const TextStyle(color: AppColors.secondaryText),
//       labelStyle: const TextStyle(color: AppColors.secondaryText),
//       floatingLabelStyle: const TextStyle(color: AppColors.primaryAccent),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(color: AppColors.border),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(color: AppColors.border),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(
//           color: AppColors.primaryAccent,
//           width: 1.2,
//         ),
//       ),
//       errorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(color: AppColors.error),
//       ),
//       focusedErrorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(color: AppColors.error),
//       ),
//     ),

//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: AppColors.primaryAccent,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         shadowColor: Colors.transparent,
//         minimumSize: const Size(0, 46),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//         textStyle: const TextStyle(
//           fontSize: 15,
//           fontWeight: FontWeight.w700,
//           fontFamily: 'Poppins',
//         ),
//       ),
//     ),

//     outlinedButtonTheme: OutlinedButtonThemeData(
//       style: OutlinedButton.styleFrom(
//         foregroundColor: AppColors.primaryText,
//         side: const BorderSide(color: AppColors.border),
//         backgroundColor: AppColors.surface,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//         textStyle: const TextStyle(
//           fontSize: 15,
//           fontWeight: FontWeight.w600,
//           fontFamily: 'Poppins',
//         ),
//       ),
//     ),

//     textButtonTheme: TextButtonThemeData(
//       style: TextButton.styleFrom(
//         foregroundColor: AppColors.primaryAccent,
//         textStyle: const TextStyle(
//           fontSize: 13,
//           fontWeight: FontWeight.w600,
//           fontFamily: 'Poppins',
//         ),
//       ),
//     ),

//     snackBarTheme: SnackBarThemeData(
//       backgroundColor: AppColors.primaryText,
//       contentTextStyle: const TextStyle(color: Colors.white),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//       behavior: SnackBarBehavior.floating,
//     ),
//   );
// }

// /// 🔥🔥 FULLY UPGRADED BACKGROUND WIDGET
// Widget gradientOrderBackground({required Widget child}) {
//   return Stack(
//     children: [
//       // 🌈 Modern layered gradient
//       Container(
//         constraints: const BoxConstraints.expand(),
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [Color(0xFFF8FAFD), Color(0xFFF1F5F9), Color(0xFFEFF3F8)],
//             stops: [0.0, 0.5, 1.0],
//           ),
//         ),
//       ),

//       // 💜 Subtle purple glow (top right)
//       Positioned(
//         top: -100,
//         right: -100,
//         child: Container(
//           width: 300,
//           height: 300,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: AppColors.primaryAccent.withOpacity(0.05),
//           ),
//         ),
//       ),

//       // 🔵 Subtle blue glow (bottom left)
//       Positioned(
//         bottom: -120,
//         left: -80,
//         child: Container(
//           width: 250,
//           height: 250,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: AppColors.accentBlue.withOpacity(0.04),
//           ),
//         ),
//       ),

//       child,
//     ],
//   );
// }
//------------------------------------------------------------
import 'dart:ui';

import 'package:flutter/material.dart';

class AppColors {
  // 🔥 NEW BACKGROUND (tinted, modern, not dull)
  static const Color appBackground = Color(0xFFF6F8FF);
  static const Color appBackgroundSoft = Color(0xFFF8FAFD);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF9FAFB);

  // 🔥 Slightly refined border (better contrast with new BG)
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);

  static const Color primaryText = Color(0xFF1F2937);
  static const Color secondaryText = Color(0xFF6B7280);

  static const Color primaryAccent = Color(0xFF7C4DFF);
  static const Color accentBlue = Color(0xFF42A5F5);
  static const Color accentPink = Color(0xFFFF6B9A);
  static const Color accentGreen = Color(0xFF6FCF97);
  static const Color accentYellow = Color(0xFFF2C94C);
  static const Color accentOrange = Color(0xFFF2994A);

  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF2994A);
  static const Color error = Color(0xFFEB5757);
  static const Color info = accentBlue;

  static const Color shadow = Color(0x1A0F172A);

  // Legacy aliases
  static const Color customAppThemeColor = primaryAccent;
  static const Color customRedColor = error;
  static const Color customBlueColor = primaryAccent;
  static const Color customBgColor = appBackground;
}

class AppGradients {
  static const adminAppBar = [Color(0xFFFFFFFF), Color(0xFFF8FAFC)];
  static const adminAccent = [AppColors.primaryAccent, AppColors.accentBlue];
}

class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 18,
      spreadRadius: -2,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 10,
      spreadRadius: -2,
      offset: Offset(0, 4),
    ),
  ];
}

class AppDecorations {
  static BoxDecoration surface({
    double radius = 20,
    Color color = AppColors.surface,
    bool elevated = true,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.border),
      boxShadow: elevated ? AppShadows.card : AppShadows.subtle,
    );
  }

  static BoxDecoration softPanel({
    double radius = 18,
    Color color = AppColors.surfaceMuted,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.border),
    );
  }

  static BoxDecoration accentFill(Color color, {double radius = 14}) {
    return BoxDecoration(
      color: color.withOpacity(0.14),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: color.withOpacity(0.22)),
    );
  }
}

// class AppTextStyles {
//   static Shader gradientBlueShader = const LinearGradient(
//     colors: <Color>[AppColors.primaryAccent, AppColors.accentBlue],
//   ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));

//   static const List<Shadow> textShadows = [];

//   static TextStyle titleStyleW = const TextStyle(
//     fontSize: 38,
//     fontWeight: FontWeight.w700,
//     fontFamily: 'Poppins',
//     letterSpacing: 1.2,
//     color: AppColors.primaryText,
//   );

//   static TextStyle subtitleStyleW = const TextStyle(
//     fontSize: 15.5,
//     height: 1.5,
//     fontFamily: 'Poppins',
//     letterSpacing: 0.2,
//     color: AppColors.secondaryText,
//   );
// }
class AppTextStyles {
  /// Premium enterprise gradient shader
  static Shader titleGradientShader = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryAccent, // Purple
      AppColors.accentBlue, // Blue touch
    ],
  ).createShader(const Rect.fromLTWH(0.0, 0.0, 250.0, 80.0));

  static const List<Shadow> textShadows = [
    Shadow(blurRadius: 18, color: Color(0x14000000), offset: Offset(0, 4)),
  ];

  /// MAIN APP TITLE STYLE (modern enterprise feel)
  static TextStyle titleStyleW = TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.w800,
    fontFamily: 'Poppins',
    letterSpacing: 0.6,

    // Premium purple shade instead of black
    color: const Color(0xFF6D4CFF),

    // subtle depth
    shadows: textShadows,
  );

  /// Optional gradient title style (for hero headings)
  static TextStyle gradientTitleStyle = TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.w800,
    fontFamily: 'Poppins',
    letterSpacing: 0.6,
    foreground: Paint()..shader = titleGradientShader,
    shadows: textShadows,
  );

  static TextStyle subtitleStyleW = const TextStyle(
    fontSize: 15.5,
    height: 1.5,
    fontFamily: 'Poppins',
    letterSpacing: 0.2,
    color: AppColors.secondaryText,
  );
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: AppColors.appBackground,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryAccent,
      primary: AppColors.primaryAccent,
      secondary: AppColors.accentBlue,
      surface: AppColors.surface,
      error: AppColors.error,
      brightness: Brightness.light,
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.primaryText),
      bodyMedium: TextStyle(color: AppColors.primaryText),
      bodySmall: TextStyle(color: AppColors.secondaryText),
      titleLarge: TextStyle(color: AppColors.primaryText),
      titleMedium: TextStyle(color: AppColors.primaryText),
      titleSmall: TextStyle(color: AppColors.primaryText),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.primaryText,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryText,
      ),
      iconTheme: IconThemeData(color: AppColors.primaryText),
    ),

    cardTheme: const CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),

    dividerColor: AppColors.divider,

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.secondaryText),
      labelStyle: const TextStyle(color: AppColors.secondaryText),
      floatingLabelStyle: const TextStyle(color: AppColors.primaryAccent),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primaryAccent,
          width: 1.2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
        ),
      ),
    ),
  );
}

/// 🔥 FINAL BACKGROUND (PROMINENT + BEAUTIFUL + MODERN)
Widget gradientOrderBackground({required Widget child}) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFDFEFF), // almost white (top)
          Color(0xFFF5F7FF), // soft bluish
          Color(0xFFEEF3FF), // gentle tint
        ],
        stops: [0.0, 0.5, 1.0],
      ),
    ),

    child: Stack(
      children: [
        // 💜 Very subtle top highlight (NO blur)
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: Color(0xFF7C4DFF).withOpacity(0.06),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // 🔵 Bottom soft tint
        Positioned(
          bottom: -100,
          left: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Color(0xFF42A5F5).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
          ),
        ),

        child,
      ],
    ),
  );
}
