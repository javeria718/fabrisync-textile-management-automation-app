// import 'dart:async';

// import 'package:fabri_sync/Model/orderModel.dart';
// import 'package:fabri_sync/Model/datamodel.dart';
// import 'package:fabri_sync/utils/customcolors.dart';
// import 'package:fabri_sync/view/tables/orders_datasource.dart';
// import 'package:fabri_sync/widgets/date_box.dart';
// import 'package:flutter/material.dart';
// import 'package:data_table_2/data_table_2.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class TableScreen extends StatefulWidget {
//   final Department? department;

//   const TableScreen({super.key, this.department});

//   @override
//   State<TableScreen> createState() => _TableScreenState();
// }

// class _TableScreenState extends State<TableScreen> {
//   Department? selectedDepartment;
//   final supabase = Supabase.instance.client;

//   List<OrderModel> allOrders = [];
//   bool loading = true;

//   WorkStatus? selectedStatus;
//   DateTime? startDate;
//   String searchQuery = "";

//   RealtimeChannel? _channel;

//   @override
//   void initState() {
//     super.initState();
//     selectedDepartment = widget.department;
//     fetchOrders();
//     setupRealtime();
//   }

//   @override
//   void dispose() {
//     if (_channel != null) {
//       supabase.removeChannel(_channel!);
//     }
//     super.dispose();
//   }

//   /// ✅ Fetch from VIEW (manager_name + quantity included)
//   Future<void> fetchOrders() async {
//     if (!mounted) return;
//     setState(() => loading = true);

//     try {
//       var query = supabase.from('v_department_orders_full').select();

//       if (selectedDepartment != null) {
//         query = query.eq('department', selectedDepartment!.name.toUpperCase());
//       }

//       final data = await query.order('date_in', ascending: false);

//       if (!mounted) return;
//       setState(() {
//         allOrders = (data as List)
//             .map(
//               (e) => OrderModel.fromDeptOrderMap({
//                 ...e,
//                 // view already provides these keys:
//                 'manager_name': e['manager_name'],
//                 'ordersmain': {
//                   'order_id': e['order_id'],
//                   'quantity': e['quantity'] ?? 0,
//                 },
//               }),
//             )
//             .toList();
//         loading = false;
//       });
//     } catch (e) {
//       debugPrint('Fetch error: $e');
//       if (!mounted) return;
//       setState(() => loading = false);
//     }
//   }

//   /// ✅ Realtime: listen on BASE TABLE, refresh VIEW data
//   void setupRealtime() {
//     _channel?.unsubscribe();

//     _channel = supabase
//         .channel('admin-table-dept-orders')
//         .onPostgresChanges(
//           event: PostgresChangeEvent.all,
//           schema: 'public',
//           table: 'department_orders',
//           callback: (_) async {
//             // ✅ refresh view-based data
//             await fetchOrders();
//           },
//         )
//         .subscribe();
//   }

//   List<OrderModel> get filteredOrders {
//     return allOrders.where((o) {
//       final matchesDept =
//           selectedDepartment == null ||
//           o.currentDepartment.toUpperCase() ==
//               selectedDepartment!.name.toUpperCase();

//       final matchesSearch = o.orderId.toLowerCase().contains(
//         searchQuery.toLowerCase(),
//       );

//       final matchesStatus =
//           selectedStatus == null ||
//           o.status.toLowerCase() == selectedStatus!.name.toLowerCase();

//       final matchesDate =
//           startDate == null || (o.dateIn?.isAfter(startDate!) ?? true);

//       return matchesDept && matchesSearch && matchesStatus && matchesDate;
//     }).toList();
//   }

//   Future pickStartDate() async {
//     final date = await showDatePicker(
//       context: context,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2030),
//       initialDate: startDate ?? DateTime.now(),
//     );
//     if (date != null && mounted) setState(() => startDate = date);
//   }

//   @override
//   Widget build(BuildContext context) {
//     const blue = Color(0xFF0A4DAB);

