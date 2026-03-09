// import 'dart:ui';
// import 'package:fabri_sync/auth/login/login_page.dart';
// import 'package:fabri_sync/utils/customcolors.dart';
// import 'package:flutter/material.dart';

// class SelectDepartmentScreen extends StatelessWidget {
//   const SelectDepartmentScreen({super.key});

//   static final List<Map<String, String>> departments = [
//     {"name": "Cutting", "icon": "assets/images/Cutting.jpeg"},
//     {"name": "Stitching", "icon": "assets/images/Stitching.jpeg"},
//     {"name": "Threading", "icon": "assets/images/Threading.jpeg"},
//     {"name": "Quality Control", "icon": "assets/images/Quality.jpeg"},
//     {"name": "Packaging", "icon": "assets/images/Packing.jpeg"},
//     {"name": "Dispatch", "icon": "assets/images/Inspection.jpeg"},
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final bool isWeb = MediaQuery.of(context).size.width > 600;

//     return Scaffold(
//       body: gradientOrderBackground(
//         child: SafeArea(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // 🔙 Top Bar
//               Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//                 child: Row(
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.arrow_back, color: Colors.white),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                     const SizedBox(width: 8),
//                     const Text(
//                       "SELECT YOUR DEPARTMENT",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.w600,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 16),

//               // 🧊 Frosted Cards
//               Expanded(
//                 child: Center(
//                   child: Container(
//                     width: isWeb ? 520 : double.infinity,
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: ListView.separated(
//                       itemCount: departments.length,
//                       separatorBuilder: (_, __) => const SizedBox(height: 16),
//                       itemBuilder: (context, index) {
//                         final department = departments[index];

//                         return _FrostedRoleCard(
//                           title: department["name"]!,
//                           iconPath: department["icon"]!,
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (_) => LoginPage()),
//                             );
//                           },
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// 🧊 Frosted Glass Card with Tap Effect
// class _FrostedRoleCard extends StatefulWidget {
//   final String title;
//   final String iconPath;
//   final VoidCallback onTap;

//   const _FrostedRoleCard({
//     required this.title,
//     required this.iconPath,
//     required this.onTap,
//   });

//   @override
//   State<_FrostedRoleCard> createState() => _FrostedRoleCardState();
// }

// class _FrostedRoleCardState extends State<_FrostedRoleCard> {
//   bool _pressed = false;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTapDown: (_) => setState(() => _pressed = true),
//       onTapUp: (_) {
//         setState(() => _pressed = false);
//         widget.onTap();
//       },
//       onTapCancel: () => setState(() => _pressed = false),
//       child: AnimatedScale(
//         scale: _pressed ? 0.97 : 1,
//         duration: const Duration(milliseconds: 120),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(18),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//             child: Container(
//               padding: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(
//                   0.18,
//                 ), // white mix synced with bg
//                 borderRadius: BorderRadius.circular(18),
//                 border: Border.all(color: Colors.white.withOpacity(0.25)),
//               ),
//               child: Row(
//                 children: [
//                   // 🖼 Image (untouched)
//                   Container(
//                     height: 48,
//                     width: 48,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(10),
//                       color: Colors.white.withOpacity(0.85),
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: Image.asset(widget.iconPath, fit: BoxFit.cover),
//                     ),
//                   ),

//                   const SizedBox(width: 16),

//                   // 📌 Text
//                   Expanded(
//                     child: Text(
//                       widget.title,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white, // synced, not cutting
//                       ),
//                     ),
//                   ),

//                   const Icon(
//                     Icons.arrow_forward_ios,
//                     size: 18,
//                     color: Colors.white70,
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
