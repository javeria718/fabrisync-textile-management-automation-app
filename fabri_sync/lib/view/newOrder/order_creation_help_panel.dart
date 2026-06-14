import 'package:fabri_sync/services/help_center/help_center_service.dart';
import 'package:fabri_sync/services/help_center/help_models.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:flutter/material.dart';

class OrderCreationHelpPanel extends StatefulWidget {
  const OrderCreationHelpPanel({super.key});

  static Future<void> open(BuildContext context) async {
    final width = MediaQuery.of(context).size.width;

    if (width >= 1000) {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: SizedBox(
            width: 940,
            height: MediaQuery.of(context).size.height * 0.88,
            child: const OrderCreationHelpPanel(),
          ),
        ),
      );
      return;
    }

    if (width >= 600) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: SafeArea(child: OrderCreationHelpPanel())),
          fullscreenDialog: true,
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.94,
        child: const OrderCreationHelpPanel(),
      ),
    );
  }

  @override
  State<OrderCreationHelpPanel> createState() => _OrderCreationHelpPanelState();
}

class _OrderCreationHelpPanelState extends State<OrderCreationHelpPanel> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    final svc = HelpCenterService();
    if (svc.catalogNotifier.value == null) svc.loadCatalog();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProductHelpCatalog?>(
      valueListenable: HelpCenterService().catalogNotifier,
      builder: (context, catalog, _) {
        if (catalog == null) return _buildLoading();

        return DefaultTabController(
          length: catalog.categories.length,
          initialIndex: _selectedTabIndex,
          child: Scaffold(
            backgroundColor: AppColors.surface,
            appBar: _buildPanelAppBar(catalog),
            body: _buildBody(catalog),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildPanelAppBar(ProductHelpCatalog catalog) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallPhone = screenWidth < 400;

    // Responsive font sizing
    final titleFontSize = isSmallPhone
        ? 14.0
        : isMobile
        ? 16.0
        : 20.0;
    final subtitleFontSize = isSmallPhone
        ? 10.0
        : isMobile
        ? 11.0
        : 13.0;
    // Dynamic appBarHeight based on content
    final appBarHeight = isSmallPhone
        ? 120.0
        : isMobile
        ? 115.0
        : 140.0;

    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: Colors.transparent),
      ),
      centerTitle: true,
      automaticallyImplyLeading: false,
      toolbarHeight: appBarHeight,
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: isSmallPhone ? 8.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Order Creation Guide',
              style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.bold,
                fontSize: titleFontSize,
              ),
              maxLines: 2,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
       Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: Text(
    'Live configuration, formula transparency, and costing insight',
    textAlign: TextAlign.center,
    maxLines: 3,
    softWrap: true,
    style: TextStyle(
      color: AppColors.secondaryText,
      fontSize: subtitleFontSize,
    ),
  ),
),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          color: AppColors.primaryText,
          tooltip: 'Refresh guide data',
          onPressed: _refreshCatalog,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 4.0 : 8.0),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Close',
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 4.0 : 8.0),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: TabBar(
          isScrollable: true,
          labelColor: AppColors.primaryText,
          unselectedLabelColor: AppColors.secondaryText,
          indicatorColor: AppColors.primaryAccent,
          onTap: (index) => setState(() => _selectedTabIndex = index),
          tabs: catalog.categories
              .map((category) => Tab(text: category.category))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildBody(ProductHelpCatalog catalog) {
    return TabBarView(
      children: catalog.categories
          .map((category) => _buildCategoryContent(category))
          .toList(),
    );
  }

  Widget _buildCategoryContent(ProductHelpCategoryData data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallPhone = screenWidth < 400;

    // Responsive padding
    final horizontalPadding = isSmallPhone
        ? 10.0
        : isMobile
        ? 14.0
        : 20.0;
    final titleFontSize = isSmallPhone
        ? 18.0
        : isMobile
        ? 20.0
        : 24.0;
    final summaryFontSize = isSmallPhone
        ? 11.0
        : isMobile
        ? 12.0
        : 14.0;
    final sectionHeaderSize = isSmallPhone ? 14.0 : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        16,
        horizontalPadding,
        30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
            softWrap: true,
          ),
          const SizedBox(height: 10),
          Text(
            data.summary,
            style: TextStyle(
              fontSize: summaryFontSize,
              color: AppColors.primaryText,
              height: 1.5,
            ),
            softWrap: true,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Product Types',
            icon: Icons.category_outlined,
            fontSize: sectionHeaderSize,
          ),
          _buildOptionList(data.productTypes),
          const SizedBox(height: 20),
          _buildSectionHeader(
            'Available Specifications',
            icon: Icons.settings_outlined,
            fontSize: sectionHeaderSize,
          ),
          ...data.specificationGroups.map(
            (group) => _buildSpecificationGroup(group, sectionHeaderSize),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(
            'Dynamic Rates & Costs',
            icon: Icons.attach_money_outlined,
            fontSize: sectionHeaderSize,
          ),
          _buildConfigEntries(data.configEntries),
          const SizedBox(height: 20),
          _buildSectionHeader(
            'Time Estimation Logic',
            icon: Icons.access_time_outlined,
            fontSize: sectionHeaderSize,
          ),
          _buildBulletedList(data.timeLogicHighlights),
          const SizedBox(height: 20),
          _buildSectionHeader(
            'Formula Transparency',
            icon: Icons.code_outlined,
            fontSize: sectionHeaderSize,
          ),
          _buildBulletedList(data.formulaRows),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    required IconData icon,
    double fontSize = 16.0,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryAccent, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
            softWrap: true,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionList(List<HelpOption> options) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallPhone = screenWidth < 400;

    // Responsive grid layout
    final crossAxisCount = isSmallPhone
        ? 1
        : isMobile
        ? 2
        : 3;
    final spacing = isSmallPhone
        ? 10.0
        : isMobile
        ? 12.0
        : 14.0;

    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    // For mobile/tablet: use Wrap for responsive grid
    if (isMobile) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: isSmallPhone ? 0.0 : 0.0),
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          alignment: WrapAlignment.start,
          children: options
              .map(
                (option) => SizedBox(
                  width:
                      (screenWidth - (crossAxisCount + 1) * spacing) /
                      crossAxisCount,
                  child: _buildOptionCard(option, isSmallPhone),
                ),
              )
              .toList(),
        ),
      );
    }

    // For desktop: use column for better readability
    return Column(
      children: options
          .map((option) => _buildOptionCard(option, isSmallPhone))
          .toList(),
    );
  }

  Widget _buildOptionCard(HelpOption option, bool isSmallPhone) {
    return Container(
      margin: EdgeInsets.only(top: isSmallPhone ? 8.0 : 10.0),
      padding: EdgeInsets.all(isSmallPhone ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.name,
            style: TextStyle(
              fontSize: isSmallPhone ? 13.0 : 15.0,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            option.description,
            style: TextStyle(
              fontSize: isSmallPhone ? 12.0 : 13.0,
              color: AppColors.secondaryText,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (option.details != null && option.details!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildDetailsGrid(option.details!),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecificationGroup(
    HelpOptionGroup group,
    double sectionHeaderFontSize,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth < 400;
    final groupTitleFontSize = isSmallPhone ? 13.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          group.title,
          style: TextStyle(
            fontSize: groupTitleFontSize,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        _buildOptionList(group.options),
      ],
    );
  }

  Widget _buildConfigEntries(List<ProductHelpConfigEntry> entries) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth < 400;
    final isMobile = screenWidth < 600;

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No live configuration records are available. Check the Supabase config tables for this category.',
          style: TextStyle(
            color: AppColors.secondaryText,
            fontSize: isSmallPhone ? 12.0 : 13.0,
          ),
        ),
      );
    }

    return Column(
      children: entries
          .map(
            (entry) => Container(
              margin: EdgeInsets.only(top: isSmallPhone ? 10.0 : 12.0),
              padding: EdgeInsets.all(isSmallPhone ? 12.0 : 16.0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: TextStyle(
                      fontSize: isSmallPhone ? 13.0 : 14.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...entry.values.entries.map(
                    (value) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  value.key,
                                  style: TextStyle(
                                    fontSize: isSmallPhone ? 12.0 : 13.0,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  value.value is double
                                      ? value.value.toStringAsFixed(2)
                                      : value.value.toString(),
                                  style: TextStyle(
                                    fontSize: isSmallPhone ? 12.0 : 13.0,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    value.key,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  value.value is double
                                      ? value.value.toStringAsFixed(2)
                                      : value.value.toString(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildBulletedList(List<String> items) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth < 400;
    final fontSize = isSmallPhone ? 13.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: EdgeInsets.symmetric(vertical: isSmallPhone ? 5.0 : 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryText,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: fontSize,
                        color: AppColors.primaryText,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDetailsGrid(Map<String, dynamic> details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth < 400;
    final spacing = isSmallPhone ? 8.0 : 12.0;
    final fontSize = isSmallPhone ? 11.0 : 12.0;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: details.entries
          .map(
            (entry) => Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallPhone ? 8.0 : 10.0,
                vertical: isSmallPhone ? 6.0 : 8.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '${entry.key}: ${entry.value}',
                style: TextStyle(
                  fontSize: fontSize,
                  color: AppColors.primaryText,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryAccent),
    );
  }

  Future<void> _refreshCatalog() async {
    final catalog = await HelpCenterService().refreshCatalog();
    if (!mounted) return;
    if (_selectedTabIndex >= catalog.categories.length) {
      setState(() => _selectedTabIndex = 0);
    } else {
      setState(() {});
    }
  }
}