//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F6FA),
//       appBar: AppBar(
//         centerTitle: true,
//         backgroundColor: AppColors.customBlueColor,
//         title: const Text(
//           "Existing Orders",
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//       body: loading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: const EdgeInsets.all(18),
//               child: Column(
//                 children: [
//                   Card(
//                     elevation: 3,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                       side: BorderSide(
//                         color: AppColors.customBlueColor,
//                         width: 1,
//                       ),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         children: [
//                           TextField(
//                             decoration: InputDecoration(
//                               hintText: "Search Order ID...",
//                               prefixIcon: const Icon(Icons.search),
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               isDense: true,
//                             ),
//                             onChanged: (v) {
//                               if (!mounted) return;
//                               setState(() => searchQuery = v);
//                             },
//                           ),
//                           const SizedBox(height: 12),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: DropdownButtonFormField<WorkStatus?>(
//                                   value: selectedStatus,
//                                   decoration: _inputDecoration("Status"),
//                                   items: [
//                                     const DropdownMenuItem(
//                                       value: null,
//                                       child: Text("All Statuses"),
//                                     ),
//                                     ...WorkStatus.values.map(
//                                       (s) => DropdownMenuItem(
//                                         value: s,
//                                         child: Text(s.name),
//                                       ),
//                                     ),
//                                   ],
//                                   onChanged: (v) {
//                                     if (!mounted) return;
//                                     setState(() => selectedStatus = v);
//                                   },
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: DropdownButtonFormField<Department?>(
//                                   value: selectedDepartment,
//                                   decoration: _inputDecoration("Department"),
//                                   items: [
//                                     const DropdownMenuItem(
//                                       value: null,
//                                       child: Text("All Departments"),
//                                     ),
//                                     ...Department.values.map(
//                                       (d) => DropdownMenuItem(
//                                         value: d,
//                                         child: Text(d.name),
//                                       ),
//                                     ),
//                                   ],
//                                   onChanged: (value) async {
//                                     if (!mounted) return;
//                                     setState(() => selectedDepartment = value);
//                                     await fetchOrders();
//                                   },
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: dateBox(
//                                   "Start Date",
//                                   startDate,
//                                   pickStartDate,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 18),

//                   Expanded(
//                     child: Card(
//                       elevation: 4,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(14),
//                         side: BorderSide(
//                           color: AppColors.customBlueColor,
//                           width: 1.2,
//                         ),
//                       ),
//                       child: PaginatedDataTable2(
//                         showCheckboxColumn: false,
//                         wrapInCard: false,
//                         rowsPerPage: 8,
//                         minWidth: 800,
//                         columnSpacing: 12,
//                         headingRowColor: MaterialStateProperty.all(
//                           blue.withOpacity(0.08),
//                         ),
//                         headingTextStyle: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: blue,
//                         ),
//                         columns: const [
//                           DataColumn(label: Text("S#")),
//                           DataColumn(label: Text("Order ID")),
//                           DataColumn(label: Text("Dept")),
//                           DataColumn(label: Text("Manager")),
//                           DataColumn(label: Text("Date In")),
//                           DataColumn(label: Text("Time In")),
//                           DataColumn(label: Text("Running")),
//                           DataColumn(label: Text("Date Out")),
//                           DataColumn(label: Text("Time Out")),
//                           DataColumn(label: Text("Status")),
//                           DataColumn(label: Text("")),
//                         ],
//                         source: OrdersDataSource(filteredOrders, context, blue),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//   InputDecoration _inputDecoration(String label) {
//     return InputDecoration(
//       labelText: label,
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//     );
//   }
// }
import 'dart:async';
import 'dart:ui';

import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/Model/datamodel.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/view/dashboards/tables/admin_datasource.dart';

import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TableScreen extends StatefulWidget {
  final Department? department;

  const TableScreen({super.key, this.department});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  Department? selectedDepartment;
  final supabase = Supabase.instance.client;

  List<OrderModel> allOrders = [];
  bool loading = true;

  WorkStatus? selectedStatus;
  DateTime? startDate;
  String searchQuery = "";

  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    selectedDepartment = widget.department;
    fetchOrders();
    setupRealtime();
  }

  @override
  void dispose() {
    if (_channel != null) {
      supabase.removeChannel(_channel!);
    }
    super.dispose();
  }

  /// ✅ Fetch from VIEW (manager_name + quantity included)
  Future<void> fetchOrders() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      final managersData = await supabase
          .from('profiles')
          .select('department, full_name')
          .eq('role', 'manager');
      final managerByDept = <String, String>{};
      for (final row in (managersData as List)) {
        final dept = (row['department'] ?? '').toString().toUpperCase();
        final name = (row['full_name'] ?? '').toString();
        if (dept.isNotEmpty && name.isNotEmpty) {
          managerByDept[dept] = name;
        }
      }

      var query = supabase.from('v_department_orders_full').select();

      if (selectedDepartment != null) {
        query = query.eq('department', selectedDepartment!.name.toUpperCase());
      }

      final data = await query.order('date_in', ascending: false);
      if (data.isNotEmpty) {
        final first = Map<String, dynamic>.from(data.first as Map);
        debugPrint("VIEW KEYS => ${first.keys.toList()}");
        debugPrint("manager_name => ${first['manager_name']}");
        debugPrint("manager_n => ${first['manager_n']}");
      }

      if (!mounted) return;
      setState(() {
        allOrders = (data as List)
            .map(
              (e) => OrderModel.fromDeptOrderMap({
                ...e,
                // view already provides these keys:
                'manager_name':
                    managerByDept[(e['department'] ?? '').toString().toUpperCase()] ??
                    e['manager_name'] ??
                    e['manager_n'] ??
                    e['manager'],
                'ordersmain': {
                  'order_id': e['order_id'],
                  'quantity': e['quantity'] ?? 0,
                },
              }),
            )
            .toList();
        loading = false;
      });
    } catch (e) {
      debugPrint('Fetch error: $e');
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  /// ✅ Realtime: listen on BASE TABLE, refresh VIEW data
  void setupRealtime() {
    _channel?.unsubscribe();

    _channel = supabase
        .channel('admin-table-dept-orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'department_orders',
          callback: (_) async {
            // ✅ refresh view-based data
            await fetchOrders();
          },
        )
        .subscribe();
  }

  List<OrderModel> get filteredOrders {
    return allOrders.where((o) {
      final matchesDept =
          selectedDepartment == null ||
          o.currentDepartment.toUpperCase() ==
              selectedDepartment!.name.toUpperCase();

      final matchesSearch = o.orderId.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );

      final matchesStatus =
          selectedStatus == null ||
          o.status.toLowerCase() == selectedStatus!.name.toLowerCase();

      final matchesDate =
          startDate == null || (o.dateIn?.isAfter(startDate!) ?? true);

      return matchesDept && matchesSearch && matchesStatus && matchesDate;
    }).toList();
  }

  Future pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDate: startDate ?? DateTime.now(),
    );
    if (date != null && mounted) setState(() => startDate = date);
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0A4DAB);

    final media = MediaQuery.of(context);
    final isMobile = media.size.width < 700;

    return Scaffold(
      // Glass theme -> background behind everything
      backgroundColor: const Color(0xFF0B1220),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          "Existing Orders",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        // subtle blur behind AppBar
        flexibleSpace: _Glass(
          borderRadius: 0,
          padding: EdgeInsets.zero,
          blur: 14,
          opacity: 0.14,
          borderOpacity: 0.10,
          child: const SizedBox.expand(),
        ),
      ),
      body: Stack(
        children: [
          // ✅ Modern gradient background (dashboard feel)
          // Positioned.fill(
          //   child: DecoratedBox(
          //     decoration: BoxDecoration(
          //       gradient: LinearGradient(
          //         begin: Alignment.topLeft,
          //         end: Alignment.bottomRight,
          //         colors: [
          //           const Color(0xFF0B1220),
          //           blue.withOpacity(0.22),
          //           const Color(0xFF0B1220),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
          Positioned.fill(
            child: gradientOrderBackground(child: const SizedBox.expand()),
          ),
          // ✅ subtle light blobs
          Positioned(
            top: -80,
            left: -60,
            child: _GlowBlob(color: blue.withOpacity(0.35), size: 220),
          ),
          Positioned(
            bottom: -90,
            right: -70,
            child: _GlowBlob(
              color: Colors.purpleAccent.withOpacity(0.18),
              size: 240,
            ),
          ),

          SafeArea(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 14 : 18,
                      10,
                      isMobile ? 14 : 18,
                      isMobile ? 14 : 18,
                    ),
                    child: Column(
                      children: [
                        // ✅ Filters (Glass Card) + responsive
                        _Glass(
                          borderRadius: 18,
                          blur: 18,
                          opacity: 0.12,
                          borderOpacity: 0.14,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                decoration: _glassInputDecoration(
                                  hint: "Search Order ID...",
                                  icon: Icons.search,
                                ),
                                style: const TextStyle(color: Colors.white),
                                onChanged: (v) {
                                  if (!mounted) return;
                                  setState(() => searchQuery = v);
                                },
                              ),
                              const SizedBox(height: 12),

                              // ✅ Wrap makes it responsive for mobile/web
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final itemWidth = constraints.maxWidth >= 900
                                      ? (constraints.maxWidth - 24) / 3
                                      : constraints.maxWidth >= 520
                                      ? (constraints.maxWidth - 12) / 2
                                      : constraints.maxWidth;

                                  return Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      SizedBox(
                                        width: itemWidth,
                                        child:
                                            DropdownButtonFormField<
                                              WorkStatus?
                                            >(
                                              value: selectedStatus,
                                              dropdownColor: const Color(
                                                0xFF0F1B33,
                                              ),
                                              decoration:
                                                  _glassDropdownDecoration(
                                                    "Status",
                                                  ),
                                              iconEnabledColor: Colors.white70,
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                              items: [
                                                const DropdownMenuItem(
                                                  value: null,
                                                  child: Text("All Statuses"),
                                                ),
                                                ...WorkStatus.values.map(
                                                  (s) => DropdownMenuItem(
                                                    value: s,
                                                    child: Text(s.name),
                                                  ),
                                                ),
                                              ],
                                              onChanged: (v) {
                                                if (!mounted) return;
                                                setState(
                                                  () => selectedStatus = v,
                                                );
                                              },
                                            ),
                                      ),
                                      SizedBox(
                                        width: itemWidth,
                                        child: DropdownButtonFormField<Department?>(
                                          value: selectedDepartment,
                                          dropdownColor: const Color(
                                            0xFF0F1B33,
                                          ),
                                          decoration: _glassDropdownDecoration(
                                            "Department",
                                          ),
                                          iconEnabledColor: Colors.white70,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          items: [
                                            const DropdownMenuItem(
                                              value: null,
                                              child: Text("All Departments"),
                                            ),
                                            ...Department.values.map(
                                              (d) => DropdownMenuItem(
                                                value: d,
                                                child: Text(
                                                  d.name
                                                      .toUpperCase(), // 👈 VISUAL ONLY
                                                  style: const TextStyle(
                                                    letterSpacing: 0.6,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                          onChanged: (value) async {
                                            if (!mounted) return;
                                            setState(
                                              () => selectedDepartment = value,
                                            );
                                            await fetchOrders();
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        width: itemWidth,
                                        child: InkWell(
                                          onTap: pickStartDate,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: _Glass(
                                            borderRadius: 14,
                                            blur: 16,
                                            opacity: 0.10,
                                            borderOpacity: 0.12,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.date_range,
                                                  size: 18,
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    startDate == null
                                                        ? "Start Date: Any"
                                                        : "Start Date: ${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}",
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.85),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ✅ Table (Glass Card)
                        Expanded(
                          child: _Glass(
                            borderRadius: 18,
                            blur: 18,
                            opacity: 0.10,
                            borderOpacity: 0.14,
                            padding: const EdgeInsets.all(0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  dividerColor: Colors.white.withOpacity(0.06),
                                  textTheme: Theme.of(context).textTheme.apply(
                                    bodyColor: Colors.white,
                                    displayColor: Colors.white,
                                  ),
                                ),
                                child: PaginatedDataTable2(
                                  showCheckboxColumn: false,
                                  wrapInCard: false,
                                  rowsPerPage: isMobile ? 6 : 8,
                                  minWidth: isMobile
                                      ? 980
                                      : 980, // keep scroll for small screens
                                  columnSpacing: 14,
                                  horizontalMargin: 16,
                                  headingRowHeight: 52,
                                  dataRowHeight: 56,

                                  // ✅ frosted header feel
                                  headingRowColor: MaterialStateProperty.all(
                                    Colors.white.withOpacity(0.06),
                                  ),
                                  headingTextStyle: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withOpacity(0.9),
                                    letterSpacing: 0.2,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text("S#")),
                                    DataColumn(label: Text("Order ID")),
                                    DataColumn(label: Text("Dept")),
                                    DataColumn(label: Text("Manager")),
                                    DataColumn(label: Text("Date In")),
                                    DataColumn(label: Text("Time In")),
                                    DataColumn(label: Text("Running")),
                                    DataColumn(label: Text("Date Out")),
                                    DataColumn(label: Text("Time Out")),
                                    DataColumn(label: Text("Status")),
                                    DataColumn(label: Text("")),
                                  ],
                                  source: OrdersDataSource(
                                    filteredOrders,
                                    context,
                                    blue,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ✅ Glass input styling
  InputDecoration _glassInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.55)),
      prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.65)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.customBlueColor.withOpacity(0.7),
          width: 1.2,
        ),
      ),
    );
  }

  InputDecoration _glassDropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.customBlueColor.withOpacity(0.7),
          width: 1.2,
        ),
      ),
    );
  }
}

/// ✅ reusable glass container
class _Glass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final double blur;
  final double opacity;
  final double borderOpacity;

  const _Glass({
    required this.child,
    this.borderRadius = 18,
    this.padding = const EdgeInsets.all(16),
    this.blur = 18,
    this.opacity = 0.12,
    this.borderOpacity = 0.14,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(borderOpacity)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(blurRadius: 60, spreadRadius: 18, color: color)],
      ),
    );
  }
}
