// import 'package:fabri_sync/Model/orderModel.dart';
// import 'package:fabri_sync/view/tables/order_details.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class OrdersDataSource extends DataTableSource {
//   final List<OrderModel> orders;
//   final BuildContext context;
//   final Color blue;
//   final supabase = Supabase.instance.client;

//   OrdersDataSource(this.orders, this.context, this.blue);

//   @override
//   DataRow? getRow(int index) {
//     if (index >= orders.length) return null;
//     final order = orders[index];

//     final createdAt = order.dateIn ?? order.createdAt;
//     final difference = DateTime.now().difference(createdAt);
//     final days = difference.inDays;
//     final hours = difference.inHours % 24;
//     final runningText = "${days}d ${hours}h";

//     final rowColor = MaterialStateProperty.resolveWith<Color?>((states) {
//       if (states.contains(MaterialState.selected))
//         return blue.withOpacity(0.12);
//       return index.isEven ? Colors.white : blue.withOpacity(0.03);
//     });

//     return DataRow.byIndex(
//       index: index,
//       color: rowColor,
//       cells: [
//         DataCell(Text((index + 1).toString())),
//         DataCell(
//           InkWell(
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => OrderDetailsScreen(order: order),
//                 ),
//               );
//             },
//             child: Text(
//               order.orderId,
//               style: TextStyle(
//                 color: blue,
//                 decoration: TextDecoration.underline,
//               ),
//             ),
//           ),
//         ),
//         DataCell(Text(order.currentDepartment)),
//         DataCell(Text(order.managerName ?? "-")),
//         DataCell(
//           Text(
//             order.dateIn != null
//                 ? DateFormat("dd MMM yyyy").format(order.dateIn!)
//                 : "-",
//           ),
//         ),
//         DataCell(
//           Text(
//             order.timeIn != null
//                 ? DateFormat("hh:mm a").format(order.timeIn!)
//                 : "-",
//           ),
//         ),
//         DataCell(Text(runningText)),
//         DataCell(
//           Text(
//             order.dateOut != null
//                 ? DateFormat("dd MMM yyyy").format(order.dateOut!)
//                 : "-",
//           ),
//         ),
//         DataCell(
//           Text(
//             order.timeOut != null
//                 ? DateFormat("hh:mm a").format(order.timeOut!)
//                 : "-",
//           ),
//         ),
//         DataCell(
//           Chip(
//             label: Text(order.status),
//             backgroundColor: order.status.toLowerCase() == "completed"
//                 ? Colors.green.shade100
//                 : order.status.toLowerCase() == "inprogress"
//                 ? Colors.orange.shade100
//                 : Colors.red.shade100,
//           ),
//         ),
//         DataCell(_actionMenu(order)),
//       ],
//     );
//   }

//   Widget _actionMenu(OrderModel order) {
//     return PopupMenuButton<String>(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       onSelected: (value) async {
//         if (value == "view") {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
//           );
//         } else if (value == "edit") {
//           // TODO: edit order
//         } else if (value == "delete") {
//           await _deleteOrder(order);
//         }
//       },
//       itemBuilder: (_) => const [
//         PopupMenuItem(
//           value: "view",
//           child: Row(
//             children: [
//               Icon(Icons.visibility, size: 18),
//               SizedBox(width: 8),
//               Text("View"),
//             ],
//           ),
//         ),
//         PopupMenuItem(
//           value: "edit",
//           child: Row(
//             children: [
//               Icon(Icons.edit, size: 18),
//               SizedBox(width: 8),
//               Text("Edit"),
//             ],
//           ),
//         ),
//         PopupMenuItem(
//           value: "delete",
//           child: Row(
//             children: [
//               Icon(Icons.delete, size: 18, color: Colors.red),
//               SizedBox(width: 8),
//               Text("Delete", style: TextStyle(color: Colors.red)),
//             ],
//           ),
//         ),
//       ],
//       child: const Icon(Icons.more_vert),
//     );
//   }

//   Future<void> _deleteOrder(OrderModel order) async {
//     try {
//       await supabase
//           .from('department_orders')
//           .delete()
//           .eq('order_id', order.orderId);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Order ${order.orderId} deleted")));
//       notifyListeners();
//     } catch (e) {
//       debugPrint("Delete error: $e");
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Failed to delete order")));
//     }
//   }

//   @override
//   bool get isRowCountApproximate => false;
//   @override
//   int get rowCount => orders.length;
//   @override
//   int get selectedRowCount => 0;
// }
import 'dart:ui';

