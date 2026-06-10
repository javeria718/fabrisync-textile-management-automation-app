// import 'dart:async';
// import 'dart:ui';

// import 'package:fabri_sync/utils/customcolors.dart'; // ✅ gradientOrderBackground (admin style)
// import 'package:fabri_sync/view/tables/manager_table.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class ManagerPanel extends StatefulWidget {
//   const ManagerPanel({super.key});

//   @override
//   State<ManagerPanel> createState() => _ManagerPanelState();
// }

// class _ManagerPanelState extends State<ManagerPanel> {
//   final supabase = Supabase.instance.client;

//   bool _showProfileCard = false;
//   bool _showAlertsPanel = false;

//   Map<String, dynamic>? profile;

//   /// Active = only inprogress orders for this dept
//   List<Map<String, dynamic>> activeOrders = [];

//   /// History/Queue = all statuses (pending/inprogress/completed) for this dept
//   List<Map<String, dynamic>> deptOrders = [];

//   RealtimeChannel? ordersChannel;

//   Timer? _ticker; // ✅ for realtime HH:MM:SS refresh
//   Timer? _debounceRefresh;

//   // ✅ FIXED THEME (same for ALL departments; matches admin)
//   static const List<Color> _kAdminAppBarGradient = [
//     Color(0xFF0F172A),
//     Color(0xFF111827),
//   ];

//   static const List<Color> _kAdminAccentGradient = [
//     Color(0xFF0EA5E9),
//     Color(0xFF2563EB),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _loadManager();

//     // ✅ real-time countdown refresh every second (UI only, no DB)
//     _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (mounted) setState(() {});
//     });
//   }

//   /// ================= LOAD MANAGER PROFILE =================
//   Future<void> _loadManager() async {
//     final user = supabase.auth.currentUser;
//     if (user == null) return;

//     final res = await supabase
//         .from('profiles')
//         .select()
//         .eq('id', user.id)
//         .single();

//     if (!mounted) return;

//     setState(() => profile = res);

//     // ✅ DB departments should be uppercase (QUALITY_CONTROL etc.)
//     final dept = (res['department'] ?? '').toString().toUpperCase();
//     if (dept.isEmpty) return;

//     await _refreshAll(dept);
//     _subscribeOrders(dept);
//   }

//   /// ================= FETCH: ACTIVE INPROGRESS + QUANTITY =================
//   Future<void> _fetchActiveOrders(String department) async {
//     final dept = department.toUpperCase();

//     // 1) Fetch active inprogress orders from department_orders
//     final data = await supabase
//         .from('department_orders')
//         .select()
//         .eq('department', dept)
//         .eq('status', 'inprogress')
//         .order('date_in', ascending: true)
//         .order('time_in', ascending: true);

//     final List<Map<String, dynamic>> list = (data as List)
//         .map((e) => Map<String, dynamic>.from(e))
//         .toList();

//     // 2) Fetch quantities from ordersmain using order_id list (NO FK required)
//     final orderIds = list
//         .map((e) => (e['order_id'] ?? '').toString())
//         .where((id) => id.isNotEmpty)
//         .toList();

//     Map<String, int> qtyMap = {};

//     if (orderIds.isNotEmpty) {
//       final qData = await supabase
//           .from('ordersmain')
//           .select('order_id, quantity')
//           .inFilter('order_id', orderIds);

//       for (final row in (qData as List)) {
//         final oid = (row['order_id'] ?? '').toString();
//         final qty = (row['quantity'] as num?)?.toInt() ?? 0;
//         if (oid.isNotEmpty) qtyMap[oid] = qty;
//       }
//     }

//     // 3) Merge quantity into active orders
//     for (final o in list) {
//       final oid = (o['order_id'] ?? '').toString();
//       o['quantity'] = qtyMap[oid] ?? 0;
//     }

//     if (!mounted) return;
//     setState(() {
//       activeOrders = list;
//     });
//   }

//   /// ================= FETCH: DEPT HISTORY/QUEUE (ALL STATUSES) =================
//   Future<void> _fetchDeptOrders(String department) async {
//     final dept = department.toUpperCase();

//     // ✅ latest first for queue/history
//     final data = await supabase
//         .from('department_orders')
//         .select()
//         .eq('department', dept)
//         .order('date_in', ascending: false)
//         .order('time_in', ascending: false);

//     if (!mounted) return;

//     setState(() {
//       deptOrders = List<Map<String, dynamic>>.from(data);
//     });
//   }

