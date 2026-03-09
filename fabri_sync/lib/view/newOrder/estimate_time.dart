import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/controllers/new_order/estimate_time_controller.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/view/newOrder/estimate_cost.dart';
import 'package:fabri_sync/widgets/custom_appBar.dart';
import 'package:fabri_sync/widgets/new_order_widgets.dart';
import 'package:fabri_sync/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class EstimateTimeScreen extends StatefulWidget {
  final TextEditingController quantityCtrl;
  final TextEditingController materialCostCtrl;
  final OrderModel? existingOrder;
  final bool isEditing;

  const EstimateTimeScreen({
    super.key,
    required this.quantityCtrl,
    required this.materialCostCtrl,
    this.existingOrder,
    this.isEditing = false,
  });

  @override
  State<EstimateTimeScreen> createState() => _EstimateTimeScreenState();
}

class _EstimateTimeScreenState extends State<EstimateTimeScreen> {
  late final EstimateTimeController controller;

  @override
  void initState() {
    super.initState();
    controller = EstimateTimeController()..addListener(_onCtrl);
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

  Future<void> calculateTime() async {
    final qty = double.tryParse(widget.quantityCtrl.text) ?? 0;
    if (qty <= 0) return;

    final ok = await controller.calculateTime(qty);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to calculate estimated time')),
      );
    }
  }

  void handleNext() {
    if (!controller.hasCalculated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please tap the card to calculate time first."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstimateCostScreen(
          quantityCtrl: widget.quantityCtrl,
          materialCostCtrl: widget.materialCostCtrl,
          estimatedTime: controller.estimatedTime,
          existingOrder: widget.existingOrder,
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
                      title: "Estimated Time",
                      value: !controller.hasCalculated
                          ? "Not Calculated"
                          : "${controller.totalDays} days (8hr/day)",
                      subtitle: controller.hasCalculated
                          ? "Total: ${controller.totalProjectHours.toStringAsFixed(0)} hrs"
                          : "Tap card to calculate",
                      minHeight: 140,
                      onTap: calculateTime,
                      isCardTapped: controller.isCardTapped,
                    ),

                    if (controller.hasCalculated)
                      DepartmentEstimateList(
                        estimatedDeptHours: controller.estimatedDeptHours,
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
