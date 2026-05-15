import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/controllers/new_order/order_input_controller.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/view/newOrder/cost_inputs.dart';
import 'package:fabri_sync/view/newOrder/order_creation_help_panel.dart';
import 'package:fabri_sync/widgets/custom_appBar.dart';
import 'package:fabri_sync/widgets/new_order_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderInputScreen extends StatefulWidget {
  final OrderModel? existingOrder;
  final bool isEditing;
  final bool isDraft;

  const OrderInputScreen.edit({super.key, required this.existingOrder})
    : isEditing = true,
      isDraft = false;

  const OrderInputScreen({
    super.key,
    this.existingOrder,
    this.isEditing = false,
    this.isDraft = false,
  });

  @override
  State<OrderInputScreen> createState() => _OrderInputScreenState();
}

class _OrderInputScreenState extends State<OrderInputScreen> {
  late final OrderInputController controller;
  bool loadingExisting = false;

  @override
  void initState() {
    super.initState();
    controller = OrderInputController()..addListener(_onControllerChanged);
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    if (widget.existingOrder == null) return;
    setState(() => loadingExisting = true);
    await controller.initFromOrder(widget.existingOrder);
    if (mounted) setState(() => loadingExisting = false);
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    controller.dispose();
    super.dispose();
  }

  Future<void> _pickDeliveryDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentDate = controller.requiredDeliveryDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate == null || currentDate.isBefore(today)
          ? today
          : currentDate,
      firstDate: today,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) controller.setRequiredDeliveryDate(picked);
  }

  void _next() {
    final error = controller.validateProductStep();
    if (error != null) {
      _showError(error);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CostInputsScreen(
          controller: controller,
          existingOrder: widget.existingOrder,
          isEditing: widget.isEditing,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: buildGradientAppBar(
        widget.isDraft
            ? 'Continue Draft'
            : widget.isEditing
            ? 'Edit Order'
            : 'New Order',
        actions: [
          IconButton(
            icon: const Icon(
              Icons.help_outline_rounded,
              color: AppColors.primaryText,
            ),
            tooltip: 'Product Guide',
            onPressed: () => OrderCreationHelpPanel.open(context),
          ),
        ],
      ),
      body: gradientOrderBackground(
        child: SafeArea(
          child: loadingExisting
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryAccent,
                  ),
                )
              : controller.draftExpired
              ? _ExpiredDraftNotice(
                  message:
                      controller.draftExpiryWarning ??
                      'This draft has expired. Refresh the draft to continue with current pricing.',
                )
              : _WizardShell(
                  stepLabel: 'Step 1 of 5',
                  children: [
                    _productSection(),
                    _basicDetailsSection(),
                    _specificationsSection(),
                    _nextButton(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _productSection() {
    return OrderStepCard(
      title: 'Product Selection',
      icon: Icons.category_outlined,
      child: OrderFieldWrap(
        children: [
          OrderDropdownField(
            label: 'Product Category',
            value: controller.productCategory,
            items: OrderInputController.productCategories,
            onChanged: controller.setProductCategory,
          ),
          OrderDropdownField(
            label: 'Product Type',
            value: controller.productType,
            items: controller.productTypes,
            onChanged: controller.productCategory == null
                ? null
                : controller.setProductType,
          ),
        ],
      ),
    );
  }

  Widget _basicDetailsSection() {
    final dateText = controller.requiredDeliveryDate == null
        ? 'Select delivery date'
        : DateFormat('dd MMM yyyy').format(controller.requiredDeliveryDate!);

    return OrderStepCard(
      title: 'Basic Order Details',
      icon: Icons.receipt_long_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.deliveryDateWarning != null) ...[
            _DeliveryDateWarning(message: controller.deliveryDateWarning!),
            const SizedBox(height: 12),
          ],
          OrderFieldWrap(
            children: [
              OrderTextInputField(
                label: 'Order Quantity',
                icon: Icons.inventory_2_outlined,
                controller: controller.quantityCtrl,
                keyboardType: TextInputType.number,
              ),
              OrderPickerField(
                label: 'Required Delivery Date',
                value: dateText,
                icon: Icons.event_outlined,
                onTap: _pickDeliveryDate,
              ),
              OrderDropdownField(
                label: 'Quality Grade',
                value: controller.qualityGrade,
                items: OrderInputController.qualityGrades,
                onChanged: controller.setQualityGrade,
              ),
              _PriorityPreview(priority: controller.priority),
            ],
          ),
        ],
      ),
    );
  }

  Widget _specificationsSection() {
    final category = controller.productCategory;
    Widget child;

    if (category == 'Bedsheet') {
      child = OrderFieldWrap(
        children: [
          OrderDropdownField(
            label: 'Bed Size',
            value: controller.bedSize,
            items: OrderInputController.bedSizes,
            onChanged: controller.setBedSize,
          ),
          OrderDropdownField(
            label: 'Fabric Type',
            value: controller.bedsheetFabricType,
            items: OrderInputController.bedsheetFabrics,
            onChanged: controller.setBedsheetFabricType,
          ),
          OrderSwitchField(
            label: 'Printing Required',
            value: controller.printingRequired,
            onChanged: controller.setPrintingRequired,
          ),
          OrderTextInputField(
            label: 'Color / Pattern',
            icon: Icons.palette_outlined,
            controller: controller.colorPatternCtrl,
          ),
        ],
      );
    } else if (category == 'Abaya') {
      child = OrderFieldWrap(
        children: [
          OrderDropdownField(
            label: 'Size Range',
            value: controller.sizeRange,
            items: OrderInputController.sizeRanges,
            onChanged: controller.setSizeRange,
          ),
          OrderDropdownField(
            label: 'Fabric Type',
            value: controller.abayaFabricType,
            items: OrderInputController.abayaFabrics,
            onChanged: controller.setAbayaFabricType,
          ),
          OrderSwitchField(
            label: 'Embellishment',
            value: controller.embellishment,
            onChanged: controller.setEmbellishment,
          ),
          OrderDropdownField(
            label: 'Style Type',
            value: controller.styleType,
            items: OrderInputController.styleTypes,
            onChanged: controller.setStyleType,
          ),
        ],
      );
    } else if (category == 'Curtain') {
      child = OrderFieldWrap(
        children: [
          OrderTextInputField(
            label: 'Length',
            icon: Icons.height_outlined,
            controller: controller.lengthCtrl,
            keyboardType: TextInputType.number,
          ),
          OrderTextInputField(
            label: 'Width',
            icon: Icons.straighten_outlined,
            controller: controller.widthCtrl,
            keyboardType: TextInputType.number,
          ),
          OrderDropdownField(
            label: 'Fabric Type',
            value: controller.curtainFabricType,
            items: OrderInputController.curtainFabrics,
            onChanged: controller.setCurtainFabricType,
          ),
          OrderDropdownField(
            label: 'Header Style',
            value: controller.headerStyle,
            items: OrderInputController.headerStyles,
            onChanged: controller.setHeaderStyle,
          ),
        ],
      );
    } else {
      child = const OrderEmptyState(text: 'Select a product category first');
    }

    return OrderStepCard(
      title: 'Product Specifications',
      icon: Icons.tune_outlined,
      child: child,
    );
  }

  Widget _nextButton() {
    return _ActionBar(
      children: [
        ElevatedButton.icon(
          onPressed: controller.hasValidDeliveryDate ? _next : null,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Next'),
        ),
      ],
    );
  }
}

class _DeliveryDateWarning extends StatelessWidget {
  const _DeliveryDateWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.accentFill(AppColors.accentOrange, radius: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.accentOrange,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiredDraftNotice extends StatelessWidget {
  const _ExpiredDraftNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AppDecorations.surface(radius: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lock_clock, color: AppColors.error),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Expired Draft',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Back to Draft List'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityPreview extends StatelessWidget {
  const _PriorityPreview({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: AppDecorations.softPanel(radius: 14),
      child: Row(
        children: [
          const Icon(Icons.flag_outlined, color: AppColors.secondaryText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              priority == 'Rush'
                  ? 'Priority: Rush'
                  : 'Priority calculated on Step 3',
              style: const TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WizardShell extends StatelessWidget {
  const _WizardShell({required this.stepLabel, required this.children});

  final String stepLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 980;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 28 : 14,
            vertical: 18,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      stepLabel,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...children,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surface(radius: 18),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.end,
        children: children,
      ),
    );
  }
}
