import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fabri_sync/Model/orderModel.dart';

class AdminDashboardController extends ChangeNotifier {
  AdminDashboardController({SupabaseClient? client})
    : supabase = client ?? Supabase.instance.client;

  final SupabaseClient supabase;

  bool showProfileCard = false;
  Map<String, dynamic>? profile;

  List<OrderModel> allOrders = [];
  bool loading = true;

  Map<String, Map<String, double>> storedDeptHoursByOrder = {};

  RealtimeChannel? deptOrdersChannel;
  RealtimeChannel? ordersMainChannel;

  bool _disposed = false;
  bool _realtimeSetup = false;
  int _fetchGeneration = 0;

  Future<void> init() async {
    // Keep same order/behavior as your original initState
    fetchOrders();
    setupRealtime();
    loadAdminProfile();
  }

  void toggleProfileCard() {
    if (_disposed) return;
    showProfileCard = !showProfileCard;
    _notifyListeners();
  }

  Future<void> loadAdminProfile() async {
    if (_disposed) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final res = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      if (_disposed) return;
      profile = res;
      _notifyListeners();
    } catch (e) {
      if (_disposed) return;
      debugPrint("Admin profile load error: $e");
    }
  }

  Future<void> fetchOrders() async {
    if (_disposed) return;

    final fetchGeneration = ++_fetchGeneration;
    loading = true;
    _notifyListeners();

    try {
      final data = await supabase
          .from('ordersmain')
          .select()
          .neq('status', 'draft')
          .order('created_at', ascending: false);

      if (_disposed || fetchGeneration != _fetchGeneration) return;
      allOrders = (data as List).map((e) => OrderModel.fromMap(e)).toList();
      await fetchStoredDepartmentHours(notify: false);

      if (_disposed || fetchGeneration != _fetchGeneration) return;
      loading = false;
      _notifyListeners();
    } catch (e) {
      if (_disposed || fetchGeneration != _fetchGeneration) return;
      loading = false;
      debugPrint("fetchOrders error: $e");
      _notifyListeners();
    }
  }

  Future<void> fetchStoredDepartmentHours({bool notify = true}) async {
    if (_disposed) return;

    try {
      final data = await supabase
          .from('v_department_orders_full')
          .select('order_id, department, expected_hours, order_status')
          .neq('order_status', 'draft');

      if (_disposed) return;
      final Map<String, Map<String, double>> grouped = {};
      for (final row in (data as List)) {
        final orderId = (row['order_id'] ?? '').toString();
        final department = (row['department'] ?? '').toString();
        final hours = (row['expected_hours'] as num?)?.toDouble();

        if (orderId.isEmpty || department.isEmpty || hours == null) continue;
        grouped.putIfAbsent(orderId, () => {})[department] = hours;
      }

      storedDeptHoursByOrder = grouped;
      if (notify) _notifyListeners();
    } catch (e) {
      if (_disposed) return;
      debugPrint("fetchStoredDepartmentHours error: $e");
    }
  }

  void setupRealtime() {
    if (_disposed || _realtimeSetup) return;

    _realtimeSetup = true;
    deptOrdersChannel = supabase
        .channel('admin-dept-orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'department_orders',
          callback: (_) {
            if (!_disposed) fetchOrders();
          },
        )
        .subscribe();

    ordersMainChannel = supabase
        .channel('admin-ordersmain')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ordersmain',
          callback: (_) {
            if (!_disposed) fetchOrders();
          },
        )
        .subscribe();
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  @override
  void dispose() {
    _disposed = true;
    _fetchGeneration++;

    final deptChannel = deptOrdersChannel;
    if (deptChannel != null) {
      supabase.removeChannel(deptChannel);
    }

    final mainChannel = ordersMainChannel;
    if (mainChannel != null) {
      supabase.removeChannel(mainChannel);
    }

    super.dispose();
  }

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }
}
