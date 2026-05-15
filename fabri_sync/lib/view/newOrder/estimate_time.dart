import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/controllers/new_order/order_input_controller.dart';
import 'package:fabri_sync/services/order_calculation_service.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/utils/work_duration_formatter.dart';
import 'package:fabri_sync/view/newOrder/estimate_cost.dart';
import 'package:fabri_sync/widgets/custom_appBar.dart';
import 'package:fabri_sync/widgets/new_order_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EstimateTimeScreen extends StatefulWidget {
  const EstimateTimeScreen({
    super.key,
    required this.controller,
    this.existingOrder,
    this.isEditing = false,
  });

  final OrderInputController controller;
  final OrderModel? existingOrder;
  final bool isEditing;

  @override
  State<EstimateTimeScreen> createState() => _EstimateTimeScreenState();
}

class _EstimateTimeScreenState extends State<EstimateTimeScreen> {
  OrderInputController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculate());
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  Future<void> _calculate() async {
    final error = await controller.calculateOrder();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  void _next() {
    if (controller.calculation == null) {
      _calculate();
      if (controller.calculation == null) return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstimateCostScreen(
          controller: controller,
          existingOrder: widget.existingOrder,
          isEditing: widget.isEditing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = controller.calculation;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: buildGradientAppBar(
        widget.isEditing ? 'Edit Order' : 'New Order',
      ),
      body: gradientOrderBackground(
        child: SafeArea(
          child: OrderWizardShell(
            stepLabel: 'Step 3 of 5',
            children: [
              OrderStepCard(
                title: 'Estimated Production Time',
                icon: Icons.schedule_outlined,
                child: result == null
                    ? const OrderEmptyState(text: 'Calculating...')
                    : OrderFieldWrap(
                        children: [
                          _MetricTile(
                            label: 'Production Hours',
                            value: result.estimatedProductionHours
                                .toStringAsFixed(1),
                            icon: Icons.access_time,
                          ),
                          _MetricTile(
                            label: 'Workday Equivalent',
                            value: _formatWorkdayEquivalent(
                              result.estimatedWorkDaysExact,
                            ),
                            icon: Icons.today_outlined,
                          ),
                          _MetricTile(
                            label: 'Priority',
                            value: result.priority,
                            icon: Icons.flag_outlined,
                            accent: result.priority == 'Rush'
                                ? AppColors.accentOrange
                                : AppColors.accentGreen,
                          ),
                        ],
                      ),
              ),
              OrderStepCard(
                title: 'Department Schedule Preview',
                icon: Icons.calendar_month_outlined,
                child: result == null
                    ? const OrderEmptyState(text: 'No schedule yet')
                    : Column(
                        children: result.schedule
                            .map((item) => _ScheduleRow(item: item))
                            .toList(),
                      ),
              ),
              OrderActionBar(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                  ElevatedButton.icon(
                    onPressed: controller.hasValidDeliveryDate ? _next : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = AppColors.primaryAccent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.softPanel(radius: 14),
      child: Row(
        children: [
          Icon(icon, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.item});

  final DepartmentScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.softPanel(radius: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 620;
          final dept = Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryAccent.withOpacity(0.12),
                child: Text(
                  item.sequenceNumber.toString(),
                  style: const TextStyle(
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.departmentLabel,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
          final meta = Text(
            '${formatWorkDuration(item.estimatedHours)}\n${fmt.format(item.plannedStartDate)} - ${fmt.format(item.plannedEndDate)}',
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
            ),
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [dept, const SizedBox(height: 8), meta],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: dept),
              Expanded(flex: 5, child: meta),
            ],
          );
        },
      ),
    );
  }
}

String _formatWorkdayEquivalent(double value) {
  final rounded = value.toStringAsFixed(2);
  return '$rounded ${value <= 1 ? 'workday' : 'workdays'}';
}
