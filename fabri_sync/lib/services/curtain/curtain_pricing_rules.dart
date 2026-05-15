/// Centralized curtain-specific pricing rules and multipliers
/// Implements realistic textile manufacturing logic for industrial costing

class CurtainPricingRules {
  // ============================================================================
  // LABOR RATES
  // ============================================================================
  static const double laborRatePerHour = 350.0; // PKR per hour

  // ============================================================================
  // CURTAIN TYPE MULTIPLIERS
  // Based on complexity, labor requirements, and processing needs
  // ============================================================================
  static const Map<String, CurtainTypeConfig> curtainTypeConfigs = {
    'Window Curtain': CurtainTypeConfig(
      complexity: 1.00,
      baseLaborHours: 0.80,
      extraProcessingCost: 150.0,
      description: 'Standard window curtain',
    ),
    'Door Curtain': CurtainTypeConfig(
      complexity: 1.15,
      baseLaborHours: 1.00,
      extraProcessingCost: 250.0,
      description: 'Heavy-duty door curtain',
    ),
    'Blackout Curtain': CurtainTypeConfig(
      complexity: 1.40,
      baseLaborHours: 1.50,
      extraProcessingCost: 500.0,
      description: 'Blackout curtain with light-blocking',
    ),
    'Decorative Curtain': CurtainTypeConfig(
      complexity: 1.60,
      baseLaborHours: 1.80,
      extraProcessingCost: 700.0,
      description: 'Decorative/printed curtain',
    ),
  };

  // ============================================================================
  // FABRIC TYPE RATES & MULTIPLIERS
  // Material rates, labor difficulty, and wastage based on fabric
  // ============================================================================
  static const Map<String, FabricTypeConfig> fabricTypeConfigs = {
    'Sheer': FabricTypeConfig(
      materialRatePerSqMeter: 450.0,
      laborMultiplier: 1.00,
      wastagePercent: 5.0,
      description: 'Sheer/lightweight fabric',
    ),
    'Blackout': FabricTypeConfig(
      materialRatePerSqMeter: 850.0,
      laborMultiplier: 1.25,
      wastagePercent: 10.0,
      description: 'Blackout fabric',
    ),
    'Thermal': FabricTypeConfig(
      materialRatePerSqMeter: 1200.0,
      laborMultiplier: 1.45,
      wastagePercent: 12.0,
      description: 'Thermal insulating fabric',
    ),
  };

  // ============================================================================
  // HEADER STYLE LABOR & COST
  // Additional labor hours and processing costs for header installation
  // ============================================================================
  static const Map<String, HeaderStyleConfig> headerStyleConfigs = {
    'Pleated': HeaderStyleConfig(
      laborHoursAdd: 0.40,
      extraCost: 350.0,
      ringInstallationLabor: 0.0,
      precisionStitchingMultiplier: 1.15,
      description: 'Precision pleated header',
    ),
    'Eyelet': HeaderStyleConfig(
      laborHoursAdd: 0.60,
      extraCost: 500.0,
      ringInstallationLabor: 0.20,
      precisionStitchingMultiplier: 1.0,
      description: 'Eyelet header with rings',
    ),
    'Rod Pocket': HeaderStyleConfig(
      laborHoursAdd: 0.20,
      extraCost: 150.0,
      ringInstallationLabor: 0.0,
      precisionStitchingMultiplier: 1.0,
      description: 'Simple rod pocket',
    ),
  };

  // ============================================================================
  // QUALITY GRADE MULTIPLIERS
  // Labor, QC, and finishing multipliers based on quality grade
  // ============================================================================
  static const Map<String, QualityGradeConfig> qualityGradeConfigs = {
    'Economy': QualityGradeConfig(
      laborMultiplier: 1.00,
      qcMultiplier: 1.00,
      finishingMultiplier: 1.00,
      rejectionBuffer: 0.05,
      description: 'Economy quality',
    ),
    'Standard': QualityGradeConfig(
      laborMultiplier: 1.15,
      qcMultiplier: 1.20,
      finishingMultiplier: 1.15,
      rejectionBuffer: 0.08,
      description: 'Standard quality',
    ),
    'Premium': QualityGradeConfig(
      laborMultiplier: 1.35,
      qcMultiplier: 1.50,
      finishingMultiplier: 1.40,
      rejectionBuffer: 0.12,
      description: 'Premium quality',
    ),
  };

