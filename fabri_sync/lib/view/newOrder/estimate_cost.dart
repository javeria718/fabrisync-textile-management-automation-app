import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/controllers/new_order/order_input_controller.dart';
import 'package:fabri_sync/services/order_calculation_service.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/view/newOrder/order_summary.dart';
import 'package:fabri_sync/widgets/custom_appBar.dart';
import 'package:fabri_sync/widgets/new_order_widgets.dart';
import 'package:flutter/material.dart';

class EstimateCostScreen extends StatefulWidget {
  const EstimateCostScreen({
    super.key,
    required this.controller,
    this.existingOrder,
    this.isEditing = false,
  });

  final OrderInputController controller;
  final OrderModel? existingOrder;
  final bool isEditing;

  @override
  State<EstimateCostScreen> createState() => _EstimateCostScreenState();
}

class _EstimateCostScreenState extends State<EstimateCostScreen> {
  OrderInputController get controller => widget.controller;
  bool _isPreparingSummary = false;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChanged);
    if (controller.calculation == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await controller.calculateOrder();
      });
    }
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

  Future<void> _next() async {
    if (_isPreparingSummary) return;

    if (controller.calculation == null) {
      final error = await controller.calculateOrder();
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
        return;
      }
    }

    setState(() => _isPreparingSummary = true);
    try {
      await controller.ensureActualOrderId(existingOrder: widget.existingOrder);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSummaryScreen(
            controller: controller,
            existingOrder: widget.existingOrder,
            isEditing: widget.isEditing,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPreparingSummary = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = controller.calculation?.costBreakdown;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: buildGradientAppBar(
        widget.isEditing ? 'Edit Order' : 'New Order',
      ),
      body: gradientOrderBackground(
        child: SafeArea(
          child: OrderWizardShell(
            stepLabel: 'Step 4 of 5',
            children: [
              OrderStepCard(
                title: 'Estimated Cost',
                icon: Icons.currency_rupee,
                child: breakdown == null
                    ? const OrderEmptyState(text: 'Cost not calculated')
                    : _CostBreakdownList(breakdown: breakdown),
              ),
              OrderActionBar(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                  ElevatedButton.icon(
                    onPressed:
                        controller.hasValidDeliveryDate && !_isPreparingSummary
                        ? _next
                        : null,
                    icon: _isPreparingSummary
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.arrow_forward),
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

class _CostBreakdownList extends StatelessWidget {
  const _CostBreakdownList({required this.breakdown});

  final OrderCostBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row('Material Total', breakdown.materialTotalCost),
        _row('Labor Total', breakdown.laborTotalCost),
        _row('Processing Cost', breakdown.processingTotalCost),
        _row('Additional Charges', breakdown.additionalTotalCost),
        _row('Rush Charges', breakdown.rushCharges),
        const Divider(color: AppColors.divider),
        _row('Estimated Total Cost', breakdown.estimatedTotalCost, bold: true),
      ],
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: bold ? AppColors.primaryText : AppColors.secondaryText,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            'PKR ${value.toStringAsFixed(0)}',
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
