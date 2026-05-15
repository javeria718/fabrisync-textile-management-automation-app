/// Abaya cost configuration models.
/// Represents runtime and persisted settings for abaya manufacturing pricing.

import 'package:fabri_sync/services/abaya/abaya_pricing_rules.dart';

class AbayaCostConfig {
  const AbayaCostConfig({
    required this.id,
    required this.abayaType,
    required this.fabricType,
    required this.qualityGrade,
    required this.baseLaborHours,
    required this.fabricRate,
    required this.laborMultiplier,
    required this.processingRate,
    required this.embellishmentCost,
    required this.wastagePercent,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String abayaType;
  final String fabricType;
  final String qualityGrade;
  final double baseLaborHours;
  final double fabricRate;
  final double laborMultiplier;
  final double processingRate;
  final double embellishmentCost;
  final double wastagePercent;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AbayaCostConfig.fromMap(Map<String, dynamic> map) {
    return AbayaCostConfig(
      id: (map['id'] ?? '').toString(),
      abayaType: (map['abaya_type'] ?? '').toString(),
      fabricType: (map['fabric_type'] ?? '').toString(),
      qualityGrade: (map['quality_grade'] ?? '').toString(),
      baseLaborHours: (map['base_labor_hours'] as num?)?.toDouble() ?? 1.2,
      fabricRate: (map['fabric_rate'] as num?)?.toDouble() ?? 850.0,
      laborMultiplier: (map['labor_multiplier'] as num?)?.toDouble() ?? 1.0,
      processingRate: (map['processing_rate'] as num?)?.toDouble() ?? 250.0,
      embellishmentCost:
          (map['embellishment_cost'] as num?)?.toDouble() ?? 450.0,
      wastagePercent: (map['wastage_percent'] as num?)?.toDouble() ?? 5.0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'abaya_type': abayaType,
      'fabric_type': fabricType,
      'quality_grade': qualityGrade,
      'base_labor_hours': baseLaborHours,
      'fabric_rate': fabricRate,
      'labor_multiplier': laborMultiplier,
      'processing_rate': processingRate,
      'embellishment_cost': embellishmentCost,
      'wastage_percent': wastagePercent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'AbayaCostConfig(abayaType=$abayaType, fabricType=$fabricType, qualityGrade=$qualityGrade)';
}

class AbayaRuntimeConfig {
  const AbayaRuntimeConfig({
    required this.abayaType,
    required this.fabricType,
    required this.qualityGrade,
    required this.size,
    required this.materialRatePerMeter,
    required this.baseLaborHours,
    required this.typeComplexity,
    required this.fabricLaborMultiplier,
    required this.sizeStitchingMultiplier,
    required this.sizeFinishingMultiplier,
    required this.qualityLaborMultiplier,
    required this.qualityQcMultiplier,
    required this.wastagePercent,
    required this.processingRate,
    required this.embellishmentCost,
    required this.artisanHandling,
    required this.premiumFinishingMultiplier,
    required this.fabricStitchingDifficulty,
    required this.fabricIroningDifficulty,
    required this.qualityQcComplexity,
  });

  final String abayaType;
  final String fabricType;
  final String qualityGrade;
  final String size;
  final double materialRatePerMeter;
  final double baseLaborHours;
  final double typeComplexity;
  final double fabricLaborMultiplier;
  final double sizeStitchingMultiplier;
  final double sizeFinishingMultiplier;
  final double qualityLaborMultiplier;
  final double qualityQcMultiplier;
  final double wastagePercent;
  final double processingRate;
  final double embellishmentCost;
  final double artisanHandling;
  final double premiumFinishingMultiplier;
  final double fabricStitchingDifficulty;
  final double fabricIroningDifficulty;
  final double qualityQcComplexity;

  factory AbayaRuntimeConfig.from({
    required AbayaCostConfig config,
    required String size,
  }) {
    final typeConfig = AbayaPricingRules.getAbayaTypeConfig(config.abayaType);
    final fabricConfig = AbayaPricingRules.getFabricTypeConfig(
      config.fabricType,
    );
    final sizeConfig = AbayaPricingRules.getSizeConfig(size);
    final qualityConfig = AbayaPricingRules.getQualityGradeConfig(
      config.qualityGrade,
    );

    return AbayaRuntimeConfig(
      abayaType: config.abayaType,
      fabricType: config.fabricType,
      qualityGrade: config.qualityGrade,
      size: size,
      materialRatePerMeter: config.fabricRate,
      baseLaborHours: config.baseLaborHours,
      typeComplexity: typeConfig?.complexity ?? 1.0,
      fabricLaborMultiplier: fabricConfig?.laborMultiplier ?? 1.0,
      sizeStitchingMultiplier: sizeConfig?.stitchingMultiplier ?? 1.0,
      sizeFinishingMultiplier: sizeConfig?.finishingMultiplier ?? 1.0,
      qualityLaborMultiplier: qualityConfig?.laborMultiplier ?? 1.0,
      qualityQcMultiplier: qualityConfig?.qcMultiplier ?? 1.0,
      wastagePercent: config.wastagePercent,
      processingRate: config.processingRate,
      embellishmentCost: config.embellishmentCost,
      artisanHandling: typeConfig?.artisanHandling ?? 0.0,
      premiumFinishingMultiplier: qualityConfig?.finishingMultiplier ?? 1.0,
      fabricStitchingDifficulty: fabricConfig?.stitchingDifficulty ?? 1.0,
      fabricIroningDifficulty: fabricConfig?.ironingDifficulty ?? 1.0,
      qualityQcComplexity:
          (typeConfig?.qcComplexity ?? 1.0) *
          (fabricConfig?.qcComplexity ?? 1.0),
    );
  }

  @override
  String toString() =>
      'AbayaRuntimeConfig($abayaType, $fabricType, $qualityGrade, $size)';
}

class AbayaCostRequest {
  const AbayaCostRequest({
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
      'subtotal': subtotal,
      'rush_charges': rushCharges,
      'estimated_total_cost': estimatedTotalCost,
    };
  }
}
