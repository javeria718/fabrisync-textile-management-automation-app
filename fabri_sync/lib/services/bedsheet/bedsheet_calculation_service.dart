/// Bedsheet-specific calculation service.
/// All bedsheet cost and schedule logic is isolated here.

import 'dart:math';
import 'package:fabri_sync/services/bedsheet/bedsheet_cost_config.dart';
import 'package:fabri_sync/services/bedsheet/bedsheet_cost_repository.dart';
import 'package:fabri_sync/services/bedsheet/bedsheet_pricing_rules.dart';
import 'package:fabri_sync/services/order_calculation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BedsheetCalculationRequest {
  const BedsheetCalculationRequest({
    required this.bedsheetType,
    required this.fabricType,
    required this.bedSize,
    required this.quantity,
    required this.qualityGrade,
    required this.printingRequired,
    required this.requiredDeliveryDate,
    required this.customPackaging,
  });

  final String bedsheetType;
  final String fabricType;
  final String bedSize;
  final int quantity;
  final String qualityGrade;
  final bool printingRequired;
  final DateTime requiredDeliveryDate;
  final bool customPackaging;
}

class BedsheetCostBreakdown {
  const BedsheetCostBreakdown({
    required this.fabricConsumptionPerUnit,
    required this.totalFabricConsumption,
    required this.materialCostPerUnit,
    required this.totalMaterialCost,
    required this.laborHoursPerUnit,
    required this.totalLaborHours,
    required this.laborCostPerUnit,
    required this.totalLaborCost,
    required this.processingCostPerUnit,
    required this.totalProcessingCost,
    required this.qcCostPerUnit,
    required this.totalQcCost,
    required this.printingSetupCost,
    required this.packagingCost,
    required this.customPackagingCost,
    required this.premiumHandlingCost,
    required this.quantitySurcharge,
    required this.subtotal,
    required this.rushCharges,
    required this.estimatedTotalCost,
  });

  final double fabricConsumptionPerUnit;
  final double totalFabricConsumption;
  final double materialCostPerUnit;
  final double totalMaterialCost;
  final double laborHoursPerUnit;
  final double totalLaborHours;
  final double laborCostPerUnit;
  final double totalLaborCost;
  final double processingCostPerUnit;
  final double totalProcessingCost;
  final double qcCostPerUnit;
  final double totalQcCost;
  final double printingSetupCost;
  final double packagingCost;
  final double customPackagingCost;
  final double premiumHandlingCost;
  final double quantitySurcharge;
  final double subtotal;
  final double rushCharges;
  final double estimatedTotalCost;

  Map<String, dynamic> toMap() {
    return {
      'fabric_consumption_per_unit': fabricConsumptionPerUnit,
      'total_fabric_consumption': totalFabricConsumption,
      'material_cost_per_unit': materialCostPerUnit,
      'total_material_cost': totalMaterialCost,
      'labor_hours_per_unit': laborHoursPerUnit,
      'total_labor_hours': totalLaborHours,
      'labor_cost_per_unit': laborCostPerUnit,
      'total_labor_cost': totalLaborCost,
      'processing_cost_per_unit': processingCostPerUnit,
      'total_processing_cost': totalProcessingCost,
      'qc_cost_per_unit': qcCostPerUnit,
      'total_qc_cost': totalQcCost,
      'printing_setup_cost': printingSetupCost,
      'packaging_cost': packagingCost,
      'custom_packaging_cost': customPackagingCost,
      'premium_handling_cost': premiumHandlingCost,
      'quantity_surcharge': quantitySurcharge,
      'subtotal': subtotal,
      'rush_charges': rushCharges,
      'estimated_total_cost': estimatedTotalCost,
    };
  }
}

class BedsheetCalculationService {
  BedsheetCalculationService({
    BedsheetCostRepository? repository,
    SupabaseClient? client,
  }) : _repository = repository ?? BedsheetCostRepository(client: client),
       _client = client ?? Supabase.instance.client;

  final BedsheetCostRepository _repository;
  final SupabaseClient _client;

  /// Calculate bedsheet estimate using dedicated module logic.
  Future<CalculationResult> calculateBedsheetEstimate(
    BedsheetCalculationRequest request,
  ) async {
    final validation = BedsheetPricingRules.validateBedsheetSpecs(
      bedsheetType: request.bedsheetType,
      fabricType: request.fabricType,
      bedSize: request.bedSize,
      qualityGrade: request.qualityGrade,
      quantity: request.quantity,
    );

    if (!validation.isValid) {
      throw Exception(
        'Bedsheet validation failed: ${validation.errors.join(', ')}',
      );
    }

    final costConfig = await _repository.fetchBedsheetCostConfig(
      bedsheetType: request.bedsheetType,
      fabricType: request.fabricType,
      bedSize: request.bedSize,
      qualityGrade: request.qualityGrade,
    );

    if (costConfig == null) {
      throw Exception(
        'Bedsheet cost configuration not found for: '
        '${request.bedsheetType}, ${request.fabricType}, ${request.bedSize}, ${request.qualityGrade}',
      );
    }

    final runtimeConfig = BedsheetRuntimeConfig.from(config: costConfig);
    return _performCalculation(request, runtimeConfig);
  }

