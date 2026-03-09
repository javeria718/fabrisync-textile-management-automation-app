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
        .from('department_orders')
        .select()
        .eq('department', dept)
        .order('date_in', ascending: false)
        .order('time_in', ascending: false);

    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchActiveInProgress(String dept) async {
    final data = await supabase
        .from('department_orders')
        .select()
        .eq('department', dept)
        .eq('status', 'inprogress')
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

  Future<void> markCompleted(String rowId) async {
    final now = DateTime.now();
    await supabase
        .from('department_orders')
        .update({
          'status': 'completed',
          'date_out':
              "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
          'time_out':
              "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}",
        })
        .eq('id', rowId); // ✅ rowId is String UUID
  }
}
