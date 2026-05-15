import 'package:fabri_sync/Model/employee_head_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeHeadService {
  EmployeeHeadService({SupabaseClient? client})
    : supabase = client ?? Supabase.instance.client;

  final SupabaseClient supabase;

  static const List<String> canonicalDepartments = [
    'CUTTING',
    'STITCHING',
    'THREADING',
    'QUALITY_CONTROL',
    'PACKAGING',
    'INSPECTION',
  ];

  static const Map<String, int> _departmentSequence = {
    'CUTTING': 1,
    'STITCHING': 2,
    'THREADING': 3,
    'QUALITY_CONTROL': 4,
    'PACKAGING': 5,
    'INSPECTION': 6,
  };

  Future<EmployeeHeadProfile> getCurrentEmployeeHeadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw StateError('No active login session found.');
    }

    final profile = await supabase
        .from('profiles')
        .select('id, full_name, email, role, department')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      throw StateError('Employee Head profile was not found.');
    }

    final profileMap = Map<String, dynamic>.from(profile);
    profileMap['id'] ??= user.id;

    final role = (profileMap['role'] ?? '').toString().toLowerCase().trim();
    if (role != 'employee_head') {
      throw StateError('Current user is not an Employee Head.');
    }

    final department = normalizeDepartment(profileMap['department']);
    if (department.isEmpty) {
      throw StateError('Employee Head profile is missing a department.');
    }
    _requireCanonicalDepartment(department);

    profileMap['department'] = department;
    return EmployeeHeadProfile.fromMap(profileMap);
  }

  Future<List<EmployeeHeadOrder>> fetchActiveDepartmentOrders(
    String department,
  ) async {
    final dept = normalizeDepartment(department);
    _requireCanonicalDepartment(dept);

    final rows = await supabase
        .from('v_department_orders_full')
        .select()
        .eq('department', dept)
        .inFilter('status', ['inprogress', 'active'])
        .neq('order_status', 'draft')
        .order('date_in', ascending: true)
        .order('time_in', ascending: true);

    return (rows as List)
        .map((row) => EmployeeHeadOrder.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<OrderItemTracking>> fetchOrderItems(String orderId) async {
    final rows = await supabase
        .from('order_items')
        .select()
        .eq('order_id', orderId)
        .order('item_no', ascending: true);

    return (rows as List)
        .map(
          (row) =>
              OrderItemTracking.fromItemMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchDepartmentProgressForOrder(
    String orderId,
    String department,
  ) async {
    final dept = normalizeDepartment(department);
    _requireCanonicalDepartment(dept);

    final rows = await supabase
        .from('item_department_progress')
        .select()
        .eq('order_id', orderId)
        .eq('department', dept)
        .order('sequence_number', ascending: true)
        .order('created_at', ascending: true);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<DepartmentProgressSummary> markItemComplete({
    required String orderId,
    required String itemId,
    required String department,
    String? departmentOrderId,
  }) async {
    final profile = await getCurrentEmployeeHeadProfile();
    final dept = normalizeDepartment(department);
    _requireCanonicalDepartment(dept);

    if (profile.department != dept) {
      throw StateError('Employee Head can only update their own department.');
    }

    await _requireOrderItem(orderId: orderId, itemId: itemId);

    final cleanDepartmentOrderId = _nullableText(departmentOrderId);
    final now = DateTime.now().toUtc().toIso8601String();
    final existing = await _fetchProgress(itemId: itemId, department: dept);

    String? progressId;
    String? fromStatus;

    if (existing != null) {
      progressId = (existing['id'] ?? '').toString();
      fromStatus = (existing['status'] ?? 'pending').toString();

      if (fromStatus.toLowerCase() == 'completed') {
        return calculateProgress(orderId, dept);
      }

      await _updateProgressToCompleted(
        progressId: progressId,
        completedBy: profile.id,
        completedAt: now,
        departmentOrderId: cleanDepartmentOrderId,
      );
    } else {
      fromStatus = 'pending';
      try {
        final inserted = await _insertCompletedProgress(
          orderId: orderId,
          itemId: itemId,
          department: dept,
          departmentOrderId: cleanDepartmentOrderId,
          completedBy: profile.id,
          completedAt: now,
        );
        progressId = (inserted['id'] ?? '').toString();
      } on PostgrestException catch (error) {
        if (!_isDuplicateProgressError(error)) rethrow;

        final duplicate = await _fetchProgress(
          itemId: itemId,
          department: dept,
        );
        if (duplicate == null) rethrow;

        progressId = (duplicate['id'] ?? '').toString();
        fromStatus = (duplicate['status'] ?? 'pending').toString();
        if (fromStatus.toLowerCase() == 'completed') {
          return calculateProgress(orderId, dept);
        }

        await _updateProgressToCompleted(
          progressId: progressId,
          completedBy: profile.id,
          completedAt: now,
          departmentOrderId: cleanDepartmentOrderId,
        );
      }
    }

    await supabase.from('item_progress_logs').insert({
      'item_id': itemId,
      'progress_id': progressId,
      'order_id': orderId,
      'department': dept,
      'event_type': 'item_completed',
      'from_status': fromStatus,
      'to_status': 'completed',
      'actor_profile_id': profile.id,
    });

    return calculateProgress(orderId, dept);
  }

  Future<DepartmentProgressSummary> calculateProgress(
    String orderId,
    String department,
  ) async {
    final dept = normalizeDepartment(department);
    _requireCanonicalDepartment(dept);

    final items = await fetchOrderItems(orderId);
    final progressRows = await fetchDepartmentProgressForOrder(orderId, dept);
    final completedItemIds = progressRows
        .where((row) => (row['status'] ?? '').toString() == 'completed')
        .map((row) => (row['item_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();

    return DepartmentProgressSummary(
      orderId: orderId,
      department: dept,
      totalQuantity: items.length,
      completedQuantity: completedItemIds.length,
    );
  }

  Future<DepartmentCompletionResult> completeDepartment({
    required String orderId,
    required String department,
    String? departmentOrderId,
    String? delayReason,
    String? delayRemarks,
  }) async {
    final profile = await getCurrentEmployeeHeadProfile();
    final dept = normalizeDepartment(department);
    _requireCanonicalDepartment(dept);

    if (profile.department != dept) {
      throw StateError('Employee Head can only complete their own department.');
    }

    final summary = await calculateProgress(orderId, dept);
    if (!_isCompleteSummary(summary)) {
      throw StateError(
        'All items must be completed before completing this department.',
      );
    }

    final departmentOrder = await _fetchDepartmentOrder(
      orderId: orderId,
      department: dept,
      departmentOrderId: departmentOrderId,
    );
    if (departmentOrder == null) {
      throw StateError('Active department order was not found.');
    }

    final currentStatus = (departmentOrder['status'] ?? '').toString();
    final wasLate = isDepartmentOrderLateMap(departmentOrder);
    final cleanDelayReason = _nullableText(delayReason);
    final cleanDelayRemarks = _nullableText(delayRemarks);

    if (wasLate && (cleanDelayReason == null || cleanDelayRemarks == null)) {
      throw StateError(
        'Delay reason and remarks are required for late department completion.',
      );
    }

    if (currentStatus.toLowerCase() == 'completed') {
      return DepartmentCompletionResult(
        completed: true,
        alreadyCompleted: true,
        wasLate: wasLate,
        message: 'Department was already completed.',
      );
    }

    final now = DateTime.now();
    final payload = <String, dynamic>{
      'status': 'completed',
      'date_out': _dateOnly(now),
      'time_out': _timeOnly(now),
    };
    if (wasLate && cleanDelayReason != null) {
      payload['delay_reason'] = cleanDelayReason;
    }

    final updated = await _completeDepartmentOrder(
      departmentOrderId: (departmentOrder['id'] ?? '').toString(),
      payload: payload,
    );

    if (updated.isEmpty) {
      return DepartmentCompletionResult(
        completed: true,
        alreadyCompleted: true,
        wasLate: wasLate,
        message: 'Department was already completed.',
      );
    }

    await supabase.from('item_progress_logs').insert({
      'order_id': orderId,
      'department': dept,
      'event_type': 'department_completed',
      'from_status': _loggableStatus(currentStatus),
      'to_status': 'completed',
      'actor_profile_id': profile.id,
      'remarks': cleanDelayRemarks,
      'delay_reason': cleanDelayReason,
    });

    return DepartmentCompletionResult(
      completed: true,
      alreadyCompleted: false,
      wasLate: wasLate,
      message: 'Department completed and sent forward.',
    );
  }

  bool isEmployeeHeadOrderLate(EmployeeHeadOrder order) {
    return _estimatedEndFromParts(
      dateIn: order.dateIn,
      timeIn: order.timeIn,
      expectedHours: order.expectedHours,
      plannedEndDate: order.plannedEndDate,
    )?.isBefore(DateTime.now()) ??
        false;
  }

  bool isDepartmentOrderLateMap(Map<String, dynamic> row) {
    return _estimatedEndFromParts(
      dateIn: _parseDate(row['date_in']),
      timeIn: _nullableText(row['time_in']?.toString()),
      expectedHours: (row['expected_hours'] as num?)?.toDouble(),
      plannedEndDate: _parseDate(row['planned_end_date']),
    )?.isBefore(DateTime.now()) ??
        false;
  }

  String normalizeDepartment(dynamic value) {
    final text = (value ?? '').toString().trim().toUpperCase();
    if (text == 'QUALITY CONTROL') return 'QUALITY_CONTROL';
    if (text == 'PACKING') return 'PACKAGING';
    return text.replaceAll(' ', '_');
  }

  Future<Map<String, dynamic>?> _fetchDepartmentOrder({
    required String orderId,
    required String department,
    String? departmentOrderId,
  }) async {
    final cleanId = _nullableText(departmentOrderId);
    if (cleanId != null) {
      final row = await supabase
          .from('department_orders')
          .select()
          .eq('id', cleanId)
          .eq('order_id', orderId)
          .eq('department', department)
          .maybeSingle();
      if (row != null) return Map<String, dynamic>.from(row);
    }

    final activeRows = await supabase
        .from('department_orders')
        .select()
        .eq('order_id', orderId)
        .eq('department', department)
        .inFilter('status', ['inprogress', 'active'])
        .order('date_in', ascending: false)
        .order('time_in', ascending: false)
        .limit(1);

    final activeList = List<Map<String, dynamic>>.from(activeRows);
    if (activeList.isNotEmpty) return activeList.first;

    final rows = await supabase
        .from('department_orders')
        .select()
        .eq('order_id', orderId)
        .eq('department', department)
        .order('date_in', ascending: false)
        .order('time_in', ascending: false)
        .limit(1);

    final list = List<Map<String, dynamic>>.from(rows);
    if (list.isEmpty) return null;
    return list.first;
  }

  Future<List<Map<String, dynamic>>> _completeDepartmentOrder({
    required String departmentOrderId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final rows = await supabase
          .from('department_orders')
          .update(payload)
          .eq('id', departmentOrderId)
          .neq('status', 'completed')
          .select('id');
      return List<Map<String, dynamic>>.from(rows);
    } on PostgrestException catch (error) {
      if (!payload.containsKey('delay_reason')) rethrow;
      if (!_isMissingColumnError(error, 'delay_reason')) rethrow;

      final retryPayload = Map<String, dynamic>.from(payload)
        ..remove('delay_reason');
      final rows = await supabase
          .from('department_orders')
          .update(retryPayload)
          .eq('id', departmentOrderId)
          .neq('status', 'completed')
          .select('id');
      return List<Map<String, dynamic>>.from(rows);
    }
  }

  Future<void> _requireOrderItem({
    required String orderId,
    required String itemId,
  }) async {
    final item = await supabase
        .from('order_items')
        .select('id')
        .eq('id', itemId)
        .eq('order_id', orderId)
        .maybeSingle();

    if (item == null) {
      throw StateError('Order item was not found for this order.');
    }
  }

  Future<Map<String, dynamic>?> _fetchProgress({
    required String itemId,
    required String department,
  }) async {
    final row = await supabase
        .from('item_department_progress')
        .select()
        .eq('item_id', itemId)
        .eq('department', department)
        .maybeSingle();

    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>> _insertCompletedProgress({
    required String orderId,
    required String itemId,
    required String department,
    required String? departmentOrderId,
    required String completedBy,
    required String completedAt,
  }) async {
    final payload = <String, dynamic>{
      'item_id': itemId,
      'order_id': orderId,
      'department': department,
      'sequence_number': _sequenceForDepartment(department),
      'department_order_id': departmentOrderId,
      'status': 'completed',
      'started_at': completedAt,
      'completed_at': completedAt,
      'completed_by': completedBy,
    };

    final row = await supabase
        .from('item_department_progress')
        .insert(payload)
        .select()
        .single();

    return Map<String, dynamic>.from(row);
  }

  Future<void> _updateProgressToCompleted({
    required String progressId,
    required String completedBy,
    required String completedAt,
    required String? departmentOrderId,
  }) async {
    final payload = <String, dynamic>{
      'status': 'completed',
      'completed_at': completedAt,
      'completed_by': completedBy,
    };
    if (departmentOrderId != null) {
      payload['department_order_id'] = departmentOrderId;
    }

    await supabase
        .from('item_department_progress')
        .update(payload)
        .eq('id', progressId);
  }

  int _sequenceForDepartment(String department) {
    final sequence = _departmentSequence[department];
    if (sequence == null) {
      throw ArgumentError.value(department, 'department', 'Unknown department');
    }
    return sequence;
  }

  void _requireCanonicalDepartment(String department) {
    if (!canonicalDepartments.contains(department)) {
      throw ArgumentError.value(
        department,
        'department',
        'Department must be one of $canonicalDepartments',
      );
    }
  }

  bool _isDuplicateProgressError(PostgrestException error) {
    return error.code == '23505' ||
        error.message.toLowerCase().contains('duplicate');
  }

  bool _isMissingColumnError(PostgrestException error, String column) {
    final message = error.message.toLowerCase();
    return error.code == '42703' ||
        (message.contains(column.toLowerCase()) &&
            message.contains('column'));
  }

  bool _isCompleteSummary(DepartmentProgressSummary summary) {
    return summary.totalQuantity > 0 &&
        summary.completedQuantity == summary.totalQuantity &&
        summary.progressPercentage == 100;
  }

  DateTime? _estimatedEndFromParts({
    required DateTime? dateIn,
    required String? timeIn,
    required double? expectedHours,
    required DateTime? plannedEndDate,
  }) {
    if (dateIn != null && timeIn != null && expectedHours != null) {
      final start = _combineDateAndTime(dateIn, timeIn);
      if (start != null) {
        return start.add(
          Duration(seconds: (expectedHours * 3600).round()),
        );
      }
    }

    if (plannedEndDate != null) {
      return DateTime(
        plannedEndDate.year,
        plannedEndDate.month,
        plannedEndDate.day,
        23,
        59,
        59,
      );
    }

    return null;
  }

  DateTime? _combineDateAndTime(DateTime date, String time) {
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    final secondText = parts.length > 2 ? parts[2].split('.').first : '0';
    final second = int.tryParse(secondText) ?? 0;
    if (hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute, second);
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _dateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _timeOnly(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  String? _loggableStatus(String status) {
    final normalized = status.toLowerCase().trim();
    if (normalized == 'pending' ||
        normalized == 'inprogress' ||
        normalized == 'completed') {
      return normalized;
    }
    return null;
  }

  String? _nullableText(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}
