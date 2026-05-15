import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/controllers/new_order/order_input_controller.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/view/newOrder/estimate_time.dart';
import 'package:fabri_sync/widgets/custom_appBar.dart';
import 'package:fabri_sync/widgets/new_order_widgets.dart';
import 'package:flutter/material.dart';

class CostInputsScreen extends StatefulWidget {
  const CostInputsScreen({
    super.key,
    required this.controller,
    this.existingOrder,
    this.isEditing = false,
  });

  final OrderInputController controller;
  final OrderModel? existingOrder;
  final bool isEditing;

  @override
  State<CostInputsScreen> createState() => _CostInputsScreenState();
}

class _CostInputsScreenState extends State<CostInputsScreen> {
  OrderInputController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChanged);
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

  void _next() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstimateTimeScreen(
          controller: controller,
          existingOrder: widget.existingOrder,
          isEditing: widget.isEditing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: buildGradientAppBar(
        widget.isEditing ? 'Edit Order' : 'New Order',
      ),
      body: gradientOrderBackground(
        child: SafeArea(
          child: OrderWizardShell(
            stepLabel: 'Step 2 of 5',
            children: [
              OrderStepCard(
                title: 'Additional Details',
                icon: Icons.notes_outlined,
                child: Column(
                  children: [
                    OrderTextInputField(
                      label: 'Special Instructions',
                      icon: Icons.edit_note_outlined,
                      controller: controller.specialInstructionsCtrl,
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 12),
                    OrderFieldWrap(
                      children: [
                        OrderSwitchField(
                          label: 'Custom Packaging',
                          value: controller.customPackaging,
                          onChanged: controller.setCustomPackaging,
                        ),
                      ],
                    ),
                  ],
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
