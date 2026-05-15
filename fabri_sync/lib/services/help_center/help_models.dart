class ProductHelpCatalog {
  const ProductHelpCatalog({required this.categories, required this.loadedAt});

  final List<ProductHelpCategoryData> categories;
  final DateTime loadedAt;
}

class ProductHelpCategoryData {
  const ProductHelpCategoryData({
    required this.category,
    required this.title,
    required this.summary,
    required this.productTypes,
    required this.specificationGroups,
    required this.configEntries,
    required this.timeLogicHighlights,
    required this.formulaRows,
  });

  final String category;
  final String title;
  final String summary;
  final List<HelpOption> productTypes;
  final List<HelpOptionGroup> specificationGroups;
  final List<ProductHelpConfigEntry> configEntries;
  final List<String> timeLogicHighlights;
  final List<String> formulaRows;
}

class HelpOptionGroup {
  const HelpOptionGroup({required this.title, required this.options});

  final String title;
  final List<HelpOption> options;
}

class HelpOption {
  const HelpOption({
    required this.name,
    required this.description,
    this.details,
  });

  final String name;
  final String description;
  final Map<String, dynamic>? details;
}

class ProductHelpConfigEntry {
  const ProductHelpConfigEntry({required this.title, required this.values});

  final String title;
  final Map<String, dynamic> values;
}
