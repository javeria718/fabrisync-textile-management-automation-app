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

  Map<String, double> estimatedDeptHours = {};
  bool loadingDeptHours = true;

  late RealtimeChannel deptOrdersChannel;
  late RealtimeChannel ordersMainChannel;
  RealtimeChannel? timeConfigChannel;

  Future<void> init() async {
    // Keep same order/behavior as your original initState
    fetchOrders();
    fetchEstimatedDeptHours();
    setupRealtime();
    setupTimeConfigRealtime();
    loadAdminProfile();
  }

  void toggleProfileCard() {
    showProfileCard = !showProfileCard;
    notifyListeners();
  }

  Future<void> loadAdminProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final res = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      profile = res;
      notifyListeners();
    } catch (e) {
      debugPrint("Admin profile load error: $e");
    }
  }

  Future<void> fetchOrders() async {
    loading = true;
    notifyListeners();

    final data = await supabase
        .from('ordersmain')
        .select()
        .order('created_at', ascending: false);

    allOrders = (data as List).map((e) => OrderModel.fromMap(e)).toList();
    loading = false;
    notifyListeners();
  }

  Future<void> fetchEstimatedDeptHours() async {
    loadingDeptHours = true;
    notifyListeners();

    try {
      final data = await supabase
          .from('master_time_config')
          .select('department, estimated_hours')
          .order('department');

      final Map<String, double> map = {};
      for (final row in (data as List)) {
        final dept = (row['department'] ?? '').toString();
        final hrs = (row['estimated_hours'] as num?)?.toDouble() ?? 0.0;
        if (dept.isNotEmpty) map[dept] = hrs;
      }

      estimatedDeptHours = map;
      loadingDeptHours = false;
      notifyListeners();
    } catch (e) {
      debugPrint("fetchEstimatedDeptHours error: $e");
      loadingDeptHours = false;
      notifyListeners();
    }
  }

  void setupRealtime() {
    deptOrdersChannel = supabase
        .channel('admin-dept-orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'department_orders',
          callback: (_) => fetchOrders(),
        )
        .subscribe();

    ordersMainChannel = supabase
        .channel('admin-ordersmain')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ordersmain',
          callback: (_) => fetchOrders(),
        )
        .subscribe();
  }

  void setupTimeConfigRealtime() {
    timeConfigChannel = supabase
        .channel('admin-time-config')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'master_time_config',
          callback: (_) => fetchEstimatedDeptHours(),
        )
        .subscribe();
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  @override
  void dispose() {
    supabase.removeChannel(deptOrdersChannel);
    supabase.removeChannel(ordersMainChannel);
    if (timeConfigChannel != null) supabase.removeChannel(timeConfigChannel!);
    super.dispose();
  }
}
