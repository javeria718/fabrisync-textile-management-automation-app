// import 'dart:ui';

// import 'package:fabri_sync/Model/datamodel.dart';
// import 'package:fabri_sync/Model/orderModel.dart';
// import 'package:fabri_sync/auth/login/login_page.dart';
// import 'package:fabri_sync/utils/customcolors.dart';
// import 'package:fabri_sync/view/dashboards/estimated_time_allorders.dart';
// import 'package:fabri_sync/view/dashboards/tables/admin_table.dart';
// import 'package:fabri_sync/view/newOrder/orderInput.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class AdminDashboardScreen extends StatefulWidget {
//   const AdminDashboardScreen({super.key});

//   @override
//   State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
// }

// class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
//   bool _showProfileCard = false;
//   Map<String, dynamic>? profile;

//   final supabase = Supabase.instance.client;

//   List<OrderModel> allOrders = [];
//   bool loading = true;

//   Map<String, double> estimatedDeptHours = {};
//   bool loadingDeptHours = true;

//   late RealtimeChannel deptOrdersChannel;
//   late RealtimeChannel ordersMainChannel;
//   RealtimeChannel? timeConfigChannel;

//   // ✅ optional: a single scroll controller (web feels smoother)
//   final ScrollController _scrollController = ScrollController();

//   @override
//   void initState() {
//     super.initState();
//     fetchOrders();
//     fetchEstimatedDeptHours();
//     setupRealtime();
//     setupTimeConfigRealtime();
//     _loadAdminProfile();
//   }

//   Future<void> _loadAdminProfile() async {
//     final user = supabase.auth.currentUser;
//     if (user == null) return;

//     try {
//       final res = await supabase
//           .from('profiles')
//           .select()
//           .eq('id', user.id)
//           .single();

//       if (!mounted) return;
//       setState(() => profile = res);
//     } catch (e) {
//       debugPrint("Admin profile load error: $e");
//     }
//   }

//   Future<void> fetchOrders() async {
//     setState(() => loading = true);

//     final data = await supabase
//         .from('ordersmain')
//         .select()
//         .order('created_at', ascending: false);

//     if (!mounted) return;

//     setState(() {
//       allOrders = (data as List).map((e) => OrderModel.fromMap(e)).toList();
//       loading = false;
//     });
//   }

//   Future<void> fetchEstimatedDeptHours() async {
//     setState(() => loadingDeptHours = true);

//     try {
//       final data = await supabase
//           .from('master_time_config')
//           .select('department, estimated_hours')
//           .order('department');

//       final Map<String, double> map = {};
//       for (final row in (data as List)) {
//         final dept = (row['department'] ?? '').toString();
//         final hrs = (row['estimated_hours'] as num?)?.toDouble() ?? 0.0;
//         if (dept.isNotEmpty) map[dept] = hrs;
//       }

//       if (!mounted) return;
//       setState(() {
//         estimatedDeptHours = map;
//         loadingDeptHours = false;
//       });
//     } catch (e) {
//       debugPrint("fetchEstimatedDeptHours error: $e");
//       if (!mounted) return;
//       setState(() => loadingDeptHours = false);
//     }
//   }

//   void setupRealtime() {
//     deptOrdersChannel = supabase
//         .channel('admin-dept-orders')
//         .onPostgresChanges(
//           event: PostgresChangeEvent.all,
//           schema: 'public',
//           table: 'department_orders',
//           callback: (_) => fetchOrders(),
//         )
//         .subscribe();

//     ordersMainChannel = supabase
//         .channel('admin-ordersmain')
//         .onPostgresChanges(
//           event: PostgresChangeEvent.all,
//           schema: 'public',
//           table: 'ordersmain',
//           callback: (_) => fetchOrders(),
//         )
//         .subscribe();
//   }

//   void setupTimeConfigRealtime() {
//     timeConfigChannel = supabase
//         .channel('admin-time-config')
//         .onPostgresChanges(
//           event: PostgresChangeEvent.all,
//           schema: 'public',
//           table: 'master_time_config',
//           callback: (_) => fetchEstimatedDeptHours(),
//         )
//         .subscribe();
//   }

