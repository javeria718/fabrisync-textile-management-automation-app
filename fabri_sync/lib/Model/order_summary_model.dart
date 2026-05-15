class OrderSummaryModel {
  const OrderSummaryModel({
    required this.orderId,
    required this.quantity,
    this.productCategory,
    this.productType,
    this.requiredDeliveryDate,
    this.qualityGrade,
    this.priority,
    this.currentDepartment,
    this.orderStatus,
    this.createdAt,
    this.updatedAt,
    this.estimatedProductionHours,
    this.estimatedProductionDays,
    this.estimatedTotalTime,
    this.estimatedTotalCost,
    this.costEstimatedTotal,
    this.completedDepartments = 0,
    this.totalDepartments = 6,
    this.progressPercent = 0,
    this.departmentExpectedHours,
    this.departmentDateIn,
    this.departmentTimeIn,
    this.departmentDateOut,
    this.departmentTimeOut,
    this.departmentStatus,
    this.managerName,
    this.hasCustomPackaging = false,
    this.hasSpecialInstructions = false,
  });

  final String orderId;
  final int quantity;
  final String? productCategory;
  final String? productType;
  final DateTime? requiredDeliveryDate;
  final String? qualityGrade;
  final String? priority;
  final String? currentDepartment;
  final String? orderStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? estimatedProductionHours;
  final int? estimatedProductionDays;
  final double? estimatedTotalTime;
  final double? estimatedTotalCost;
  final double? costEstimatedTotal;
  final int completedDepartments;
  final int totalDepartments;
  final double progressPercent;
  final double? departmentExpectedHours;
  final DateTime? departmentDateIn;
  final String? departmentTimeIn;
  final DateTime? departmentDateOut;
  final String? departmentTimeOut;
  final String? departmentStatus;
  final String? managerName;
  final bool hasCustomPackaging;
  final bool hasSpecialInstructions;

  factory OrderSummaryModel.fromMap(Map<String, dynamic> map) {
    return OrderSummaryModel(
      orderId: (map['order_id'] ?? '').toString(),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      productCategory: _nullableString(map['product_category']),
      productType: _nullableString(map['product_type']),
      requiredDeliveryDate: _parseDateTime(map['required_delivery_date']),
      qualityGrade: _nullableString(map['quality_grade']),
      priority: _nullableString(map['priority']),
      currentDepartment: _nullableString(map['current_department']),
      orderStatus:
          _nullableString(map['order_status']) ??
          _nullableString(map['status']),
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
      estimatedProductionHours: (map['estimated_production_hours'] as num?)
          ?.toDouble(),
      estimatedProductionDays: (map['estimated_production_days'] as num?)
          ?.toInt(),
      estimatedTotalTime: (map['estimated_total_time'] as num?)?.toDouble(),
      estimatedTotalCost: (map['estimated_total_cost'] as num?)?.toDouble(),
      costEstimatedTotal: (map['cost_estimated_total'] as num?)?.toDouble(),
      completedDepartments:
          (map['completed_departments'] as num?)?.toInt() ?? 0,
      totalDepartments: (map['total_departments'] as num?)?.toInt() ?? 6,
      progressPercent: (map['progress_percent'] as num?)?.toDouble() ?? 0,
      departmentExpectedHours: (map['expected_hours'] as num?)?.toDouble(),
      departmentDateIn: _parseDateTime(map['date_in']),
      departmentTimeIn: _nullableString(map['time_in']),
      departmentDateOut: _parseDateTime(map['date_out']),
      departmentTimeOut: _nullableString(map['time_out']),
      departmentStatus: _nullableString(map['status']),
      managerName: _nullableString(map['manager_name']),
      hasCustomPackaging: map['has_custom_packaging'] == true,
      hasSpecialInstructions: map['has_special_instructions'] == true,
    );
  }
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
