/// Abaya-specific calculation service.
/// Handles full abaya cost, time, and department scheduling logic.

import 'dart:math';
import 'package:fabri_sync/services/abaya/abaya_cost_config.dart';
import 'package:fabri_sync/services/abaya/abaya_cost_repository.dart';
import 'package:fabri_sync/services/abaya/abaya_pricing_rules.dart';
import 'package:fabri_sync/services/order_calculation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AbayaCalculationRequest {
  const AbayaCalculationRequest({
    required this.abayaType,
    required this.fabricType,
    required this.size,
    required this.quantity,
    required this.qualityGrade,
    required this.embellishment,
    required this.requiredDeliveryDate,
    required this.customPackaging,
  });

  final String abayaType;
  final String fabricType;
  final String size;
  final int quantity;
  final String qualityGrade;
  final bool embellishment;
  final DateTime requiredDeliveryDate;
  final bool customPackaging;
}

class AbayaCostBreakdown {
  const AbayaCostBreakdown({
    required this.fabricConsumptionPerUnit,
    required this.totalFabricConsumption,
    required this.materialCostPerUnit,
    required this.totalMaterialCost,
    required this.baseLaborHoursPerUnit,
    required this.totalLaborHours,
    required this.laborCostPerUnit,
    required this.totalLaborCost,
    required this.processingCostPerUnit,
    required this.totalProcessingCost,
    required this.qcCostPerUnit,
    required this.totalQcCost,
    required this.packagingCost,
    required this.artisanSurcharge,
    required this.quantitySurcharge,
    required this.subtotal,
    required this.rushCharges,
    required this.estimatedTotalCost,
  });

  final double fabricConsumptionPerUnit;
  final double totalFabricConsumption;
  final double materialCostPerUnit;
  final double totalMaterialCost;
  final double baseLaborHoursPerUnit;
  final double totalLaborHours;
  final double laborCostPerUnit;
  final double totalLaborCost;
  final double processingCostPerUnit;
  final double totalProcessingCost;
  final double qcCostPerUnit;
  final double totalQcCost;
  final double packagingCost;
  final double artisanSurcharge;
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
      'base_labor_hours_per_unit': baseLaborHoursPerUnit,
      'total_labor_hours': totalLaborHours,
      'labor_cost_per_unit': laborCostPerUnit,
      'total_labor_cost': totalLaborCost,
      'processing_cost_per_unit': processingCostPerUnit,
      'total_processing_cost': totalProcessingCost,
      'qc_cost_per_unit': qcCostPerUnit,
      'total_qc_cost': totalQcCost,
      'packaging_cost': packagingCost,
      'artisan_surcharge': artisanSurcharge,
      'quantity_surcharge': quantitySurcharge,
      'subtotal': subtotal,
      'rush_charges': rushCharges,
      'estimated_total_cost': estimatedTotalCost,
    };
  }
}

class AbayaCalculationService {
  AbayaCalculationService({
    AbayaCostRepository? repository,
    SupabaseClient? client,
  }) : _repository = repository ?? AbayaCostRepository(client: client);

  final AbayaCostRepository _repository;

  Future<CalculationResult> calculateAbayaEstimate(
    AbayaCalculationRequest request,
  ) async {
    final normalizedAbayaType = AbayaPricingRules.normalizeLegacyAbayaType(
      request.abayaType,
    );

    final validation = AbayaPricingRules.validateAbayaSpecs(
      abayaType: normalizedAbayaType,
      fabricType: request.fabricType,
      size: request.size,
      qualityGrade: request.qualityGrade,
      quantity: request.quantity,
    );

    if (!validation.isValid) {
      throw Exception(
        'Abaya validation failed: ${validation.errors.join(', ')}',
      );
    }

    final costConfig = await _repository.fetchAbayaCostConfig(
      abayaType: normalizedAbayaType,
      fabricType: request.fabricType,
      qualityGrade: request.qualityGrade,
    );

    if (costConfig == null) {
      throw Exception(
        'Abaya cost configuration not found for: '
        '${request.abayaType}, ${request.fabricType}, ${request.qualityGrade}',
      );
    }

    final runtimeConfig = AbayaRuntimeConfig.from(
      config: costConfig,
      size: request.size,
    );

    return _performCalculation(request, runtimeConfig);
  }

