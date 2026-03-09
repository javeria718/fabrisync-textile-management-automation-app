// class OrderModel {
//   final String orderId;
//   final int quantity;

//   // ordersmain fields
//   final String currentDepartment;
//   final String status;
//   final DateTime createdAt;

//   final double estimatedTime;
//   final double estimatedCost;

//   OrderModel({
//     required this.orderId,
//     required this.quantity,
//     required this.currentDepartment,
//     required this.status,
//     required this.createdAt,
//     required this.estimatedTime,
//     required this.estimatedCost,
//   });

//   /// FOR INSERT / UPDATE
//   Map<String, dynamic> toMap() {
//     return {
//       'order_id': orderId,
//       'quantity': quantity,
//       'current_department': currentDepartment,
//       'status': status,
//       'created_at': createdAt.toIso8601String(),
//       'estimated_time': estimatedTime,
//       'estimated_cost': estimatedCost,
//     };
//   }

//   /// FROM SUPABASE (ordersmain)
//   factory OrderModel.fromMap(Map<String, dynamic> map) {
//     return OrderModel(
//       orderId: map['order_id'],
//       quantity: map['quantity'],
//       currentDepartment: map['current_department'],
//       status: map['status'],
//       createdAt: DateTime.parse(map['created_at']),
//       estimatedTime: (map['estimated_time'] ?? 0).toDouble(),
//       estimatedCost: (map['estimated_cost'] ?? 0).toDouble(),
//     );
//   }
// }
class OrderModel {
  final String orderId;
  final int quantity;

  // ordersmain fields
  final String currentDepartment; // stored as UPPERCASE in DB (recommended)
  final String status;
  final DateTime createdAt;
  final double estimatedTime; // maps to estimated_total_time
  final double estimatedCost; // maps to estimated_total_cost

  // department_orders fields
  final String? managerName;
  final DateTime? dateIn;
  final DateTime? timeIn;
  final DateTime? dateOut;
  final DateTime? timeOut;

  OrderModel({
    required this.orderId,
    required this.quantity,
    required this.currentDepartment,
    required this.status,
    required this.createdAt,
    required this.estimatedTime,
    required this.estimatedCost,
    this.managerName,
    this.dateIn,
    this.timeIn,
    this.dateOut,
    this.timeOut,
  });

  /// FOR INSERT / UPDATE (ordersmain)
  /// ✅ keys updated to match your DB columns:
  /// estimated_total_time, estimated_total_cost
  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'quantity': quantity,
      'current_department': currentDepartment.toUpperCase(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'estimated_total_time': estimatedTime,
      'estimated_total_cost': estimatedCost,
    };
  }

  /// FROM SUPABASE (ordersmain)
  /// ✅ reads correct DB columns
  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      orderId: (map['order_id'] ?? '').toString(),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      currentDepartment: (map['current_department'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      estimatedTime: (map['estimated_total_time'] as num?)?.toDouble() ?? 0.0,
      estimatedCost: (map['estimated_total_cost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// FROM SUPABASE (department_orders join ordersmain)
  factory OrderModel.fromDeptOrderMap(Map<String, dynamic> map) {
    final orderMain = (map['ordersmain'] is Map<String, dynamic>)
        ? map['ordersmain']
        : {};

    // date_in is DATE, time_in is TIME -> parse safely
    DateTime? parseDateOnly(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    DateTime? parseTimeOnly(dynamic v) {
      if (v == null) return null;
      // store as DateTime with dummy date to keep your existing UI formatting
      final t = v.toString(); // e.g. "13:05:00"
      final parsed = DateTime.tryParse('1970-01-01 $t');
      return parsed;
    }

    return OrderModel(
      orderId: (map['order_id'] ?? orderMain['order_id'] ?? '').toString(),
      quantity: (orderMain['quantity'] as num?)?.toInt() ?? 0,
      currentDepartment:
          (map['department'] ?? orderMain['current_department'] ?? '')
              .toString(),
      status: (map['status'] ?? orderMain['status'] ?? '').toString(),
      createdAt: orderMain['created_at'] != null
          ? DateTime.parse(orderMain['created_at'].toString())
          : DateTime.now(),
      estimatedTime:
          (orderMain['estimated_total_time'] as num?)?.toDouble() ?? 0.0,
      estimatedCost:
          (orderMain['estimated_total_cost'] as num?)?.toDouble() ?? 0.0,
      managerName: (map['manager_name'] ?? map['manager_n'] ?? map['manager'])
          ?.toString(),
      dateIn: parseDateOnly(map['date_in']),
      timeIn: parseTimeOnly(map['time_in']),
      dateOut: parseDateOnly(map['date_out']),
      timeOut: parseTimeOnly(map['time_out']),
    );
  }
}
