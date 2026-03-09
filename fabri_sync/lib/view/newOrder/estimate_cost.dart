import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/controllers/new_order/estimate_cost_controller.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/view/newOrder/order_summary.dart';
import 'package:fabri_sync/widgets/custom_appBar.dart';
import 'package:fabri_sync/widgets/new_order_widgets.dart';
import 'package:fabri_sync/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class EstimateCostScreen extends StatefulWidget {
  final TextEditingController quantityCtrl;
  final TextEditingController materialCostCtrl;
  final double estimatedTime;
  final OrderModel? existingOrder;
  final bool isEditing;

  const EstimateCostScreen({
    super.key,
    required this.quantityCtrl,
    required this.materialCostCtrl,
    required this.estimatedTime,
    this.existingOrder,
    this.isEditing = false,
  });

  @override
  State<EstimateCostScreen> createState() => _EstimateCostScreenState();
}

class _EstimateCostScreenState extends State<EstimateCostScreen> {
  late final EstimateCostController controller;

  @override
  void initState() {
    super.initState();
    controller = EstimateCostController()..addListener(_onCtrl);
    fetchHourlyRate();
  }

  void _onCtrl() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onCtrl);
    controller.dispose();
    super.dispose();
  }

  Future<void> fetchHourlyRate() async {
    final ok = await controller.fetchHourlyRate();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Hourly rate not found in database!"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void calculateCost() {
    if (controller.isLoadingRate) return;

    final qty = double.tryParse(widget.quantityCtrl.text) ?? 0;
    final materialCost = double.tryParse(widget.materialCostCtrl.text) ?? 0;

    controller.calculateCost(
      estimatedTime: widget.estimatedTime,
      qty: qty,
      materialCost: materialCost,
    );
  }

  void handleNext() {
    if (!controller.hasCalculated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please tap the card to calculate cost first."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final base = widget.existingOrder;
    final tempOrder = OrderModel(
      orderId:
          base?.orderId ?? "ORD-${DateTime.now().millisecondsSinceEpoch}",
      quantity: int.parse(widget.quantityCtrl.text),
      currentDepartment: base?.currentDepartment ?? "Cutting",
      status: base?.status ?? "Pending",
      createdAt: base?.createdAt ?? DateTime.now(),
      estimatedTime: widget.estimatedTime,
      estimatedCost: controller.estimatedCost,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSummaryScreen(
          order: tempOrder,
          isEditing: widget.isEditing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: buildGradientAppBar(
        widget.isEditing ? "Edit Order" : "New Order",
      ),
      body: gradientOrderBackground(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: NewOrderGlassCard(
                minHeight: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EstimateCard(
                      title: "Estimated Cost",
                      value: controller.estimatedCost == 0
                          ? "Not Calculated"
                          : "PKR ${controller.estimatedCost.toStringAsFixed(0)}",
                      subtitle: controller.hasCalculated
                          ? null
                          : "Tap card to calculate",
                      height: 140,
                      onTap: calculateCost,
                      isCardTapped: controller.isCardTapped,
                    ),

                    const SizedBox(height: 150),

                    SizedBox(
                      width: double.infinity,
                      child: primaryButton(
                        context: context,
                        text: "Next",
                        onTap: handleNext,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
