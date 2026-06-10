import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/services/new_order_service.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/utils/work_duration_formatter.dart';
import 'package:fabri_sync/widgets/custom_appBar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final supabase = Supabase.instance.client;
  final NewOrderService orderService = NewOrderService();
  late OrderModel order;
  bool pageLoading = false;
  Map<String, dynamic>? costBreakdown;
  List<Map<String, dynamic>> departmentSchedule = [];
  List<Map<String, dynamic>> orderItems = [];
  List<Map<String, dynamic>> itemProgressRows = [];
  List<Map<String, dynamic>> progressLogs = [];
  Map<String, String> profileNamesById = {};
  String? trackingError;

  static const double kTabletBp = 600;
  static const double kDesktopBp = 1024;
  static const List<String> _canonicalDepartments = [
    'CUTTING',
    'STITCHING',
    'THREADING',
    'QUALITY_CONTROL',
    'PACKAGING',
    'INSPECTION',
  ];

  @override
  void initState() {
    super.initState();
    order = widget.order;
    _fetchLatestOrder();
  }

  Future<void> _fetchLatestOrder() async {
    setState(() => pageLoading = true);
    try {
      final res = await supabase
          .from('ordersmain')
          .select()
          .eq('order_id', order.orderId)
          .maybeSingle();

      if (res != null && mounted) {
        setState(() {
          order = OrderModel.fromMap(res);
        });
      }

      final cost = await orderService.fetchCostBreakdown(order.orderId);
      final schedule = await orderService.fetchDepartmentSchedule(
        order.orderId,
      );
      final tracking = await _fetchTrackingData(order.orderId);

      if (mounted) {
        setState(() {
          costBreakdown = cost;
          departmentSchedule = schedule;
          orderItems = tracking.items;
          itemProgressRows = tracking.progressRows;
          progressLogs = tracking.logs;
          profileNamesById = tracking.profileNamesById;
          trackingError = tracking.error;
        });
      }
    } catch (e) {
      debugPrint("Fetch latest order error: $e");
    } finally {
      if (mounted) setState(() => pageLoading = false);
    }
  }

  Future<_AdminTrackingData> _fetchTrackingData(String orderId) async {
    try {
      final itemsRaw = await supabase
          .from('order_items')
          .select()
          .eq('order_id', orderId)
          .order('item_no', ascending: true);

      final progressRaw = await supabase
          .from('item_department_progress')
          .select()
          .eq('order_id', orderId)
          .order('sequence_number', ascending: true)
          .order('created_at', ascending: true);

      final logsRaw = await supabase
          .from('item_progress_logs')
          .select()
          .eq('order_id', orderId)
          .order('created_at', ascending: false);

      final items = (itemsRaw as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      final progressRows = (progressRaw as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      final logs = (logsRaw as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

      final profileIds = <String>{
        ...progressRows
            .map((row) => (row['completed_by'] ?? '').toString())
            .where((id) => id.isNotEmpty),
        ...logs
            .map((row) => (row['actor_profile_id'] ?? '').toString())
            .where((id) => id.isNotEmpty),
      }.toList();

      final names = <String, String>{};
      if (profileIds.isNotEmpty) {
        final profilesRaw = await supabase
            .from('profiles')
            .select('id, full_name, email')
            .inFilter('id', profileIds);

        for (final row in (profilesRaw as List)) {
          final map = Map<String, dynamic>.from(row);
          final id = (map['id'] ?? '').toString();
          final name = (map['full_name'] ?? map['email'] ?? '').toString();
          if (id.isNotEmpty && name.isNotEmpty) names[id] = name;
        }
      }

      return _AdminTrackingData(
        items: items,
        progressRows: progressRows,
        logs: logs,
        profileNamesById: names,
      );
    } catch (e) {
      debugPrint("Fetch tracking data error: $e");
      return _AdminTrackingData.empty(error: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: buildGradientAppBar("Order Details"),
      body: gradientOrderBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final bool isDesktop = w >= kDesktopBp;
              final bool isTablet = w >= kTabletBp && w < kDesktopBp;

              final double horizontalPadding = isDesktop
                  ? 32
                  : isTablet
                  ? 24
                  : 16;
              final double verticalPadding = isDesktop
                  ? 28
                  : isTablet
                  ? 22
                  : 16;
              final double maxContentWidth = isDesktop
                  ? 760
                  : isTablet
                  ? 560
                  : double.infinity;
              final double rowFont = isDesktop ? 14 : 13;
              final double cardTitleFont = isDesktop ? 15 : 14;
              final double cardValueFont = isDesktop ? 20 : 18;
              final double avatarRadius = isDesktop ? 30 : 28;
              final double iconSize = isDesktop ? 30 : 28;

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContentWidth),
                        child: Container(
                          padding: EdgeInsets.all(isDesktop ? 28 : 24),
                          decoration: AppDecorations.surface(radius: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (pageLoading) ...[
                                const SizedBox(height: 6),
                                const LinearProgressIndicator(minHeight: 2),
                                const SizedBox(height: 18),
                              ],
                              if (isTablet || isDesktop)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 6,
                                      child: _summaryCard(rowFont),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 5,
                                      child: Column(
                                        children: [
                                          _metricCard(
                                            title: "Estimated Time",
                                            value: formatWorkDuration(
                                              order.estimatedTime,
                                            ),
                                            icon: Icons.access_time,
                                            accent: AppColors.accentBlue,
                                            titleFont: cardTitleFont,
                                            valueFont: cardValueFont,
                                            avatarRadius: avatarRadius,
                                            iconSize: iconSize,
                                          ),
                                          const SizedBox(height: 14),
                                          _metricCard(
                                            title: "Estimated Cost",
                                            value:
                                                "PKR ${order.estimatedCost.toStringAsFixed(0)}",
                                            icon: Icons.currency_rupee,
                                            accent: AppColors.accentOrange,
                                            titleFont: cardTitleFont,
                                            valueFont: cardValueFont,
                                            avatarRadius: avatarRadius,
                                            iconSize: iconSize,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                _summaryCard(rowFont),
                                const SizedBox(height: 18),
                                _metricCard(
                                  title: "Estimated Time",
                                  value: formatWorkDuration(
                                    order.estimatedTime,
                                  ),
                                  icon: Icons.access_time,
                                  accent: AppColors.accentBlue,
                                  titleFont: cardTitleFont,
                                  valueFont: cardValueFont,
                                  avatarRadius: avatarRadius,
                                  iconSize: iconSize,
                                ),
                                const SizedBox(height: 14),
                                _metricCard(
                                  title: "Estimated Cost",
                                  value:
                                      "PKR ${order.estimatedCost.toStringAsFixed(0)}",
                                  icon: Icons.currency_rupee,
                                  accent: AppColors.accentOrange,
                                  titleFont: cardTitleFont,
                                  valueFont: cardValueFont,
                                  avatarRadius: avatarRadius,
                                  iconSize: iconSize,
                                ),
                              ],
                              if (_hasProductDetails) ...[
                                const SizedBox(height: 18),
                                _productDetailsCard(rowFont),
                              ],
                              if (costBreakdown != null) ...[
                                const SizedBox(height: 18),
                                _costBreakdownCard(rowFont),
                              ],
                              if (departmentSchedule.isNotEmpty) ...[
                                const SizedBox(height: 18),
                                _scheduleCard(rowFont),
                              ],
                              const SizedBox(height: 18),
                              _trackingCard(rowFont),
                            ],
                          ),
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

  Widget _summaryCard(double rowFont) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.softPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _row("Order ID", order.orderId, fontSize: rowFont),
          _row(
            "Department",
            _departmentLabel(order.currentDepartment),
            fontSize: rowFont,
          ),
          _row("Quantity", order.quantity.toString(), fontSize: rowFont),
          _row(
            "Date",
            DateFormat("dd MMM yyyy").format(order.createdAt),
            fontSize: rowFont,
          ),
          _row(
            "Time",
            DateFormat("hh:mm a").format(order.createdAt),
            fontSize: rowFont,
          ),
          _row("Status", order.status, fontSize: rowFont),
        ],
      ),
    );
  }

  bool get _hasProductDetails {
    return order.productCategory != null ||
        order.productType != null ||
        order.requiredDeliveryDate != null ||
        order.qualityGrade != null ||
        order.priority != null ||
        order.productSpecifications.isNotEmpty;
  }

  Widget _productDetailsCard(double rowFont) {
    final specs = order.productSpecifications.entries
        .where((e) => e.value != null && e.value.toString().trim().isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.softPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Product Details",
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _row("Category", order.productCategory ?? "-", fontSize: rowFont),
          _row("Type", order.productType ?? "-", fontSize: rowFont),
          _row(
            "Delivery",
            order.requiredDeliveryDate != null
                ? DateFormat("dd MMM yyyy").format(order.requiredDeliveryDate!)
                : "-",
            fontSize: rowFont,
          ),
          _row("Quality", order.qualityGrade ?? "-", fontSize: rowFont),
          _row("Priority", order.priority ?? "-", fontSize: rowFont),
          _row(
            "Custom Packaging",
            order.customPackaging ? "Yes" : "No",
            fontSize: rowFont,
          ),
          if ((order.specialInstructions ?? '').trim().isNotEmpty)
            _row("Instructions", order.specialInstructions!, fontSize: rowFont),
          if (specs.isNotEmpty) ...[
            const Divider(color: AppColors.divider),
            ...specs.map((e) {
              var displayValue = e.value is bool
                  ? ((e.value as bool) ? "Yes" : "No")
                  : e.value.toString();
              // Add unit suffix for curtain dimensions
              if (order.productCategory == 'Curtain' &&
                  (e.key == 'length' || e.key == 'width')) {
                displayValue = '$displayValue m';
              }
              return _row(_prettyKey(e.key), displayValue, fontSize: rowFont);
            }),
          ],
        ],
      ),
    );
  }

  Widget _costBreakdownCard(double rowFont) {
    double numValue(String key) =>
        (costBreakdown?[key] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.softPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Cost Breakdown",
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _row(
            "Material",
            "PKR ${numValue('material_total_cost').toStringAsFixed(0)}",
            fontSize: rowFont,
          ),
          _row(
            "Labor",
            "PKR ${numValue('labor_total_cost').toStringAsFixed(0)}",
            fontSize: rowFont,
          ),
          _row(
            "Processing",
            "PKR ${numValue('processing_total_cost').toStringAsFixed(0)}",
            fontSize: rowFont,
          ),
          _row(
            "Additional",
            "PKR ${numValue('additional_total_cost').toStringAsFixed(0)}",
            fontSize: rowFont,
          ),
          _row(
            "Rush Charges",
            "PKR ${numValue('rush_charges').toStringAsFixed(0)}",
            fontSize: rowFont,
          ),
          const Divider(color: AppColors.divider),
          _row(
            "Estimated Total",
            "PKR ${numValue('estimated_total_cost').toStringAsFixed(0)}",
            fontSize: rowFont,
          ),
        ],
      ),
    );
  }

  Widget _scheduleCard(double rowFont) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.softPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Production Schedule",
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...departmentSchedule.map((row) {
            final department = _departmentLabel(row['department']?.toString());
            final start = _formatDate(row['planned_start_date']);
            final end = _formatDate(row['planned_end_date']);
            final hours = (row['expected_hours'] as num?)?.toDouble() ?? 0.0;
            return _row(
              department,
              "$start - $end (${formatWorkDuration(hours)})",
              fontSize: rowFont,
            );
          }),
        ],
      ),
    );
  }

  Widget _trackingCard(double rowFont) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.softPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Production Tracking",
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (trackingError != null) ...[
            _infoNotice(
              icon: Icons.error_outline,
              color: AppColors.error,
              text: "Unable to load tracking details: $trackingError",
            ),
            const SizedBox(height: 12),
          ],
          if (orderItems.isEmpty) ...[
            _emptyNotice(
              "No generated items found for this order yet.",
              Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 12),
          ],
          ..._canonicalDepartments.map(
            (department) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _departmentTrackingTile(department, rowFont),
            ),
          ),
          const SizedBox(height: 6),
          _timelineSection(),
        ],
      ),
    );
  }

  Widget _departmentTrackingTile(String department, double rowFont) {
    final schedule = _scheduleForDepartment(department);
    final progressRows = _progressRowsForDepartment(department);
    final progressByItemId = _progressByItemId(progressRows);
    final total = orderItems.length;
    final completed = _completedCount(progressRows);
    final pending = total - completed < 0 ? 0 : total - completed;
    final progress = total <= 0 ? 0.0 : completed / total;
    final delayReason = (schedule?['delay_reason'] ?? '').toString().trim();
    final delayRemarks = _delayRemarksText(department);

    return Container(
      decoration: AppDecorations.surface(radius: 16, elevated: false),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        initiallyExpanded:
            department == _normalizeDepartment(order.currentDepartment),
        title: Text(
          _departmentLabel(department),
          style: const TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0).toDouble(),
                  minHeight: 7,
                  backgroundColor: AppColors.border,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _miniChip("Total", "$total"),
                  _miniChip("Completed", "$completed"),
                  _miniChip("Pending", "$pending"),
                  _miniChip(
                    "Progress",
                    "${(progress * 100).toStringAsFixed(0)}%",
                  ),
                  _miniChip("Status", _statusLabel(schedule?['status'])),
                ],
              ),
            ],
          ),
        ),
        children: [
          _departmentMetaRows(schedule, rowFont),
          if (delayReason.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoNotice(
              icon: Icons.warning_amber_rounded,
              color: AppColors.accentOrange,
              text: "Delay reason: $delayReason",
            ),
          ],
          if (delayRemarks.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoNotice(
              icon: Icons.notes_outlined,
              color: AppColors.accentBlue,
              text: "Delay remarks: $delayRemarks",
            ),
          ],
          const SizedBox(height: 12),
          if (orderItems.isEmpty)
            _emptyNotice(
              "No item records are available for this order.",
              Icons.inventory_outlined,
            )
          else
            ...orderItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _itemProgressRow(
                  item: item,
                  progress: progressByItemId[(item['id'] ?? '').toString()],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _departmentMetaRows(Map<String, dynamic>? schedule, double rowFont) {
    if (schedule == null) {
      return _emptyNotice(
        "No department workflow row found yet.",
        Icons.route_outlined,
      );
    }

    final expectedHours = (schedule['expected_hours'] as num?)?.toDouble();
    return Column(
      children: [
        _row(
          "Expected",
          expectedHours == null ? "-" : formatWorkDuration(expectedHours),
          fontSize: rowFont,
        ),
        _row(
          "Started",
          _dateTimePair(schedule['date_in'], schedule['time_in']),
          fontSize: rowFont,
        ),
        _row(
          "Completed",
          _dateTimePair(schedule['date_out'], schedule['time_out']),
          fontSize: rowFont,
        ),
      ],
    );
  }

  Widget _itemProgressRow({
    required Map<String, dynamic> item,
    required Map<String, dynamic>? progress,
  }) {
    final itemCode = (item['item_code'] ?? '').toString();
    final itemNo = (item['item_no'] as num?)?.toInt() ?? 0;
    final status = (progress?['status'] ?? 'pending').toString();
    final completedBy = (progress?['completed_by'] ?? '').toString();
    final completedByName = profileNamesById[completedBy] ?? completedBy;
    final completed = status.toLowerCase() == 'completed';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.softPanel(radius: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 190,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemCode.isEmpty ? "-" : itemCode,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Item #$itemNo",
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _statusPill(
            completed ? "Completed" : "Pending",
            completed ? AppColors.success : AppColors.warning,
          ),
          SizedBox(
            width: 155,
            child: Text(
              completed ? _formatDateTime(progress?['completed_at']) : "-",
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 155,
            child: Text(
              completedByName.isEmpty ? "-" : completedByName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineSection() {
    final itemCodeById = {
      for (final item in orderItems)
        (item['id'] ?? '').toString(): (item['item_code'] ?? '').toString(),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tracking Timeline",
          style: TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (progressLogs.isEmpty)
          _emptyNotice("No progress logs found yet.", Icons.timeline_outlined)
        else
          ...progressLogs.map(
            (log) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _timelineRow(log, itemCodeById),
            ),
          ),
      ],
    );
  }

  Widget _timelineRow(
    Map<String, dynamic> log,
    Map<String, String> itemCodeById,
  ) {
    final itemId = (log['item_id'] ?? '').toString();
    final actorId = (log['actor_profile_id'] ?? '').toString();
    final actor = profileNamesById[actorId] ?? actorId;
    final delayReason = (log['delay_reason'] ?? '').toString().trim();
    final remarks = (log['remarks'] ?? '').toString().trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.softPanel(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _eventLabel((log['event_type'] ?? '').toString()),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatDateTime(log['created_at']),
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _miniChip(
                "Department",
                _departmentLabel(log['department']?.toString()),
              ),
              _miniChip(
                "Item",
                itemCodeById[itemId]?.isNotEmpty == true
                    ? itemCodeById[itemId]!
                    : "-",
              ),
              _miniChip("Actor", actor.isEmpty ? "-" : actor),
            ],
          ),
          if (delayReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "Delay reason: $delayReason",
              style: const TextStyle(
                color: AppColors.accentOrange,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (remarks.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              "Remarks: $remarks",
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, {double fontSize = 13}) {
    final labelStyle = TextStyle(
      color: AppColors.secondaryText,
      fontSize: fontSize,
    );

    final valueStyle = TextStyle(
      color: AppColors.primaryText,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: labelStyle, softWrap: true),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: valueStyle,
                textAlign: TextAlign.right,
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
    required double titleFont,
    required double valueFont,
    required double avatarRadius,
    required double iconSize,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.surface(radius: 18),
      child: Row(
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: accent.withOpacity(0.14),
            child: Icon(icon, color: accent, size: iconSize),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: titleFont,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: valueFont,
                    fontWeight: FontWeight.bold,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: AppDecorations.surface(radius: 999, elevated: false),
      child: Text(
        "$label: $value",
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.primaryText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: AppDecorations.accentFill(color, radius: 999),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _emptyNotice(String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.surface(radius: 14, elevated: false),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.secondaryText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoNotice({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.accentFill(color, radius: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _scheduleForDepartment(String department) {
    final normalized = _normalizeDepartment(department);
    for (final row in departmentSchedule) {
      if (_normalizeDepartment(row['department']) == normalized) return row;
    }
    return null;
  }

  List<Map<String, dynamic>> _progressRowsForDepartment(String department) {
    final normalized = _normalizeDepartment(department);
    return itemProgressRows
        .where((row) => _normalizeDepartment(row['department']) == normalized)
        .toList();
  }

  Map<String, Map<String, dynamic>> _progressByItemId(
    List<Map<String, dynamic>> rows,
  ) {
    final byItemId = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final itemId = (row['item_id'] ?? '').toString();
      if (itemId.isNotEmpty) byItemId[itemId] = row;
    }
    return byItemId;
  }

  int _completedCount(List<Map<String, dynamic>> rows) {
    return rows
        .where((row) => (row['status'] ?? '').toString() == 'completed')
        .map((row) => (row['item_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet()
        .length;
  }

  String _delayRemarksText(String department) {
    final normalized = _normalizeDepartment(department);
    final remarks = progressLogs
        .where((log) {
          final event = (log['event_type'] ?? '').toString();
          return _normalizeDepartment(log['department']) == normalized &&
              (event == 'department_completed' || event == 'delay_recorded') &&
              (log['remarks'] ?? '').toString().trim().isNotEmpty;
        })
        .map((log) => (log['remarks'] ?? '').toString().trim())
        .toList();
    return remarks.join(" | ");
  }

  String _normalizeDepartment(dynamic value) {
    final dept = (value ?? '').toString().trim().toUpperCase();
    if (dept == 'QUALITY CONTROL') return 'QUALITY_CONTROL';
    if (dept == 'PACKING') return 'PACKAGING';
    return dept.replaceAll(' ', '_');
  }

  String _statusLabel(dynamic value) {
    final status = (value ?? '').toString().trim().toLowerCase();
    if (status.isEmpty) return "-";
    if (status == "inprogress") return "In Progress";
    return status[0].toUpperCase() + status.substring(1);
  }

  String _eventLabel(String value) {
    switch (value) {
      case 'item_created':
        return 'Item created';
      case 'item_started':
        return 'Item started';
      case 'item_completed':
        return 'Item completed';
      case 'department_completed':
        return 'Department completed';
      case 'delay_recorded':
        return 'Delay recorded';
      case 'remark_added':
        return 'Remark added';
      default:
        return value.replaceAll('_', ' ');
    }
  }

  String _dateTimePair(dynamic dateValue, dynamic timeValue) {
    final date = _formatDate(dateValue);
    final time = _formatTime(timeValue);
    if (date == '-' && time == '-') return '-';
    if (date == '-') return time;
    if (time == '-') return date;
    return "$date $time";
  }

  String _formatTime(dynamic value) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty) return '-';
    final parts = text.split(':');
    if (parts.length < 2) return text;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return text;
    return DateFormat("hh:mm a").format(DateTime(2000, 1, 1, hour, minute));
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return '-';
    final date = value is DateTime
        ? value
        : DateTime.tryParse(value.toString());
    if (date == null) return '-';
    return DateFormat("dd MMM yyyy, hh:mm a").format(date.toLocal());
  }

  String _prettyKey(String key) {
    final words = key.split('_');
    return words
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  String _departmentLabel(String? value) {
    final dept = (value ?? '').trim().toUpperCase();
    if (dept == 'QUALITY_CONTROL') return 'Quality Control';
    if (dept == 'PACKAGING') return 'Packaging';
    if (dept.isEmpty) return '-';
    return dept[0] + dept.substring(1).toLowerCase();
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return '-';
    return DateFormat("dd MMM yyyy").format(date);
  }
}

class _AdminTrackingData {
  const _AdminTrackingData({
    required this.items,
    required this.progressRows,
    required this.logs,
    required this.profileNamesById,
    this.error,
  });

  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> progressRows;
  final List<Map<String, dynamic>> logs;
  final Map<String, String> profileNamesById;
  final String? error;

  factory _AdminTrackingData.empty({String? error}) {
    return _AdminTrackingData(
      items: const [],
      progressRows: const [],
      logs: const [],
      profileNamesById: const {},
      error: error,
    );
  }
}
