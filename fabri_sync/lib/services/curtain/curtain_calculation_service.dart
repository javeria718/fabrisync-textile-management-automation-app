/// Curtain calculation service
/// Implements realistic textile manufacturing costing and time estimation
/// All curtain-specific logic is isolated in this service

import 'dart:math';
import 'package:fabri_sync/services/curtain/curtain_cost_config.dart';
import 'package:fabri_sync/services/curtain/curtain_cost_repository.dart';
import 'package:fabri_sync/services/curtain/curtain_pricing_rules.dart';
import 'package:fabri_sync/services/order_calculation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Request model for curtain order calculation
class CurtainCalculationRequest {
  const CurtainCalculationRequest({
    required this.curtainType,
    required this.fabricType,
    required this.headerStyle,
    required this.length,
    required this.width,
    required this.quantity,
    required this.qualityGrade,
    required this.requiredDeliveryDate,
    required this.customPackaging,
  });

  final String curtainType;
  final String fabricType;
  final String headerStyle;
  final double length; // in meters
  final double width; // in meters
  final int quantity;
  final String qualityGrade;
  final DateTime requiredDeliveryDate;
  final bool customPackaging;
}

/// Result model for curtain cost breakdown
class CurtainCostBreakdown {
  const CurtainCostBreakdown({
    required this.fabricAreaPerUnit,
    required this.effectiveFabricArea,
    required this.materialCostPerUnit,
    required this.totalMaterialCost,
    required this.baseLaborHoursPerUnit,
    required this.totalLaborHours,
    required this.laborCostPerUnit,
    required this.totalLaborCost,
    required this.baseProcessingCost,
    required this.headerProcessingCost,
    required this.qualityQcCost,
    required this.totalProcessingCost,
    required this.packagingCost,
    required this.transportHandling,
    required this.premiumFinishing,
    required this.subtotal,
    required this.rushCharges,
    required this.estimatedTotalCost,
  });

  final double fabricAreaPerUnit;
  final double effectiveFabricArea;
  final double materialCostPerUnit;
  final double totalMaterialCost;
  final double baseLaborHoursPerUnit;
  final double totalLaborHours;
  final double laborCostPerUnit;
  final double totalLaborCost;
  final double baseProcessingCost;
  final double headerProcessingCost;
  final double qualityQcCost;
  final double totalProcessingCost;
  final double packagingCost;
  final double transportHandling;
  final double premiumFinishing;
  final double subtotal;
  final double rushCharges;
  final double estimatedTotalCost;

  Map<String, dynamic> toMap() {
    return {
      'fabric_area_per_unit': fabricAreaPerUnit,
      'effective_fabric_area': effectiveFabricArea,
      'material_cost_per_unit': materialCostPerUnit,
      'total_material_cost': totalMaterialCost,
      'base_labor_hours_per_unit': baseLaborHoursPerUnit,
      'total_labor_hours': totalLaborHours,
      'labor_cost_per_unit': laborCostPerUnit,
      'total_labor_cost': totalLaborCost,
      'base_processing_cost': baseProcessingCost,
      'header_processing_cost': headerProcessingCost,
      'quality_qc_cost': qualityQcCost,
      'total_processing_cost': totalProcessingCost,
      'packaging_cost': packagingCost,
      'transport_handling': transportHandling,
      'premium_finishing': premiumFinishing,
      'subtotal': subtotal,
      'rush_charges': rushCharges,
      'estimated_total_cost': estimatedTotalCost,
    };
  }
}

/// Main service for all curtain calculations
class CurtainCalculationService {
  CurtainCalculationService({
    CurtainCostRepository? repository,
    SupabaseClient? client,
  }) : _repository = repository ?? CurtainCostRepository(client: client),
       _client = client ?? Supabase.instance.client;

  final CurtainCostRepository _repository;
  final SupabaseClient _client;

  // ============================================================================
  // MAIN CALCULATION ENTRYPOINT
  // ============================================================================

  /// Calculate complete curtain order estimate
  /// This is the primary method called from OrderCalculationService
  Future<CalculationResult> calculateCurtainEstimate(
    CurtainCalculationRequest request,
  ) async {
    // Validate input
    final validation = CurtainPricingRules.validateCurtainSpecs(
      curtainType: request.curtainType,
      fabricType: request.fabricType,
      headerStyle: request.headerStyle,
      qualityGrade: request.qualityGrade,
      length: request.length,
      width: request.width,
      quantity: request.quantity,
    );

    if (!validation.isValid) {
      throw Exception(
        'Curtain validation failed: ${validation.errors.join(', ')}',
      );
    }

    // Fetch configuration from database
    final costConfig = await _repository.fetchCurtainCostConfig(
      curtainType: request.curtainType,
      fabricType: request.fabricType,
      headerStyle: request.headerStyle,
    );

    if (costConfig == null) {
      throw Exception(
        'Curtain cost configuration not found for: '
        '${request.curtainType}, ${request.fabricType}, ${request.headerStyle}',
      );
    }

    // Build runtime configuration
    final runtimeConfig = CurtainRuntimeConfig.from(
      config: costConfig,
      qualityGrade: request.qualityGrade,
    );

    // Perform calculations
    return _performCalculation(request, runtimeConfig);
  }

