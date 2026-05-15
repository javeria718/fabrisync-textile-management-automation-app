/// Curtain cost configuration models
/// These models represent the flexible, dynamic pricing configuration
/// that can be fetched from Supabase and customized per factory

import 'package:fabri_sync/services/curtain/curtain_pricing_rules.dart';

/// Complete curtain cost configuration combining all elements
/// Represents a single pricing configuration for a specific curtain variant
class CurtainCostConfig {
  const CurtainCostConfig({
    required this.id,
    required this.curtainType,
    required this.fabricType,
    required this.headerStyle,
    required this.materialRate,
    required this.laborMultiplier,
    required this.complexityMultiplier,
    required this.baseLaborHours,
    required this.processingCost,
    required this.wastagePercent,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String curtainType;
  final String fabricType;
  final String headerStyle;
  final double materialRate;
  final double laborMultiplier;
  final double complexityMultiplier;
  final double baseLaborHours;
  final double processingCost;
  final double wastagePercent;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Create from Supabase database row
  factory CurtainCostConfig.fromMap(Map<String, dynamic> map) {
    return CurtainCostConfig(
      id: (map['id'] ?? '').toString(),
      curtainType: (map['curtain_type'] ?? '').toString(),
      fabricType: (map['fabric_type'] ?? '').toString(),
      headerStyle: (map['header_style'] ?? '').toString(),
      materialRate: (map['material_rate'] as num?)?.toDouble() ?? 450.0,
      laborMultiplier: (map['labor_multiplier'] as num?)?.toDouble() ?? 1.0,
      complexityMultiplier:
          (map['complexity_multiplier'] as num?)?.toDouble() ?? 1.0,
      baseLaborHours: (map['base_labor_hours'] as num?)?.toDouble() ?? 0.8,
      processingCost: (map['processing_cost'] as num?)?.toDouble() ?? 200.0,
      wastagePercent: (map['wastage_percent'] as num?)?.toDouble() ?? 5.0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : DateTime.now(),
    );
  }

  /// Convert to Supabase insert/update format
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'curtain_type': curtainType,
      'fabric_type': fabricType,
      'header_style': headerStyle,
      'material_rate': materialRate,
      'labor_multiplier': laborMultiplier,
      'complexity_multiplier': complexityMultiplier,
      'base_labor_hours': baseLaborHours,
      'processing_cost': processingCost,
      'wastage_percent': wastagePercent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'CurtainCostConfig(curtainType=$curtainType, fabricType=$fabricType, headerStyle=$headerStyle)';
}

/// Request/Input model for fetching specific curtain cost config
class CurtainCostRequest {
  const CurtainCostRequest({
    required this.curtainType,
    required this.fabricType,
    required this.headerStyle,
  });

  final String curtainType;
  final String fabricType;
  final String headerStyle;

  @override
  String toString() =>
      'CurtainCostRequest($curtainType, $fabricType, $headerStyle)';
}

/// Computed runtime values for a specific curtain order
/// Combines static configs with dynamic calculations
class CurtainRuntimeConfig {
  const CurtainRuntimeConfig({
    required this.curtainType,
    required this.fabricType,
    required this.headerStyle,
    required this.qualityGrade,
    required this.materialRatePerSqMeter,
    required this.baseLaborHoursPerUnit,
    required this.totalLaborMultiplier,
    required this.totalComplexityMultiplier,
    required this.wastagePercent,
    required this.baseProcessingCost,
    required this.headerProcessingCost,
    required this.qualityQcMultiplier,
  });

  final String curtainType;
  final String fabricType;
  final String headerStyle;
  final String qualityGrade;
  final double materialRatePerSqMeter;
  final double baseLaborHoursPerUnit;
  final double totalLaborMultiplier;
  final double totalComplexityMultiplier;
  final double wastagePercent;
  final double baseProcessingCost;
  final double headerProcessingCost;
  final double qualityQcMultiplier;

  /// Creates runtime config from cost config and other specs
  factory CurtainRuntimeConfig.from({
    required CurtainCostConfig config,
    required String qualityGrade,
  }) {
    final typeConfig = CurtainPricingRules.getCurtainTypeConfig(
      config.curtainType,
    );
    final fabricConfig = CurtainPricingRules.getFabricTypeConfig(
      config.fabricType,
    );
    final headerConfig = CurtainPricingRules.getHeaderStyleConfig(
      config.headerStyle,
    );
    final qualityConfig = CurtainPricingRules.getQualityGradeConfig(
      qualityGrade,
    );

    // Combine multipliers
    final totalLaborMult =
        (fabricConfig?.laborMultiplier ?? 1.0) *
        (qualityConfig?.laborMultiplier ?? 1.0);

    final totalComplexityMult =
        (typeConfig?.complexity ?? 1.0) *
        (headerConfig?.precisionStitchingMultiplier ?? 1.0);

    final baseProcessing = typeConfig?.extraProcessingCost ?? 200.0;
    final headerProcessing = headerConfig?.extraCost ?? 150.0;

    return CurtainRuntimeConfig(
      curtainType: config.curtainType,
      fabricType: config.fabricType,
      headerStyle: config.headerStyle,
      qualityGrade: qualityGrade,
      materialRatePerSqMeter: config.materialRate,
      baseLaborHoursPerUnit: config.baseLaborHours,
      totalLaborMultiplier: totalLaborMult,
      totalComplexityMultiplier: totalComplexityMult,
      wastagePercent: config.wastagePercent,
      baseProcessingCost: baseProcessing,
      headerProcessingCost: headerProcessing,
      qualityQcMultiplier: qualityConfig?.qcMultiplier ?? 1.0,
    );
  }

  @override
  String toString() =>
      'CurtainRuntimeConfig($curtainType, $fabricType, $headerStyle, $qualityGrade)';
}