//   @override
//   void dispose() {
//     supabase.removeChannel(deptOrdersChannel);
//     supabase.removeChannel(ordersMainChannel);
//     if (timeConfigChannel != null) supabase.removeChannel(timeConfigChannel!);
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final w = constraints.maxWidth;

//         // ✅ more reliable breakpoints (mobile / tablet / desktop / wide)
//         final isMobile = w < 600;
//         final isTablet = w >= 600 && w < 1024;
//         final isDesktop = w >= 1024;
//         final isWide = w >= 1400;

//         // ✅ responsive page padding
//         final horizontalPad = isWide
//             ? 48.0
//             : isDesktop
//             ? 32.0
//             : isTablet
//             ? 22.0
//             : 14.0;

//         final verticalPad = isDesktop ? 24.0 : 16.0;

//         // ✅ responsive max width (prevents "mobile look" on web)
//         final maxContentWidth = isWide
//             ? 1320.0
//             : isDesktop
//             ? 1180.0
//             : double.infinity;

//         final inProgress = allOrders
//             .where((o) => o.status.toLowerCase() == 'inprogress')
//             .length;

//         final pending = allOrders
//             .where(
//               (o) =>
//                   o.status.toLowerCase() == 'pending' ||
//                   o.status.toLowerCase() == 'delayed',
//             )
//             .length;

//         final completed = allOrders
//             .where((o) => o.status.toLowerCase() == 'completed')
//             .length;

//         // ✅ profile overlay width responsive
//         final profileCardWidth = (w * 0.33).clamp(260.0, 340.0);

//         return Scaffold(
//           backgroundColor: const Color(0xFF0F172A),
//           appBar: _buildAppBar(context),
//           body: loading
//               ? const Center(
//                   child: CircularProgressIndicator(color: Colors.white),
//                 )
//               : Stack(
//                   children: [
//                     // ✅ Background fills ALL screen (no white gaps on zoom)
//                     Positioned.fill(
//                       child: gradientOrderBackground(
//                         child: const SizedBox.expand(),
//                       ),
//                     ),

//                     // ✅ Main content (fills height; smooth on web)
//                     Positioned.fill(
//                       child: SafeArea(
//                         child: Center(
//                           child: ConstrainedBox(
//                             constraints: BoxConstraints(
//                               maxWidth: maxContentWidth,
//                             ),
//                             child: ScrollConfiguration(
//                               behavior: const _NoGlowScrollBehavior(),
//                               child: ListView(
//                                 controller: _scrollController,
//                                 padding: EdgeInsets.symmetric(
//                                   horizontal: horizontalPad,
//                                   vertical: verticalPad,
//                                 ),
//                                 children: [
//                                   _kpiSectionResponsive(
//                                     isMobile: isMobile,
//                                     isTablet: isTablet,
//                                     isDesktop: isDesktop,
//                                     inProgress: inProgress,
//                                     pending: pending,
//                                     completed: completed,
//                                   ),
//                                   const SizedBox(height: 22),

//                                   _departmentProgressSectionResponsive(
//                                     isMobile,
//                                   ),
//                                   const SizedBox(height: 22),

//                                   loadingDeptHours
//                                       ? const Center(
//                                           child: CircularProgressIndicator(
//                                             color: Colors.white,
//                                           ),
//                                         )
//                                       : _estimatedTimeSection(
//                                           estimatedDeptHours,
//                                           allOrders,
//                                         ),
//                                   const SizedBox(height: 22),

//                                   _queueAndEfficiencySection(
//                                     context,
//                                     isDesktop,
//                                   ),
//                                   const SizedBox(height: 12),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),

