class OrderModel {
  final String orderId;
  final int quantity;

  // ordersmain fields
  final String currentDepartment;
  final String status;
  final DateTime createdAt;
  final double estimatedTime;
  final double estimatedCost;
  final String? productCategory;
  final String? productType;
  final Map<String, dynamic> productSpecifications;
  final DateTime? requiredDeliveryDate;
  final String? qualityGrade;
  final String? priority;
  final String? specialInstructions;
  final bool customPackaging;
  final bool brandingRequired;
  final DateTime? draftCreatedAt;
  final DateTime? draftExpiresAt;
  final bool isDraftExpired;
  final double? estimatedProductionHours;
  final double? estimatedProductionDays;
  final Map<String, double>? estimatedDeptHours;

  // department_orders / view fields
  final String? managerName;
  final DateTime? dateIn;
  final DateTime? timeIn;
  final DateTime? dateOut;
  final DateTime? timeOut;
  final int? sequenceNumber;
  final DateTime? plannedStartDate;
  final DateTime? plannedEndDate;
  final DateTime? actualStartDate;
  final DateTime? actualEndDate;
  final String? delayReason;

  OrderModel({
    required this.orderId,
    required this.quantity,
    required this.currentDepartment,
    required this.status,
    required this.createdAt,
    required this.estimatedTime,
    required this.estimatedCost,
    this.productCategory,
    this.productType,
    Map<String, dynamic>? productSpecifications,
    this.requiredDeliveryDate,
    this.qualityGrade,
    this.priority,
    this.specialInstructions,
    this.customPackaging = false,
    this.brandingRequired = false,
    this.draftCreatedAt,
    this.draftExpiresAt,
    this.isDraftExpired = false,
    this.estimatedProductionHours,
    this.estimatedProductionDays,
    this.estimatedDeptHours,
    this.managerName,
    this.dateIn,
    this.timeIn,
    this.dateOut,
    this.timeOut,
    this.sequenceNumber,
    this.plannedStartDate,
    this.plannedEndDate,
    this.actualStartDate,
    this.actualEndDate,
    this.delayReason,
  }) : productSpecifications = productSpecifications ?? const {};

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'quantity': quantity,
      'current_department': currentDepartment.toUpperCase(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'estimated_total_time': estimatedTime,
      'estimated_total_cost': estimatedCost,
      'product_category': productCategory,
      'product_type': productType,
      'product_specifications': productSpecifications,
      'required_delivery_date': _dateOnly(requiredDeliveryDate),
      'quality_grade': qualityGrade,
      'priority': priority,
      'special_instructions': specialInstructions,
      'custom_packaging': customPackaging,
      'draft_created_at': draftCreatedAt?.toIso8601String(),
      'draft_expires_at': draftExpiresAt?.toIso8601String(),
      'is_draft_expired': isDraftExpired,
      'estimated_production_hours': estimatedProductionHours,
      'estimated_production_days': estimatedProductionDays,
      'estimated_dept_hours': estimatedDeptHours,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      orderId: (map['order_id'] ?? '').toString(),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      currentDepartment: (map['current_department'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      createdAt: _parseDateTime(map['created_at']) ?? DateTime.now(),
      estimatedTime: (map['estimated_total_time'] as num?)?.toDouble() ?? 0.0,
      estimatedCost: (map['estimated_total_cost'] as num?)?.toDouble() ?? 0.0,
      productCategory: _nullableString(map['product_category']),
      productType: _nullableString(map['product_type']),
      productSpecifications: _parseJsonMap(map['product_specifications']),
      requiredDeliveryDate: _parseDateTime(map['required_delivery_date']),
      qualityGrade: _nullableString(map['quality_grade']),
      priority: _nullableString(map['priority']),
      specialInstructions: _nullableString(map['special_instructions']),
      customPackaging: map['custom_packaging'] == true,
      brandingRequired: map['branding_required'] == true,
      draftCreatedAt: _parseDateTime(map['draft_created_at']),
      draftExpiresAt: _parseDateTime(map['draft_expires_at']),
      isDraftExpired: map['is_draft_expired'] == true,
      estimatedProductionHours: (map['estimated_production_hours'] as num?)
          ?.toDouble(),
      estimatedProductionDays: (map['estimated_production_days'] as num?)
          ?.toDouble(),
      estimatedDeptHours: _parseDoubleMap(map['estimated_dept_hours']),
    );
  }

  factory OrderModel.fromDeptOrderMap(Map<String, dynamic> map) {
    final orderMain = (map['ordersmain'] is Map<String, dynamic>)
        ? map['ordersmain'] as Map<String, dynamic>
        : <String, dynamic>{};

    return OrderModel(
      orderId: (map['order_id'] ?? orderMain['order_id'] ?? '').toString(),
      quantity:
          (map['quantity'] as num?)?.toInt() ??
          (orderMain['quantity'] as num?)?.toInt() ??
          0,
      currentDepartment:
          (map['department'] ?? orderMain['current_department'] ?? '')
              .toString(),
      status: (map['status'] ?? orderMain['status'] ?? '').toString(),
      createdAt: _parseDateTime(orderMain['created_at']) ?? DateTime.now(),
      estimatedTime:
          (map['estimated_total_time'] as num?)?.toDouble() ??
          (orderMain['estimated_total_time'] as num?)?.toDouble() ??
          0.0,
      estimatedCost:
          (map['estimated_total_cost'] as num?)?.toDouble() ??
          (orderMain['estimated_total_cost'] as num?)?.toDouble() ??
          0.0,
      productCategory:
          _nullableString(map['product_category']) ??
          _nullableString(orderMain['product_category']),
      productType:
          _nullableString(map['product_type']) ??
          _nullableString(orderMain['product_type']),
      productSpecifications:
          _parseJsonMap(map['product_specifications']).isNotEmpty
          ? _parseJsonMap(map['product_specifications'])
          : _parseJsonMap(orderMain['product_specifications']),
      requiredDeliveryDate:
          _parseDateTime(map['required_delivery_date']) ??
          _parseDateTime(orderMain['required_delivery_date']),
      qualityGrade:
          _nullableString(map['quality_grade']) ??
          _nullableString(orderMain['quality_grade']),
      priority:
          _nullableString(map['priority']) ??
          _nullableString(orderMain['priority']),
      specialInstructions:
          _nullableString(map['special_instructions']) ??
          _nullableString(orderMain['special_instructions']),
      customPackaging:
          map['custom_packaging'] == true ||
          orderMain['custom_packaging'] == true,
      brandingRequired:
          map['branding_required'] == true ||
          orderMain['branding_required'] == true,
      draftCreatedAt:
          _parseDateTime(map['draft_created_at']) ??
          _parseDateTime(orderMain['draft_created_at']),
      draftExpiresAt:
          _parseDateTime(map['draft_expires_at']) ??
          _parseDateTime(orderMain['draft_expires_at']),
      isDraftExpired:
          map['is_draft_expired'] == true ||
          orderMain['is_draft_expired'] == true,
      estimatedProductionHours:
          (map['estimated_production_hours'] as num?)?.toDouble() ??
          (orderMain['estimated_production_hours'] as num?)?.toDouble(),
      estimatedProductionDays:
          (map['estimated_production_days'] as num?)?.toDouble() ??
          (orderMain['estimated_production_days'] as num?)?.toDouble(),
      managerName: (map['manager_name'] ?? map['manager_n'] ?? map['manager'])
          ?.toString(),
      dateIn: _parseDateTime(map['date_in']),
      timeIn: _parseTimeOnly(map['time_in']),
      dateOut: _parseDateTime(map['date_out']),
      timeOut: _parseTimeOnly(map['time_out']),
      sequenceNumber: (map['sequence_number'] as num?)?.toInt(),
      plannedStartDate: _parseDateTime(map['planned_start_date']),
      plannedEndDate: _parseDateTime(map['planned_end_date']),
      actualStartDate: _parseDateTime(map['actual_start_date']),
      actualEndDate: _parseDateTime(map['actual_end_date']),
      delayReason: _nullableString(map['delay_reason']),
    );
  }
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.trim().isEmpty ? null : text;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

DateTime? _parseTimeOnly(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse('1970-01-01 ${value.toString()}');
}

Map<String, dynamic> _parseJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

Map<String, double>? _parseDoubleMap(dynamic value) {
  final raw = _parseJsonMap(value);
  if (raw.isEmpty) return null;
  final parsed = <String, double>{};
  raw.forEach((key, item) {
    if (item is num) parsed[key] = item.toDouble();
  });
  return parsed;
}

String? _dateOnly(DateTime? value) {
  if (value == null) return null;
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
