/// Abaya-specific pricing rules and manufacturing multipliers.
/// Uses production-grade textile formulas and realistic labor/cost drivers.

class AbayaPricingRules {
  // ============================================================================
  // LABOR RATES
  // ============================================================================
  static const double laborRatePerHour = 450.0; // PKR per hour

  // ============================================================================
  // ABAYA TYPE CONFIGURATIONS
  // ============================================================================
  static const Map<String, AbayaTypeConfig> abayaTypeConfigs = {
    'Casual Abaya': AbayaTypeConfig(
      complexity: 1.00,
      baseLaborHours: 1.20,
      processingRate: 250.0,
      artisanHandling: 80.0,
      qcComplexity: 1.00,
      description: 'Casual abaya with efficient workflow',
    ),
    'Fancy Abaya': AbayaTypeConfig(
      complexity: 1.40,
      baseLaborHours: 2.00,
      processingRate: 550.0,
      artisanHandling: 180.0,
      qcComplexity: 1.25,
      description: 'Fancy abaya with refined finishes and premium handling',
    ),
    'Embroidered Abaya': AbayaTypeConfig(
      complexity: 1.80,
      baseLaborHours: 3.00,
      processingRate: 900.0,
      artisanHandling: 420.0,
      qcComplexity: 1.60,
      description:
          'Premium embroidered abaya with handwork and elevated inspection',
    ),
  };

  // ============================================================================
  // FABRIC TYPE RATES & MULTIPLIERS
  // ============================================================================
  static const Map<String, FabricTypeConfig> fabricTypeConfigs = {
    'Nidha': FabricTypeConfig(
      fabricRatePerMeter: 850.0,
      laborMultiplier: 1.00,
      wastagePercent: 5.0,
      stitchingDifficulty: 1.00,
      ironingDifficulty: 1.00,
      qcComplexity: 1.00,
      description: 'Soft and stable Nidha fabric, reliable handling',
    ),
    'Chiffon': FabricTypeConfig(
      fabricRatePerMeter: 1200.0,
      laborMultiplier: 1.35,
      wastagePercent: 10.0,
      stitchingDifficulty: 1.30,
      ironingDifficulty: 1.25,
      qcComplexity: 1.20,
      description:
          'Delicate chiffon with slow stitching and delicate finishing',
    ),
    'Georgette': FabricTypeConfig(
      fabricRatePerMeter: 1050.0,
      laborMultiplier: 1.20,
      wastagePercent: 8.0,
      stitchingDifficulty: 1.15,
      ironingDifficulty: 1.10,
      qcComplexity: 1.10,
      description: 'Semi-sheer georgette with moderate handling complexity',
    ),
  };

  // ============================================================================
  // SIZE IMPACT CONFIGURATIONS
  // ============================================================================
  static const Map<String, SizeConfig> sizeConfigs = {
    'Small': SizeConfig(
      fabricMeters: 2.8,
      cuttingTimeFactor: 1.00,
      stitchingMultiplier: 1.00,
      finishingMultiplier: 1.00,
      description: 'Compact size with efficient workflow',
    ),
    'Medium': SizeConfig(
      fabricMeters: 3.2,
      cuttingTimeFactor: 1.10,
      stitchingMultiplier: 1.10,
      finishingMultiplier: 1.10,
      description: 'Standard medium abaya size',
    ),
    'Large': SizeConfig(
      fabricMeters: 3.6,
      cuttingTimeFactor: 1.20,
      stitchingMultiplier: 1.20,
      finishingMultiplier: 1.20,
      description: 'Large size with proportional labor increase',
    ),
    'XLarge': SizeConfig(
      fabricMeters: 4.2,
      cuttingTimeFactor: 1.35,
      stitchingMultiplier: 1.35,
      finishingMultiplier: 1.35,
      description: 'XLarge size with premium handling and extra time',
    ),
  };

  // ============================================================================
  // ABAYA PRODUCT + STYLE LABELS
  // ============================================================================
  static const List<String> abayaProductTypes = [
    'Fancy Abaya',
    'Casual Abaya',
    'Embroidered Abaya',
  ];

  static const List<String> abayaStyleTypes = ['Open Abaya', 'Closed Abaya'];