//                     // ✅ PROFILE CARD OVERLAY
//                     if (_showProfileCard)
//                       Positioned(
//                         top: kToolbarHeight + 10,
//                         right: 16,
//                         child: Material(
//                           color: Colors.transparent,
//                           child: _glassOverlayCard(
//                             width: profileCardWidth,
//                             child: profile == null
//                                 ? const Padding(
//                                     padding: EdgeInsets.all(8),
//                                     child: Text(
//                                       "Loading profile...",
//                                       style: TextStyle(color: Colors.white70),
//                                     ),
//                                   )
//                                 : Column(
//                                     mainAxisSize: MainAxisSize.min,
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       _profileRow(
//                                         Icons.person,
//                                         (profile!['full_name'] ?? '')
//                                             .toString(),
//                                       ),
//                                       const SizedBox(height: 10),
//                                       _profileRow(
//                                         Icons.email,
//                                         (profile!['email'] ?? '').toString(),
//                                       ),
//                                       const SizedBox(height: 10),
//                                       _profileRow(
//                                         Icons.phone,
//                                         (profile!['phone_number'] ?? '')
//                                             .toString(),
//                                       ),
//                                       const SizedBox(height: 14),
//                                       Divider(
//                                         color: Colors.white.withOpacity(0.14),
//                                       ),
//                                       const SizedBox(height: 12),
//                                       GestureDetector(
//                                         onTap: () async {
//                                           await supabase.auth.signOut();
//                                           if (!mounted) return;
//                                           Navigator.of(
//                                             context,
//                                           ).pushReplacementNamed('/login');
//                                         },
//                                         child: Container(
//                                           width: double.infinity,
//                                           padding: const EdgeInsets.symmetric(
//                                             vertical: 10,
//                                           ),
//                                           alignment: Alignment.center,
//                                           decoration: BoxDecoration(
//                                             color: Colors.redAccent.withOpacity(
//                                               0.95,
//                                             ),
//                                             borderRadius: BorderRadius.circular(
//                                               12,
//                                             ),
//                                           ),
//                                           child: const Text(
//                                             "Logout",
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//         );
//       },
//     );
//   }

//   // ================= APP BAR =================
//   AppBar _buildAppBar(BuildContext context) {
//     return AppBar(
//       elevation: 0,
//       centerTitle: true,
//       backgroundColor: Colors.transparent,
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
//         onPressed: () {
//           Navigator.of(context).pushAndRemoveUntil(
//             MaterialPageRoute(
//               builder: (_) => const LoginPage(expectedRole: ''),
//             ),
//             (route) => false,
//           );
//         },
//       ),
//       title: const Text(
//         'Admin Dashboard',
//         style: TextStyle(
//           fontSize: 20,
//           fontWeight: FontWeight.w600,
//           color: Colors.white,
//         ),
//       ),
//       flexibleSpace: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFF0F172A), Color(0xFF111827)],
//           ),
//         ),
//       ),
//       actions: [
//         IconButton(
//           tooltip: "Create New Order",
//           icon: const Icon(Icons.add_circle_outline, color: Colors.white),
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => const OrderInputScreen()),
//             );
//           },
//         ),
//         GestureDetector(
//           onTap: () => setState(() => _showProfileCard = !_showProfileCard),
//           child: const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 12),
//             child: Icon(Icons.account_circle, size: 32, color: Colors.white),
//           ),
//         ),
//         const SizedBox(width: 12),
//       ],
//     );
//   }

//   // ================= KPI (FULLY RESPONSIVE) =================
//   // ================= KPI (NO OVERFLOW ON WEB ZOOM) =================
//   Widget _kpiSectionResponsive({
//     required bool isMobile,
//     required bool isTablet,
//     required bool isDesktop,
//     required int inProgress,
//     required int pending,
//     required int completed,
//   }) {
//     final cards = [
//       _kpiCard(
//         title: 'In Progress',
//         value: inProgress.toString(),
//         icon: Icons.autorenew_rounded,
//         color: Colors.orange,
//       ),
//       _kpiCard(
//         title: 'Pending',
//         value: pending.toString(),
//         icon: Icons.warning_amber,
//         color: Colors.red,
//       ),
//       _kpiCard(
//         title: 'Completed',
//         value: completed.toString(),
//         icon: Icons.check_circle_outline,
//         color: Colors.green,
//       ),
//     ];

