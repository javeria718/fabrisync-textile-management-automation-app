import 'dart:ui';

import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/controllers/new_order/order_summary_controller.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/view/dashboards/admin.dart';
import 'package:fabri_sync/widgets/custom_appBar.dart';
import 'package:fabri_sync/widgets/new_order_widgets.dart';
import 'package:fabri_sync/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class OrderSummaryScreen extends StatelessWidget {
  final OrderModel order;
  final bool isEditing;
  final OrderSummaryController controller = OrderSummaryController();

  OrderSummaryScreen({super.key, required this.order, this.isEditing = false});

  // Simple breakpoints (tweak if you want)
  static const double kTabletBp = 600;
  static const double kDesktopBp = 1024;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: buildGradientAppBar("Order Summary"),
      body: gradientOrderBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;

              final bool isDesktop = w >= kDesktopBp;
              final bool isTablet = w >= kTabletBp && w < kDesktopBp;

              // Responsive paddings
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

              // Responsive card max width
              final double cardMaxWidth = isDesktop
                  ? 560
                  : isTablet
                  ? 480
                  : double.infinity;

              // Responsive typography
              final double titleFont = isDesktop ? 15 : 14;
              final double valueFont = isDesktop ? 19 : 18;
              final double rowFont = isDesktop ? 14 : 13;

              // Responsive icon sizes
              final double avatarRadius = isDesktop ? 30 : 28;
              final double iconSize = isDesktop ? 30 : 28;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cardMaxWidth),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: EdgeInsets.all(isDesktop ? 28 : 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black38,
                                blurRadius: 30,
                                offset: Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OrderSummaryDetails(
                                order: order,
                                rowFont: rowFont,
                              ),

                              const SizedBox(height: 18),

                              /// ⏱ ESTIMATED TIME CARD
                              FrostedGradientCard(
                                title: "Estimated Time",
                                value:
                                    "${order.estimatedTime.toStringAsFixed(2)} hrs",
                                icon: Icons.access_time,
                                titleFont: titleFont,
                                valueFont: valueFont,
                                avatarRadius: avatarRadius,
                                iconSize: iconSize,
                              ),

                              const SizedBox(height: 14),

                              /// 💰 ESTIMATED COST CARD
                              FrostedGradientCard(
                                title: "Estimated Cost",
                                value:
                                    "PKR ${order.estimatedCost.toStringAsFixed(0)}",
                                icon: Icons.currency_rupee,
                                titleFont: titleFont,
                                valueFont: valueFont,
                                avatarRadius: avatarRadius,
                                iconSize: iconSize,
                              ),

                              const SizedBox(height: 24),

                              /// ✅ CREATE / UPDATE ORDER BUTTON
                              SizedBox(
                                width: double.infinity,
                                child: primaryButton(
                                  context: context,
                                  text: isEditing
                                      ? "Update Order"
                                      : "Create Order",
                                  onTap: () async {
                                    try {
                                      if (isEditing) {
                                        await controller.updateOrder(
                                          orderId: order.orderId,
                                          quantity: order.quantity,
                                          estimatedTime: order.estimatedTime,
                                          estimatedCost: order.estimatedCost,
                                        );
                                      } else {
                                        final String newOrderId =
                                            'ORD-${DateTime.now().millisecondsSinceEpoch}';

                                        await controller.createOrder(
                                          orderId: newOrderId,
                                          quantity: order.quantity,
                                          estimatedTime: order.estimatedTime,
                                          estimatedCost: order.estimatedCost,
                                        );
                                      }

                                      if (!context.mounted) return;

                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AdminDashboardScreen(),
                                        ),
                                        (route) => false,
                                      );

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isEditing
                                                ? "Order updated successfully"
                                                : "Order created successfully",
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } catch (e) {
                                      debugPrint("Order creation error: $e");
                                      if (!context.mounted) return;

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isEditing
                                                ? "Failed to update order"
                                                : "Failed to create order",
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
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
            },
          ),
        ),
      ),
    );
  }
}