  // ============================================================================
  // CALCULATION LOGIC
  // ============================================================================

  CalculationResult _performCalculation(
    CurtainCalculationRequest request,
    CurtainRuntimeConfig config,
  ) {
    // === FABRIC AREA & WASTAGE ===
    final fabricAreaPerUnit = request.length * request.width;
    final wastagePercent = config.wastagePercent / 100;
    final effectiveFabricAreaPerUnit = fabricAreaPerUnit * (1 + wastagePercent);
    final effectiveFabricAreaTotal =
        effectiveFabricAreaPerUnit * request.quantity;

    // === MATERIAL COST ===
    final materialCostPerUnit =
        effectiveFabricAreaPerUnit * config.materialRatePerSqMeter;
    final totalMaterialCost = materialCostPerUnit * request.quantity;

    // === LABOR HOURS & COST ===
    final baseLaborHours = config.baseLaborHoursPerUnit;
    final headerLaborHours =
        CurtainPricingRules
            .headerStyleConfigs[config.headerStyle]
            ?.laborHoursAdd ??
        0.0;
    final ringInstallationLabor =
        CurtainPricingRules
            .headerStyleConfigs[config.headerStyle]
            ?.ringInstallationLabor ??
        0.0;

    // Scale labor by area (more fabric = more handling time)
    final areaLaborScale = 0.05 * fabricAreaPerUnit; // 0.05 hours per sq meter

    // Scale labor by quantity efficiency
    final quantityEfficiency = CurtainPricingRules.getQuantityEfficiencyRule(
      request.quantity,
    );

    // Calculate per-unit labor hours
    var laborHoursPerUnit =
        (baseLaborHours + headerLaborHours) *
        config.totalLaborMultiplier *
        config.totalComplexityMultiplier *
        quantityEfficiency.laborEfficiency;

    // Add area-based labor
    laborHoursPerUnit += areaLaborScale * config.totalLaborMultiplier;

    // Add header-specific labor
    laborHoursPerUnit += ringInstallationLabor;

    final totalLaborHours = laborHoursPerUnit * request.quantity;
    final laborCostPerUnit =
        laborHoursPerUnit * CurtainPricingRules.laborRatePerHour;
    final totalLaborCost = laborCostPerUnit * request.quantity;

    // === PROCESSING COSTS ===
    final baseProcessing = config.baseProcessingCost;
    final headerProcessing = config.headerProcessingCost;
    final totalProcessingPerUnit = baseProcessing + headerProcessing;
    final totalProcessingCost = totalProcessingPerUnit * request.quantity;

    // === QUALITY QC COST ===
    final qualityConfig =
        CurtainPricingRules.qualityGradeConfigs[config.qualityGrade];
    final qcMultiplier = qualityConfig?.qcMultiplier ?? 1.0;
    final finishingMultiplier = qualityConfig?.finishingMultiplier ?? 1.0;

    // QC time based on area and quality
    final qcHoursPerUnit = fabricAreaPerUnit * 0.02 * qcMultiplier;
    final qcCostPerUnit = qcHoursPerUnit * CurtainPricingRules.laborRatePerHour;
    final qualityQcCost = qcCostPerUnit * request.quantity;

    // === PREMIUM FINISHING ===
    final premiumFinishing =
        (fabricAreaPerUnit *
            CurtainPricingRules.premiumFinishingPerSqMeter *
            finishingMultiplier) *
        request.quantity;

    // === PACKAGING ===
    final packagingCost = request.customPackaging
        ? CurtainPricingRules.packagingChargePerUnit * request.quantity
        : 0.0;

    // === TRANSPORT & HANDLING ===
    final transportHandling = CurtainPricingRules.transportHandlingCharge;

    // === QUANTITY SURCHARGES ===
    final quantitySurcharge =
        totalMaterialCost * quantityEfficiency.setupSurcharge;

    // === SUBTOTAL & RUSH CHARGES ===
    final subtotal =
        totalMaterialCost +
        totalLaborCost +
        totalProcessingCost +
        qualityQcCost +
        premiumFinishing +
        packagingCost +
        transportHandling +
        (quantitySurcharge > 0 ? quantitySurcharge : 0);

    // === RUSH CHARGES ===
    final now = DateTime.now();
    final deliveryDate = request.requiredDeliveryDate;
    final daysAvailable = deliveryDate.difference(now).inDays.abs().toDouble();
    final isRush = daysAvailable < totalLaborHours / 8;
    final rushCharges = isRush
        ? subtotal * CurtainPricingRules.rushChargePercentage
        : 0.0;

    final estimatedTotal = subtotal + rushCharges;

    // === BUILD COST BREAKDOWN ===
    final costBreakdown = CurtainCostBreakdown(
      fabricAreaPerUnit: fabricAreaPerUnit,
      effectiveFabricArea: effectiveFabricAreaPerUnit,
      materialCostPerUnit: materialCostPerUnit,
      totalMaterialCost: totalMaterialCost,
      baseLaborHoursPerUnit: laborHoursPerUnit,
      totalLaborHours: totalLaborHours,
      laborCostPerUnit: laborCostPerUnit,
      totalLaborCost: totalLaborCost,
      baseProcessingCost: baseProcessing,
      headerProcessingCost: headerProcessing,
      qualityQcCost: qualityQcCost,
      totalProcessingCost: totalProcessingCost,
      packagingCost: packagingCost,
      transportHandling: transportHandling,
      premiumFinishing: premiumFinishing,
      subtotal: subtotal,
      rushCharges: rushCharges,
      estimatedTotalCost: estimatedTotal,
    );

    // === TIME ESTIMATION ===
    final estimatedProductionDays = max(1, (totalLaborHours / 8).ceil());
    final priority = isRush ? 'Rush' : 'Normal';

    // === BUILD DEPARTMENT SCHEDULE ===
    final departmentSchedule = _buildCurtainDepartmentSchedule(
      totalLaborHours: totalLaborHours,
      startDate: now,
      quantity: request.quantity,
      fabricArea: fabricAreaPerUnit,
    );

    final departmentHours = {
      for (final item in departmentSchedule)
        item.departmentDb: item.estimatedHours,
    };

    // === BUILD FINAL RESULT ===
    return CalculationResult(
      estimatedProductionHours: totalLaborHours,
      estimatedProductionDays: estimatedProductionDays,
      priority: priority,
      costBreakdown: OrderCostBreakdown(
        materialCostPerUnit: costBreakdown.materialCostPerUnit,
        laborCostPerUnit: costBreakdown.laborCostPerUnit,
        processingCost: costBreakdown.baseProcessingCost,
        additionalCharges: costBreakdown.packagingCost,
        materialTotalCost: costBreakdown.totalMaterialCost,
        laborTotalCost: costBreakdown.totalLaborCost,
        processingTotalCost: costBreakdown.totalProcessingCost,
        additionalTotalCost: costBreakdown.qualityQcCost,
        rushCharges: costBreakdown.rushCharges,
        estimatedTotalCost: costBreakdown.estimatedTotalCost,
      ),
      departmentSchedule: departmentSchedule,
      departmentHours: departmentHours,
    );
  }