//     // ✅ Desktop/Web: grid, but enforce a minimum card height via childAspectRatio + mainAxisExtent
//     if (isDesktop) {
//       return LayoutBuilder(
//         builder: (context, c) {
//           // Keep cards tall enough even when zoom changes constraints
//           final double minCardHeight = 120; // prevents 80-90px height cases
//           final double spacing = 20;

//           return GridView.builder(
//             itemCount: cards.length,
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3,
//               crossAxisSpacing: spacing,
//               mainAxisSpacing: spacing,
//               mainAxisExtent: minCardHeight, // ✅ key fix: locks height
//             ),
//             itemBuilder: (_, i) => cards[i],
//           );
//         },
//       );
//     }

//     // ✅ Tablet: 2 columns grid with safe height
//     if (isTablet) {
//       return GridView.builder(
//         itemCount: cards.length,
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           crossAxisSpacing: 16,
//           mainAxisSpacing: 16,
//           mainAxisExtent: 120, // ✅ safe height
//         ),
//         itemBuilder: (_, i) => cards[i],
//       );
//     }

//     // ✅ Mobile: horizontal scroll (already safe)
//     return LayoutBuilder(
//       builder: (context, c) {
//         final cardW = (c.maxWidth * 0.78).clamp(220.0, 320.0);

//         return SizedBox(
//           height: 140,
//           child: ListView.separated(
//             scrollDirection: Axis.horizontal,
//             itemCount: cards.length,
//             separatorBuilder: (_, __) => const SizedBox(width: 16),
//             itemBuilder: (_, i) => SizedBox(width: cardW, child: cards[i]),
//           ),
//         );
//       },
//     );
//   }

//   Widget _kpiCard({
//     required String title,
//     required String value,
//     required IconData icon,
//     required Color color,
//   }) {
//     return LayoutBuilder(
//       builder: (context, c) {
//         // ✅ scale typography based on available height (important for web zoom)
//         final h = c.maxHeight;
//         final valueFont = h < 110 ? 22.0 : 28.0;
//         final titleFont = h < 110 ? 12.0 : 14.0;
//         final iconSize = h < 110 ? 26.0 : 30.0;

//         return Container(
//           padding: const EdgeInsets.all(16),
//           decoration: _glassCard(),
//           child: Column(
//             // ✅ no Spacer() so it never overflows
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Icon(icon, color: color, size: iconSize),

//               // ✅ Big number auto-shrinks if needed
//               FittedBox(
//                 fit: BoxFit.scaleDown,
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   value,
//                   style: TextStyle(
//                     fontSize: valueFont,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                     height: 1.0,
//                   ),
//                 ),
//               ),

//               Text(
//                 title,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                   fontSize: titleFont,
//                   color: Colors.white.withOpacity(0.7),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // ================= PROFILE OVERLAY HELPERS =================
//   Widget _glassOverlayCard({required double width, required Widget child}) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(16),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
//         child: Container(
//           width: width,
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.07),
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: Colors.white.withOpacity(0.12)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.28),
//                 blurRadius: 18,
//                 offset: const Offset(0, 10),
//               ),
//             ],
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }

//   Widget _profileRow(IconData icon, String text) {
//     return Row(
//       children: [
//         Icon(icon, size: 18, color: Colors.white),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             text.isEmpty ? "-" : text,
//             style: const TextStyle(fontSize: 15, color: Colors.white),
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     );
//   }

//   // ================= DEPARTMENT PROGRESS (RESPONSIVE LABEL WIDTH) =================
//   Widget _departmentProgressSectionResponsive(bool isMobile) {
//     final activeOrders = allOrders
//         .where((o) => o.status.toLowerCase() != "completed")
//         .toList();

//     final Map<String, int> countByDept = {};
//     for (final dept in Department.values) {
//       final dbDept = _deptDbName(dept);
//       countByDept[dbDept] = activeOrders
//           .where((o) => o.currentDepartment.toUpperCase() == dbDept)
//           .length;
//     }

//     int maxCount = 0;
//     for (final c in countByDept.values) {
//       if (c > maxCount) maxCount = c;
//     }

