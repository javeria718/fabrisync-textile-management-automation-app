import 'dart:async';

import 'package:data_table_2/data_table_2.dart';
import 'package:fabri_sync/Model/datamodel.dart';
import 'package:fabri_sync/Model/order_summary_model.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/view/dashboards/tables/manager_datasource.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerDepartmentTableScreen extends StatefulWidget {
  final String department;

  const ManagerDepartmentTableScreen({super.key, required this.department});

  @override
  State<ManagerDepartmentTableScreen> createState() =>
      _ManagerDepartmentTableScreenState();
}

class _ManagerDepartmentTableScreenState
    extends State<ManagerDepartmentTableScreen> {
  final supabase = Supabase.instance.client;

  List<OrderSummaryModel> allOrders = [];
  bool loading = true;
  String? errorMessage;

  WorkStatus? selectedStatus;
  DateTime? startDate;
  String searchQuery = "";

  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
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

  Future<void> fetchOrders() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final data = await supabase
          .from('v_department_orders_full')
          .select()
          .eq('department', widget.department.toUpperCase())
          .neq('order_status', 'draft')
          .order('date_in', ascending: false)
          .order('time_in', ascending: false);

      final rows = List<Map<String, dynamic>>.from(
        (data as List).map((e) => Map<String, dynamic>.from(e)),
      );

      debugPrint('[ManagerOrders] fetched from view: ${rows.length}');

      final parsedOrders = rows.map((row) {
        if (row['date_in'] == null || row['time_in'] == null) {
          debugPrint(
            '[ManagerOrders] missing schedule timestamps for department order '
            '${row['order_id'] ?? 'unknown'} / ${row['department'] ?? 'unknown'}',
          );
          assert(
            row['date_in'] != null && row['time_in'] != null,
            'Missing date_in or time_in for department order row',
          );
        }

        final departmentStatus = (row['status'] ?? '').toString().toLowerCase();
        final progressPercent = departmentStatus == 'completed'
            ? 100.0
            : departmentStatus == 'inprogress'
            ? 50.0
            : 0.0;

        final merged = <String, dynamic>{
          ...row,
          'order_status': row['order_status'],
          'updated_at': row['updated_at'] ?? row['created_at'],
          'completed_departments': departmentStatus == 'completed' ? 1 : 0,
          'total_departments': 1,
          'progress_percent': progressPercent,
        };
        return OrderSummaryModel.fromMap(merged);
      }).toList();

      debugPrint(
        '[ManagerOrders] parsed order objects: '
        '${parsedOrders.map((o) => '${o.orderId}/${o.orderStatus}/${o.currentDepartment}').toList()}',
      );

      if (!mounted) return;
      setState(() {
        allOrders = parsedOrders;
        loading = false;
      });
    } catch (e) {
      debugPrint('[ManagerOrders] fetch error: $e');
      if (!mounted) return;
      setState(() {
        allOrders = [];
        loading = false;
        errorMessage = 'Failed to load orders: $e';
      });
    }
  }

  Future<Map<String, _OrderProgress>> _fetchProgressByOrder(
    List<String> orderIds,
  ) async {
    if (orderIds.isEmpty) return {};

    try {
      final data = await supabase
          .from('department_orders')
          .select('order_id, status')
          .inFilter('order_id', orderIds)
          .eq('department', widget.department.toUpperCase());

      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final item in data as List) {
        final row = Map<String, dynamic>.from(item);
        final orderId = (row['order_id'] ?? '').toString();
        if (orderId.isEmpty) continue;
        grouped.putIfAbsent(orderId, () => []).add(row);
      }

      return grouped.map((orderId, rows) {
        final completed = rows
            .where(
              (row) =>
                  (row['status'] ?? '').toString().toLowerCase() == 'completed',
            )
            .length;
        final total = rows.isEmpty ? 1 : rows.length;
        return MapEntry(
          orderId,
          _OrderProgress(
            completedDepartments: completed,
            totalDepartments: total,
          ),
        );
      });
    } catch (e) {
      debugPrint('[ManagerOrders] progress fetch error: $e');
      rethrow;
    }
  }

  void setupRealtime() {
    _channel?.unsubscribe();

    _channel = supabase
        .channel('manager-table-${widget.department}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'department_orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'department',
            value: widget.department.toUpperCase(),
          ),
          callback: (_) async {
            await fetchOrders();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ordersmain',
          callback: (_) async {
            await fetchOrders();
          },
        )
        .subscribe();
  }

  List<OrderSummaryModel> get filteredOrders {
    final query = searchQuery.trim().toLowerCase();
    final filtered = allOrders.where((o) {
      final matchesSearch =
          query.isEmpty || o.orderId.toLowerCase().contains(query);

      final matchesStatus =
          selectedStatus == null ||
          (o.orderStatus ?? '').toLowerCase() ==
              selectedStatus!.name.toLowerCase();

      final matchesDate =
          startDate == null ||
          (o.createdAt != null && !o.createdAt!.isBefore(startDate!));

      return matchesSearch && matchesStatus && matchesDate;
    }).toList();
    debugPrint(
      '[ManagerOrders] filtered list count: ${filtered.length} '
      '(source: ${allOrders.length}, search: "$searchQuery", '
      'status: ${selectedStatus?.name ?? 'all'}, '
      'startDate: ${startDate?.toIso8601String() ?? 'any'})',
    );
    return filtered;
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
    final media = MediaQuery.of(context);
    final isMobile = media.size.width < 700;
    final visibleOrders = filteredOrders;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.primaryText,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          "${widget.department} Orders",
          style: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: gradientOrderBackground(child: const SizedBox.expand()),
          ),
          SafeArea(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryAccent,
                    ),
                  )
                : errorMessage != null
                ? Center(
                    child: _Panel(
                      elevated: false,
                      child: Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 14 : 18,
                      10,
                      isMobile ? 14 : 18,
                      isMobile ? 14 : 18,
                    ),
                    child: Column(
                      children: [
                        _Panel(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                decoration: _inputDecoration(
                                  hint: "Search Order ID...",
                                  icon: Icons.search,
                                ),
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                ),
                                onChanged: (v) {
                                  if (!mounted) return;
                                  setState(() => searchQuery = v);
                                },
                              ),
                              const SizedBox(height: 12),
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
                                              dropdownColor: AppColors.surface,
                                              decoration: _dropdownDecoration(
                                                "Status",
                                              ),
                                              iconEnabledColor:
                                                  AppColors.secondaryText,
                                              style: const TextStyle(
                                                color: AppColors.primaryText,
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
                                        child: InkWell(
                                          onTap: pickStartDate,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: _Panel(
                                            radius: 14,
                                            color: AppColors.surfaceMuted,
                                            elevated: false,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.date_range,
                                                  size: 18,
                                                  color:
                                                      AppColors.secondaryText,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    startDate == null
                                                        ? "Start Date: Any"
                                                        : "Start Date: ${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}",
                                                    style: const TextStyle(
                                                      color:
                                                          AppColors.primaryText,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.arrow_drop_down,
                                                  color:
                                                      AppColors.secondaryText,
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
                        Expanded(
                          child: _Panel(
                            padding: EdgeInsets.zero,
                            child: visibleOrders.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No orders found',
                                      style: TextStyle(
                                        color: AppColors.secondaryText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        dividerColor: AppColors.divider,
                                        textTheme: Theme.of(context).textTheme
                                            .apply(
                                              bodyColor: AppColors.primaryText,
                                              displayColor:
                                                  AppColors.primaryText,
                                            ),
                                      ),
                                      child: PaginatedDataTable2(
                                        showCheckboxColumn: false,
                                        wrapInCard: false,
                                        rowsPerPage: isMobile ? 6 : 8,
                                        minWidth: 1200,
                                        columnSpacing: 14,
                                        horizontalMargin: 16,
                                        headingRowHeight: 52,
                                        dataRowHeight: 64,
                                        headingRowColor:
                                            MaterialStateProperty.all(
                                              AppColors.surfaceMuted,
                                            ),
                                        headingTextStyle: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryText,
                                          letterSpacing: 0.2,
                                        ),
                                        columns: const [
                                          DataColumn(label: Text("S#")),
                                          DataColumn(label: Text("Order ID")),
                                          DataColumn(label: Text("Product")),
                                          DataColumn(label: Text("Quantity")),
                                          DataColumn(label: Text("Priority")),
                                          DataColumn(label: Text("Progress")),
                                          DataColumn(label: Text("Date In")),
                                          DataColumn(label: Text("Time In")),
                                          DataColumn(
                                            label: Text("Expected Hours"),
                                          ),
                                          DataColumn(label: Text("Date Out")),
                                          DataColumn(label: Text("Time Out")),
                                          DataColumn(label: Text("Status")),
                                        ],
                                        source: ManagerOrdersDataSource(
                                          visibleOrders,
                                          context,
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

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.secondaryText),
      prefixIcon: Icon(icon, color: AppColors.secondaryText),
      filled: true,
      fillColor: AppColors.surfaceMuted,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.secondaryText),
      filled: true,
      fillColor: AppColors.surfaceMuted,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
    );
  }
}

class _OrderProgress {
  const _OrderProgress({
    required this.completedDepartments,
    required this.totalDepartments,
  });

  final int completedDepartments;
  final int totalDepartments;

  double get progressPercent {
    if (totalDepartments <= 0) return 0;
    return (completedDepartments / totalDepartments) * 100;
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Color color;
  final bool elevated;

  const _Panel({
    required this.child,
    this.radius = 18,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.surface,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: AppDecorations.surface(
        radius: radius,
        color: color,
        elevated: elevated,
      ),
      child: child,
    );
  }
}