  CalculationResult _performCalculation(
    BedsheetCalculationRequest request,
    BedsheetRuntimeConfig config,
  ) {
    final quantityEfficiency = BedsheetPricingRules.getQuantityEfficiencyRule(
      request.quantity,
    );

    final fabricUsageFactor = request.bedsheetType == 'Pillow Cover Set'
        ? 0.65
        : 1.0;
    final fabricConsumptionPerUnit =
        config.sizeFabricMeters *
        fabricUsageFactor *
        (1 + config.wastagePercent / 100);
    final totalFabricConsumption = fabricConsumptionPerUnit * request.quantity;
    final materialCostPerUnit =
        fabricConsumptionPerUnit * config.materialRatePerMeter;
    final totalMaterialCost = materialCostPerUnit * request.quantity;

    final cuttingHoursPerUnit =
        0.25 *
        config.sizeCuttingMultiplier *
        config.typeCuttingComplexity *
        config.fabricStitchingDifficulty *
        config.qualityLaborMultiplier;
    var stitchingHoursPerUnit =
        config.baseLaborHours *
        config.typeComplexity *
        config.laborMultiplier *
        config.sizeStitchingMultiplier *
        config.qualityLaborMultiplier;
    var finishingHoursPerUnit =
        0.30 *
        config.sizeFinishingMultiplier *
        config.qualityFinishingMultiplier *
        config.typeFinishingComplexity *
        config.fabricFinishingDifficulty;
    final printingHours = request.printingRequired
        ? BedsheetPricingRules.printingLaborHours
        : 0.0;

    if (request.printingRequired) {
      finishingHoursPerUnit *= 1.20;
    }

    var laborHoursPerUnit =
        (cuttingHoursPerUnit + stitchingHoursPerUnit + finishingHoursPerUnit) *
        quantityEfficiency.laborEfficiency;
    laborHoursPerUnit += printingHours;
    final totalLaborHours = laborHoursPerUnit * request.quantity;
    final laborCostPerUnit =
        laborHoursPerUnit * BedsheetPricingRules.laborRatePerHour;
    final totalLaborCost = laborCostPerUnit * request.quantity;

    final qcHoursPerUnit =
        0.20 *
            config.qualityQcMultiplier *
            config.fabricQcSensitivity *
            config.typeQcRequirement +
        (request.printingRequired ? 0.15 : 0.0);
    final qcCostPerUnit =
        qcHoursPerUnit * BedsheetPricingRules.laborRatePerHour;
    final totalQcCost = qcCostPerUnit * request.quantity;

    final processingCostPerUnit =
        config.processingRate * (request.printingRequired ? 1.20 : 1.0);
    final totalProcessingCost = processingCostPerUnit * request.quantity;

    final printingSetupCost = request.printingRequired
        ? config.printingCharge
        : 0.0;
    final packagingCost =
        BedsheetPricingRules.packagingBasePerUnit *
        config.sizePackagingMultiplier *
        request.quantity;
    final customPackagingCost = request.customPackaging
        ? packagingCost * BedsheetPricingRules.customPackagingSurcharge
        : 0.0;
    final premiumHandlingCost =
        config.fabricPremiumHandlingSurcharge * request.quantity;

    final quantitySurcharge =
        totalMaterialCost * quantityEfficiency.setupSurcharge;
    final subtotal =
        totalMaterialCost +
        totalLaborCost +
        totalProcessingCost +
        totalQcCost +
        packagingCost +
        customPackagingCost +
        premiumHandlingCost +
        printingSetupCost +
        quantitySurcharge;

    final now = DateTime.now();
    final availableDays = request.requiredDeliveryDate
        .difference(now)
        .inDays
        .toDouble();
    final isRush = availableDays < max(1, totalLaborHours / 8);
    final rushCharges = isRush
        ? subtotal * BedsheetPricingRules.rushChargePercentage
        : 0.0;
    final estimatedTotalCost = subtotal + rushCharges;
    final estimatedProductionDays = max(1, (totalLaborHours / 8).ceil());

    final costBreakdown = BedsheetCostBreakdown(
      fabricConsumptionPerUnit: fabricConsumptionPerUnit,
      totalFabricConsumption: totalFabricConsumption,
      materialCostPerUnit: materialCostPerUnit,
      totalMaterialCost: totalMaterialCost,
      laborHoursPerUnit: laborHoursPerUnit,
      totalLaborHours: totalLaborHours,
      laborCostPerUnit: laborCostPerUnit,
      totalLaborCost: totalLaborCost,
      processingCostPerUnit: processingCostPerUnit,
      totalProcessingCost: totalProcessingCost,
      qcCostPerUnit: qcCostPerUnit,
      totalQcCost: totalQcCost,
      printingSetupCost: printingSetupCost,
      packagingCost: packagingCost,
      customPackagingCost: customPackagingCost,
      premiumHandlingCost: premiumHandlingCost,
      quantitySurcharge: quantitySurcharge,
      subtotal: subtotal,
      rushCharges: rushCharges,
      estimatedTotalCost: estimatedTotalCost,
    );

    final departmentSchedule = _buildBedsheetDepartmentSchedule(
      totalLaborHours: totalLaborHours,
      startDate: now,
      qualityGrade: request.qualityGrade,
      fabricType: request.fabricType,
      bedSize: request.bedSize,
      printingRequired: request.printingRequired,
    );

    final departmentHours = {
      for (final item in departmentSchedule)
        item.departmentDb: item.estimatedHours,
    };

    return CalculationResult(
      estimatedProductionHours: totalLaborHours,
      estimatedProductionDays: estimatedProductionDays,
      priority: isRush ? 'Rush' : 'Normal',
      costBreakdown: OrderCostBreakdown(
        materialCostPerUnit: costBreakdown.materialCostPerUnit,
        laborCostPerUnit: costBreakdown.laborCostPerUnit,
        processingCost: costBreakdown.processingCostPerUnit,
        additionalCharges:
            costBreakdown.packagingCost +
            costBreakdown.customPackagingCost +
            costBreakdown.premiumHandlingCost +
            costBreakdown.printingSetupCost +
            costBreakdown.quantitySurcharge,
        materialTotalCost: costBreakdown.totalMaterialCost,
        laborTotalCost: costBreakdown.totalLaborCost,
        processingTotalCost: costBreakdown.totalProcessingCost,
        additionalTotalCost:
            costBreakdown.totalQcCost +
            costBreakdown.packagingCost +
            costBreakdown.customPackagingCost +
            costBreakdown.premiumHandlingCost +
            costBreakdown.printingSetupCost +
            costBreakdown.quantitySurcharge,
        rushCharges: costBreakdown.rushCharges,
        estimatedTotalCost: costBreakdown.estimatedTotalCost,
      ),
      departmentSchedule: departmentSchedule,
      departmentHours: departmentHours,
    );
  }

