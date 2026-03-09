import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/controllers/new_order/order_input_controller.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/view/newOrder/estimate_time.dart';
import 'package:fabri_sync/widgets/custom_appBar.dart';
import 'package:fabri_sync/widgets/new_order_widgets.dart';
import 'package:fabri_sync/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class OrderInputScreen extends StatefulWidget {
  final OrderModel? existingOrder;
  final bool isEditing;

  const OrderInputScreen.edit({super.key, required this.existingOrder})
    : isEditing = true;

  const OrderInputScreen({
    super.key,
    this.existingOrder,
    this.isEditing = false,
  });

  @override
  State<OrderInputScreen> createState() => _OrderInputScreenState();
}

class _OrderInputScreenState extends State<OrderInputScreen> {
  late final OrderInputController controller;

  @override
  void initState() {
    super.initState();
    controller = OrderInputController()..initFromOrder(widget.existingOrder);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OrderInputCard(
                      label: "Order Quantity",
                      icon: Icons.inventory,
                      controller: controller.quantityCtrl,
                    ),
                    OrderInputCard(
                      label: "Material Cost / Unit",
                      icon: Icons.attach_money,
                      controller: controller.materialCostCtrl,
                    ),

                    const SizedBox(height: 36),

                    primaryButton(
                      context: context,
                      text: "Next",
                      onTap: () {
                        if (!controller.validateInputs()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Please enter all fields before proceeding",
                              ),
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EstimateTimeScreen(
                              quantityCtrl: controller.quantityCtrl,
                              materialCostCtrl: controller.materialCostCtrl,
                              existingOrder: widget.existingOrder,
                              isEditing: widget.isEditing,
                            ),
                          ),
                        );
                      },
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