//   Future<void> _refreshAll(String dept) async {
//     await Future.wait([_fetchActiveOrders(dept), _fetchDeptOrders(dept)]);
//   }

//   /// ================= REALTIME SUBSCRIBE =================
//   void _subscribeOrders(String department) {
//     final dept = department.toUpperCase();

//     // remove old channel
//     if (ordersChannel != null) {
//       supabase.removeChannel(ordersChannel!);
//     }

//     ordersChannel = supabase
//         .channel('mgr-$dept')
//         .onPostgresChanges(
//           event: PostgresChangeEvent.all,
//           schema: 'public',
//           table: 'department_orders',
//           filter: PostgresChangeFilter(
//             type: PostgresChangeFilterType.eq,
//             column: 'department',
//             value: dept,
//           ),
//           callback: (_) {
//             // ✅ debounce refresh to avoid multiple rapid refetches
//             _debounceRefresh?.cancel();
//             _debounceRefresh = Timer(const Duration(milliseconds: 250), () {
//               _refreshAll(dept);
//             });
//           },
//         )
//         .subscribe();
//   }

//   @override
//   void dispose() {
//     _ticker?.cancel();
//     _debounceRefresh?.cancel();
//     if (ordersChannel != null) supabase.removeChannel(ordersChannel!);
//     super.dispose();
//   }

//   /// ================= TIME / ALERT HELPERS =================
//   DateTime _startDateTime(Map<String, dynamic> o) {
//     final dateIn = DateTime.parse(o['date_in']);
//     final timeIn = DateFormat.Hms().parse(o['time_in']);
//     return DateTime(
//       dateIn.year,
//       dateIn.month,
//       dateIn.day,
//       timeIn.hour,
//       timeIn.minute,
//       timeIn.second,
//     );
//   }

//   int _remainingSeconds(Map<String, dynamic> o) {
//     final expectedHours = (o['expected_hours'] as num).toDouble();
//     final expectedSeconds = (expectedHours * 3600).round();

//     final start = _startDateTime(o);
//     final elapsedSeconds = DateTime.now().difference(start).inSeconds;

//     return expectedSeconds - elapsedSeconds;
//   }

//   bool _isExceeded(Map<String, dynamic> o) => _remainingSeconds(o) <= 0;

//   /// ✅ ALERT RULE: when 3 hours remain
//   bool _isAlert(Map<String, dynamic> o) {
//     final s = _remainingSeconds(o);
//     return s > 0 && s <= (3 * 3600);
//   }

//   String _formatCountdown(int seconds) {
//     if (seconds <= 0) return "00:00:00";

//     final h = seconds ~/ 3600;
//     final m = (seconds % 3600) ~/ 60;
//     final s = seconds % 60;

//     String two(int v) => v.toString().padLeft(2, '0');
//     return "${two(h)}:${two(m)}:${two(s)}";
//   }

//   String _formatTime(dynamic timeValue) {
//     if (timeValue == null) return "-";
//     // dept_orders time_in/out are strings like "12:34:56"
//     final t = DateFormat.Hms().parse(timeValue.toString());
//     return DateFormat("hh:mm a").format(DateTime(2000, 1, 1, t.hour, t.minute));
//   }

//   String _formatDate(dynamic dateValue) {
//     if (dateValue == null) return "-";
//     final d = DateTime.parse(dateValue.toString());
//     return DateFormat("dd MMM yyyy").format(d);
//   }

