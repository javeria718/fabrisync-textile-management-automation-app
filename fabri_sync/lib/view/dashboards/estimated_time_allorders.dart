import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:flutter/material.dart';

class EstimatedTimeAllOrdersScreen extends StatelessWidget {
  final List<OrderModel> allOrders;
  final Map<String, double> perUnitDeptHours;

  final String Function(double) formatToDaysHours;
  final BoxDecoration glassCard;

  const EstimatedTimeAllOrdersScreen({
    super.key,
    required this.allOrders,
    required this.perUnitDeptHours,
    required this.formatToDaysHours,
    required this.glassCard,
  });

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "All Orders - Estimated Time",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF111827)],
          ),
        ),
      ),
      // ✅ NO ACTIONS (as per your requirement)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(context),
      body: gradientOrderBackground(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: allOrders.length,
          itemBuilder: (context, i) {
            final o = allOrders[i];

            // calculate per dept = qty * perUnitHours
            final Map<String, double> calculated = {};
            perUnitDeptHours.forEach((dept, perUnitHours) {
              calculated[dept] = perUnitHours * o.quantity;
            });

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
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...calculated.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              e.key,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
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
                                formatToDaysHours(e.value),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