  CalculationResult _performCalculation(
    AbayaCalculationRequest request,
    AbayaRuntimeConfig config,
  ) {
    final sizeConfig = AbayaPricingRules.getSizeConfig(request.size)!;
    final fabricConfig = AbayaPricingRules.getFabricTypeConfig(
      request.fabricType,
    )!;
    final normalizedAbayaType = AbayaPricingRules.normalizeLegacyAbayaType(
      request.abayaType,
    );
    final typeConfig = AbayaPricingRules.getAbayaTypeConfig(
      normalizedAbayaType,
    )!;
    final quantityEfficiency = AbayaPricingRules.getQuantityEfficiencyRule(
      request.quantity,
    );

    final fabricConsumptionPerUnit =
        sizeConfig.fabricMeters * (1 + config.wastagePercent / 100);
    final totalFabricConsumption = fabricConsumptionPerUnit * request.quantity;
    final materialCostPerUnit =
        fabricConsumptionPerUnit * config.materialRatePerMeter;
    final totalMaterialCost = materialCostPerUnit * request.quantity;

    final embellishmentHours = request.embellishment ? 1.5 : 0.0;
    final finishingBaseHours = 0.6 * sizeConfig.finishingMultiplier;
    final stitchingBaseHours = config.baseLaborHours * config.typeComplexity;
    final fabricDifficultyHours =
        stitchingBaseHours * (fabricConfig.stitchingDifficulty - 1.0) * 0.25;

    /// MIGRATION: Use database labor_multiplier instead of computing from static rules.
    /// Database value: laborMultiplier = typeComplexity × fabricLaborMultiplier × qualityLaborMultiplier
    /// To avoid double-applying typeComplexity (already in stitchingBaseHours),
    /// divide database value by typeComplexity to extract (fabric × quality) portion only.
    final combinedFabricQualityMultiplier =
        config.laborMultiplier / config.typeComplexity;

    var laborHoursPerUnit =
        (stitchingBaseHours + finishingBaseHours) *
        combinedFabricQualityMultiplier *
        config.sizeStitchingMultiplier;

    laborHoursPerUnit += embellishmentHours;
    laborHoursPerUnit += fabricDifficultyHours;
    laborHoursPerUnit *= quantityEfficiency.laborEfficiency;

    final totalLaborHours = laborHoursPerUnit * request.quantity;
    final laborCostPerUnit =
        laborHoursPerUnit * AbayaPricingRules.laborRatePerHour;
    final totalLaborCost = laborCostPerUnit * request.quantity;

    final qcHoursPerUnit =
        0.55 * config.qualityQcMultiplier * typeConfig.qcComplexity +
        (request.embellishment ? 0.5 : 0.0);
    final qcCostPerUnit = qcHoursPerUnit * AbayaPricingRules.laborRatePerHour;
    final totalQcCost = qcCostPerUnit * request.quantity;

    final processingCostPerUnit =
        config.processingRate *
        config.premiumFinishingMultiplier *
        (request.embellishment ? 1.20 : 1.00);
    final totalProcessingCost = processingCostPerUnit * request.quantity;

    final packagingCost = request.customPackaging
        ? AbayaPricingRules.packagingChargePerUnit * request.quantity
        : 60.0 * request.quantity;
    final artisanSurcharge = request.embellishment
        ? AbayaPricingRules.embellishmentSurchargePerUnit * request.quantity
        : 0.0;
    final premiumHandling =
        typeConfig.artisanHandling * request.quantity * 0.25;

    final quantitySurcharge =
        totalMaterialCost * quantityEfficiency.setupSurcharge;

    final subtotal =
        totalMaterialCost +
        totalLaborCost +
        totalProcessingCost +
        totalQcCost +
        packagingCost +
        artisanSurcharge +
        premiumHandling +
        (quantitySurcharge > 0 ? quantitySurcharge : 0);

    final now = DateTime.now();
    final deliveryWindow = request.requiredDeliveryDate
        .difference(now)
        .inDays
        .toDouble();
    final isRush = deliveryWindow < max(1, totalLaborHours / 8);
    final rushCharges = isRush
        ? subtotal * AbayaPricingRules.rushChargePercentage
        : 0.0;
    final estimatedTotalCost = subtotal + rushCharges;

    final estimatedProductionDays = max(1, (totalLaborHours / 8).ceil());

    final costBreakdown = AbayaCostBreakdown(
      fabricConsumptionPerUnit: fabricConsumptionPerUnit,
      totalFabricConsumption: totalFabricConsumption,
      materialCostPerUnit: materialCostPerUnit,
      totalMaterialCost: totalMaterialCost,
      baseLaborHoursPerUnit: laborHoursPerUnit,
      totalLaborHours: totalLaborHours,
      laborCostPerUnit: laborCostPerUnit,
      totalLaborCost: totalLaborCost,
      processingCostPerUnit: processingCostPerUnit,
      totalProcessingCost: totalProcessingCost,
      qcCostPerUnit: qcCostPerUnit,
      totalQcCost: totalQcCost,
      packagingCost: packagingCost,
      artisanSurcharge: artisanSurcharge,
      quantitySurcharge: quantitySurcharge,
      subtotal: subtotal,
      rushCharges: rushCharges,
      estimatedTotalCost: estimatedTotalCost,
    );

    final departmentSchedule = _buildAbayaDepartmentSchedule(
      totalLaborHours: totalLaborHours,
      startDate: now,
      qualityGrade: request.qualityGrade,
      abayaType: request.abayaType,
      hasEmbellishment: request.embellishment,
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
        additionalCharges: packagingCost + artisanSurcharge + quantitySurcharge,
        materialTotalCost: costBreakdown.totalMaterialCost,
        laborTotalCost: costBreakdown.totalLaborCost,
        processingTotalCost: costBreakdown.totalProcessingCost,
        additionalTotalCost:
            costBreakdown.totalQcCost +
            packagingCost +
            artisanSurcharge +
            quantitySurcharge,
        rushCharges: costBreakdown.rushCharges,
        estimatedTotalCost: costBreakdown.estimatedTotalCost,
      ),
      departmentSchedule: departmentSchedule,
      departmentHours: departmentHours,
    );
  }

  List<DepartmentScheduleItem> _buildAbayaDepartmentSchedule({
    required double totalLaborHours,
    required DateTime startDate,
    required String qualityGrade,
    required String abayaType,
    required bool hasEmbellishment,
  }) {
    final isPremium = qualityGrade == 'Premium';
    final isEmbroidered = abayaType == 'Embroidered Abaya';

    final splitting = <_AbayaDepartmentSplit>[
      _AbayaDepartmentSplit(1, 'CUTTING', 'Cutting', 0.18),
      _AbayaDepartmentSplit(2, 'STITCHING', 'Stitching', 0.45),
      _AbayaDepartmentSplit(3, 'THREADING', 'Threading', 0.10),
      _AbayaDepartmentSplit(
        4,
        'QUALITY_CONTROL',
        'Quality Control',
        isEmbroidered ? 0.17 : (isPremium ? 0.15 : 0.13),
      ),
      _AbayaDepartmentSplit(
        5,
        'PACKAGING',
        'Packaging',
        hasEmbellishment ? 0.07 : 0.06,
      ),
      _AbayaDepartmentSplit(
        6,
        'INSPECTION',
        'Inspection',
        isEmbroidered ? 0.08 : (isPremium ? 0.09 : 0.08),
      ),
    ];

    final items = <DepartmentScheduleItem>[];
    var cursor = startDate;

    for (final split in splitting) {
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

class _AbayaDepartmentSplit {
  const _AbayaDepartmentSplit(
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