//   /// ================= MARK COMPLETED =================
//   Future<void> markCompleted(Map<String, dynamic> o) async {
//     await supabase
//         .from('department_orders')
//         .update({
//           'status': 'completed',
//           'date_out': DateFormat('yyyy-MM-dd').format(DateTime.now()),
//           'time_out': DateFormat('HH:mm:ss').format(DateTime.now()),
//         })
//         .eq('id', o['id']);
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (profile == null) {
//       return const Scaffold(
//         backgroundColor: Color(0xFF0B1220),
//         body: Center(child: CircularProgressIndicator(color: Colors.white)),
//       );
//     }

//     final deptForUi = (profile!['department'] ?? '').toString();

//     final width = MediaQuery.of(context).size.width;
//     final isDesktop = width > 900;
//     final isWide = width > 1200;

//     final total = deptOrders.length;
//     final completed = deptOrders
//         .where((o) => (o['status'] ?? '').toString() == 'completed')
//         .length;
//     final inProgress = deptOrders
//         .where((o) => (o['status'] ?? '').toString() == 'inprogress')
//         .length;

//     final late = activeOrders.where(_isExceeded).length;

//     final near = activeOrders.where(_isAlert).toList();
//     final exceeded = activeOrders.where(_isExceeded).toList();

//     final queuePreview = deptOrders.take(4).toList();

//     return Scaffold(
//       // ✅ IMPORTANT: dont keep transparent, otherwise white shows
//       backgroundColor: const Color(0xFF0B1220),

//       appBar: _buildAdminLikeAppBar(
//         context,
//         deptForUi: deptForUi,
//         hasAlerts: near.isNotEmpty || exceeded.isNotEmpty,
//       ),

//       body: Stack(
//         children: [
//           // ✅ FULL-SCREEN background (fixes white bottom)
//           Positioned.fill(
//             child: gradientOrderBackground(child: const SizedBox.expand()),
//           ),

//           // ✅ Content layer
//           Positioned.fill(
//             child: SafeArea(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(20),
//                 child: Center(
//                   child: ConstrainedBox(
//                     constraints: BoxConstraints(
//                       maxWidth: isWide ? 1200 : double.infinity,
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _kpiSectionAdminLike(
//                           isDesktop: isDesktop,
//                           total: total,
//                           inProgress: inProgress,
//                           completed: completed,
//                           late: late,
//                         ),
//                         const SizedBox(height: 22),

//                         if (isDesktop)
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Expanded(
//                                 child: _glassCardWrapper(
//                                   title: "Order Queue Overview",
//                                   rightAction: TextButton(
//                                     onPressed: () {
//                                       final dept = deptForUi.toUpperCase();
//                                       Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder: (_) =>
//                                               ManagerDepartmentTableScreen(
//                                                 department: dept,
//                                               ),
//                                         ),
//                                       );
//                                     },
//                                     child: const Text(
//                                       "View Full",
//                                       style: TextStyle(color: Colors.white),
//                                     ),
//                                   ),
//                                   child: _queuePreviewTable(queuePreview),
//                                 ),
//                               ),
//                               const SizedBox(width: 20),
//                               Expanded(
//                                 child: _glassCardWrapper(
//                                   title: "Active Orders",
//                                   subtitle: activeOrders.isEmpty
//                                       ? "No active orders right now."
//                                       : "Realtime countdown enabled",
//                                   child: _activeOrdersList(),
//                                 ),
//                               ),
//                             ],
//                           )
//                         else ...[
//                           _glassCardWrapper(
//                             title: "Order Queue Overview",
//                             rightAction: TextButton(
//                               onPressed: () {
//                                 final dept = deptForUi.toUpperCase();
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (_) =>
//                                         ManagerDepartmentTableScreen(
//                                           department: dept,
//                                         ),
//                                   ),
//                                 );
//                               },
//                               child: const Text(
//                                 "View Full",
//                                 style: TextStyle(color: Colors.white),
//                               ),
//                             ),
//                             child: _queuePreviewTable(queuePreview),
//                           ),
//                           const SizedBox(height: 18),
//                           _glassCardWrapper(
//                             title: "Active Orders",
//                             subtitle: activeOrders.isEmpty
//                                 ? "No active orders right now."
//                                 : "Realtime countdown enabled",
//                             child: _activeOrdersList(),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           // PROFILE CARD OVERLAY (same as yours)
//           if (_showProfileCard)
//             Positioned(
//               top: kToolbarHeight + 10,
//               right: 16,
//               child: Material(
//                 color: Colors.transparent,
//                 child: _glassOverlayCard(
//                   width: 280,
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _row(
//                         Icons.person,
//                         (profile!['full_name'] ?? '').toString(),
//                       ),
//                       const SizedBox(height: 10),
//                       _row(Icons.email, (profile!['email'] ?? '').toString()),
//                       const SizedBox(height: 10),
//                       _row(
//                         Icons.phone,
//                         (profile!['phone_number'] ?? '').toString(),
//                       ),
//                       const SizedBox(height: 14),
//                       Divider(color: Colors.white.withOpacity(0.14)),
//                       const SizedBox(height: 12),
//                       GestureDetector(
//                         onTap: () async {
//                           await supabase.auth.signOut();
//                           if (!mounted) return;
//                           Navigator.of(context).pushReplacementNamed('/login');
//                         },
//                         child: Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.symmetric(vertical: 10),
//                           alignment: Alignment.center,
//                           decoration: BoxDecoration(
//                             color: Colors.redAccent.withOpacity(0.95),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: const Text(
//                             "Logout",
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//           // ALERTS RIGHT PANEL (same as yours)
//           AnimatedPositioned(
//             duration: const Duration(milliseconds: 220),
//             curve: Curves.easeOut,
//             top: 0,
//             bottom: 0,
//             right: _showAlertsPanel ? 0 : -340,
//             child: _alertsPanel(
//               width: 340,
//               title: "Alerts",
//               subtitle: "Orders with ≤ 3 hours remaining",
//               nearDeadline: near,
//               exceeded: exceeded,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ================= ADMIN-LIKE APPBAR (fixed colors) =================
//   AppBar _buildAdminLikeAppBar(
//     BuildContext context, {
//     required String deptForUi,
//     required bool hasAlerts,
//   }) {
//     return AppBar(
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
//         onPressed: () => Navigator.of(context).maybePop(),
//       ),
//       elevation: 0,
//       backgroundColor: Colors.transparent,
//       centerTitle: false,
//       titleSpacing: 16,
//       title: Row(
//         children: [
//           Container(
//             width: 38,
//             height: 38,
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 colors: _kAdminAccentGradient,
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(
//               _departmentIcon(deptForUi),
//               size: 20,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Flexible(
//             child: Text(
//               _prettyDept(deptForUi),
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ],
//       ),

//       // ✅ Frosted + bottom separation
//       flexibleSpace: ClipRect(
//         child: Stack(
//           children: [
//             // base gradient (aapka existing)
//             Container(
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: _kAdminAppBarGradient,
//                 ),
//               ),
//             ),

//             // frosted blur layer
//             BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//               child: Container(
//                 color: Colors.white.withOpacity(0.04), // subtle glass tint
//               ),
//             ),

//             // bottom "neeche wali" distinguish strip + hairline
//             Align(
//               alignment: Alignment.bottomCenter,
//               child: Container(
//                 height: 18,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       Colors.transparent,
//                       Colors.black.withOpacity(0.25),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             Align(
//               alignment: Alignment.bottomCenter,
//               child: Container(
//                 height: 1,
//                 color: Colors.white.withOpacity(0.10), // hairline divider
//               ),
//             ),
//           ],
//         ),
//       ),

//       actions: [
//         IconButton(
//           tooltip: "Alerts",
//           icon: Stack(
//             children: [
//               const Icon(Icons.notifications_none, color: Colors.white),
//               if (hasAlerts)
//                 Positioned(
//                   right: 0,
//                   top: 2,
//                   child: Container(
//                     width: 10,
//                     height: 10,
//                     decoration: BoxDecoration(
//                       color: Colors.redAccent,
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           onPressed: () => setState(() => _showAlertsPanel = !_showAlertsPanel),
//         ),
//         GestureDetector(
//           onTap: () => setState(() => _showProfileCard = !_showProfileCard),
//           child: const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 12),
//             child: Icon(Icons.account_circle, size: 32, color: Colors.white),
//           ),
//         ),
//         const SizedBox(width: 8),
//       ],
//     );
//   }

//   // ================= KPI (fixed colors, admin style) =================
//   Widget _kpiSectionAdminLike({
//     required bool isDesktop,
//     required int total,
//     required int inProgress,
//     required int completed,
//     required int late,
//   }) {
//     final cards = [
//       _kpiCardAdmin(
//         title: "Total",
//         value: total.toString(),
//         icon: Icons.inventory_2_outlined,
//         color: Colors.cyanAccent,
//       ),
//       _kpiCardAdmin(
//         title: "In Progress",
//         value: inProgress.toString(),
//         icon: Icons.autorenew_rounded,
//         color: Colors.orangeAccent,
//       ),
//       _kpiCardAdmin(
//         title: "Completed",
//         value: completed.toString(),
//         icon: Icons.check_circle_outline,
//         color: Colors.greenAccent,
//       ),
//       _kpiCardAdmin(
//         title: "Late",
//         value: late.toString(),
//         icon: Icons.warning_amber_rounded,
//         color: Colors.redAccent,
//       ),
//     ];

//     if (isDesktop) {
//       return GridView.count(
//         crossAxisCount: 4,
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         crossAxisSpacing: 20,
//         childAspectRatio: 2.35,
//         children: cards,
//       );
//     }

//     return SizedBox(
//       height: 140,
//       child: ListView.separated(
//         scrollDirection: Axis.horizontal,
//         itemCount: cards.length,
//         separatorBuilder: (_, __) => const SizedBox(width: 16),
//         itemBuilder: (_, i) => SizedBox(width: 220, child: cards[i]),
//       ),
//     );
//   }

//   Widget _kpiCardAdmin({
//     required String title,
//     required String value,
//     required IconData icon,
//     required Color color,
//   }) {
//     return LayoutBuilder(
//       builder: (context, c) {
//         final h = c.maxHeight;

//         // ✅ Auto compact for short heights (web resize / small grid height)
//         final pad = h < 105 ? 12.0 : 16.0;
//         final iconSize = h < 105 ? 24.0 : 28.0;
//         final valueSize = h < 105 ? 22.0 : 26.0;
//         final titleSize = h < 105 ? 11.5 : 13.0;
//         final gap = h < 105 ? 2.0 : 4.0;

//         return _glass(
//           radius: 20,
//           padding: EdgeInsets.all(pad),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Icon(icon, color: color, size: iconSize),

//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   FittedBox(
//                     fit: BoxFit.scaleDown,
//                     alignment: Alignment.centerLeft,
//                     child: Text(
//                       value,
//                       style: TextStyle(
//                         fontSize: valueSize,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                         height:
//                             1.0, // ✅ line-height tight (removes 0.x overflow)
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: gap),
//                   FittedBox(
//                     fit: BoxFit.scaleDown,
//                     alignment: Alignment.centerLeft,
//                     child: Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: titleSize,
//                         color: Colors.white.withOpacity(0.70),
//                         height: 1.0, // ✅ important
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // ================= SECTIONS =================
//   Widget _glassCardWrapper({
//     required String title,
//     String? subtitle,
//     Widget? rightAction,
//     required Widget child,
//   }) {
//     return _glass(
//       radius: 20,
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 17,
//                     fontWeight: FontWeight.w700,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//               if (rightAction != null) rightAction,
//             ],
//           ),
//           if (subtitle != null) ...[
//             const SizedBox(height: 6),
//             Text(
//               subtitle,
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.70),
//                 fontSize: 12,
//               ),
//             ),
//           ],
//           const SizedBox(height: 16),
//           child,
//         ],
//       ),
//     );
//   }

//   Widget _queuePreviewTable(List<Map<String, dynamic>> queuePreview) {
//     if (queuePreview.isEmpty) {
//       return const Padding(
//         padding: EdgeInsets.symmetric(vertical: 16),
//         child: Center(
//           child: Text(
//             "No history yet",
//             style: TextStyle(color: Colors.white70),
//           ),
//         ),
//       );
//     }

//     return Column(
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: Text(
//                 "Order ID",
//                 style: TextStyle(
//                   color: Colors.white.withOpacity(0.60),
//                   fontSize: 12,
//                 ),
//               ),
//             ),
//             Expanded(
//               child: Text(
//                 "In",
//                 style: TextStyle(
//                   color: Colors.white.withOpacity(0.60),
//                   fontSize: 12,
//                 ),
//               ),
//             ),
//             Expanded(
//               child: Text(
//                 "Out",
//                 style: TextStyle(
//                   color: Colors.white.withOpacity(0.60),
//                   fontSize: 12,
//                 ),
//               ),
//             ),
//             Expanded(
//               child: Text(
//                 "Status",
//                 style: TextStyle(
//                   color: Colors.white.withOpacity(0.60),
//                   fontSize: 12,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         Divider(color: Colors.white.withOpacity(0.14)),
//         ...queuePreview.map((o) {
//           final status = (o['status'] ?? '').toString();
//           return Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     (o['order_id'] ?? '').toString(),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   child: Text(
//                     "${_formatDate(o['date_in'])}\n${_formatTime(o['time_in'])}",
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.78),
//                       fontSize: 12,
//                       height: 1.25,
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   child: Text(
//                     "${_formatDate(o['date_out'])}\n${_formatTime(o['time_out'])}",
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.78),
//                       fontSize: 12,
//                       height: 1.25,
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   child: Text(
//                     status,
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.82),
//                       fontSize: 12,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }).toList(),
//       ],
//     );
//   }

//   Widget _activeOrdersList() {
//     if (activeOrders.isEmpty) {
//       return const Padding(
//         padding: EdgeInsets.symmetric(vertical: 22),
//         child: Center(
//           child: Text(
//             "No active orders",
//             style: TextStyle(color: Colors.white70),
//           ),
//         ),
//       );
//     }

//     return ListView.builder(
//       itemCount: activeOrders.length,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemBuilder: (context, index) {
//         final o = activeOrders[index];

//         final orderId = (o['order_id'] ?? '').toString();
//         final expectedHours = (o['expected_hours'] as num).toDouble();
//         final qty = (o['quantity'] ?? 0).toString();

//         final remainingSec = _remainingSeconds(o);
//         final countdown = _formatCountdown(remainingSec);

//         final danger = remainingSec <= 0;
//         final alert = _isAlert(o);

//         return Padding(
//           padding: const EdgeInsets.only(bottom: 14),
//           child: _orderGlassCard(
//             departmentColors: _kAdminAccentGradient, // ✅ FIXED for all
//             orderId: orderId,
//             expectedHours: expectedHours,
//             quantity: qty,
//             countdown: countdown,
//             danger: danger,
//             alert: alert,
//             onComplete: () => markCompleted(o),
//           ),
//         );
//       },
//     );
//   }

//   // ================= REUSABLE GLASS =================
//   Widget _glass({
//     required double radius,
//     required EdgeInsets padding,
//     required Widget child,
//   }) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(radius),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
//         child: Container(
//           padding: padding,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(radius),
//             color: Colors.white.withOpacity(0.05),
//             border: Border.all(color: Colors.white.withOpacity(0.12)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.20),
//                 blurRadius: 18,
//                 offset: const Offset(0, 8),
//               ),
//             ],
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }

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

//   // ================= ORDER CARD =================
//   Widget _orderGlassCard({
//     required List<Color> departmentColors,
//     required String orderId,
//     required double expectedHours,
//     required String quantity,
//     required String countdown,
//     required bool danger,
//     required bool alert,
//     required VoidCallback onComplete,
//   }) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(18),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.05),
//             borderRadius: BorderRadius.circular(18),
//             border: Border.all(color: Colors.white.withOpacity(0.12)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.18),
//                 blurRadius: 18,
//                 offset: const Offset(0, 8),
//               ),
//             ],
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 44,
//                 height: 44,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       departmentColors[0].withOpacity(0.90),
//                       departmentColors[1].withOpacity(0.90),
//                     ],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 child: const Icon(Icons.receipt_long, color: Colors.white),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Order $orderId",
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w700,
//                         fontSize: 15,
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       "Expected: ${expectedHours.toStringAsFixed(1)} hrs",
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.75),
//                         fontSize: 12,
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       "Qty: $quantity",
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.75),
//                         fontSize: 12,
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       countdown,
//                       style: TextStyle(
//                         color: danger
//                             ? Colors.redAccent
//                             : alert
//                             ? Colors.amberAccent
//                             : Colors.white.withOpacity(0.92),
//                         fontWeight: FontWeight.w800,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 12),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: danger ? Colors.redAccent : Colors.green,
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 14,
//                     vertical: 12,
//                   ),
//                   elevation: 0,
//                 ),
//                 onPressed: onComplete,
//                 child: const Text("Complete"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ================= ALERTS PANEL =================
//   Widget _alertsPanel({
//     required double width,
//     required String title,
//     required String subtitle,
//     required List<Map<String, dynamic>> nearDeadline,
//     required List<Map<String, dynamic>> exceeded,
//   }) {
//     return Material(
//       color: Colors.transparent,
//       child: Container(
//         width: width,
//         height: double.infinity,
//         decoration: BoxDecoration(
//           color: Colors.black.withOpacity(0.22),
//           border: Border(
//             left: BorderSide(color: Colors.white.withOpacity(0.12)),
//           ),
//         ),
//         child: ClipRRect(
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             title,
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.w800,
//                               fontSize: 18,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             subtitle,
//                             style: TextStyle(
//                               color: Colors.white.withOpacity(0.70),
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                       IconButton(
//                         onPressed: () =>
//                             setState(() => _showAlertsPanel = false),
//                         icon: const Icon(Icons.close, color: Colors.white),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 14),
//                   _alertsGroup(
//                     label: "Near Deadline (≤ 3 hrs)",
//                     items: nearDeadline,
//                     color: Colors.amberAccent,
//                   ),
//                   const SizedBox(height: 14),
//                   _alertsGroup(
//                     label: "Time Exceeded",
//                     items: exceeded,
//                     color: Colors.redAccent,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _alertsGroup({
//     required String label,
//     required List<Map<String, dynamic>> items,
//     required Color color,
//   }) {
//     return Expanded(
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(16),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
//           child: Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.08),
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(color: Colors.white.withOpacity(0.12)),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       width: 10,
//                       height: 10,
//                       decoration: BoxDecoration(
//                         color: color,
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Text(
//                       label,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10),
//                 if (items.isEmpty)
//                   Text(
//                     "No alerts",
//                     style: TextStyle(color: Colors.white.withOpacity(0.70)),
//                   )
//                 else
//                   Expanded(
//                     child: ListView.separated(
//                       itemCount: items.length,
//                       separatorBuilder: (_, __) =>
//                           Divider(color: Colors.white.withOpacity(0.12)),
//                       itemBuilder: (context, i) {
//                         final o = items[i];
//                         final orderId = (o['order_id'] ?? '').toString();
//                         final sec = _remainingSeconds(o);
//                         final countdown = _formatCountdown(sec);

//                         return Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               "Order $orderId",
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             Text(
//                               countdown,
//                               style: TextStyle(
//                                 color: Colors.white.withOpacity(0.85),
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),
//                           ],
//                         );
//                       },
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _row(IconData icon, String text, {Color color = Colors.white}) {
//     return Row(
//       children: [
//         Icon(icon, size: 18, color: color),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(text, style: TextStyle(fontSize: 15, color: color)),
//         ),
//       ],
//     );
//   }
// }

// /// ================= HELPERS =================
// String _normalizeDept(String dept) => dept.trim().toUpperCase();

// String _prettyDept(String dept) {
//   final d = _normalizeDept(dept);
//   switch (d) {
//     case 'QUALITY_CONTROL':
//       return 'QUALITY CONTROL';
//     default:
//       return d;
//   }
// }

// IconData _departmentIcon(String dept) {
//   switch (_normalizeDept(dept)) {
//     case 'CUTTING':
//       return Icons.cut;
//     case 'STITCHING':
//       return Icons.design_services;
//     case 'THREADING':
//       return Icons.settings;
//     case 'QUALITY_CONTROL':
//       return Icons.verified_outlined;
//     case 'PACKAGING':
//       return Icons.inventory_2_outlined;
//     case 'INSPECTION':
//       return Icons.search_rounded;
//     default:
//       return Icons.factory_outlined;
//   }
// }
import 'dart:ui';
import 'package:fabri_sync/services/auth_navigation_service.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/view/dashboards/tables/manager_table.dart';
import 'package:fabri_sync/widgets/glass_Card.dart';
import 'package:fabri_sync/widgets/manager_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/manager_controller.dart';

class ManagerPanel extends StatelessWidget {
  const ManagerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ManagerController()..init(),
      child: const _ManagerView(),
    );
  }
}

class _ManagerView extends StatelessWidget {
  const _ManagerView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ManagerController>();

    if (c.profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.appBackground,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
      );
    }

    final deptForUi = (c.profile!['department'] ?? '').toString();
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;
    final isWide = width > 1200;

    final near = c.nearDeadline;
    final exceeded = c.exceeded;
    final hasAlerts = near.isNotEmpty || exceeded.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: _buildAdminLikeAppBar(
        context,
        c,
        deptForUi: deptForUi,
        hasAlerts: hasAlerts,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: gradientOrderBackground(child: const SizedBox.expand()),
          ),
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 1200 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ManagerKpiSection(
                          isDesktop: isDesktop,
                          total: c.total,
                          inProgress: c.inProgress,
                          completed: c.completed,
                          late: c.lateCount,
                        ),
                        const SizedBox(height: 22),
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _sectionQueue(context, c, deptForUi),
                              ),
                              const SizedBox(width: 20),
                              Expanded(child: _sectionActive(c)),
                            ],
                          )
                        else ...[
                          _sectionQueue(context, c, deptForUi),
                          const SizedBox(height: 18),
                          _sectionActive(c),
                        ],
                        const SizedBox(height: 18),
                        _sectionTrackingDetails(c),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (c.showProfileCard)
            Positioned(
              top: kToolbarHeight + 10,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: GlassOverlayCard(
                  width: 280,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row(
                        Icons.person,
                        (c.profile!['full_name'] ?? '').toString(),
                      ),
                      const SizedBox(height: 10),
                      _row(Icons.email, (c.profile!['email'] ?? '').toString()),
                      const SizedBox(height: 10),
                      _row(
                        Icons.phone,
                        (c.profile!['phone_number'] ?? '').toString(),
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: () async {
                          await AuthNavigationService.logoutAndNavigate(
                            context,
                            'manager',
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(12),
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

          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            top: 0,
            bottom: 0,
            right: c.showAlertsPanel ? 0 : -340,
            child: AlertsPanel(
              width: 340,
              title: "Alerts",
              subtitle: "Orders with ≤ 3 hours remaining",
              nearDeadline: near,
              exceeded: exceeded,
              remainingSeconds: c.remainingSeconds,
              formatCountdown: c.formatCountdown,
              onClose: c.closeAlertsPanel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionQueue(
    BuildContext context,
    ManagerController c,
    String deptForUi,
  ) {
    return Glass(
      radius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveHeader(
            title: "Order Queue Overview",
            rightAction: TextButton(
              onPressed: () {
                final dept = deptForUi.toUpperCase();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ManagerDepartmentTableScreen(department: dept),
                  ),
                );
              },
              child: const Text(
                "View Full",
                style: TextStyle(
                  color: AppColors.primaryAccent,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          QueuePreviewTable(
            queuePreview: c.queuePreview,
            formatDate: c.formatDate,
            formatTime: c.formatTime,
            selectedOrderId: (c.selectedOrder?['order_id'] ?? '').toString(),
            onViewDetails: c.loadOrderDetails,
          ),
        ],
      ),
    );
  }

  Widget _sectionActive(ManagerController c) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveHeader(
            title: "Active Orders",
            subtitle: c.activeOrders.isEmpty
                ? "No active orders right now."
                : "Realtime countdown enabled",
          ),
          const SizedBox(height: 16),
          ActiveOrdersList(
            activeOrders: c.activeOrders,
            remainingSeconds: c.remainingSeconds,
            isAlert: c.isAlert,
            formatCountdown: c.formatCountdown,
            summaryForOrder: c.summaryForOrder,
            latestLogForOrder: c.latestLogForOrder,
            selectedOrderId: (c.selectedOrder?['order_id'] ?? '').toString(),
            onViewDetails: c.loadOrderDetails,
          ),
        ],
      ),
    );
  }

  Widget _sectionTrackingDetails(ManagerController c) {
    return ManagerOrderDetailsPanel(
      selectedOrder: c.selectedOrder,
      loading: c.detailLoading,
      error: c.detailError,
      items: c.selectedOrderItems,
      summary: c.selectedProgressSummary,
      logs: c.selectedLogs,
    );
  }

  AppBar _buildAdminLikeAppBar(
    BuildContext context,
    ManagerController c, {
    required String deptForUi,
    required bool hasAlerts,
  }) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.primaryText,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      elevation: 0,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppGradients.adminAccent,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _departmentIcon(deptForUi),
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              _prettyDept(deptForUi),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
      ),
      actions: [
        IconButton(
          tooltip: "Alerts",
          icon: Stack(
            children: [
              const Icon(
                Icons.notifications_none,
                color: AppColors.primaryText,
              ),
              if (hasAlerts)
                Positioned(
                  right: 0,
                  top: 2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),
          onPressed: c.toggleAlertsPanel,
        ),
        GestureDetector(
          onTap: c.toggleProfileCard,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.account_circle,
              size: 32,
              color: AppColors.primaryText,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _row(
    IconData icon,
    String text, {
    Color color = AppColors.primaryText,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 15, color: color)),
        ),
      ],
    );
  }
}

// helpers
String _normalizeDept(String dept) => dept.trim().toUpperCase();

String _prettyDept(String dept) {
  final d = _normalizeDept(dept);
  switch (d) {
    case 'QUALITY_CONTROL':
      return 'QUALITY CONTROL';
    case 'PACKAGING':
      return 'Packaging';
    default:
      return d;
  }
}

IconData _departmentIcon(String dept) {
  switch (_normalizeDept(dept)) {
    case 'CUTTING':
      return Icons.cut;
    case 'STITCHING':
      return Icons.design_services;
    case 'THREADING':
      return Icons.settings;
    case 'QUALITY_CONTROL':
      return Icons.verified_outlined;
    case 'PACKAGING':
      return Icons.inventory_2_outlined;
    case 'INSPECTION':
      return Icons.search_rounded;
    default:
      return Icons.factory_outlined;
  }
}