//     return _cardWrapper(
//       title: 'Department Progress Overview',
//       child: Column(
//         children: Department.values.map((dept) {
//           final dbDept = _deptDbName(dept);
//           final count = countByDept[dbDept] ?? 0;
//           final progress = maxCount == 0 ? 0.0 : (count / maxCount);

//           return Padding(
//             padding: const EdgeInsets.symmetric(vertical: 10),
//             child: Row(
//               children: [
//                 // ✅ label flexes on small screens instead of fixed 120
//                 SizedBox(
//                   width: isMobile ? 92 : 140,
//                   child: Text(
//                     dbDept,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w600,
//                       color: Colors.white,
//                       letterSpacing: 0.6,
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(10),
//                     child: LinearProgressIndicator(
//                       value: progress,
//                       minHeight: 10,
//                       backgroundColor: Colors.white.withOpacity(0.15),
//                       color: _progressColor(progress),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Text(
//                   "$count",
//                   style: TextStyle(color: Colors.white.withOpacity(0.8)),
//                 ),
//               ],
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   Color _progressColor(double value) {
//     if (value >= 0.8) return Colors.greenAccent;
//     if (value >= 0.4) return Colors.orangeAccent;
//     return Colors.redAccent;
//   }

//   String _deptDbName(Department dept) => dept.name.toUpperCase();

//   // ================= ESTIMATED TIME PER DEPARTMENT (UNCHANGED LOGIC) =================
//   Widget _estimatedTimeSection(
//     Map<String, double> perUnitDeptHours,
//     List<OrderModel> orders,
//   ) {
//     final OrderModel? latestOrder = orders.isNotEmpty ? orders.first : null;

//     if (latestOrder == null) {
//       return _cardWrapper(
//         title: 'Estimated Remaining Time (By Department)',
//         child: const Text(
//           "No orders available",
//           style: TextStyle(color: Colors.white70),
//         ),
//       );
//     }

//     const orderedDepts = [
//       'CUTTING',
//       'STITCHING',
//       'THREADING',
//       'QUALITY_CONTROL',
//       'PACKING',
//       'INSPECTION',
//     ];

//     String norm(String d) => d.trim().toUpperCase().replaceAll(' ', '_');

//     final normalizedPerUnit = <String, double>{};
//     perUnitDeptHours.forEach((dept, hrs) {
//       normalizedPerUnit[norm(dept)] = hrs;
//     });

//     final calculated = <String, double>{};
//     for (final dept in orderedDepts) {
//       final perUnit = normalizedPerUnit[dept] ?? 0.0;
//       calculated[dept] = perUnit * latestOrder.quantity;
//     }

//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: _glassCard(),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           LayoutBuilder(
//             builder: (context, c) {
//               final isNarrow = c.maxWidth < 520;

//               if (isNarrow) {
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Estimated Remaining Time (By Department)',
//                       style: TextStyle(
//                         fontSize: 17,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Align(
//                       alignment: Alignment.centerLeft,
//                       child: TextButton(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => EstimatedTimeAllOrdersScreen(
//                                 allOrders: orders,
//                                 perUnitDeptHours: perUnitDeptHours,
//                                 formatToDaysHours: formatToDaysHours,
//                                 glassCard: _glassCard(),
//                               ),
//                             ),
//                           );
//                         },
//                         child: const Text(
//                           'View All Orders',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ),
//                     ),
//                   ],
//                 );
//               }

//               return Row(
//                 children: [
//                   const Expanded(
//                     child: Text(
//                       'Estimated Remaining Time (By Department)',
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         fontSize: 17,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                   TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => EstimatedTimeAllOrdersScreen(
//                             allOrders: orders,
//                             perUnitDeptHours: perUnitDeptHours,
//                             formatToDaysHours: formatToDaysHours,
//                             glassCard: _glassCard(),
//                           ),
//                         ),
//                       );
//                     },
//                     child: const Text(
//                       'View All Orders',
//                       style: TextStyle(
//                         color: Colors.white,
//                         decoration: TextDecoration.underline,
//                         decorationColor: Colors.white,
//                         decorationThickness: 2,
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//           const SizedBox(height: 6),
//           Text(
//             "Order: ${latestOrder.orderId}  •  Qty: ${latestOrder.quantity}",
//             style: TextStyle(color: Colors.white.withOpacity(0.75)),
//           ),
//           const SizedBox(height: 16),
//           Column(
//             children: orderedDepts.map((dept) {
//               final hrs = calculated[dept] ?? 0.0;
//               return Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 6),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Flexible(
//                       child: Text(
//                         dept,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w500,
//                           letterSpacing: 0.6,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Text(
//                       formatToDaysHours(hrs),
//                       style: TextStyle(color: Colors.white.withOpacity(0.8)),
//                     ),
//                   ],
//                 ),
//               );
//             }).toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   String formatToDaysHours(double hours) {
//     final days = hours ~/ 24;
//     final remainingHours = (hours % 24).round();

//     if (days > 0) {
//       return '$days day${days > 1 ? 's' : ''} $remainingHours hrs';
//     }
//     return '$remainingHours hrs';
//   }

//   // ================= QUEUE + EFFICIENCY =================
//   Widget _queueAndEfficiencySection(BuildContext context, bool isDesktop) {
//     return isDesktop
//         ? Row(
//             children: [
//               Expanded(child: _orderQueue(context)),
//               const SizedBox(width: 20),
//               Expanded(child: _efficiencyPanel()),
//             ],
//           )
//         : Column(
//             children: [
//               _orderQueue(context),
//               const SizedBox(height: 20),
//               _efficiencyPanel(),
//             ],
//           );
//   }

//   Widget _orderQueue(BuildContext context) {
//     final preview = allOrders.take(4).toList();

//     return _cardWrapper(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Expanded(
//                 child: Text(
//                   'Order Queue Overview',
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) =>
//                           TableScreen(department: Department.cutting),
//                     ),
//                   );
//                 },
//                 child: const Text(
//                   'View Full',
//                   style: TextStyle(
//                     color: Colors.white,
//                     decoration: TextDecoration.underline,
//                     decorationColor: Colors.white,
//                     decorationThickness: 2,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 14),

//           // ✅ if super narrow, stack headers
//           LayoutBuilder(
//             builder: (context, c) {
//               final narrow = c.maxWidth < 420;
//               if (narrow) {
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Order ID',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.6),
//                         fontSize: 12,
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       'Department',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.6),
//                         fontSize: 12,
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       'Status',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.6),
//                         fontSize: 12,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     const Divider(color: Colors.white24),
//                     ...preview.map(
//                       (o) => Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 8),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               o.orderId,
//                               style: const TextStyle(color: Colors.white),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               o.currentDepartment,
//                               style: TextStyle(
//                                 color: Colors.white.withOpacity(0.75),
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               o.status,
//                               style: TextStyle(
//                                 color: Colors.white.withOpacity(0.75),
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             const Divider(color: Colors.white12),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 );
//               }

