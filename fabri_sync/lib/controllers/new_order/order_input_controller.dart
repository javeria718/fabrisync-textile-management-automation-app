import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/services/draft/draft_expiry_service.dart';
import 'package:fabri_sync/services/new_order_service.dart';
import 'package:fabri_sync/services/order_calculation_service.dart';
import 'package:flutter/material.dart';

class OrderInputController extends ChangeNotifier {
  OrderInputController({
    NewOrderService? service,
    DraftExpiryService? draftExpiryService,
  }) : _service = service ?? NewOrderService(),
       _draftExpiryService = draftExpiryService ?? DraftExpiryService() {
    for (final ctrl in [
      quantityCtrl,
      colorPatternCtrl,
      lengthCtrl,
      widthCtrl,
    ]) {
      ctrl.addListener(_clearCalculation);
    }
  }

  final NewOrderService _service;
  final DraftExpiryService _draftExpiryService;

  static const productCategories = ['Bedsheet', 'Abaya', 'Curtain'];
  static const qualityGrades = ['Economy', 'Standard', 'Premium'];

  static const productTypesByCategory = {
    'Bedsheet': ['Flat Sheet', 'Fitted Sheet', 'Pillow Cover Set'],
    'Abaya': ['Fancy Abaya', 'Casual Abaya', 'Embroidered Abaya'],
    'Curtain': [
      'Window Curtain',
      'Door Curtain',
      'Blackout Curtain',
      'Decorative Curtain',
    ],
  };

  static const bedSizes = ['Single', 'Double', 'Queen', 'King'];
  static const bedsheetFabrics = ['Cotton', 'Blend', 'Silk'];
  static const sizeRanges = ['Small', 'Medium', 'Large', 'XLarge'];
  static const abayaFabrics = ['Nidha', 'Georgette', 'Chiffon'];
  static const styleTypes = ['Open Abaya', 'Closed Abaya'];
  static const curtainFabrics = ['Sheer', 'Blackout', 'Thermal'];
  static const headerStyles = ['Eyelet', 'Pleated', 'Rod Pocket'];

  static const Map<String, String> _legacyAbayaProductTypeMap = {
    'Open Abaya': 'Fancy Abaya',
    'Closed Abaya': 'Casual Abaya',
  };

  static const Map<String, String> _legacyAbayaStyleTypeMap = {
    'Casual': 'Closed Abaya',
    'Fancy': 'Open Abaya',
    'Open': 'Open Abaya',
    'Closed': 'Closed Abaya',
    'Open Abaya': 'Open Abaya',
    'Closed Abaya': 'Closed Abaya',
  };

  static String? normalizeLegacyAbayaProductType(String? value) {
    if (value == null) return null;
    return _legacyAbayaProductTypeMap[value] ?? value;
  }

  static String? normalizeLegacyAbayaStyleType(String? value) {
    if (value == null) return null;
    return _legacyAbayaStyleTypeMap[value] ?? value;
  }

  final quantityCtrl = TextEditingController();
  final colorPatternCtrl = TextEditingController();
  final lengthCtrl = TextEditingController();
  final widthCtrl = TextEditingController();
  final specialInstructionsCtrl = TextEditingController();

  String? productCategory;
  String? productType;
  DateTime? requiredDeliveryDate;
  String? qualityGrade;
  String priority = 'Normal';

  String? bedSize;
  String? bedsheetFabricType;
  bool printingRequired = false;

  String? sizeRange;
  String? abayaFabricType;
  bool embellishment = false;
  String? styleType;

  String? curtainFabricType;
  String? headerStyle;

  bool customPackaging = false;
  bool isSubmitting = false;
  CalculationResult? calculation;
  String? orderId;
  bool isPersisted = false;
  bool isDraftMode = false;
  bool draftExpired = false;
  String? draftExpiryWarning;
  bool deliveryDateExpired = false;
  String? deliveryDateWarning;

  static const expiredDeliveryDateMessage =
      'Saved delivery date has passed. Please select a new delivery date to recalculate this draft.';

  List<String> get productTypes =>
      productTypesByCategory[productCategory] ?? const [];

  bool get hasCalculated => calculation != null;

  Future<String> ensureActualOrderId({OrderModel? existingOrder}) async {
    final existingId = existingOrder?.orderId.trim();
    if (existingId != null && existingId.isNotEmpty) {
      if (orderId != existingId) {
        orderId = existingId;
        notifyListeners();
      }
      return existingId;
    }

    final currentId = orderId?.trim();
    if (currentId != null && currentId.isNotEmpty) return currentId;

    if (productCategory == null) {
      throw Exception('Select a product category before generating order ID');
    }

    final generated = await _service.generateNextOrderId(
      productCategory: productCategory!,
    );
    orderId = generated;
    notifyListeners();
    return generated;
  }

