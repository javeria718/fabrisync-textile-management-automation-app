import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/controllers/new_order/order_input_controller.dart';
import 'package:fabri_sync/services/order_calculation_service.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/utils/work_duration_formatter.dart';
import 'package:fabri_sync/view/dashboards/admin.dart';
import 'package:fabri_sync/widgets/custom_appBar.dart';
import 'package:fabri_sync/widgets/new_order_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderSummaryScreen extends StatefulWidget {
  const OrderSummaryScreen({
    super.key,
    required this.controller,
    this.existingOrder,
    this.isEditing = false,
  });

  final OrderInputController controller;
  final OrderModel? existingOrder;
  final bool isEditing;

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  OrderInputController get controller => widget.controller;
  bool _isResolvingOrderId = false;
  String? _orderIdError;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChanged);
    if (_currentOrderId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resolveOrderId();
      });
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  String? get _currentOrderId {
    final existingId = widget.existingOrder?.orderId.trim();
    if (existingId != null && existingId.isNotEmpty) return existingId;

    final controllerId = controller.orderId?.trim();
    if (controllerId != null && controllerId.isNotEmpty) return controllerId;

    return null;
  }

  Future<void> _resolveOrderId() async {
    if (_isResolvingOrderId || _currentOrderId != null) return;

    setState(() {
      _isResolvingOrderId = true;
      _orderIdError = null;
    });

    try {
      await controller.ensureActualOrderId(existingOrder: widget.existingOrder);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _orderIdError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isResolvingOrderId = false);
      }
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  Future<void> _saveDraft() async {
    await _submit(
      successMessage: 'Draft saved successfully',
      action: () => controller.saveDraft(existingOrder: widget.existingOrder),
      navigateHome: true,
    );
  }

  Future<void> _onSaveDraftPressed() async {
    if (controller.isSubmitting) return;

    final confirmed = await _showSaveDraftConfirmation();
    if (!confirmed || !mounted) return;

    await _saveDraft();
  }

  Future<bool> _showSaveDraftConfirmation() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            final width = MediaQuery.of(context).size.width;
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: width >= 700 ? 620 : width - 40,
                ),
                child: Container(
                  decoration: AppDecorations.surface(radius: 22),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.save_outlined,
                              color: AppColors.primaryAccent,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Confirm Draft Save',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Saving a draft preserves the current estimate and delivery assumptions for up to three days. Expired drafts will require a fresh estimate before order creation.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryText,
                                backgroundColor: AppColors.surface,
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                minimumSize: const Size.fromHeight(52),
                              ),
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                minimumSize: const Size.fromHeight(52),
                              ),
                              onPressed: controller.isSubmitting
                                  ? null
                                  : () => Navigator.of(context).pop(true),
                              child: const Text('Save Draft'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ) ??
        false;
  }

  Future<void> _createOrder() async {
    await _submit(
      successMessage: widget.isEditing
          ? 'Order updated successfully'
          : 'Order created successfully',
      action: () => controller.createOrder(existingOrder: widget.existingOrder),
      navigateHome: true,
    );
  }

  Future<void> _onCreateOrderPressed() async {
    if (controller.isSubmitting) return;

    final confirmed = await _showOrderCreationConfirmation();
    if (!confirmed || !mounted) return;

    await _createOrder();
  }

  Future<bool> _showOrderCreationConfirmation() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            final screenSize = MediaQuery.of(context).size;
            final width = screenSize.width;
            final height = screenSize.height;
            final isMobile = width < 600;

            // Responsive sizing
            final dialogWidth = width >= 700 ? 620.0 : width - 40;
            final maxDialogHeight =
                height * 0.85; // Leave 15% margin for system UI
            final contentPadding = isMobile ? 18.0 : 24.0;
            final spaceBetweenSections = isMobile ? 14.0 : 18.0;

            // Responsive font sizes
            final headingFontSize = isMobile ? 16.0 : 20.0;
            final descriptionFontSize = isMobile ? 13.0 : 15.0;
            final infoFontSize = isMobile ? 12.0 : 13.0;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(
                horizontal: contentPadding,
                vertical: contentPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogWidth,
                  maxHeight: maxDialogHeight,
                ),
                child: Container(
                  decoration: AppDecorations.surface(radius: 22),
                  padding: EdgeInsets.all(contentPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with icon and title
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.accentYellow.withAlpha(36),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.accentYellow,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Confirm Order Creation',
                              style: TextStyle(
                                fontSize: headingFontSize,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryText,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spaceBetweenSections),

                      // Scrollable content
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Description text
                              Text(
                                'Please review all entered order details carefully before proceeding. Once the order is created, major specifications and production planning data may no longer be editable.',
                                style: TextStyle(
                                  fontSize: descriptionFontSize,
                                  height: 1.5,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              SizedBox(height: spaceBetweenSections + 2),

                              // Info box
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.accentYellow.withAlpha(31),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.accentYellow.withAlpha(56),
                                  ),
                                ),
                                padding: EdgeInsets.all(isMobile ? 10.0 : 14.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: AppColors.accentYellow,
                                      size: isMobile ? 18 : 20,
                                    ),
                                    SizedBox(width: isMobile ? 8 : 10),
                                    Expanded(
                                      child: Text(
                                        'You will not be able to make significant changes after order creation.',
                                        style: TextStyle(
                                          fontSize: infoFontSize,
                                          color: AppColors.primaryText,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: spaceBetweenSections),

                      // Responsive buttons
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final buttonAreaWidth = constraints.maxWidth;
                          // Stack buttons vertically if width is too small
                          final useVerticalLayout = buttonAreaWidth < 320;

                          if (useVerticalLayout) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryText,
                                    backgroundColor: AppColors.surface,
                                    side: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                  onPressed: controller.isSubmitting
                                      ? null
                                      : () => Navigator.of(context).pop(true),
                                  child: const Text(
                                    'Confirm & Create Order',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primaryText,
                                      backgroundColor: AppColors.surface,
                                      side: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryAccent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                    onPressed: controller.isSubmitting
                                        ? null
                                        : () => Navigator.of(context).pop(true),
                                    child: const Text(
                                      'Confirm & Create Order',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ) ??
        false;
  }

  Future<void> _submit({
    required String successMessage,
    required Future<void> Function() action,
    bool navigateHome = false,
  }) async {
    final error = controller.validateAll();
    if (error != null) {
      _showSnack(error, isError: true);
      return;
    }

    if (controller.calculation == null) {
      final calcError = await controller.calculateOrder();
      if (calcError != null) {
        _showSnack(calcError, isError: true);
        return;
      }
    }

    try {
      await action();
      if (!mounted) return;
      _showSnack(successMessage);
      if (navigateHome) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = controller.calculation;
    final orderId = _currentOrderId;

    if (orderId == null) {
      return Scaffold(
        backgroundColor: AppColors.appBackground,
        appBar: buildGradientAppBar('Order Summary'),
        body: gradientOrderBackground(
          child: SafeArea(
            child: Center(
              child: _orderIdError == null
                  ? const CircularProgressIndicator()
                  : OrderStepCard(
                      title: 'Order ID',
                      icon: Icons.receipt_long_outlined,
                      child: Column(
                        children: [
                          OrderEmptyState(text: _orderIdError!),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _isResolvingOrderId
                                ? null
                                : _resolveOrderId,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: buildGradientAppBar('Order Summary'),
      body: gradientOrderBackground(
        child: SafeArea(
          child: OrderWizardShell(
            stepLabel: 'Step 5 of 5',
            children: [
              OrderStepCard(
                title: 'Order Overview',
                icon: Icons.receipt_long_outlined,
                child: Column(
                  children: [
                    _row('Order ID', orderId),
                    _row('Product Category', controller.productCategory ?? '-'),
                    _row('Product Type', controller.productType ?? '-'),
                    _row('Quantity', controller.quantity.toString()),
                    _row(
                      'Required Delivery',
                      controller.requiredDeliveryDate == null
                          ? '-'
                          : DateFormat(
                              'dd MMM yyyy',
                            ).format(controller.requiredDeliveryDate!),
                    ),
                    _row('Quality Grade', controller.qualityGrade ?? '-'),
                    _row('Priority', result?.priority ?? controller.priority),
                  ],
                ),
              ),
              OrderStepCard(
                title: 'Product Specifications',
                icon: Icons.tune_outlined,
                child: Column(
                  children: controller.buildSpecifications().entries.map((e) {
                    final value = e.value is bool
                        ? ((e.value as bool) ? 'Yes' : 'No')
                        : e.value.toString();
                    return _row(_prettyKey(e.key), value);
                  }).toList(),
                ),
              ),
              if (controller.draftExpired)
                OrderStepCard(
                  title: 'Draft Expiry Notice',
                  icon: Icons.lock_clock,
                  child: Column(
                    children: [
                      const Text(
                        'This draft has expired. The data shown may no longer reflect current pricing and production timing. Refresh the draft before creating an order.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              OrderStepCard(
                title: 'Base Cost Configuration (Per Unit)',
                icon: Icons.payments_outlined,
                child: result == null
                    ? const OrderEmptyState(text: 'Calculating costs...')
                    : Column(
                        children: [
                          _row(
                            'Material Rate / Unit',
                            'PKR ${result.costBreakdown.materialCostPerUnit.toStringAsFixed(0)}',
                          ),
                          _row(
                            'Labor Rate / Unit',
                            'PKR ${result.costBreakdown.laborCostPerUnit.toStringAsFixed(0)}',
                          ),
                          _row(
                            'Processing Rate',
                            'PKR ${result.costBreakdown.processingCost.toStringAsFixed(0)}',
                          ),
                          _row(
                            'Additional Rate / Extras',
                            'PKR ${result.costBreakdown.additionalCharges.toStringAsFixed(0)}',
                          ),
                          if (controller.specialInstructionsCtrl.text
                              .trim()
                              .isNotEmpty)
                            _row(
                              'Special Instructions',
                              controller.specialInstructionsCtrl.text.trim(),
                            ),
                          _row(
                            'Custom Packaging',
                            controller.customPackaging ? 'Yes' : 'No',
                          ),
                        ],
                      ),
              ),
              if (result != null) ...[
                OrderStepCard(
                  title: 'Production Estimate',
                  icon: Icons.schedule_outlined,
                  child: Column(
                    children: [
                      _row(
                        'Estimated Hours',
                        result.estimatedProductionHours.toStringAsFixed(1),
                      ),
                      _row(
                        'Workday Equivalent',
                        _formatWorkdayEquivalent(result.estimatedWorkDaysExact),
                      ),
                      ...result.schedule.map((item) => _scheduleRow(item)),
                    ],
                  ),
                ),
                OrderStepCard(
                  title: 'Final Order Cost Breakdown',
                  icon: Icons.currency_rupee,
                  child: Column(
                    children: [
                      _moneyRow(
                        'Material Total Cost',
                        result.costBreakdown.materialTotalCost,
                      ),
                      _moneyRow(
                        'Labor Total Cost',
                        result.costBreakdown.laborTotalCost,
                      ),
                      _moneyRow(
                        'Processing Total Cost',
                        result.costBreakdown.processingTotalCost,
                      ),
                      _moneyRow(
                        'Additional Total Cost',
                        result.costBreakdown.additionalTotalCost,
                      ),
                      _moneyRow(
                        'Rush Charges',
                        result.costBreakdown.rushCharges,
                      ),
                      const Divider(color: AppColors.divider),
                      _moneyRow(
                        'Estimated Total Cost',
                        result.costBreakdown.estimatedTotalCost,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ],
              OrderActionBar(
                children: [
                  OutlinedButton.icon(
                    onPressed: controller.isSubmitting
                        ? null
                        : () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        controller.isSubmitting ||
                            !controller.hasValidDeliveryDate ||
                            controller.draftExpired
                        ? null
                        : _onSaveDraftPressed,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save as Draft'),
                  ),
                  ElevatedButton.icon(
                    onPressed:
                        controller.isSubmitting ||
                            !controller.hasValidDeliveryDate ||
                            controller.draftExpired
                        ? null
                        : _onCreateOrderPressed,
                    icon: controller.isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      widget.isEditing ? 'Update Order' : 'Create Order',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moneyRow(String label, double value, {bool bold = false}) {
    return _row(label, 'PKR ${value.toStringAsFixed(0)}', bold: bold);
  }

  Widget _scheduleRow(DepartmentScheduleItem item) {
    final fmt = DateFormat('dd MMM, hh:mm a');
    return _row(
      item.departmentLabel,
      '${formatWorkDuration(item.estimatedHours)} (${fmt.format(item.plannedStartDate)} - ${fmt.format(item.plannedEndDate)})',
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                color: bold ? AppColors.primaryText : AppColors.secondaryText,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _prettyKey(String key) {
    return key
        .split('_')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  String _formatWorkdayEquivalent(double value) {
    final rounded = value.toStringAsFixed(2);
    return '$rounded ${value <= 1 ? 'workday' : 'workdays'}';
  }
}
