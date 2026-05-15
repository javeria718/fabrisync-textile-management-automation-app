/// Bedsheet cost configuration models.
/// Represents persisted pricing configuration and runtime values.

import 'package:fabri_sync/services/bedsheet/bedsheet_pricing_rules.dart';

class BedsheetCostConfig {
  const BedsheetCostConfig({
    required this.id,
    required this.bedsheetType,
    required this.fabricType,
    required this.bedSize,
    required this.qualityGrade,
    required this.baseLaborHours,
    required this.materialRate,
    required this.laborMultiplier,
    required this.processingRate,
    required this.printingCharge,
    required this.wastagePercent,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String bedsheetType;
  final String fabricType;
  final String bedSize;
  final String qualityGrade;
  final double baseLaborHours;
  final double materialRate;
  final double laborMultiplier;
  final double processingRate;
  final double printingCharge;
  final double wastagePercent;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory BedsheetCostConfig.fromMap(Map<String, dynamic> map) {
    return BedsheetCostConfig(
      id: (map['id'] ?? '').toString(),
      bedsheetType: (map['bedsheet_type'] ?? '').toString(),
      fabricType: (map['fabric_type'] ?? '').toString(),
      bedSize: (map['bed_size'] ?? '').toString(),
      qualityGrade: (map['quality_grade'] ?? '').toString(),
      baseLaborHours: (map['base_labor_hours'] as num?)?.toDouble() ?? 0.8,
      materialRate: (map['material_rate'] as num?)?.toDouble() ?? 650.0,
      laborMultiplier: (map['labor_multiplier'] as num?)?.toDouble() ?? 1.0,
      processingRate: (map['processing_rate'] as num?)?.toDouble() ?? 180.0,
      printingCharge: (map['printing_charge'] as num?)?.toDouble() ?? 850.0,
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
      'bedsheet_type': bedsheetType,
      'fabric_type': fabricType,
      'bed_size': bedSize,
      'quality_grade': qualityGrade,
      'base_labor_hours': baseLaborHours,
      'material_rate': materialRate,
      'labor_multiplier': laborMultiplier,
      'processing_rate': processingRate,
      'printing_charge': printingCharge,
      'wastage_percent': wastagePercent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'BedsheetCostConfig($bedsheetType, $fabricType, $bedSize, $qualityGrade)';
}

class BedsheetRuntimeConfig {
  const BedsheetRuntimeConfig({
    required this.bedsheetType,
    required this.fabricType,
    required this.bedSize,
    required this.qualityGrade,
    required this.materialRatePerMeter,
    required this.baseLaborHours,
    required this.laborMultiplier,
    required this.processingRate,
    required this.printingCharge,
    required this.wastagePercent,
    required this.sizeFabricMeters,
    required this.sizeCuttingMultiplier,
    required this.sizeStitchingMultiplier,
    required this.sizeFinishingMultiplier,
    required this.sizePackagingMultiplier,
    required this.qualityLaborMultiplier,
    required this.qualityQcMultiplier,
    required this.qualityFinishingMultiplier,
    required this.typeComplexity,
    required this.typeCuttingComplexity,
    required this.typeFinishingComplexity,
    required this.typeQcRequirement,
    required this.fabricStitchingDifficulty,
    required this.fabricFinishingDifficulty,
    required this.fabricQcSensitivity,
    required this.fabricPremiumHandlingSurcharge,
  });

  final String bedsheetType;
  final String fabricType;
  final String bedSize;
  final String qualityGrade;
  final double materialRatePerMeter;
  final double baseLaborHours;
  final double laborMultiplier;
  final double processingRate;
  final double printingCharge;
  final double wastagePercent;
  final double sizeFabricMeters;
  final double sizeCuttingMultiplier;
  final double sizeStitchingMultiplier;
  final double sizeFinishingMultiplier;
  final double sizePackagingMultiplier;
  final double qualityLaborMultiplier;
  final double qualityQcMultiplier;
  final double qualityFinishingMultiplier;
  final double typeComplexity;
  final double typeCuttingComplexity;
  final double typeFinishingComplexity;
  final double typeQcRequirement;
  final double fabricStitchingDifficulty;
  final double fabricFinishingDifficulty;
  final double fabricQcSensitivity;
  final double fabricPremiumHandlingSurcharge;

  factory BedsheetRuntimeConfig.from({required BedsheetCostConfig config}) {
    final typeConfig = BedsheetPricingRules.getBedsheetTypeConfig(
      config.bedsheetType,
    );
    final fabricConfig = BedsheetPricingRules.getFabricTypeConfig(
      config.fabricType,
    );
    final sizeConfig = BedsheetPricingRules.getBedSizeConfig(config.bedSize);
    final qualityConfig = BedsheetPricingRules.getQualityGradeConfig(
      config.qualityGrade,
    );

    return BedsheetRuntimeConfig(
      bedsheetType: config.bedsheetType,
      fabricType: config.fabricType,
      bedSize: config.bedSize,
      qualityGrade: config.qualityGrade,
      materialRatePerMeter: config.materialRate,
      baseLaborHours: config.baseLaborHours,
      laborMultiplier: config.laborMultiplier,
      processingRate: config.processingRate,
      printingCharge: config.printingCharge,
      wastagePercent: config.wastagePercent,
      sizeFabricMeters: sizeConfig?.fabricMeters ?? 4.5,
      sizeCuttingMultiplier: sizeConfig?.cuttingTimeFactor ?? 1.0,
      sizeStitchingMultiplier: sizeConfig?.stitchingMultiplier ?? 1.0,
      sizeFinishingMultiplier: sizeConfig?.finishingMultiplier ?? 1.0,
      sizePackagingMultiplier: sizeConfig?.packagingMultiplier ?? 1.0,
      qualityLaborMultiplier: qualityConfig?.laborMultiplier ?? 1.0,
      qualityQcMultiplier: qualityConfig?.qcMultiplier ?? 1.0,
      qualityFinishingMultiplier: qualityConfig?.finishingMultiplier ?? 1.0,
      typeComplexity: typeConfig?.complexity ?? 1.0,
      typeCuttingComplexity: typeConfig?.cuttingComplexity ?? 1.0,
      typeFinishingComplexity: typeConfig?.finishingComplexity ?? 1.0,
      typeQcRequirement: typeConfig?.qcRequirement ?? 1.0,
      fabricStitchingDifficulty: fabricConfig?.stitchingDifficulty ?? 1.0,
      fabricFinishingDifficulty: fabricConfig?.finishingDifficulty ?? 1.0,
      fabricQcSensitivity: fabricConfig?.qcSensitivity ?? 1.0,
      fabricPremiumHandlingSurcharge:
          fabricConfig?.premiumHandlingSurcharge ?? 0.0,
    );
  }
}

class BedsheetCostRequest {
  const BedsheetCostRequest({
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