  // ============================================================================
  // QUALITY GRADE MULTIPLIERS
  // ============================================================================
  static const Map<String, QualityGradeConfig> qualityGradeConfigs = {
    'Economy': QualityGradeConfig(
      laborMultiplier: 1.00,
      qcMultiplier: 1.00,
      finishingMultiplier: 1.00,
      rejectionBuffer: 0.05,
      description: 'Economy quality with basic finishing',
    ),
    'Standard': QualityGradeConfig(
      laborMultiplier: 1.15,
      qcMultiplier: 1.20,
      finishingMultiplier: 1.15,
      rejectionBuffer: 0.08,
      description: 'Standard quality with refined finishes',
    ),
    'Premium': QualityGradeConfig(
      laborMultiplier: 1.40,
      qcMultiplier: 1.60,
      finishingMultiplier: 1.40,
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
      description: 'Small batch surcharge',
    ),
    'medium': QuantityEfficiencyConfig(
      minQty: 6,
      maxQty: 20,
      laborEfficiency: 1.00,
      setupSurcharge: 0.0,
      description: 'Normal batch sizing',
    ),
    'large': QuantityEfficiencyConfig(
      minQty: 21,
      maxQty: 50,
      laborEfficiency: 0.95,
      setupSurcharge: -0.05,
      description: 'Large batch efficiency improvement',
    ),
    'xlarge': QuantityEfficiencyConfig(
      minQty: 51,
      maxQty: 999999,
      laborEfficiency: 0.90,
      setupSurcharge: -0.10,
      description: 'Extra-large batch efficiency improvement',
    ),
  };

  // ============================================================================
  // ADDITIONAL CHARGES
  // ============================================================================
  static const double packagingChargePerUnit = 85.0;
  static const double premiumHandlingChargePerUnit = 120.0;
  static const double embellishmentSurchargePerUnit = 450.0;
  static const double rushChargePercentage = 0.18;

  // ============================================================================
  // UTILITIES
  // ============================================================================
  static FabricTypeConfig? getFabricTypeConfig(String fabricType) {
    return fabricTypeConfigs[fabricType];
  }

  static SizeConfig? getSizeConfig(String size) {
    return sizeConfigs[size];
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

  /// No longer needed: product types map directly to themselves
  static String normalizeLegacyAbayaType(String abayaType) {
    return abayaType;
  }

  static AbayaTypeConfig? getAbayaTypeConfig(String abayaType) {
    return abayaTypeConfigs[normalizeLegacyAbayaType(abayaType)];
  }

  /// Validate abaya order specifications before calculation.
  static ValidationResult validateAbayaSpecs({
    required String abayaType,
    required String fabricType,
    required String size,
    required String qualityGrade,
    required int quantity,
  }) {
    final errors = <String>[];
    final normalizedAbayaType = normalizeLegacyAbayaType(abayaType);

    if (!abayaTypeConfigs.containsKey(normalizedAbayaType)) {
      errors.add('Invalid Abaya type: $abayaType');
    }
    if (!fabricTypeConfigs.containsKey(fabricType)) {
      errors.add('Invalid fabric type: $fabricType');
    }
    if (!sizeConfigs.containsKey(size)) {
      errors.add('Invalid size: $size');
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

class AbayaTypeConfig {
  const AbayaTypeConfig({
    required this.complexity,
    required this.baseLaborHours,
    required this.processingRate,
    required this.artisanHandling,
    required this.qcComplexity,
    required this.description,
  });

  final double complexity;
  final double baseLaborHours;
  final double processingRate;
  final double artisanHandling;
  final double qcComplexity;
  final String description;
}

class FabricTypeConfig {
  const FabricTypeConfig({
    required this.fabricRatePerMeter,
    required this.laborMultiplier,
    required this.wastagePercent,
    required this.stitchingDifficulty,
    required this.ironingDifficulty,
    required this.qcComplexity,
    required this.description,
  });

  final double fabricRatePerMeter;
  final double laborMultiplier;
  final double wastagePercent;
  final double stitchingDifficulty;
  final double ironingDifficulty;
  final double qcComplexity;
  final String description;
}

class SizeConfig {
  const SizeConfig({
    required this.fabricMeters,
    required this.cuttingTimeFactor,
    required this.stitchingMultiplier,
    required this.finishingMultiplier,
    required this.description,
  });

  final double fabricMeters;
  final double cuttingTimeFactor;
  final double stitchingMultiplier;
  final double finishingMultiplier;
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