  // ============================================================================
  // QUANTITY-BASED EFFICIENCY SCALING
  // Small batch surcharges and large batch discounts
  // ============================================================================
  static const Map<String, QuantityEfficiencyConfig> quantityEfficiencyRules = {
    'small': QuantityEfficiencyConfig(
      minQty: 1,
      maxQty: 5,
      laborEfficiency: 1.20, // 20% surcharge
      setupSurcharge: 0.20,
      description: 'Small batch (1-5 units)',
    ),
    'medium': QuantityEfficiencyConfig(
      minQty: 6,
      maxQty: 20,
      laborEfficiency: 1.00, // Normal
      setupSurcharge: 0.0,
      description: 'Medium batch (6-20 units)',
    ),
    'large': QuantityEfficiencyConfig(
      minQty: 21,
      maxQty: 50,
      laborEfficiency: 0.95, // 5% efficiency gain
      setupSurcharge: -0.05,
      description: 'Large batch (21-50 units)',
    ),
    'xlarge': QuantityEfficiencyConfig(
      minQty: 51,
      maxQty: 999999,
      laborEfficiency: 0.90, // 10% efficiency gain
      setupSurcharge: -0.10,
      description: 'Extra large batch (51+ units)',
    ),
  };

  // ============================================================================
  // BASE PROCESSING COSTS
  // Includes finishing, ironing, packaging, inspection setup by curtain type
  // ============================================================================
  static const Map<String, double> baseProcessingCosts = {
    'Window Curtain': 200.0,
    'Door Curtain': 300.0,
    'Blackout Curtain': 600.0,
    'Decorative Curtain': 850.0,
  };

  // ============================================================================
  // ADDITIONAL CHARGES
  // ============================================================================
  static const double packagingChargePerUnit = 80.0; // PKR per unit
  static const double transportHandlingCharge = 250.0; // PKR flat charge
  static const double premiumFinishingPerSqMeter = 25.0; // PKR per sq meter

  // ============================================================================
  // RUSH ORDER CHARGES
  // ============================================================================
  static const double rushChargePercentage = 0.15; // 15% surcharge if rush

  // ============================================================================
  // UTILITIES
  // ============================================================================

  /// Get curtain type config by name
  static CurtainTypeConfig? getCurtainTypeConfig(String curtainType) {
    return curtainTypeConfigs[curtainType];
  }

  /// Get fabric type config by name
  static FabricTypeConfig? getFabricTypeConfig(String fabricType) {
    return fabricTypeConfigs[fabricType];
  }

  /// Get header style config by name
  static HeaderStyleConfig? getHeaderStyleConfig(String headerStyle) {
    return headerStyleConfigs[headerStyle];
  }

  /// Get quality grade config by name
  static QualityGradeConfig? getQualityGradeConfig(String qualityGrade) {
    return qualityGradeConfigs[qualityGrade];
  }

  /// Get quantity efficiency rule for given quantity
  static QuantityEfficiencyConfig getQuantityEfficiencyRule(int quantity) {
    for (final rule in quantityEfficiencyRules.values) {
      if (quantity >= rule.minQty && quantity <= rule.maxQty) {
        return rule;
      }
    }
    // Default to medium
    return quantityEfficiencyRules['medium']!;
  }

  /// Validate all curtain specifications
  static ValidationResult validateCurtainSpecs({
    required String curtainType,
    required String fabricType,
    required String headerStyle,
    required String qualityGrade,
    required double length,
    required double width,
    required int quantity,
  }) {
    final errors = <String>[];

    if (!curtainTypeConfigs.containsKey(curtainType)) {
      errors.add('Invalid curtain type: $curtainType');
    }

    if (!fabricTypeConfigs.containsKey(fabricType)) {
      errors.add('Invalid fabric type: $fabricType');
    }

    if (!headerStyleConfigs.containsKey(headerStyle)) {
      errors.add('Invalid header style: $headerStyle');
    }

    if (!qualityGradeConfigs.containsKey(qualityGrade)) {
      errors.add('Invalid quality grade: $qualityGrade');
    }

    if (length <= 0) {
      errors.add('Length must be greater than 0');
    }

    if (width <= 0) {
      errors.add('Width must be greater than 0');
    }

    if (quantity <= 0) {
      errors.add('Quantity must be greater than 0');
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }
}

// ============================================================================
// CONFIGURATION MODELS
// ============================================================================

class CurtainTypeConfig {
  const CurtainTypeConfig({
    required this.complexity,
    required this.baseLaborHours,
    required this.extraProcessingCost,
    required this.description,
  });

  final double complexity;
  final double baseLaborHours;
  final double extraProcessingCost;
  final String description;
}

class FabricTypeConfig {
  const FabricTypeConfig({
    required this.materialRatePerSqMeter,
    required this.laborMultiplier,
    required this.wastagePercent,
    required this.description,
  });

  final double materialRatePerSqMeter;
  final double laborMultiplier;
  final double wastagePercent;
  final String description;
}

class HeaderStyleConfig {
  const HeaderStyleConfig({
    required this.laborHoursAdd,
    required this.extraCost,
    required this.ringInstallationLabor,
    required this.precisionStitchingMultiplier,
    required this.description,
  });

  final double laborHoursAdd;
  final double extraCost;
  final double ringInstallationLabor;
  final double precisionStitchingMultiplier;
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

  @override
  String toString() => errors.join('; ');
}
