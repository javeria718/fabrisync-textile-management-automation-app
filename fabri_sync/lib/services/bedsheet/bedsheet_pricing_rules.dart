/// Bedsheet-specific pricing rules and manufacturing multipliers.
/// Uses the same production-grade modular architecture as Curtain and Abaya.

class BedsheetPricingRules {
  // ============================================================================
  // LABOR RATES
  // ============================================================================
  static const double laborRatePerHour = 450.0; // PKR per hour

  // ============================================================================
  // BED SHEET TYPE CONFIGURATION
  // ============================================================================
  static const Map<String, BedsheetTypeConfig> bedsheetTypeConfigs = {
    'Flat Sheet': BedsheetTypeConfig(
      baseLaborHours: 0.8,
      complexity: 1.0,
      processingCost: 180.0,
      cuttingComplexity: 1.0,
      finishingComplexity: 1.0,
      qcRequirement: 1.0,
      description: 'Simple flat sheet production flow',
    ),
    'Fitted Sheet': BedsheetTypeConfig(
      baseLaborHours: 1.5,
      complexity: 1.5,
      processingCost: 450.0,
      cuttingComplexity: 1.2,
      finishingComplexity: 1.3,
      qcRequirement: 1.2,
      description:
          'Fitted sheet with elastic fitting and corner stitching finish',
    ),
    'Pillow Cover Set': BedsheetTypeConfig(
      baseLaborHours: 0.5,
      complexity: 0.8,
      processingCost: 120.0,
      cuttingComplexity: 0.8,
      finishingComplexity: 0.9,
      qcRequirement: 0.9,
      description: 'Low fabric usage pillow cover production set',
    ),
  };

  // ============================================================================
  // FABRIC TYPE CONFIGURATION
  // ============================================================================
  static const Map<String, FabricTypeConfig> fabricTypeConfigs = {
    'Cotton': FabricTypeConfig(
      fabricRatePerMeter: 650.0,
      laborMultiplier: 1.0,
      wastagePercent: 5.0,
      stitchingDifficulty: 1.0,
      finishingDifficulty: 1.0,
      qcSensitivity: 1.0,
      premiumHandlingSurcharge: 0.0,
      description: 'Standard cotton with reliable production flow',
    ),
    'Blend': FabricTypeConfig(
      fabricRatePerMeter: 850.0,
      laborMultiplier: 1.15,
      wastagePercent: 7.0,
      stitchingDifficulty: 1.1,
      finishingDifficulty: 1.1,
      qcSensitivity: 1.1,
      premiumHandlingSurcharge: 60.0,
      description: 'Blend fabric with moderate handling complexity',
    ),
    'Silk': FabricTypeConfig(
      fabricRatePerMeter: 1600.0,
      laborMultiplier: 1.6,
      wastagePercent: 12.0,
      stitchingDifficulty: 1.4,
      finishingDifficulty: 1.5,
      qcSensitivity: 1.5,
      premiumHandlingSurcharge: 180.0,
      description: 'Premium silk with delicate handling and inspection',
    ),
  };

  // ============================================================================
  // BED SIZE CONFIGURATION
  // ============================================================================
  static const Map<String, BedSizeConfig> bedSizeConfigs = {
    'Single': BedSizeConfig(
      fabricMeters: 4.5,
      cuttingTimeFactor: 1.0,
      stitchingMultiplier: 1.0,
      finishingMultiplier: 1.0,
      packagingMultiplier: 1.0,
      description: 'Single bed size with standard material usage',
    ),
    'Double': BedSizeConfig(
      fabricMeters: 6.0,
      cuttingTimeFactor: 1.2,
      stitchingMultiplier: 1.15,
      finishingMultiplier: 1.10,
      packagingMultiplier: 1.1,
      description: 'Double size with larger fabric consumption',
    ),
    'Queen': BedSizeConfig(
      fabricMeters: 7.5,
      cuttingTimeFactor: 1.4,
      stitchingMultiplier: 1.25,
      finishingMultiplier: 1.20,
      packagingMultiplier: 1.2,
      description: 'Queen size with significant material and time increase',
    ),
    'King': BedSizeConfig(
      fabricMeters: 9.0,
      cuttingTimeFactor: 1.65,
      stitchingMultiplier: 1.4,
      finishingMultiplier: 1.35,
      packagingMultiplier: 1.35,
      description: 'King size with premium production effort and packaging',
    ),
  };

  // ============================================================================
  // QUALITY GRADE CONFIGURATION
  // ============================================================================
  static const Map<String, QualityGradeConfig> qualityGradeConfigs = {
    'Economy': QualityGradeConfig(
      laborMultiplier: 1.0,
      qcMultiplier: 1.0,
      finishingMultiplier: 1.0,
      rejectionBuffer: 0.05,
      description: 'Economy quality with basic inspection and finishing',
    ),
    'Standard': QualityGradeConfig(
      laborMultiplier: 1.15,
      qcMultiplier: 1.20,
      finishingMultiplier: 1.15,
      rejectionBuffer: 0.08,
      description: 'Standard quality with improved finishing and QC',
    ),
    'Premium': QualityGradeConfig(
      laborMultiplier: 1.4,
      qcMultiplier: 1.6,
      finishingMultiplier: 1.5,
      rejectionBuffer: 0.12,
      description: 'Premium quality with luxury finishing and inspection',
    ),
  };

