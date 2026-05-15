class EmployeeHeadProfile {
  const EmployeeHeadProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.department,
  });

  final String id;
  final String fullName;
  final String email;
  final String department;

  factory EmployeeHeadProfile.fromMap(Map<String, dynamic> map) {
    return EmployeeHeadProfile(
      id: (map['id'] ?? '').toString(),
      fullName: _nullableString(map['full_name']) ?? '',
      email: _nullableString(map['email']) ?? '',
      department: _canonicalDepartment(map['department']),
    );
  }
}

class EmployeeHeadOrder {
  const EmployeeHeadOrder({
    required this.departmentOrderId,
    required this.orderId,
    required this.orderNumber,
    required this.department,
    required this.status,
    required this.quantity,
    this.productCategory,
    this.productType,
    this.expectedHours,
    this.dateIn,
    this.timeIn,
    this.dateOut,
    this.timeOut,
    this.plannedStartDate,
    this.plannedEndDate,
    this.actualStartDate,
    this.actualEndDate,
    this.orderStatus,
  });

  final String departmentOrderId;
  final String orderId;
  final String orderNumber;
  final String department;
  final String status;
  final int quantity;
  final String? productCategory;
  final String? productType;
  final double? expectedHours;
  final DateTime? dateIn;
  final String? timeIn;
  final DateTime? dateOut;
  final String? timeOut;
  final DateTime? plannedStartDate;
  final DateTime? plannedEndDate;
  final DateTime? actualStartDate;
  final DateTime? actualEndDate;
  final String? orderStatus;

  factory EmployeeHeadOrder.fromMap(Map<String, dynamic> map) {
    final orderId = (map['order_id'] ?? '').toString();
    return EmployeeHeadOrder(
      departmentOrderId: (map['id'] ?? '').toString(),
      orderId: orderId,
      orderNumber:
          _nullableString(map['order_number']) ??
          _nullableString(map['order_no']) ??
          orderId,
      department: _canonicalDepartment(map['department']),
      status: (map['status'] ?? '').toString(),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      productCategory: _nullableString(map['product_category']),
      productType: _nullableString(map['product_type']),
      expectedHours: (map['expected_hours'] as num?)?.toDouble(),
      dateIn: _parseDateTime(map['date_in']),
      timeIn: _nullableString(map['time_in']),
      dateOut: _parseDateTime(map['date_out']),
      timeOut: _nullableString(map['time_out']),
      plannedStartDate: _parseDateTime(map['planned_start_date']),
      plannedEndDate: _parseDateTime(map['planned_end_date']),
      actualStartDate: _parseDateTime(map['actual_start_date']),
      actualEndDate: _parseDateTime(map['actual_end_date']),
      orderStatus: _nullableString(map['order_status']),
    );
  }
}

class OrderItemTracking {
  const OrderItemTracking({
    required this.id,
    required this.orderId,
    required this.itemNo,
    required this.itemCode,
    required this.productPrefix,
    this.createdAt,
    this.progressId,
    this.department,
    this.departmentOrderId,
    this.status = 'pending',
    this.completedAt,
    this.completedBy,
    this.completedByName,
  });

  final String id;
  final String orderId;
  final int itemNo;
  final String itemCode;
  final String productPrefix;
  final DateTime? createdAt;
  final String? progressId;
  final String? department;
  final String? departmentOrderId;
  final String status;
  final DateTime? completedAt;
  final String? completedBy;
  final String? completedByName;

  bool get isCompleted => status.toLowerCase() == 'completed';

  factory OrderItemTracking.fromItemMap(Map<String, dynamic> map) {
    return OrderItemTracking(
      id: (map['id'] ?? '').toString(),
      orderId: (map['order_id'] ?? '').toString(),
      itemNo: (map['item_no'] as num?)?.toInt() ?? 0,
      itemCode: (map['item_code'] ?? '').toString(),
      productPrefix: (map['product_prefix'] ?? '').toString(),
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  OrderItemTracking copyWithProgress(Map<String, dynamic>? progress) {
    if (progress == null) return this;
    return OrderItemTracking(
      id: id,
      orderId: orderId,
      itemNo: itemNo,
      itemCode: itemCode,
      productPrefix: productPrefix,
      createdAt: createdAt,
      progressId: _nullableString(progress['id']),
      department: _nullableString(progress['department']),
      departmentOrderId: _nullableString(progress['department_order_id']),
      status: (progress['status'] ?? status).toString(),
      completedAt: _parseDateTime(progress['completed_at']),
      completedBy: _nullableString(progress['completed_by']),
      completedByName: _nullableString(progress['completed_by_name']),
    );
  }
}

class DepartmentProgressSummary {
  const DepartmentProgressSummary({
    required this.orderId,
    required this.department,
    required this.totalQuantity,
    required this.completedQuantity,
  });

  final String orderId;
  final String department;
  final int totalQuantity;
  final int completedQuantity;

  int get pendingQuantity {
    final pending = totalQuantity - completedQuantity;
    return pending < 0 ? 0 : pending;
  }

  double get progressPercentage {
    if (totalQuantity <= 0) return 0;
    return (completedQuantity / totalQuantity) * 100;
  }

  static const empty = DepartmentProgressSummary(
    orderId: '',
    department: '',
    totalQuantity: 0,
    completedQuantity: 0,
  );
}

class DepartmentCompletionResult {
  const DepartmentCompletionResult({
    required this.completed,
    required this.alreadyCompleted,
    required this.wasLate,
    required this.message,
  });

  final bool completed;
  final bool alreadyCompleted;
  final bool wasLate;
  final String message;
}

String _canonicalDepartment(dynamic value) {
  final text = (value ?? '').toString().trim().toUpperCase();
  if (text == 'QUALITY CONTROL') return 'QUALITY_CONTROL';
  if (text == 'PACKING') return 'PACKAGING';
  return text.replaceAll(' ', '_');
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