//               return Column(
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           'Order ID',
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(0.6),
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),
//                       Expanded(
//                         child: Text(
//                           'Department',
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(0.6),
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),
//                       Expanded(
//                         child: Text(
//                           'Status',
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(0.6),
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   const Divider(color: Colors.white24),
//                   ...preview.map(
//                     (o) => Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 6),
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               o.orderId,
//                               style: const TextStyle(color: Colors.white),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           Expanded(
//                             child: Text(
//                               o.currentDepartment,
//                               style: TextStyle(
//                                 color: Colors.white.withOpacity(0.75),
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           Expanded(
//                             child: Text(
//                               o.status,
//                               style: TextStyle(
//                                 color: Colors.white.withOpacity(0.75),
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _efficiencyPanel() {
//     const orderedDepts = [
//       'CUTTING',
//       'STITCHING',
//       'THREADING',
//       'QUALITY_CONTROL',
//       'PACKING',
//       'INSPECTION',
//     ];

//     final List<Color> deptColors = [
//       Colors.greenAccent,
//       Colors.blueAccent,
//       Colors.amberAccent,
//       Colors.redAccent,
//       Colors.purpleAccent,
//       Colors.cyanAccent,
//     ];

//     String norm(String d) => d.trim().toUpperCase().replaceAll(' ', '_');

//     final Map<String, int> countByDept = {for (final d in orderedDepts) d: 0};

//     for (final o in allOrders) {
//       final key = norm(o.currentDepartment.toString());
//       if (countByDept.containsKey(key)) {
//         countByDept[key] = (countByDept[key] ?? 0) + 1;
//       }
//     }

//     return _cardWrapper(
//       title: 'Production Efficiency',
//       child: Column(
//         children: [
//           LayoutBuilder(
//             builder: (context, c) {
//               // ✅ responsive chart height
//               final h = (c.maxWidth * 0.55).clamp(180.0, 240.0);
//               return SizedBox(
//                 height: h,
//                 child: PieChart(
//                   PieChartData(
//                     sectionsSpace: 4,
//                     centerSpaceRadius: 45,
//                     sections: orderedDepts.asMap().entries.map((entry) {
//                       final index = entry.key;
//                       final dept = entry.value;
//                       final count = countByDept[dept] ?? 0;

//                       return PieChartSectionData(
//                         value: count == 0 ? 0.1 : count.toDouble(),
//                         color: deptColors[index % deptColors.length],
//                         title: '',
//                         radius: 55,
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               );
//             },
//           ),
//           const SizedBox(height: 20),
//           Wrap(
//             spacing: 22,
//             runSpacing: 12,
//             children: orderedDepts.asMap().entries.map((entry) {
//               final index = entry.key;
//               final dept = entry.value;
//               final count = countByDept[dept] ?? 0;

//               return Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     width: 14,
//                     height: 14,
//                     decoration: BoxDecoration(
//                       color: deptColors[index % deptColors.length],
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     '$dept ($count)',
//                     style: const TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ],
//               );
//             }).toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   // ================= CARD =================
//   Widget _cardWrapper({String? title, required Widget child}) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: _glassCard(),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (title != null) ...[
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 17,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 16),
//           ],
//           child,
//         ],
//       ),
//     );
//   }