  List<DepartmentScheduleItem> _buildBedsheetDepartmentSchedule({
    required double totalLaborHours,
    required DateTime startDate,
    required String qualityGrade,
    required String fabricType,
    required String bedSize,
    required bool printingRequired,
  }) {
    var cuttingPercent = 0.18;
    var stitchingPercent = 0.44;
    var threadingPercent = 0.10;
    var qualityPercent = 0.14;
    var packagingPercent = 0.07;
    var inspectionPercent = 0.07;

    if (qualityGrade == 'Premium') {
      qualityPercent += 0.02;
      stitchingPercent -= 0.02;
    }
    if (fabricType == 'Silk') {
      inspectionPercent += 0.01;
      stitchingPercent -= 0.01;
    }
    if (bedSize == 'King') {
      packagingPercent += 0.01;
      stitchingPercent -= 0.01;
    }
    if (printingRequired) {
      inspectionPercent += 0.01;
      stitchingPercent -= 0.01;
    }

    final scheduleSplits = <_BedsheetDepartmentSplit>[
      _BedsheetDepartmentSplit(1, 'CUTTING', 'Cutting', cuttingPercent),
      _BedsheetDepartmentSplit(2, 'STITCHING', 'Stitching', stitchingPercent),
      _BedsheetDepartmentSplit(3, 'THREADING', 'Threading', threadingPercent),
      _BedsheetDepartmentSplit(
        4,
        'QUALITY_CONTROL',
        'Quality Control',
        qualityPercent,
      ),
      _BedsheetDepartmentSplit(5, 'PACKAGING', 'Packaging', packagingPercent),
      _BedsheetDepartmentSplit(
        6,
        'INSPECTION',
        'Inspection',
        inspectionPercent,
      ),
    ];

    final items = <DepartmentScheduleItem>[];
    var cursor = startDate;

    for (final split in scheduleSplits) {
      final deptHours = totalLaborHours * split.percent;
      final deptMinutes = deptHours <= 0 ? 0 : max(1, (deptHours * 60).round());
      final end = cursor.add(Duration(minutes: deptMinutes));
      final deptDays = deptHours >= 8 ? (deptHours / 8).ceil() : 0;
      items.add(
        DepartmentScheduleItem(
          sequenceNumber: split.sequenceNumber,
          departmentDb: split.departmentDb,
          departmentLabel: split.departmentLabel,
          plannedStartDate: cursor,
          plannedEndDate: end,
          estimatedHours: deptHours,
          estimatedDays: deptDays,
          status: split.sequenceNumber == 1 ? 'inprogress' : 'planned',
        ),
      );
      cursor = end;
    }

    return items;
  }
}

class _BedsheetDepartmentSplit {
  const _BedsheetDepartmentSplit(
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

/// Example calculation walkthrough:
///
/// Flat Sheet, Cotton, Queen, Standard, printing=false, quantity=10
/// - Fabric consumption uses 7.5m × 1.07 wastage = 8.025m
/// - Material cost = 8.025m × 650 = 5,216.25 PKR per unit
/// - Labor uses cutting + stitching + finishing × quality and quantity scales
/// - Processing cost applies base 180 PKR and QC/packaging impact
/// - Estimated days = ceil(totalHours / 8)
/// This service isolates all bedsheet-specific logic away from generic order routing.
