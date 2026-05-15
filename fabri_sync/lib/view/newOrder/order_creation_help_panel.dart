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
  late final Future<ProductHelpCatalog> _catalogFuture;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _catalogFuture = HelpCenterService().loadCatalog();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProductHelpCatalog>(
      future: _catalogFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildLoading();
        }

        if (snapshot.hasError) {
          return _buildError(snapshot.error.toString());
        }

        final catalog = snapshot.data!;
        return DefaultTabController(
          length: catalog.categories.length,
          initialIndex: _selectedTabIndex,
          child: Scaffold(
            backgroundColor: AppColors.surface,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(92),
              child: _buildPanelAppBar(catalog),
            ),
            body: _buildBody(catalog),
          ),
        );
      },
    );
  }

  Widget _buildPanelAppBar(ProductHelpCatalog catalog) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            'Order Creation Guide',
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Live configuration, formula transparency, and costing insight',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          color: AppColors.primaryText,
          tooltip: 'Refresh guide data',
          onPressed: _refreshCatalog,
        ),
        IconButton(
          icon: const Icon(Icons.close, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Close',
        ),
      ],
      bottom: TabBar(
        isScrollable: true,
        labelColor: AppColors.primaryText,
        unselectedLabelColor: AppColors.secondaryText,
        indicatorColor: AppColors.primaryAccent,
        onTap: (index) => setState(() => _selectedTabIndex = index),
        tabs: catalog.categories
            .map((category) => Tab(text: category.category))
            .toList(),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.summary,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Product Types', icon: Icons.category_outlined),
          _buildOptionList(data.productTypes),
          const SizedBox(height: 20),
          _buildSectionHeader(
            'Available Specifications',
            icon: Icons.settings_outlined,
          ),
          ...data.specificationGroups.map(
            (group) => _buildSpecificationGroup(group),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(
            'Dynamic Rates & Costs',
            icon: Icons.attach_money_outlined,
          ),
          _buildConfigEntries(data.configEntries),
          const SizedBox(height: 20),
          _buildSectionHeader(
            'Time Estimation Logic',
            icon: Icons.access_time_outlined,
          ),
          _buildBulletedList(data.timeLogicHighlights),
          const SizedBox(height: 20),
          _buildSectionHeader(
            'Formula Transparency',
            icon: Icons.code_outlined,
          ),
          _buildBulletedList(data.formulaRows),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required IconData icon}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryAccent, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionList(List<HelpOption> options) {
    return Column(
      children: options
          .map(
            (option) => Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(16),
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    option.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  if (option.details != null && option.details!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildDetailsGrid(option.details!),
                  ],
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSpecificationGroup(HelpOptionGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          group.title,
          style: const TextStyle(
            fontSize: 14,
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
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No live configuration records are available. Check the Supabase config tables for this category.',
          style: TextStyle(color: AppColors.secondaryText),
        ),
      );
    }

    return Column(
      children: entries
          .map(
            (entry) => Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...entry.values.entries.map(
                    (value) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
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
                      style: const TextStyle(
                        fontSize: 14,
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
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: details.entries
          .map(
            (entry) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '${entry.key}: ${entry.value}',
                style: const TextStyle(
                  fontSize: 12,
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

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load guide',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshCatalog() async {
    setState(() {
      _catalogFuture = HelpCenterService().refreshCatalog();
    });
  }
}
