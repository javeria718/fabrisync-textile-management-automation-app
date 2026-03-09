// import 'dart:ui';

// import 'package:fabri_sync/Model/orderModel.dart';
// import 'package:fabri_sync/utils/customcolors.dart';
// import 'package:fabri_sync/widgets/custom_appBar.dart';
// import 'package:fabri_sync/widgets/primary_button.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class OrderDetailsScreen extends StatefulWidget {
//   final OrderModel order;

//   const OrderDetailsScreen({super.key, required this.order});

//   @override
//   State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
// }

// class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
//   final supabase = Supabase.instance.client;
//   late OrderModel order;

//   bool loading = false;
//   bool pageLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     order = widget.order;

//     // Optional: agar aap chahen ke details screen open hote hi latest status/department DB se aa jaye:
//     _fetchLatestOrder();
//   }

//   Future<void> _fetchLatestOrder() async {
//     setState(() => pageLoading = true);
//     try {
//       // ⚠️ Table name yahan aapke create order code ke mutabiq ordersmain hai
//       final res = await supabase
//           .from('ordersmain')
//           .select()
//           .eq('order_id', order.orderId)
//           .maybeSingle();

//       if (res != null && mounted) {
//         // NOTE: yahan aapke OrderModel ka fromMap hona chahiye.
//         // Agar aapke model me fromMap nahi, to aap manually assign kar sakti hain.
//         setState(() {
//           order = OrderModel.fromMap(res);
//         });
//       }
//     } catch (e) {
//       debugPrint("Fetch latest order error: $e");
//     } finally {
//       if (mounted) setState(() => pageLoading = false);
//     }
//   }

//   Future<void> markAsCompleted() async {
//     setState(() => loading = true);

//     try {
//       final nextDept = nextDepartment(order.currentDepartment);

//       // ⚠️ IMPORTANT:
//       // Aapke create order me ordersmain use ho raha hai, isliye yahan bhi ordersmain update kiya.
//       await supabase
//           .from('ordersmain')
//           .update({
//             'status': 'Completed',
//             'current_department': nextDept, // keep consistent with your column
//           })
//           .eq('order_id', order.orderId);

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Order marked as completed!")),
//       );

//       // Refresh local UI with latest values
//       await _fetchLatestOrder();

//       Navigator.pop(context); // go back to table
//     } catch (e) {
//       debugPrint("Error updating order: $e");
//       if (!mounted) return;

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Failed to update order")));
//     } finally {
//       if (mounted) setState(() => loading = false);
//     }
//   }

//   String nextDepartment(String currentDept) {
//     // ✅ Aapke OrderSummary me department uppercase (CUTTING) use ho raha hai
//     // Isliye flow uppercase rakha:
//     const flow = ['CUTTING', 'STITCHING', 'FINISHING', 'PACKAGING'];
//     final index = flow.indexOf(currentDept.toUpperCase());
//     return index < flow.length - 1 ? flow[index + 1] : currentDept;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       appBar: buildGradientAppBar("Order Details"),
//       body: gradientOrderBackground(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(18),
//           child: Center(
//             child: ConstrainedBox(
//               constraints: const BoxConstraints(maxWidth: 420),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(24),
//                 child: BackdropFilter(
//                   filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
//                   child: Container(
//                     padding: const EdgeInsets.all(24),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.12),
//                       borderRadius: BorderRadius.circular(24),
//                       border: Border.all(color: Colors.white.withOpacity(0.25)),
//                       boxShadow: const [
//                         BoxShadow(
//                           color: Colors.black38,
//                           blurRadius: 30,
//                           offset: Offset(0, 20),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         if (pageLoading) ...[
//                           const SizedBox(height: 6),
//                           const LinearProgressIndicator(minHeight: 2),
//                           const SizedBox(height: 18),
//                         ],

//                         /// 🧾 ORDER SUMMARY CARD (same as OrderSummaryScreen)
//                         Container(
//                           padding: const EdgeInsets.all(18),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.08),
//                             borderRadius: BorderRadius.circular(18),
//                             border: Border.all(
//                               color: Colors.white.withOpacity(0.15),
//                             ),
//                             boxShadow: const [
//                               BoxShadow(
//                                 color: Colors.black26,
//                                 blurRadius: 20,
//                                 offset: Offset(0, 10),
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const SizedBox(height: 12),
//                               _row("Order ID", order.orderId),
//                               _row("Department", order.currentDepartment),
//                               _row("Quantity", order.quantity.toString()),
//                               _row(
//                                 "Date",
//                                 DateFormat(
//                                   "dd MMM yyyy",
//                                 ).format(order.createdAt),
//                               ),
//                               _row(
//                                 "Time",
//                                 DateFormat("hh:mm a").format(order.createdAt),
//                               ),
//                               _row("Status", order.status),
//                             ],
//                           ),
//                         ),

//                         const SizedBox(height: 18),

