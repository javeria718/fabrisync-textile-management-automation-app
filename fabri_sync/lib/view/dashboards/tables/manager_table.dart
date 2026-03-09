import 'dart:ui';

import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/view/dashboards/tables/maanger_datasource.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerDepartmentTableScreen extends StatefulWidget {
  final String department; // MUST be uppercase e.g. CUTTING

  const ManagerDepartmentTableScreen({super.key, required this.department});

  @override
  State<ManagerDepartmentTableScreen> createState() =>
      _ManagerDepartmentTableScreenState();
}

class _ManagerDepartmentTableScreenState
    extends State<ManagerDepartmentTableScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  List<Map<String, dynamic>> allRows = [];
  List<Map<String, dynamic>> rows = [];

  String searchQuery = "";
  String? selectedStatus; // pending | inprogress | completed
  DateTime? startDate;

  RealtimeChannel? channel;

  @override
  void initState() {
    super.initState();
    fetchRows();
    setupRealtime();
  }

  void applyFilters() {
    final filtered = allRows.where((r) {
      final orderId = (r['order_id'] ?? '').toString().toLowerCase();
      final matchesSearch = orderId.contains(searchQuery.toLowerCase());

      final status = (r['status'] ?? '').toString().toLowerCase();
      final matchesStatus =
          selectedStatus == null ||
          selectedStatus!.isEmpty ||
          status == selectedStatus!.toLowerCase();

      bool matchesDate = true;
      if (startDate != null && r['date_in'] != null) {
        final d = DateTime.parse(r['date_in'].toString());
        matchesDate = !d.isBefore(startDate!);
      }

      return matchesSearch && matchesStatus && matchesDate;
    }).toList();

    if (!mounted) return;
    setState(() => rows = filtered);
  }

  Future<void> fetchRows() async {
    setState(() => loading = true);

    try {
      var query = supabase
          .from('department_orders')
          .select()
          .eq('department', widget.department);

      final data = await query
          .order('date_in', ascending: false)
          .order('time_in', ascending: false);

      final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
        data,
      );

      if (!mounted) return;
      setState(() {
        allRows = list;
        loading = false;
      });
      applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  void setupRealtime() {
    channel = supabase
        .channel('mgr-table-${widget.department}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'department_orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'department',
            value: widget.department,
          ),
          callback: (_) => fetchRows(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (channel != null) supabase.removeChannel(channel!);
    super.dispose();
  }

  Future<void> pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: startDate ?? DateTime.now(),
    );
    if (date != null) {
      setState(() => startDate = date);
      applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0A4DAB);

    final media = MediaQuery.of(context);
    final isMobile = media.size.width < 700;

    return Scaffold(
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
        title: Text(
          "${widget.department} ",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
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
          // ✅ background gradient
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
          // ✅ glow blobs
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
                        // ✅ Filter glass card (responsive)
                        _Glass(
                          borderRadius: 18,
                          blur: 18,
                          opacity: 0.12,
                          borderOpacity: 0.14,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              TextField(
                                decoration: _glassInputDecoration(
                                  hint: "Search Order ID...",
                                  icon: Icons.search,
                                  blue: blue,
                                ),
                                style: const TextStyle(color: Colors.white),
                                onChanged: (v) {
                                  setState(() => searchQuery = v);
                                  applyFilters();
                                },
                              ),
                              const SizedBox(height: 12),

                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final itemWidth = constraints.maxWidth >= 760
                                      ? (constraints.maxWidth - 12) / 2
                                      : constraints.maxWidth;

                                  return Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      SizedBox(
                                        width: itemWidth,
                                        child: DropdownButtonFormField<String?>(
                                          value: selectedStatus,
                                          dropdownColor: const Color(
                                            0xFF0F1B33,
                                          ),
                                          iconEnabledColor: Colors.white70,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          decoration: _glassDropdownDecoration(
                                            "Status",
                                            blue,
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: null,
                                              child: Text("All Statuses"),
                                            ),
                                            DropdownMenuItem(
                                              value: "pending",
                                              child: Text("pending"),
                                            ),
                                            DropdownMenuItem(
                                              value: "inprogress",
                                              child: Text("inprogress"),
                                            ),
                                            DropdownMenuItem(
                                              value: "completed",
                                              child: Text("completed"),
                                            ),
                                          ],
                                          onChanged: (v) {
                                            setState(() => selectedStatus = v);
                                            applyFilters();
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

                        // ✅ Table glass card
                        Expanded(
                          child: _Glass(
                            borderRadius: 18,
                            blur: 18,
                            opacity: 0.10,
                            borderOpacity: 0.14,
                            padding: EdgeInsets.zero,
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
                                  minWidth:
                                      920, // keep scroll for small screens
                                  columnSpacing: 14,
                                  horizontalMargin: 16,
                                  headingRowHeight: 52,
                                  dataRowHeight: 56,
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
                                    DataColumn(label: Text("Date In")),
                                    DataColumn(label: Text("Time In")),
                                    DataColumn(label: Text("Expected Hours")),
                                    DataColumn(label: Text("Date Out")),
                                    DataColumn(label: Text("Time Out")),
                                    DataColumn(label: Text("Status")),
                                  ],
                                  source: ManagerOrdersDataSource(rows),
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

  InputDecoration _glassInputDecoration({
    required String hint,
    required IconData icon,
    required Color blue,
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
        borderSide: BorderSide(color: blue.withOpacity(0.7), width: 1.2),
      ),
    );
  }

  InputDecoration _glassDropdownDecoration(String label, Color blue) {
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
        borderSide: BorderSide(color: blue.withOpacity(0.7), width: 1.2),
      ),
    );
  }
}

/// ✅ same glass helper (same as admin table version)
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
