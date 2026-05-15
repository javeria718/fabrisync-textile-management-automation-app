import 'package:fabri_sync/services/abaya/abaya_calculation_service.dart';
import 'package:fabri_sync/services/bedsheet/bedsheet_calculation_service.dart';
import 'package:fabri_sync/services/curtain/curtain_calculation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Request model for order estimation.
/// Routes to category-specific services (Curtain, Abaya, Bedsheet).
/// Each category uses its dedicated cost configuration table.
class OrderDraftInput {
  const OrderDraftInput({
    required this.productCategory,
    required this.productType,
    required this.quantity,
    required this.requiredDeliveryDate,
    required this.qualityGrade,
    required this.specifications,
  });

  final String productCategory;
  final String productType;
  final int quantity;
  final DateTime requiredDeliveryDate;
  final String qualityGrade;
  final Map<String, dynamic> specifications;
}

class OrderCostBreakdown {
  const OrderCostBreakdown({
    required this.materialCostPerUnit,
    required this.laborCostPerUnit,
    required this.processingCost,
    required this.additionalCharges,
    required this.materialTotalCost,
    required this.laborTotalCost,
    required this.processingTotalCost,
    required this.additionalTotalCost,
    required this.rushCharges,
    required this.estimatedTotalCost,
  });

  final double materialCostPerUnit;
  final double laborCostPerUnit;
  final double processingCost;
  final double additionalCharges;
  final double materialTotalCost;
  final double laborTotalCost;
  final double processingTotalCost;
  final double additionalTotalCost;
  final double rushCharges;
  final double estimatedTotalCost;

  Map<String, dynamic> toInsertMap(String orderId) {
    return {
      'order_id': orderId,
      'material_cost_per_unit': materialCostPerUnit,
      'labor_cost_per_unit': laborCostPerUnit,
      'processing_cost': processingCost,
      'additional_charges': additionalCharges,
      'material_total_cost': materialTotalCost,
      'labor_total_cost': laborTotalCost,
      'processing_total_cost': processingTotalCost,
      'additional_total_cost': additionalTotalCost,
      'rush_charges': rushCharges,
      'estimated_total_cost': estimatedTotalCost,
    };
  }
}

class DepartmentScheduleItem {
  const DepartmentScheduleItem({
    required this.sequenceNumber,
    required this.departmentDb,
    required this.departmentLabel,
    required this.plannedStartDate,
    required this.plannedEndDate,
    required this.estimatedHours,
    required this.estimatedDays,
    required this.status,
  });

  final int sequenceNumber;
  final String departmentDb;
  final String departmentLabel;
  final DateTime plannedStartDate;
  final DateTime plannedEndDate;
  final double estimatedHours;
  final int estimatedDays;
  final String status;

  Map<String, dynamic> toDepartmentOrderUpdateMap() {
    return {
      'sequence_number': sequenceNumber,
      'planned_start_date': _dateOnly(plannedStartDate),
      'planned_end_date': _dateOnly(plannedEndDate),
      'actual_start_date': _dateOnly(plannedStartDate),
      'expected_hours': estimatedHours,
    };
  }
}

class OrderCalculationResult {
  const OrderCalculationResult({
    required this.estimatedProductionHours,
    required this.estimatedProductionDays,
    required this.priority,
    required this.costBreakdown,
    required this.departmentSchedule,
    required this.departmentHours,
  });

  final double estimatedProductionHours;
  final int estimatedProductionDays;
  final String priority;
  final OrderCostBreakdown costBreakdown;
  final List<DepartmentScheduleItem> departmentSchedule;
  final Map<String, double> departmentHours;

  List<DepartmentScheduleItem> get schedule => departmentSchedule;
  double get estimatedWorkDaysExact => estimatedProductionHours / 8;
  double get materialTotal => costBreakdown.materialTotalCost;
  double get laborTotal => costBreakdown.laborTotalCost;
  double get processingTotal => costBreakdown.processingTotalCost;
  double get additionalTotal => costBreakdown.additionalTotalCost;
  double get subtotal =>
      materialTotal + laborTotal + processingTotal + additionalTotal;
  double get rushCharges => costBreakdown.rushCharges;
  double get estimatedTotalCost => costBreakdown.estimatedTotalCost;
}

typedef CalculationResult = OrderCalculationResult;

