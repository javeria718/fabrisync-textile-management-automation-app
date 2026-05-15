import 'package:fabri_sync/Model/employee_head_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerService {
  final SupabaseClient supabase;
  ManagerService(this.supabase);

  Future<Map<String, dynamic>> loadProfile(String userId) async {
    final res = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return Map<String, dynamic>.from(res);
  }

  Future<List<Map<String, dynamic>>> fetchDeptOrdersAllStatuses(
    String dept,
  ) async {
    final data = await supabase
        .from('v_department_orders_full')
        .select()
        .eq('department', _normalizeDepartment(dept))
        .neq('order_status', 'draft')
        .order('date_in', ascending: false)
        .order('time_in', ascending: false);

    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchActiveInProgress(String dept) async {
    final data = await supabase
        .from('v_department_orders_full')
        .select()
        .eq('department', _normalizeDepartment(dept))
        .eq('status', 'inprogress')
        .neq('order_status', 'draft')
        .order('date_in', ascending: true)
        .order('time_in', ascending: true);

    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, int>> fetchQuantitiesByOrderIds(
    List<String> orderIds,
  ) async {
    if (orderIds.isEmpty) return {};

    final qData = await supabase
        .from('ordersmain')
        .select('order_id, quantity')
        .inFilter('order_id', orderIds);

    final Map<String, int> qtyMap = {};
    for (final row in (qData as List)) {
      final oid = (row['order_id'] ?? '').toString();
      final qty = (row['quantity'] as num?)?.toInt() ?? 0;
      if (oid.isNotEmpty) qtyMap[oid] = qty;
    }
    return qtyMap;
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
    final rows = await supabase
        .from('item_department_progress')
        .select()
        .eq('order_id', orderId)
        .eq('department', _normalizeDepartment(department))
        .order('created_at', ascending: true);

    final progressRows = (rows as List)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    await _addProfileNames(
      progressRows,
      idKey: 'completed_by',
      nameKey: 'completed_by_name',
    );
    return progressRows;
  }

  Future<List<Map<String, dynamic>>> fetchProgressLogs(
    String orderId,
    String department,
  ) async {
    final rows = await supabase
        .from('item_progress_logs')
        .select()
        .eq('order_id', orderId)
        .eq('department', _normalizeDepartment(department))
        .order('created_at', ascending: false);

    final logs = (rows as List)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    await _addProfileNames(
      logs,
      idKey: 'actor_profile_id',
      nameKey: 'actor_name',
    );
    return logs;
  }

  Future<Map<String, dynamic>?> fetchLatestProgressLog(
    String orderId,
    String department,
  ) async {
    final logs = await fetchProgressLogs(orderId, department);
    if (logs.isEmpty) return null;
    return logs.first;
  }

  Future<DepartmentProgressSummary> calculateProgress(
    String orderId,
    String department,
  ) async {
    final dept = _normalizeDepartment(department);
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

  Future<void> _addProfileNames(
    List<Map<String, dynamic>> rows, {
    required String idKey,
    required String nameKey,
  }) async {
    final ids = rows
        .map((row) => (row[idKey] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) return;

    final profileRows = await supabase
        .from('profiles')
        .select('id, full_name, email')
        .inFilter('id', ids);
    final profiles = <String, String>{};
    for (final row in (profileRows as List)) {
      final map = Map<String, dynamic>.from(row);
      final id = (map['id'] ?? '').toString();
      final name = (map['full_name'] ?? map['email'] ?? '').toString();
      if (id.isNotEmpty && name.isNotEmpty) profiles[id] = name;
    }

    for (final row in rows) {
      final id = (row[idKey] ?? '').toString();
      if (profiles.containsKey(id)) {
        row[nameKey] = profiles[id];
      }
    }
  }
}

String _normalizeDepartment(String department) {
  final text = department.trim().toUpperCase();
  if (text == 'QUALITY CONTROL') return 'QUALITY_CONTROL';
  if (text == 'PACKING') return 'PACKAGING';
  return text.replaceAll(' ', '_');
}