  Future<void> initFromOrder(OrderModel? existingOrder) async {
    if (existingOrder == null) return;

    orderId = existingOrder.orderId;
    isPersisted = true;
    isDraftMode = existingOrder.status.toLowerCase() == 'draft';
    quantityCtrl.text = existingOrder.quantity == 0
        ? ''
        : existingOrder.quantity.toString();
    productCategory = existingOrder.productCategory;
    productType = normalizeLegacyAbayaProductType(existingOrder.productType);
    requiredDeliveryDate = existingOrder.requiredDeliveryDate;
    deliveryDateExpired = false;
    deliveryDateWarning = null;
    if (isDraftMode &&
        requiredDeliveryDate != null &&
        _isBeforeToday(requiredDeliveryDate!)) {
      requiredDeliveryDate = null;
      deliveryDateExpired = true;
      deliveryDateWarning = expiredDeliveryDateMessage;
    }
    qualityGrade = existingOrder.qualityGrade;
    priority = existingOrder.priority ?? 'Normal';
    specialInstructionsCtrl.text = existingOrder.specialInstructions ?? '';
    customPackaging = existingOrder.customPackaging;

    if (isDraftMode) {
      draftExpired = _draftExpiryService.isDraftExpired(existingOrder);
      if (draftExpired) {
        await _draftExpiryService.validateDraftExpiry(existingOrder);
        draftExpiryWarning =
            'This draft is expired. Pricing and lead times are no longer guaranteed. Create a fresh order to capture the latest rates.';
      }
    }

    final specs = existingOrder.productSpecifications;
    bedSize = specs['bed_size']?.toString();
    bedsheetFabricType = specs['fabric_type']?.toString();
    printingRequired = specs['printing_required'] == true;
    colorPatternCtrl.text = specs['color_pattern']?.toString() ?? '';

    sizeRange = specs['size_range']?.toString();
    abayaFabricType = specs['fabric_type']?.toString();
    embellishment = specs['embellishment'] == true;
    styleType = normalizeLegacyAbayaStyleType(specs['style_type']?.toString());

    lengthCtrl.text = specs['length']?.toString() ?? '';
    widthCtrl.text = specs['width']?.toString() ?? '';
    curtainFabricType = specs['fabric_type']?.toString();
    headerStyle = specs['header_style']?.toString();

    await _service.fetchCostBreakdown(existingOrder.orderId);
    // Cost values are calculated by category-specific services

    if (draftExpired) {
      notifyListeners();
      return;
    }

    if (canCalculate) {
      await calculateOrder();
    } else {
      notifyListeners();
    }
  }

  void setProductCategory(String? value) {
    productCategory = value;
    productType = null;
    calculation = null;
    _resetSpecifications();
    notifyListeners();
  }

  void setProductType(String? value) {
    productType = value;
    calculation = null;
    notifyListeners();
  }

  void setRequiredDeliveryDate(DateTime value) {
    requiredDeliveryDate = value;
    if (!_isBeforeToday(value)) {
      deliveryDateExpired = false;
      deliveryDateWarning = null;
    }
    calculation = null;
    notifyListeners();
  }

  void setQualityGrade(String? value) {
    qualityGrade = value;
    calculation = null;
    notifyListeners();
  }

  void setBedSize(String? value) {
    bedSize = value;
    calculation = null;
    notifyListeners();
  }

  void setBedsheetFabricType(String? value) {
    bedsheetFabricType = value;
    calculation = null;
    notifyListeners();
  }

  void setPrintingRequired(bool value) {
    printingRequired = value;
    calculation = null;
    notifyListeners();
  }

  void setSizeRange(String? value) {
    sizeRange = value;
    calculation = null;
    notifyListeners();
  }

  void setAbayaFabricType(String? value) {
    abayaFabricType = value;
    calculation = null;
    notifyListeners();
  }

  void setEmbellishment(bool value) {
    embellishment = value;
    calculation = null;
    notifyListeners();
  }

  void setStyleType(String? value) {
    styleType = value;
    calculation = null;
    notifyListeners();
  }

  void setCurtainFabricType(String? value) {
    curtainFabricType = value;
    calculation = null;
    notifyListeners();
  }

  void setHeaderStyle(String? value) {
    headerStyle = value;
    calculation = null;
    notifyListeners();
  }

