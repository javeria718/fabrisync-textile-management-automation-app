import 'package:fabri_sync/services/abaya/abaya_pricing_rules.dart';
import 'package:fabri_sync/services/bedsheet/bedsheet_pricing_rules.dart';
import 'package:fabri_sync/services/curtain/curtain_pricing_rules.dart';
import 'package:fabri_sync/services/help_center/help_models.dart';
import 'package:fabri_sync/services/help_center/product_help_repository.dart';
import 'package:fabri_sync/services/curtain/curtain_cost_config.dart';
import 'package:fabri_sync/services/abaya/abaya_cost_config.dart';
import 'package:fabri_sync/services/bedsheet/bedsheet_cost_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HelpCenterService {
  HelpCenterService({SupabaseClient? client, ProductHelpRepository? repository})
    : _repository = repository ?? ProductHelpRepository(client: client);

  final ProductHelpRepository _repository;
  ProductHelpCatalog? _cachedCatalog;

  Future<ProductHelpCatalog> loadCatalog({bool forceRefresh = false}) async {
    if (_cachedCatalog != null && !forceRefresh) {
      return _cachedCatalog!;
    }

    final curtainConfigs = await _repository.fetchAllCurtainCostConfigs();
    final abayaConfigs = await _repository.fetchAllAbayaCostConfigs();
    final bedsheetConfigs = await _repository.fetchAllBedsheetCostConfigs();

    final catalog = ProductHelpCatalog(
      categories: [
        _buildCurtainCategory(curtainConfigs),
        _buildAbayaCategory(abayaConfigs),
        _buildBedsheetCategory(bedsheetConfigs),
      ],
      loadedAt: DateTime.now(),
    );

    _cachedCatalog = catalog;
    return catalog;
  }

  Future<ProductHelpCatalog> refreshCatalog() async {
    return loadCatalog(forceRefresh: true);
  }

  ProductHelpCategoryData _buildCurtainCategory(
    List<CurtainCostConfig> configs,
  ) {
    final productTypeOptions = CurtainPricingRules.curtainTypeConfigs.entries
        .map(
          (entry) =>
              HelpOption(name: entry.key, description: entry.value.description),
        )
        .toList();

    final fabricOptions = CurtainPricingRules.fabricTypeConfigs.entries
        .map(
          (entry) => HelpOption(
            name: entry.key,
            description: entry.value.description,
            details: {
              'Material Rate': entry.value.materialRatePerSqMeter,
              'Labor Multiplier': entry.value.laborMultiplier,
              'Wastage %': entry.value.wastagePercent,
            },
          ),
        )
        .toList();

    final headerOptions = CurtainPricingRules.headerStyleConfigs.entries
        .map(
          (entry) => HelpOption(
            name: entry.key,
            description: entry.value.description,
            details: {
              'Additional Labor Hours': entry.value.laborHoursAdd,
              'Extra Cost': entry.value.extraCost,
              'Ring Installation Labor': entry.value.ringInstallationLabor,
            },
          ),
        )
        .toList();

    final qualityOptions = CurtainPricingRules.qualityGradeConfigs.entries
        .map(
          (entry) => HelpOption(
            name: entry.key,
            description: entry.value.description,
            details: {
              'Labor Multiplier': entry.value.laborMultiplier,
              'QC Multiplier': entry.value.qcMultiplier,
              'Finishing Multiplier': entry.value.finishingMultiplier,
            },
          ),
        )
        .toList();

    final configEntries = configs.map((config) {
      return ProductHelpConfigEntry(
        title:
            '${config.curtainType} • ${config.fabricType} • ${config.headerStyle}',
        values: {
          'Material Rate (PKR/m²)': config.materialRate,
          'Labor Multiplier': config.laborMultiplier,
          'Complexity Multiplier': config.complexityMultiplier,
          'Base Labor Hours': config.baseLaborHours,
          'Processing Cost': config.processingCost,
          'Wastage %': config.wastagePercent,
        },
      );
    }).toList();

    final specificationGroups = [
      HelpOptionGroup(title: 'Fabric Types', options: fabricOptions),
      HelpOptionGroup(title: 'Header Styles', options: headerOptions),
      HelpOptionGroup(title: 'Quality Grades', options: qualityOptions),
    ];

    return ProductHelpCategoryData(
      category: 'Curtain',
      title: 'Curtains',
      summary:
          'Curtain estimates are generated from live curtain_cost_config values and the CurtainCalculationService logic. This section explains product types, fabric choice, header styling, and the dynamic costing model used during order creation.',
      productTypes: productTypeOptions,
      specificationGroups: specificationGroups,
      configEntries: configEntries,
      timeLogicHighlights: [
        'Fabric area is calculated from length × width, then adjusted for wastage.',
        'Labor is scaled by base labor, header style, quality grade, and order quantity efficiency.',
        'Processing includes base finishing and header-specific work, plus premium handling and QC for premium quality grades.',
        'Rush charges are applied if delivery date demands faster completion than available production hours.',
      ],
      formulaRows: [
        'Effective fabric area = length × width × (1 + wastagePercent / 100)',
        'Material cost = effective fabric area × materialRatePerSqMeter',
        'Labor hours per unit = ((baseLaborHours + headerLaborHours) × totalLaborMultiplier × totalComplexityMultiplier × quantityEfficiency) + areaLaborScale + ringInstallationLabor',
        'Labor cost = labor hours per unit × laborRatePerHour',
        'Processing cost = baseProcessingCost + headerProcessingCost',
        'Total cost = material cost + labor cost + processing cost + packaging + transport + rush charges',
      ],
    );
  }

  ProductHelpCategoryData _buildAbayaCategory(List<AbayaCostConfig> configs) {
    final productTypeOptions = AbayaPricingRules.abayaProductTypes
        .map(
          (type) => HelpOption(
            name: type,
            description: type == 'Embroidered Abaya'
                ? 'Abaya with premium handwork and embellishment logic.'
                : 'Core abaya product type used for pricing and order flow.',
          ),
        )
        .toList();

    final styleTypeOptions = AbayaPricingRules.abayaStyleTypes
        .map(
          (style) => HelpOption(
            name: style,
            description: style == 'Open Abaya'
                ? 'Open-style abaya shape with a wider front opening.'
                : 'Closed-style abaya shape with a full-front design.',
            details: {
              'Production concern':
                  'Open/Closed style affects cutting and stitching flow',
            },
          ),
        )
        .toList();

    final fabricOptions = AbayaPricingRules.fabricTypeConfigs.entries
        .map(
          (entry) => HelpOption(
            name: entry.key,
            description: entry.value.description,
            details: {
              'Fabric Rate': entry.value.fabricRatePerMeter,
              'Labor Multiplier': entry.value.laborMultiplier,
              'Wastage %': entry.value.wastagePercent,
            },
          ),
        )
        .toList();

    final sizeOptions = AbayaPricingRules.sizeConfigs.entries
        .map(
          (entry) => HelpOption(
            name: entry.key,
            description: entry.value.description,
            details: {
              'Fabric Metern': entry.value.fabricMeters,
              'Stitching Multiplier': entry.value.stitchingMultiplier,
            },
          ),
        )
        .toList();

    final qualityOptions = AbayaPricingRules.qualityGradeConfigs.entries
        .map(
          (entry) => HelpOption(
            name: entry.key,
            description: entry.value.description,
            details: {
              'Labor Multiplier': entry.value.laborMultiplier,
              'QC Multiplier': entry.value.qcMultiplier,
              'Finishing Multiplier': entry.value.finishingMultiplier,
            },
          ),
        )
        .toList();

    final configEntries = configs.map((config) {
      return ProductHelpConfigEntry(
        title:
            '${config.abayaType} • ${config.fabricType} • ${config.qualityGrade}',
        values: {
          'Fabric Rate (PKR/m)': config.fabricRate,
          'Base Labor Hours': config.baseLaborHours,
          'Labor Multiplier': config.laborMultiplier,
          'Processing Rate': config.processingRate,
          'Embellishment Cost': config.embellishmentCost,
          'Wastage %': config.wastagePercent,
        },
      );
    }).toList();

    final specificationGroups = [
      HelpOptionGroup(title: 'Style Types', options: styleTypeOptions),
      HelpOptionGroup(title: 'Fabric Types', options: fabricOptions),
      HelpOptionGroup(title: 'Size Ranges', options: sizeOptions),
      HelpOptionGroup(title: 'Quality Grades', options: qualityOptions),
    ];

    return ProductHelpCategoryData(
      category: 'Abaya',
      title: 'Abaya',
      summary:
          'Abaya estimates consume live abaya_cost_config data and the AbayaCalculationService logic to keep production pricing aligned with the system. The panel surfaces fabric, size, quality, and embellishment impact.',
      productTypes: productTypeOptions,
      specificationGroups: specificationGroups,
      configEntries: configEntries,
      timeLogicHighlights: [
        'Fabric consumption is based on size range and wastage percentage.',
        'Labor hours include base stitching, size-based finishing, and embellishment overhead.',
        'Quality grade influences labor, QC, and finishing multipliers.',
        'Rush order rules compare required delivery date to expected production hours.',
      ],
      formulaRows: [
        'Fabric consumption = size fabric meters × (1 + wastagePercent / 100)',
        'Material cost = fabric consumption × materialRatePerMeter',
        'Labor hours = (baseLaborHours × typeComplexity + finishingBase + embellishmentHours + fabricDifficultyHours) × fabricLaborMultiplier × qualityLaborMultiplier × sizeStitchingMultiplier × quantityEfficiency',
        'Labor cost = labor hours × laborRatePerHour',
        'Processing cost = processingRate × premiumFinishingMultiplier × embellishmentFactor',
        'Total cost = material + labor + processing + QC + packaging + artisan surcharge + rush charges',
      ],
    );
  }

  ProductHelpCategoryData _buildBedsheetCategory(
    List<BedsheetCostConfig> configs,
  ) {
    final productTypeOptions = BedsheetPricingRules.bedsheetTypeConfigs.entries
        .map(
          (entry) =>
              HelpOption(name: entry.key, description: entry.value.description),
        )
        .toList();

    final fabricOptions = BedsheetPricingRules.fabricTypeConfigs.entries
        .map(
          (entry) => HelpOption(
            name: entry.key,
            description: entry.value.description,
            details: {
              'Material Rate': entry.value.fabricRatePerMeter,
              'Labor Multiplier': entry.value.laborMultiplier,
              'Wastage %': entry.value.wastagePercent,
            },
          ),
        )
        .toList();

    final bedSizeOptions = BedsheetPricingRules.bedSizeConfigs.entries
        .map(
          (entry) => HelpOption(
            name: entry.key,
            description: entry.value.description,
            details: {
              'Fabric Meters': entry.value.fabricMeters,
              'Stitching Multiplier': entry.value.stitchingMultiplier,
            },
          ),
        )
        .toList();

    final qualityOptions = BedsheetPricingRules.qualityGradeConfigs.entries
        .map(
          (entry) => HelpOption(
            name: entry.key,
            description: entry.value.description,
            details: {
              'Labor Multiplier': entry.value.laborMultiplier,
              'QC Multiplier': entry.value.qcMultiplier,
              'Finishing Multiplier': entry.value.finishingMultiplier,
            },
          ),
        )
        .toList();

    final configEntries = configs.map((config) {
      return ProductHelpConfigEntry(
        title:
            '${config.bedsheetType} • ${config.fabricType} • ${config.bedSize}',
        values: {
          'Material Rate (PKR/m)': config.materialRate,
          'Base Labor Hours': config.baseLaborHours,
          'Labor Multiplier': config.laborMultiplier,
          'Processing Rate': config.processingRate,
          'Printing Charge': config.printingCharge,
          'Wastage %': config.wastagePercent,
        },
      );
    }).toList();

    final specificationGroups = [
      HelpOptionGroup(title: 'Fabric Types', options: fabricOptions),
      HelpOptionGroup(title: 'Bed Sizes', options: bedSizeOptions),
      HelpOptionGroup(title: 'Quality Grades', options: qualityOptions),
    ];

    return ProductHelpCategoryData(
      category: 'Bedsheet',
      title: 'Bedsheet',
      summary:
          'Bedsheet guidance is built from live bedsheet_cost_config data and the BedsheetCalculationService formulas. It explains the impact of bed size, fabric grade, printing, and quality on the estimate.',
      productTypes: productTypeOptions,
      specificationGroups: specificationGroups,
      configEntries: configEntries,
      timeLogicHighlights: [
        'Fabric use is driven by bed size and the type of bedsheet selected.',
        'Labor is composed of cutting, stitching, finishing, and printing setup when required.',
        'Quality grade and printing both increase inspection and finishing workloads.',
        'Rush and custom packaging costs are layered on top of the calculated production cost.',
      ],
      formulaRows: [
        'Fabric consumption = sizeFabricMeters × fabricUsageFactor × (1 + wastagePercent / 100)',
        'Material cost = fabric consumption × materialRatePerMeter',
        'Labor hours = (cuttingHours + stitchingHours + finishingHours) × quantityEfficiency + printingHours',
        'Labor cost = labor hours × laborRatePerHour',
        'Processing cost = processingRate × printingFactor',
        'Total cost = material + labor + processing + QC + packaging + printing setup + premium handling + rush charges',
      ],
    );
  }
}