//                         /// ⏱ ESTIMATED TIME CARD (same frosted style)
//                         _frostedGradientCard(
//                           title: "Estimated Time",
//                           value:
//                               "${order.estimatedTime.toStringAsFixed(2)} hrs",
//                           icon: Icons.access_time,
//                         ),

//                         const SizedBox(height: 14),

//                         /// 💰 ESTIMATED COST CARD
//                         _frostedGradientCard(
//                           title: "Estimated Cost",
//                           value:
//                               "PKR ${order.estimatedCost.toStringAsFixed(0)}",
//                           icon: Icons.currency_rupee,
//                         ),

//                         const SizedBox(height: 24),

//                         /// ✅ MARK AS COMPLETED BUTTON
//                         SizedBox(
//                           width: double.infinity,
//                           child: primaryButton(
//                             context: context,
//                             text: "Mark as Completed",
//                             loading: loading,
//                             showTick: true,
//                             onTap: markAsCompleted,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   /// 🔹 Helper for rows (same as OrderSummaryScreen)
//   Widget _row(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7))),
//           Text(
//             value,
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// 🔹 Frosted Gradient Card (same as OrderSummaryScreen)
//   Widget _frostedGradientCard({
//     required String title,
//     required String value,
//     required IconData icon,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(18),
//         gradient: const LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Color(0x66FFFFFF), Color(0x33E0EFFF)],
//         ),
//         border: Border.all(color: Colors.white.withOpacity(0.15)),
//         boxShadow: const [
//           BoxShadow(
//             color: Colors.black26,
//             blurRadius: 20,
//             offset: Offset(0, 10),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 28,
//             backgroundColor: Colors.white.withOpacity(0.2),
//             child: Icon(icon, color: Colors.white, size: 28),
//           ),
//           const SizedBox(width: 16),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 title,
//                 style: const TextStyle(color: Colors.white70, fontSize: 14),
//               ),
//               Text(
//                 value,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:ui';

import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/utils/customcolors.dart';
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
  late OrderModel order;

  bool pageLoading = false;

  static const double kTabletBp = 600;
  static const double kDesktopBp = 1024;

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
    } catch (e) {
      debugPrint("Fetch latest order error: $e");
    } finally {
      if (mounted) setState(() => pageLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ IMPORTANT: Avoid white “Scaffold background” bleed
      backgroundColor: Colors.black,
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
                // ✅ This prevents “tiny content = leftover white”
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Container(
                    // ✅ Make sure background fills width too
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContentWidth),
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
                                  if (pageLoading) ...[
                                    const SizedBox(height: 6),
                                    const LinearProgressIndicator(minHeight: 2),
                                    const SizedBox(height: 18),
                                  ],

                                  if (isTablet || isDesktop)
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                              _frostedGradientCard(
                                                title: "Estimated Time",
                                                value:
                                                    "${order.estimatedTime.toStringAsFixed(2)} hrs",
                                                icon: Icons.access_time,
                                                titleFont: cardTitleFont,
                                                valueFont: cardValueFont,
                                                avatarRadius: avatarRadius,
                                                iconSize: iconSize,
                                              ),
                                              const SizedBox(height: 14),
                                              _frostedGradientCard(
                                                title: "Estimated Cost",
                                                value:
                                                    "PKR ${order.estimatedCost.toStringAsFixed(0)}",
                                                icon: Icons.currency_rupee,
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
                                    _frostedGradientCard(
                                      title: "Estimated Time",
                                      value:
                                          "${order.estimatedTime.toStringAsFixed(2)} hrs",
                                      icon: Icons.access_time,
                                      titleFont: cardTitleFont,
                                      valueFont: cardValueFont,
                                      avatarRadius: avatarRadius,
                                      iconSize: iconSize,
                                    ),
                                    const SizedBox(height: 14),
                                    _frostedGradientCard(
                                      title: "Estimated Cost",
                                      value:
                                          "PKR ${order.estimatedCost.toStringAsFixed(0)}",
                                      icon: Icons.currency_rupee,
                                      titleFont: cardTitleFont,
                                      valueFont: cardValueFont,
                                      avatarRadius: avatarRadius,
                                      iconSize: iconSize,
                                    ),
                                  ],

                                  // ✅ No button here (removed)
                                ],
                              ),
                            ),
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
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _row("Order ID", order.orderId, fontSize: rowFont),
          _row("Department", order.currentDepartment, fontSize: rowFont),
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

  Widget _row(String label, String value, {double fontSize = 13}) {
    final labelStyle = TextStyle(
      color: Colors.white.withOpacity(0.7),
      fontSize: fontSize,
    );

    final valueStyle = TextStyle(
      color: Colors.white,
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

  Widget _frostedGradientCard({
    required String title,
    required String value,
    required IconData icon,
    required double titleFont,
    required double valueFont,
    required double avatarRadius,
    required double iconSize,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x66FFFFFF), Color(0x33E0EFFF)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.white70, fontSize: titleFont),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
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
}
