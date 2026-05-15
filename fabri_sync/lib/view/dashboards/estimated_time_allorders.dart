import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/utils/work_duration_formatter.dart';
import 'package:flutter/material.dart';

class EstimatedTimeAllOrdersScreen extends StatelessWidget {
  final List<OrderModel> allOrders;
  final Map<String, Map<String, double>> storedDeptHoursByOrder;
  final BoxDecoration glassCard;

  const EstimatedTimeAllOrdersScreen({
    super.key,
    required this.allOrders,
    required this.storedDeptHoursByOrder,
    required this.glassCard,
  });

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "All Orders - Estimated Time",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
        ),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleOrders = allOrders
        .where((o) => o.status.toLowerCase() != 'draft')
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(context),
      body: gradientOrderBackground(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: visibleOrders.length,
          itemBuilder: (context, i) {
            final o = visibleOrders[i];

            final calculated = _storedDepartmentHoursForOrder(o);
            final hasEstimate = calculated.values.any((hrs) => hrs > 0);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: glassCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order: ${o.orderId}  •  Qty: ${o.quantity}",
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!hasEstimate)
                    const Text(
                      'No stored estimate available',
                      style: TextStyle(color: AppColors.secondaryText),
                    )
                  else
                    ...calculated.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _deptLabel(e.key),
                                style: const TextStyle(
                                  color: AppColors.secondaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  formatWorkDuration(e.value),
                                  style: const TextStyle(
                                    color: AppColors.primaryText,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Map<String, double> _storedDepartmentHoursForOrder(OrderModel order) {
    String norm(String d) => d.trim().toUpperCase().replaceAll(' ', '_');

    final orderedDepts = [
      'CUTTING',
      'STITCHING',
      'THREADING',
      'QUALITY_CONTROL',
      'PACKAGING',
      'INSPECTION',
    ];

    final stored = <String, double>{};
    order.estimatedDeptHours?.forEach((dept, hrs) {
      stored[norm(dept)] = hrs;
    });

    if (stored.values.any((hrs) => hrs > 0)) {
      return {for (final dept in orderedDepts) dept: stored[dept] ?? 0.0};
    }

    storedDeptHoursByOrder[order.orderId]?.forEach((dept, hrs) {
      stored[norm(dept)] = hrs;
    });

    if (stored.values.any((hrs) => hrs > 0)) {
      return {for (final dept in orderedDepts) dept: stored[dept] ?? 0.0};
    }
    return {};
  }

  String _deptLabel(String value) {
    final dept = value.trim().toUpperCase();
    if (dept == 'QUALITY_CONTROL') return 'Quality Control';
    if (dept == 'PACKAGING') return 'Packaging';
    if (dept.isEmpty) return '-';
    return dept;
  }
}