  // ============================================================================
  // QUANTITY EFFICIENCY
  // ============================================================================
  static const Map<String, QuantityEfficiencyConfig> quantityEfficiencyRules = {
    'small': QuantityEfficiencyConfig(
      minQty: 1,
      maxQty: 5,
      laborEfficiency: 1.20,
      setupSurcharge: 0.20,
      description: 'Small batch setup surcharge',
    ),
    'medium': QuantityEfficiencyConfig(
      minQty: 6,
      maxQty: 20,
      laborEfficiency: 1.00,
      setupSurcharge: 0.0,
      description: 'Standard batch sizing',
    ),
    'large': QuantityEfficiencyConfig(
      minQty: 21,
      maxQty: 50,
      laborEfficiency: 0.95,
      setupSurcharge: -0.05,
      description: 'Large batch labor efficiency gain',
    ),
    'xlarge': QuantityEfficiencyConfig(
      minQty: 51,
      maxQty: 999999,
      laborEfficiency: 0.90,
      setupSurcharge: -0.10,
      description: 'Extra-large batch labor efficiency gain',
    ),
  };

  // ============================================================================
  // ADDITIONAL CHARGES
  // ============================================================================
  static const double printingSetupCost = 850.0;
  static const double printingLaborHours = 0.8;
  static const double packagingBasePerUnit = 65.0;
  static const double customPackagingSurcharge = 1.35;
  static const double rushChargePercentage = 0.18;

  // ============================================================================
  // UTILITIES
  // ============================================================================
  static BedsheetTypeConfig? getBedsheetTypeConfig(String bedsheetType) {
    return bedsheetTypeConfigs[bedsheetType];
  }

  static FabricTypeConfig? getFabricTypeConfig(String fabricType) {
    return fabricTypeConfigs[fabricType];
  }

  static BedSizeConfig? getBedSizeConfig(String bedSize) {
    return bedSizeConfigs[bedSize];
  }

  static QualityGradeConfig? getQualityGradeConfig(String qualityGrade) {
    return qualityGradeConfigs[qualityGrade];
  }

  static QuantityEfficiencyConfig getQuantityEfficiencyRule(int quantity) {
    for (final rule in quantityEfficiencyRules.values) {
      if (quantity >= rule.minQty && quantity <= rule.maxQty) {
        return rule;
      }
    }
    return quantityEfficiencyRules['medium']!;
  }

  static ValidationResult validateBedsheetSpecs({
    required String bedsheetType,
    required String fabricType,
    required String bedSize,
    required String qualityGrade,
    required int quantity,
  }) {
    final errors = <String>[];

    if (!bedsheetTypeConfigs.containsKey(bedsheetType)) {
      errors.add('Invalid bedsheet type: $bedsheetType');
    }
    if (!fabricTypeConfigs.containsKey(fabricType)) {
      errors.add('Invalid fabric type: $fabricType');
    }
    if (!bedSizeConfigs.containsKey(bedSize)) {
      errors.add('Invalid bed size: $bedSize');
    }
    if (!qualityGradeConfigs.containsKey(qualityGrade)) {
      errors.add('Invalid quality grade: $qualityGrade');
    }
    if (quantity <= 0) {
      errors.add('Quantity must be greater than 0');
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }
}

class BedsheetTypeConfig {
  const BedsheetTypeConfig({
    required this.baseLaborHours,
    required this.complexity,
    required this.processingCost,
    required this.cuttingComplexity,
    required this.finishingComplexity,
    required this.qcRequirement,
    required this.description,
  });

  final double baseLaborHours;
  final double complexity;
  final double processingCost;
  final double cuttingComplexity;
  final double finishingComplexity;
  final double qcRequirement;
  final String description;
}

class FabricTypeConfig {
  const FabricTypeConfig({
    required this.fabricRatePerMeter,
    required this.laborMultiplier,
    required this.wastagePercent,
    required this.stitchingDifficulty,
    required this.finishingDifficulty,
    required this.qcSensitivity,
    required this.premiumHandlingSurcharge,
    required this.description,
  });

  final double fabricRatePerMeter;
  final double laborMultiplier;
  final double wastagePercent;
  final double stitchingDifficulty;
  final double finishingDifficulty;
  final double qcSensitivity;
  final double premiumHandlingSurcharge;
  final String description;
}

class BedSizeConfig {
  const BedSizeConfig({
    required this.fabricMeters,
    required this.cuttingTimeFactor,
    required this.stitchingMultiplier,
    required this.finishingMultiplier,
    required this.packagingMultiplier,
    required this.description,
  });

  final double fabricMeters;
  final double cuttingTimeFactor;
  final double stitchingMultiplier;
  final double finishingMultiplier;
  final double packagingMultiplier;
  final String description;
}

class QualityGradeConfig {
  const QualityGradeConfig({
    required this.laborMultiplier,
    required this.qcMultiplier,
    required this.finishingMultiplier,
    required this.rejectionBuffer,
    required this.description,
  });

  final double laborMultiplier;
  final double qcMultiplier;
  final double finishingMultiplier;
  final double rejectionBuffer;
  final String description;
}

class QuantityEfficiencyConfig {
  const QuantityEfficiencyConfig({
    required this.minQty,
    required this.maxQty,
    required this.laborEfficiency,
    required this.setupSurcharge,
    required this.description,
  });

  final int minQty;
  final int maxQty;
  final double laborEfficiency;
  final double setupSurcharge;
  final String description;
}

class ValidationResult {
  const ValidationResult({required this.isValid, required this.errors});

  final bool isValid;
  final List<String> errors;
}