import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/view/newOrder/orderInput.dart';
import 'package:fabri_sync/view/dashboards/tables/order_details.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersDataSource extends DataTableSource {
  final List<OrderModel> orders;
  final BuildContext context;
  final Color blue;
  final supabase = Supabase.instance.client;

  OrdersDataSource(this.orders, this.context, this.blue);

  @override
  DataRow? getRow(int index) {
    if (index >= orders.length) return null;
    final order = orders[index];

    final createdAt = order.dateIn ?? order.createdAt;
    final difference = DateTime.now().difference(createdAt);
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final runningText = "${days}d ${hours}h";

    // ✅ glass rows (transparent-ish)
    final rowColor = MaterialStateProperty.resolveWith<Color?>((states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.white.withOpacity(0.10);
      }
      return index.isEven
          ? Colors.white.withOpacity(0.04)
          : Colors.white.withOpacity(0.02);
    });

    return DataRow.byIndex(
      index: index,
      color: rowColor,
      cells: [
        DataCell(
          Text(
            (index + 1).toString(),
            style: TextStyle(color: Colors.white.withOpacity(0.85)),
          ),
        ),
        DataCell(
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailsScreen(order: order),
                ),
              );
            },
            child: Text(
              order.orderId,
              style: TextStyle(
                color: Colors.white.withOpacity(0.92),
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withOpacity(0.35),
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            order.currentDepartment,
            style: TextStyle(color: Colors.white.withOpacity(0.85)),
          ),
        ),
        DataCell(
          Text(
            order.managerName ?? "-",
            style: TextStyle(color: Colors.white.withOpacity(0.85)),
          ),
        ),
        DataCell(
          Text(
            order.dateIn != null
                ? DateFormat("dd MMM yyyy").format(order.dateIn!)
                : "-",
            style: TextStyle(color: Colors.white.withOpacity(0.85)),
          ),
        ),
        DataCell(
          Text(
            order.timeIn != null
                ? DateFormat("hh:mm a").format(order.timeIn!)
                : "-",
            style: TextStyle(color: Colors.white.withOpacity(0.85)),
          ),
        ),
        DataCell(
          Text(
            runningText,
            style: TextStyle(color: Colors.white.withOpacity(0.85)),
          ),
        ),
        DataCell(
          Text(
            order.dateOut != null
                ? DateFormat("dd MMM yyyy").format(order.dateOut!)
                : "-",
            style: TextStyle(color: Colors.white.withOpacity(0.85)),
          ),
        ),
        DataCell(
          Text(
            order.timeOut != null
                ? DateFormat("hh:mm a").format(order.timeOut!)
                : "-",
            style: TextStyle(color: Colors.white.withOpacity(0.85)),
          ),
        ),

        // ✅ glass chip status
        DataCell(_statusChip(order.status)),

        DataCell(_actionMenu(order)),
      ],
    );
  }

  Widget _statusChip(String status) {
    final s = status.toLowerCase();
    Color tint;
    if (s == "completed") {
      tint = Colors.greenAccent;
    } else if (s == "inprogress") {
      tint = Colors.orangeAccent;
    } else {
      tint = Colors.redAccent;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: tint.withOpacity(0.45)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: Colors.white.withOpacity(0.90),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionMenu(OrderModel order) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF0F1B33),
      onSelected: (value) async {
        if (value == "view") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
          );
        } else if (value == "edit") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  OrderInputScreen(existingOrder: order, isEditing: true),
            ),
          );
        } else if (value == "delete") {
          await _deleteOrder(order);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: "view",
          child: Row(
            children: [
              Icon(Icons.visibility, size: 18, color: Colors.white),
              SizedBox(width: 8),
              Text("View", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem(
          value: "edit",
          child: Row(
            children: [
              Icon(Icons.edit, size: 18, color: Colors.white),
              SizedBox(width: 8),
              Text("Edit", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem(
          value: "delete",
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.redAccent),
              SizedBox(width: 8),
              Text("Delete", style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
      child: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.85)),
    );
  }

  Future<void> _deleteOrder(OrderModel order) async {
    try {
      await supabase
          .from('department_orders')
          .delete()
          .eq('order_id', order.orderId);
      await supabase.from('ordersmain').delete().eq('order_id', order.orderId);
      orders.removeWhere((o) => o.orderId == order.orderId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Order ${order.orderId} deleted")));
      notifyListeners();
    } catch (e) {
      debugPrint("Delete error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to delete order")));
    }
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => orders.length;
  @override
  int get selectedRowCount => 0;
}