//   // ================= STYLES =================
//   BoxDecoration _glassCard() {
//     return BoxDecoration(
//       borderRadius: BorderRadius.circular(20),
//       color: Colors.white.withOpacity(0.05),
//       border: Border.all(color: Colors.white.withOpacity(0.12)),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withOpacity(0.2),
//           blurRadius: 18,
//           offset: const Offset(0, 8),
//         ),
//       ],
//     );
//   }
// }

// // ✅ removes overscroll glow on Android + feels cleaner on web too
// class _NoGlowScrollBehavior extends ScrollBehavior {
//   const _NoGlowScrollBehavior();

//   @override
//   Widget buildOverscrollIndicator(
//     BuildContext context,
//     Widget child,
//     ScrollableDetails details,
//   ) {
//     return child;
//   }
// }
// -----------------------------------

import 'package:fabri_sync/auth/login/login_page.dart';
import 'package:fabri_sync/controllers/admin_controller.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/view/newOrder/orderInput.dart';
import 'package:fabri_sync/widgets/admin_widgets.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final AdminDashboardController controller;

  // ✅ optional: a single scroll controller (web feels smoother)
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = AdminDashboardController()..addListener(_onCtrl);
    controller.init();
  }

  void _onCtrl() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onCtrl);
    controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String formatToDaysHours(double hours) {
    final days = hours ~/ 24;
    final remainingHours = (hours % 24).round();

    if (days > 0) {
      return '$days day${days > 1 ? 's' : ''} $remainingHours hrs';
    }
    return '$remainingHours hrs';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        // ✅ more reliable breakpoints (mobile / tablet / desktop / wide)
        final isMobile = w < 600;
        final isTablet = w >= 600 && w < 1024;
        final isDesktop = w >= 1024;
        final isWide = w >= 1400;

        // ✅ responsive page padding
        final horizontalPad = isWide
            ? 48.0
            : isDesktop
            ? 32.0
            : isTablet
            ? 22.0
            : 14.0;

        final verticalPad = isDesktop ? 24.0 : 16.0;

        // ✅ responsive max width (prevents "mobile look" on web)
        final maxContentWidth = isWide
            ? 1320.0
            : isDesktop
            ? 1180.0
            : double.infinity;

        final inProgress = controller.allOrders
            .where((o) => o.status.toLowerCase() == 'inprogress')
            .length;

        final pending = controller.allOrders
            .where(
              (o) =>
                  o.status.toLowerCase() == 'pending' ||
                  o.status.toLowerCase() == 'delayed',
            )
            .length;

        final completed = controller.allOrders
            .where((o) => o.status.toLowerCase() == 'completed')
            .length;

        // ✅ profile overlay width responsive
        final profileCardWidth = (w * 0.33).clamp(260.0, 340.0);

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AdminDashboardAppBar(
            onBack: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const LoginPage(expectedRole: ''),
                ),
                (route) => false,
              );
            },
            onCreateOrder: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderInputScreen()),
              );
            },
            onToggleProfile: controller.toggleProfileCard,
          ),
          body: controller.loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Stack(
                  children: [
                    // ✅ Background fills ALL screen (no white gaps on zoom)
                    Positioned.fill(
                      child: gradientOrderBackground(
                        child: const SizedBox.expand(),
                      ),
                    ),

                    // ✅ Main content (fills height; smooth on web)
                    Positioned.fill(
                      child: SafeArea(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: maxContentWidth,
                            ),
                            child: ScrollConfiguration(
                              behavior: const NoGlowScrollBehavior(),
                              child: ListView(
                                controller: _scrollController,
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPad,
                                  vertical: verticalPad,
                                ),
                                children: [
                                  KpiSection(
                                    isMobile: isMobile,
                                    isTablet: isTablet,
                                    isDesktop: isDesktop,
                                    inProgress: inProgress,
                                    pending: pending,
                                    completed: completed,
                                    glassCard: glassCard,
                                  ),
                                  const SizedBox(height: 22),

                                  DepartmentProgressSection(
                                    isMobile: isMobile,
                                    allOrders: controller.allOrders,
                                    glassCard: glassCard,
                                  ),
                                  const SizedBox(height: 22),

                                  controller.loadingDeptHours
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        )
                                      : EstimatedTimeSection(
                                          perUnitDeptHours:
                                              controller.estimatedDeptHours,
                                          orders: controller.allOrders,
                                          formatToDaysHours: formatToDaysHours,
                                          glassCard: glassCard,
                                        ),
                                  const SizedBox(height: 22),

                                  QueueEfficiencySection(
                                    context: context,
                                    isDesktop: isDesktop,
                                    allOrders: controller.allOrders,
                                    glassCard: glassCard,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ✅ PROFILE CARD OVERLAY (unchanged UI)
                    if (controller.showProfileCard)
                      Positioned(
                        top: kToolbarHeight + 10,
                        right: 16,
                        child: Material(
                          color: Colors.transparent,
                          child: GlassOverlayCard(
                            width: profileCardWidth,
                            child: controller.profile == null
                                ? const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      "Loading profile...",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ProfileRow(
                                        icon: Icons.person,
                                        text:
                                            (controller.profile!['full_name'] ??
                                                    '')
                                                .toString(),
                                      ),
                                      const SizedBox(height: 10),
                                      ProfileRow(
                                        icon: Icons.email,
                                        text:
                                            (controller.profile!['email'] ?? '')
                                                .toString(),
                                      ),
                                      const SizedBox(height: 10),
                                      ProfileRow(
                                        icon: Icons.phone,
                                        text:
                                            (controller.profile!['phone_number'] ??
                                                    '')
                                                .toString(),
                                      ),
                                      const SizedBox(height: 14),
                                      Divider(
                                        color: Colors.white.withOpacity(0.14),
                                      ),
                                      const SizedBox(height: 12),
                                      GestureDetector(
                                        onTap: () async {
                                          await controller.signOut();
                                          if (!mounted) return;
                                          Navigator.of(context).pushAndRemoveUntil(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const LoginPage(expectedRole: ''),
                                            ),
                                            (route) => false,
                                          );
                                        },
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent.withOpacity(
                                              0.95,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Text(
                                            "Logout",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
