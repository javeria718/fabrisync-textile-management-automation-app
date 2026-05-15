import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/services/draft/draft_expiry_service.dart';
import 'package:fabri_sync/services/order_calculation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewOrderService {
  NewOrderService({
    SupabaseClient? client,
    DraftExpiryService? draftExpiryService,
  }) : supabase = client ?? Supabase.instance.client,
       _draftExpiryService =
           draftExpiryService ?? DraftExpiryService(client: client);

  final SupabaseClient supabase;
  final DraftExpiryService _draftExpiryService;

  Future<String> generateNextOrderId({
    required String productCategory,
    DateTime? date,
  }) async {
    final prefix = _productPrefix(productCategory);
    final datePart = _compactDate(date ?? DateTime.now());
    final stem = '$prefix-$datePart-';

    final rows = await supabase
        .from('ordersmain')
        .select('order_id')
        .like('order_id', '$stem%');

    var maxSequence = 0;
    for (final row in (rows as List)) {
      final orderId = (row['order_id'] ?? '').toString();
      if (!orderId.startsWith(stem)) continue;
      final sequence = int.tryParse(orderId.substring(stem.length));
      if (sequence != null && sequence > maxSequence) {
        maxSequence = sequence;
      }
    }

    final nextSequence = (maxSequence + 1).toString().padLeft(3, '0');
    return '$stem$nextSequence';
  }

  Future<List<OrderModel>> fetchDraftOrders() async {
    await _refreshExpiredDrafts();

    final rows = await supabase
        .from('ordersmain')
        .select()
        .eq('status', 'draft')
        .order('created_at', ascending: false);

    return (rows as List)
        .map((e) => OrderModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<OrderModel?> loadDraftOrder(String orderId) async {
    final row = await supabase
        .from('ordersmain')
        .select()
        .eq('order_id', orderId)
        .eq('status', 'draft')
        .maybeSingle();

    if (row == null) return null;

    final order = OrderModel.fromMap(Map<String, dynamic>.from(row));
    if (_draftExpiryService.isDraftExpired(order) && !order.isDraftExpired) {
      await _markDraftExpired(order.orderId);
      final updatedRow = Map<String, dynamic>.from(row);
      updatedRow['is_draft_expired'] = true;
      return OrderModel.fromMap(updatedRow);
    }

    return order;
  }

  Future<void> saveDraft({
    required String orderId,
    required int quantity,
    required String productCategory,
    required String productType,
    required Map<String, dynamic> productSpecifications,
    required DateTime requiredDeliveryDate,
    required String qualityGrade,
    required String priority,
    required String specialInstructions,
    required bool customPackaging,
    required OrderCalculationResult calculation,
  }) {
    return createDynamicOrder(
      orderId: orderId,
      quantity: quantity,
      productCategory: productCategory,
      productType: productType,
      productSpecifications: productSpecifications,
      requiredDeliveryDate: requiredDeliveryDate,
      qualityGrade: qualityGrade,
      priority: priority,
      specialInstructions: specialInstructions,
      customPackaging: customPackaging,
      calculation: calculation,
      status: 'draft',
    );
  }

  Future<void> updateDraft({
    required String orderId,
    required int quantity,
    required String productCategory,
    required String productType,
    required Map<String, dynamic> productSpecifications,
    required DateTime requiredDeliveryDate,
    required String qualityGrade,
    required String priority,
    required String specialInstructions,
    required bool customPackaging,
    required OrderCalculationResult calculation,
  }) {
    return updateDynamicOrder(
      orderId: orderId,
      quantity: quantity,
      productCategory: productCategory,
      productType: productType,
      productSpecifications: productSpecifications,
      requiredDeliveryDate: requiredDeliveryDate,
      qualityGrade: qualityGrade,
      priority: priority,
      specialInstructions: specialInstructions,
      customPackaging: customPackaging,
      calculation: calculation,
      status: 'draft',
    );
  }

  Future<void> createOrderFromDraft({
    required String orderId,
    required int quantity,
    required String productCategory,
    required String productType,
    required Map<String, dynamic> productSpecifications,
    required DateTime requiredDeliveryDate,
    required String qualityGrade,
    required String priority,
    required String specialInstructions,
    required bool customPackaging,
    required OrderCalculationResult calculation,
  }) {
    return updateDynamicOrder(
      orderId: orderId,
      quantity: quantity,
      productCategory: productCategory,
      productType: productType,
      productSpecifications: productSpecifications,
      requiredDeliveryDate: requiredDeliveryDate,
      qualityGrade: qualityGrade,
      priority: priority,
      specialInstructions: specialInstructions,
      customPackaging: customPackaging,
      calculation: calculation,
      status: 'pending',
    );
  }

  Future<void> deleteDraft(String orderId) async {
    final draft = await loadDraftOrder(orderId);
    if (draft == null) return;

    await supabase.from('department_orders').delete().eq('order_id', orderId);
    await supabase
        .from('order_cost_breakdown')
        .delete()
        .eq('order_id', orderId);
    await supabase
        .from('ordersmain')
        .delete()
        .eq('order_id', orderId)
        .eq('status', 'draft');
  }

  Future<void> createDynamicOrder({
    required String orderId,
    required int quantity,
    required String productCategory,
    required String productType,
    required Map<String, dynamic> productSpecifications,
    required DateTime requiredDeliveryDate,
    required String qualityGrade,
    required String priority,
    required String specialInstructions,
    required bool customPackaging,
    required OrderCalculationResult calculation,
    required String status,
  }) async {
    await supabase.from('ordersmain').insert({
      'order_id': orderId,
      'quantity': quantity,
      'current_department': 'CUTTING',
      'status': status,
      'estimated_total_time': calculation.estimatedProductionHours,
      'estimated_total_cost': calculation.costBreakdown.estimatedTotalCost,
      'estimated_dept_hours': calculation.departmentHours,
      'product_category': productCategory,
      'product_type': productType,
      'product_specifications': productSpecifications,
      'required_delivery_date': _dateOnly(requiredDeliveryDate),
      'quality_grade': qualityGrade,
      'priority': priority,
      'special_instructions': specialInstructions.trim().isEmpty
          ? null
          : specialInstructions.trim(),
      'custom_packaging': customPackaging,
      ..._buildDraftExpiryFields(status.toLowerCase() == 'draft'),
      'estimated_production_hours': calculation.estimatedProductionHours,
      'estimated_production_days': calculation.estimatedProductionDays,
    });

    await _replaceCostBreakdown(orderId, calculation.costBreakdown);

    if (status.toLowerCase() != 'draft' && calculation.schedule.isNotEmpty) {
      await updateFirstDepartmentSchedule(orderId, calculation.schedule.first);
    }

    if (status.toLowerCase() != 'draft') {
      await _ensureOrderItemsGenerated(
        orderId: orderId,
        quantity: quantity,
        productCategory: productCategory,
      );
    }
  }

  Future<void> updateDynamicOrder({
    required String orderId,
    required int quantity,
    required String productCategory,
    required String productType,
    required Map<String, dynamic> productSpecifications,
    required DateTime requiredDeliveryDate,
    required String qualityGrade,
    required String priority,
    required String specialInstructions,
    required bool customPackaging,
    required OrderCalculationResult calculation,
    required String status,
  }) async {
    await supabase
        .from('ordersmain')
        .update({
          'quantity': quantity,
          'status': status,
          'estimated_total_time': calculation.estimatedProductionHours,
          'estimated_total_cost': calculation.costBreakdown.estimatedTotalCost,
          'estimated_dept_hours': calculation.departmentHours,
          'product_category': productCategory,
          'product_type': productType,
          'product_specifications': productSpecifications,
          'required_delivery_date': _dateOnly(requiredDeliveryDate),
          'quality_grade': qualityGrade,
          'priority': priority,
          'special_instructions': specialInstructions.trim().isEmpty
              ? null
              : specialInstructions.trim(),
          'custom_packaging': customPackaging,
          ..._buildDraftExpiryFields(status.toLowerCase() == 'draft'),
          'estimated_production_hours': calculation.estimatedProductionHours,
          'estimated_production_days': calculation.estimatedProductionDays,
        })
        .eq('order_id', orderId);

    await _replaceCostBreakdown(orderId, calculation.costBreakdown);

    if (status.toLowerCase() != 'draft' && calculation.schedule.isNotEmpty) {
      await updateFirstDepartmentSchedule(orderId, calculation.schedule.first);
    }

    if (status.toLowerCase() != 'draft') {
      await _ensureOrderItemsGenerated(
        orderId: orderId,
        quantity: quantity,
        productCategory: productCategory,
      );
    }
  }

  Future<void> updateFirstDepartmentSchedule(
    String orderId,
    DepartmentScheduleItem schedule,
  ) async {
    final rows = await supabase
        .from('department_orders')
        .select('id')
        .eq('order_id', orderId)
        .eq('department', schedule.departmentDb)
        .limit(1);

    final list = List<Map<String, dynamic>>.from(rows);
    if (list.isEmpty) return;

    await supabase
        .from('department_orders')
        .update(schedule.toDepartmentOrderUpdateMap())
        .eq('id', list.first['id']);
  }

  Future<Map<String, dynamic>?> fetchCostBreakdown(String orderId) async {
    final row = await supabase
        .from('order_cost_breakdown')
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row;
  }

  Future<List<Map<String, dynamic>>> fetchDepartmentSchedule(
    String orderId,
  ) async {
    final rows = await supabase
        .from('department_orders')
        .select()
        .eq('order_id', orderId)
        .order('sequence_number', ascending: true)
        .order('date_in', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _replaceCostBreakdown(
    String orderId,
    OrderCostBreakdown breakdown,
  ) async {
    await supabase
        .from('order_cost_breakdown')
        .delete()
        .eq('order_id', orderId);
    await supabase
        .from('order_cost_breakdown')
        .insert(breakdown.toInsertMap(orderId));
  }

  Future<void> _ensureOrderItemsGenerated({
    required String orderId,
    required int quantity,
    required String productCategory,
  }) async {
    if (quantity <= 0) return;

    final existing = await supabase
        .from('order_items')
        .select('id')
        .eq('order_id', orderId)
        .limit(1);

    if ((existing as List).isNotEmpty) return;

    final productPrefix = _productPrefix(productCategory);
    final rows = List<Map<String, dynamic>>.generate(quantity, (index) {
      final itemNo = index + 1;
      final itemSequence = itemNo.toString().padLeft(3, '0');
      return {
        'order_id': orderId,
        'item_no': itemNo,
        'item_code': '${orderId.trim().toUpperCase()}-$itemSequence',
        'product_prefix': productPrefix,
      };
    });

    try {
      await supabase.from('order_items').insert(rows);
    } on PostgrestException catch (error) {
      if (!_isDuplicateInsert(error)) rethrow;
    }
  }

  Map<String, dynamic> _buildDraftExpiryFields(bool isDraft) {
    if (!isDraft) {
      // For non-draft orders, only set is_draft_expired to false.
      // Don't set draft_created_at and draft_expires_at to null,
      // to avoid schema conflicts if columns don't exist.
      return {'is_draft_expired': false};
    }

    final now = DateTime.now();
    return {
      'draft_created_at': now.toIso8601String(),
      'draft_expires_at': now.add(const Duration(days: 3)).toIso8601String(),
      'is_draft_expired': false,
    };
  }

  Future<void> _refreshExpiredDrafts() async {
    await supabase
        .from('ordersmain')
        .update({'is_draft_expired': true})
        .lt('draft_expires_at', DateTime.now().toIso8601String())
        .eq('status', 'draft')
        .eq('is_draft_expired', false);
  }

  Future<void> _markDraftExpired(String orderId) async {
    await supabase
        .from('ordersmain')
        .update({'is_draft_expired': true})
        .eq('order_id', orderId)
        .eq('status', 'draft');
  }
}

String _dateOnly(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _compactDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year$month$day';
}

String _productPrefix(String productCategory) {
  switch (productCategory.trim().toLowerCase()) {
    case 'abaya':
      return 'ABY';
    case 'bedsheet':
      return 'BED';
    case 'curtain':
      return 'CUR';
    default:
      return 'ITEM';
  }
}

bool _isDuplicateInsert(PostgrestException error) {
  return error.code == '23505' ||
      error.message.toLowerCase().contains('duplicate');
}