  void setCustomPackaging(bool value) {
    customPackaging = value;
    notifyListeners();
  }

  /// Calculate order estimate using category-specific services.
  /// Each category (Curtain, Abaya, Bedsheet) uses dedicated cost configurations.
  Future<String?> calculateOrder() async {
    final error = validateAll();
    if (error != null) return error;

    try {
      final result = await _draftExpiryService.refreshLatestEstimate(
        OrderDraftInput(
          productCategory: productCategory!,
          productType: productType!,
          quantity: quantity,
          requiredDeliveryDate: requiredDeliveryDate!,
          qualityGrade: qualityGrade!,
          specifications: buildSpecifications(),
        ),
      );

      calculation = result;
      priority = result.priority;
      notifyListeners();
      return null;
    } catch (e) {
      return 'Failed to calculate order: ${e.toString()}';
    }
  }

  Future<void> saveDraft({OrderModel? existingOrder}) async {
    await _save(status: 'draft', existingOrder: existingOrder);
  }

  Future<void> createOrder({OrderModel? existingOrder}) async {
    await _save(status: 'pending', existingOrder: existingOrder);
  }

  Future<void> _save({
    required String status,
    required OrderModel? existingOrder,
  }) async {
    if (calculation == null) {
      final error = await calculateOrder();
      if (error != null) throw Exception(error);
    }

    final result = calculation!;

    isSubmitting = true;
    notifyListeners();
    try {
      final orderId = existingOrder?.orderId ?? await _ensureOrderIdForSave();
      final shouldUpdate = isPersisted || existingOrder != null;
      if (status.toLowerCase() == 'draft') {
        if (shouldUpdate) {
          await _service.updateDraft(
            orderId: orderId,
            quantity: quantity,
            productCategory: productCategory!,
            productType: productType!,
            productSpecifications: buildSpecifications(),
            requiredDeliveryDate: requiredDeliveryDate!,
            qualityGrade: qualityGrade!,
            priority: result.priority,
            specialInstructions: specialInstructionsCtrl.text,
            customPackaging: customPackaging,
            calculation: result,
          );
        } else {
          await _service.saveDraft(
            orderId: orderId,
            quantity: quantity,
            productCategory: productCategory!,
            productType: productType!,
            productSpecifications: buildSpecifications(),
            requiredDeliveryDate: requiredDeliveryDate!,
            qualityGrade: qualityGrade!,
            priority: result.priority,
            specialInstructions: specialInstructionsCtrl.text,
            customPackaging: customPackaging,
            calculation: result,
          );
        }
        isPersisted = true;
        isDraftMode = true;
      } else if (shouldUpdate) {
        if (isDraftMode || existingOrder?.status.toLowerCase() == 'draft') {
          await _service.createOrderFromDraft(
            orderId: orderId,
            quantity: quantity,
            productCategory: productCategory!,
            productType: productType!,
            productSpecifications: buildSpecifications(),
            requiredDeliveryDate: requiredDeliveryDate!,
            qualityGrade: qualityGrade!,
            priority: result.priority,
            specialInstructions: specialInstructionsCtrl.text,
            customPackaging: customPackaging,
            calculation: result,
          );
        } else {
          await _service.updateDynamicOrder(
            orderId: orderId,
            quantity: quantity,
            productCategory: productCategory!,
            productType: productType!,
            productSpecifications: buildSpecifications(),
            requiredDeliveryDate: requiredDeliveryDate!,
            qualityGrade: qualityGrade!,
            priority: result.priority,
            specialInstructions: specialInstructionsCtrl.text,
            customPackaging: customPackaging,
            calculation: result,
            status: status,
          );
        }
        isPersisted = true;
        isDraftMode = false;
      } else {
        await _service.createDynamicOrder(
          orderId: orderId,
          quantity: quantity,
          productCategory: productCategory!,
          productType: productType!,
          productSpecifications: buildSpecifications(),
          requiredDeliveryDate: requiredDeliveryDate!,
          qualityGrade: qualityGrade!,
          priority: result.priority,
          specialInstructions: specialInstructionsCtrl.text,
          customPackaging: customPackaging,
          calculation: result,
          status: status,
        );
        isPersisted = true;
        isDraftMode = false;
      }
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  String? validateProductStep() {
    if (productCategory == null) return 'Select a product category';
    if (productType == null) return 'Select a product type';
    if (quantity <= 0) return 'Enter a valid quantity';
    if (deliveryDateExpired) {
      return deliveryDateWarning ?? expiredDeliveryDateMessage;
    }
    if (draftExpired) {
      return draftExpiryWarning;
    }
    if (requiredDeliveryDate == null) return 'Select a delivery date';
    if (_isBeforeToday(requiredDeliveryDate!)) {
      return 'Select a valid delivery date';
    }
    if (qualityGrade == null) return 'Select a quality grade';

    final specError = _validateSpecifications();
    if (specError != null) return specError;

    return null;
  }

  /// Validation for order specifications and routing to category service.
  String? validateAll() {
    return validateProductStep();
  }

  bool get canCalculate => validateAll() == null;

  bool get hasValidDeliveryDate =>
      requiredDeliveryDate != null &&
      !deliveryDateExpired &&
      !_isBeforeToday(requiredDeliveryDate!);

  Map<String, dynamic> buildSpecifications() {
    switch (productCategory) {
      case 'Bedsheet':
        return {
          'bed_size': bedSize,
          'fabric_type': bedsheetFabricType,
          'printing_required': printingRequired,
          'custom_packaging': customPackaging,
          'color_pattern': colorPatternCtrl.text.trim(),
        };
      case 'Abaya':
        return {
          'size_range': sizeRange,
          'fabric_type': abayaFabricType,
          'embellishment': embellishment,
          'style_type': styleType,
          'custom_packaging': customPackaging,
        };
      case 'Curtain':
        return {
          'length': double.tryParse(lengthCtrl.text.trim()) ?? 0,
          'width': double.tryParse(widthCtrl.text.trim()) ?? 0,
          'fabric_type': curtainFabricType,
          'header_style': headerStyle,
          'custom_packaging': customPackaging,
        };
      default:
        return {};
    }
  }

  int get quantity => int.tryParse(quantityCtrl.text.trim()) ?? 0;

  String? _validateSpecifications() {
    switch (productCategory) {
      case 'Bedsheet':
        if (bedSize == null) return 'Select bed size';
        if (bedsheetFabricType == null) return 'Select bedsheet fabric';
        if (colorPatternCtrl.text.trim().isEmpty) {
          return 'Enter color or pattern';
        }
        break;
      case 'Abaya':
        if (sizeRange == null) return 'Select size range';
        if (abayaFabricType == null) return 'Select abaya fabric';
        if (styleType == null) return 'Select style type';
        break;
      case 'Curtain':
        final length = double.tryParse(lengthCtrl.text.trim()) ?? 0;
        final width = double.tryParse(widthCtrl.text.trim()) ?? 0;

        // Validate dimensions
        if (lengthCtrl.text.trim().isEmpty) {
          return 'Please enter curtain length in meters (m)';
        }
        if (length <= 0) {
          return 'Curtain length must be greater than 0 m';
        }
        if (length > 10) {
          return 'Maximum curtain length is 10 m';
        }

        if (widthCtrl.text.trim().isEmpty) {
          return 'Please enter curtain width in meters (m)';
        }
        if (width <= 0) {
          return 'Curtain width must be greater than 0 m';
        }
        if (width > 5) {
          return 'Maximum curtain width is 5 m';
        }

        // Validate fabric and header
        if (curtainFabricType == null) return 'Select curtain fabric type';
        if (headerStyle == null) return 'Select header style';
        break;
    }
    return null;
  }

  void _resetSpecifications() {
    bedSize = null;
    bedsheetFabricType = null;
    printingRequired = false;
    colorPatternCtrl.clear();
    sizeRange = null;
    abayaFabricType = null;
    embellishment = false;
    styleType = null;
    lengthCtrl.clear();
    widthCtrl.clear();
    curtainFabricType = null;
    headerStyle = null;
  }

  void _clearCalculation() {
    if (calculation == null) return;
    calculation = null;
    priority = 'Normal';
    notifyListeners();
  }

  bool _isBeforeToday(DateTime value) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedValue = DateTime(value.year, value.month, value.day);
    return normalizedValue.isBefore(normalizedToday);
  }

  Future<String> _ensureOrderIdForSave() async {
    if (orderId != null && orderId!.trim().isNotEmpty) return orderId!;
    final generated = await _service.generateNextOrderId(
      productCategory: productCategory!,
    );
    orderId = generated;
    return generated;
  }

  @override
  void dispose() {
    for (final ctrl in [
      quantityCtrl,
      colorPatternCtrl,
      lengthCtrl,
      widthCtrl,
    ]) {
      ctrl.removeListener(_clearCalculation);
    }
    quantityCtrl.dispose();
    colorPatternCtrl.dispose();
    lengthCtrl.dispose();
    widthCtrl.dispose();
    specialInstructionsCtrl.dispose();
    super.dispose();
  }
}