class OrderCalculationService {
  OrderCalculationService({SupabaseClient? client})
    : supabase = client ?? Supabase.instance.client;

  final SupabaseClient supabase;

  /// Calculate order estimate using category-specific logic.
  ///
  /// Routes to category-specific calculation services:
  /// - 'curtain' → CurtainCalculationService
  /// - 'abaya' → AbayaCalculationService
  /// - 'bedsheet' → BedsheetCalculationService
  ///
  /// Each category uses its dedicated cost configuration table.
  /// Throws exception for unrecognized categories (no fallback).
  Future<CalculationResult> calculateOrderEstimate(
    OrderDraftInput input,
  ) async {
    final category = input.productCategory.toLowerCase().trim();

    if (category == 'curtain') {
      return _calculateCurtainEstimate(input);
    }

    if (category == 'abaya') {
      return _calculateAbayaEstimate(input);
    }

    if (category == 'bedsheet') {
      return _calculateBedsheetEstimate(input);
    }

    // Fail loudly for unrecognized categories - no silent fallback
    throw Exception(
      'Unsupported product category: "${input.productCategory}". '
      'Supported categories are: Curtain, Abaya, Bedsheet. '
      'Category-specific cost configurations are required.',
    );
  }

  /// Calculate curtain order using specialized textile manufacturing logic
  Future<CalculationResult> _calculateCurtainEstimate(
    OrderDraftInput input,
  ) async {
    final curtainService = CurtainCalculationService(client: supabase);

    // Extract specifications
    final specs = input.specifications;

    // Build curtain calculation request
    final curtainRequest = CurtainCalculationRequest(
      curtainType: input.productType,
      fabricType: (specs['fabric_type'] as String?) ?? 'Sheer',
      headerStyle: (specs['header_style'] as String?) ?? 'Rod Pocket',
      length: (specs['length'] as num?)?.toDouble() ?? 1.5,
      width: (specs['width'] as num?)?.toDouble() ?? 1.0,
      quantity: input.quantity,
      qualityGrade: input.qualityGrade,
      requiredDeliveryDate: input.requiredDeliveryDate,
      customPackaging: (specs['custom_packaging'] as bool?) ?? false,
    );

    // Use curtain calculation service
    return curtainService.calculateCurtainEstimate(curtainRequest);
  }

  /// Calculate abaya orders using specialized abaya logic
  Future<CalculationResult> _calculateAbayaEstimate(
    OrderDraftInput input,
  ) async {
    final abayaService = AbayaCalculationService(client: supabase);
    final specs = input.specifications;

    final abayaRequest = AbayaCalculationRequest(
      abayaType: input.productType,
      fabricType: (specs['fabric_type'] as String?) ?? 'Nidha',
      size: (specs['size_range'] as String?) ?? 'Medium',
      quantity: input.quantity,
      qualityGrade: input.qualityGrade,
      embellishment: (specs['embellishment'] as bool?) ?? false,
      requiredDeliveryDate: input.requiredDeliveryDate,
      customPackaging: (specs['custom_packaging'] as bool?) ?? false,
    );

    return abayaService.calculateAbayaEstimate(abayaRequest);
  }

  /// Calculate bedsheet orders using dedicated bedsheet logic
  Future<CalculationResult> _calculateBedsheetEstimate(
    OrderDraftInput input,
  ) async {
    final bedsheetService = BedsheetCalculationService(client: supabase);
    final specs = input.specifications;

    final bedsheetRequest = BedsheetCalculationRequest(
      bedsheetType: input.productType,
      fabricType: (specs['fabric_type'] as String?) ?? 'Cotton',
      bedSize: (specs['bed_size'] as String?) ?? 'Single',
      quantity: input.quantity,
      qualityGrade: input.qualityGrade,
      printingRequired: (specs['printing_required'] as bool?) ?? false,
      requiredDeliveryDate: input.requiredDeliveryDate,
      customPackaging: (specs['custom_packaging'] as bool?) ?? false,
    );

    return bedsheetService.calculateBedsheetEstimate(bedsheetRequest);
  }

  @Deprecated('Use calculateOrderEstimate instead.')
  Future<CalculationResult> calculate(OrderDraftInput input) {
    return calculateOrderEstimate(input);
  }
}

/// Helper: Convert DateTime to SQL date string (yyyy-MM-dd format)
String _dateOnly(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