  // ============================================================================
  // DEPARTMENT SCHEDULING
  // ============================================================================

  List<DepartmentScheduleItem> _buildCurtainDepartmentSchedule({
    required double totalLaborHours,
    required DateTime startDate,
    required int quantity,
    required double fabricArea,
  }) {
    const curtainDepartmentSplits = [
      _CurtainDepartmentSplit(
        1,
        'CUTTING',
        'Cutting & Measuring',
        0.20,
      ), // Cutting fabric sheets
      _CurtainDepartmentSplit(
        2,
        'STITCHING',
        'Stitching & Seaming',
        0.45,
      ), // Main stitching work
      _CurtainDepartmentSplit(
        3,
        'HEADER_INSTALLATION',
        'Header Installation',
        0.15,
      ), // Header/eyelet/pleats
      _CurtainDepartmentSplit(
        4,
        'FINISHING',
        'Finishing & Ironing',
        0.10,
      ), // Ironing and finishing
      _CurtainDepartmentSplit(
        5,
        'QUALITY_CONTROL',
        'Quality Control',
        0.05,
      ), // QC inspection
      _CurtainDepartmentSplit(
        6,
        'PACKAGING',
        'Packaging & Dispatch',
        0.05,
      ), // Packaging
    ];

    final items = <DepartmentScheduleItem>[];
    var cursor = startDate;

    for (final split in curtainDepartmentSplits) {
      final deptHours = totalLaborHours * split.percent;
      final deptDays = deptHours >= 8 ? (deptHours / 8).ceil() : 0;

      // Calculate realistic end time (8 hours per day)
      final endDate = cursor.add(Duration(days: deptDays));

      items.add(
        DepartmentScheduleItem(
          sequenceNumber: split.sequenceNumber,
          departmentDb: split.departmentDb,
          departmentLabel: split.departmentLabel,
          plannedStartDate: cursor,
          plannedEndDate: endDate,
          estimatedHours: deptHours,
          estimatedDays: deptDays,
          status: split.sequenceNumber == 1 ? 'inprogress' : 'planned',
        ),
      );

      cursor = endDate;
    }

    return items;
  }
}

/// Helper class for curtain-specific department allocations
class _CurtainDepartmentSplit {
  const _CurtainDepartmentSplit(
    this.sequenceNumber,
    this.departmentDb,
    this.departmentLabel,
    this.percent,
  );

  final int sequenceNumber;
  final String departmentDb;
  final String departmentLabel;
  final double percent;
}
