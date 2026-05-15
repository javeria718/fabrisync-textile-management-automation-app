// import 'dart:async';

// import 'package:flutter/foundation.dart';
// import 'package:intl/intl.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../services/manager_service.dart';

// class ManagerController extends ChangeNotifier {
//   final SupabaseClient supabase;
//   late final ManagerService _service;

//   ManagerController({SupabaseClient? supabaseClient})
//     : supabase = supabaseClient ?? Supabase.instance.client {
//     _service = ManagerService(supabase);
//   }

//   // UI toggles
//   bool showProfileCard = false;
//   bool showAlertsPanel = false;

//   // data
//   Map<String, dynamic>? profile;
//   List<Map<String, dynamic>> activeOrders = [];
//   List<Map<String, dynamic>> deptOrders = [];

//   // realtime/timers
//   RealtimeChannel? ordersChannel;
//   Timer? _ticker;
//   Timer? _debounceRefresh;

//   // theme constants (same as your file)
//   static const List<int> kAdminAppBarGradient = [0xFF0F172A, 0xFF111827];
//   static const List<int> kAdminAccentGradient = [0xFF0EA5E9, 0xFF2563EB];

//   // init
//   Future<void> init() async {
//     await loadManager();

//     // realtime countdown refresh every second (UI only)
//     _ticker?.cancel();
//     _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
//       notifyListeners();
//     });
//   }

//   Future<void> loadManager() async {
//     final user = supabase.auth.currentUser;
//     if (user == null) return;

//     final res = await _service.loadProfile(user.id);
//     profile = res;
//     notifyListeners();

//     final dept = (res['department'] ?? '').toString().toUpperCase();
//     if (dept.isEmpty) return;

//     await refreshAll(dept);
//     subscribeOrders(dept);
//   }

//   Future<void> refreshAll(String dept) async {
//     await Future.wait([fetchActiveOrders(dept), fetchDeptOrders(dept)]);
//   }

//   Future<void> fetchActiveOrders(String department) async {
//     final dept = department.toUpperCase();

//     final list = await _service.fetchActiveInProgress(dept);

//     final orderIds = list
//         .map((e) => (e['order_id'] ?? '').toString())
//         .where((id) => id.isNotEmpty)
//         .toList();

//     final qtyMap = await _service.fetchQuantitiesByOrderIds(orderIds);

//     for (final o in list) {
//       final oid = (o['order_id'] ?? '').toString();
//       o['quantity'] = qtyMap[oid] ?? 0;
//     }

//     activeOrders = list;
//     notifyListeners();
//   }

//   Future<void> fetchDeptOrders(String department) async {
//     final dept = department.toUpperCase();
//     deptOrders = await _service.fetchDeptOrdersAllStatuses(dept);
//     notifyListeners();
//   }

//   void subscribeOrders(String department) {
//     final dept = department.toUpperCase();

//     if (ordersChannel != null) {
//       supabase.removeChannel(ordersChannel!);
//     }

//     ordersChannel = supabase
//         .channel('mgr-$dept')
//         .onPostgresChanges(
//           event: PostgresChangeEvent.all,
//           schema: 'public',
//           table: 'department_orders',
//           filter: PostgresChangeFilter(
//             type: PostgresChangeFilterType.eq,
//             column: 'department',
//             value: dept,
//           ),
//           callback: (_) {
//             _debounceRefresh?.cancel();
//             _debounceRefresh = Timer(const Duration(milliseconds: 250), () {
//               refreshAll(dept);
//             });
//           },
//         )
//         .subscribe();
//   }

//   // computed stats
//   int get total => deptOrders.length;
//   int get completed =>
//       deptOrders.where((o) => (o['status'] ?? '') == 'completed').length;
//   int get inProgress =>
//       deptOrders.where((o) => (o['status'] ?? '') == 'inprogress').length;
//   int get lateCount => activeOrders.where(isExceeded).length;

//   List<Map<String, dynamic>> get nearDeadline =>
//       activeOrders.where(isAlert).toList();
//   List<Map<String, dynamic>> get exceeded =>
//       activeOrders.where(isExceeded).toList();

//   List<Map<String, dynamic>> get queuePreview => deptOrders.take(4).toList();

//   // toggles
//   void toggleProfileCard() {
//     showProfileCard = !showProfileCard;
//     notifyListeners();
//   }

//   void toggleAlertsPanel() {
//     showAlertsPanel = !showAlertsPanel;
//     notifyListeners();
//   }

//   void closeAlertsPanel() {
//     showAlertsPanel = false;
//     notifyListeners();
//   }

//   // helpers (time/alerts)
//   DateTime startDateTime(Map<String, dynamic> o) {
//     final dateIn = DateTime.parse(o['date_in']);
//     final timeIn = DateFormat.Hms().parse(o['time_in']);
//     return DateTime(
//       dateIn.year,
//       dateIn.month,
//       dateIn.day,
//       timeIn.hour,
//       timeIn.minute,
//       timeIn.second,
//     );
//   }

//   int remainingSeconds(Map<String, dynamic> o) {
//     final expectedHours = (o['expected_hours'] as num).toDouble();
//     final expectedSeconds = (expectedHours * 3600).round();

//     final start = startDateTime(o);
//     final elapsedSeconds = DateTime.now().difference(start).inSeconds;
//     return expectedSeconds - elapsedSeconds;
//   }

//   bool isExceeded(Map<String, dynamic> o) => remainingSeconds(o) <= 0;

//   // ALERT RULE: when 3 hours remain
//   bool isAlert(Map<String, dynamic> o) {
//     final s = remainingSeconds(o);
//     return s > 0 && s <= (3 * 3600);
//   }

//   String formatCountdown(int seconds) {
//     if (seconds <= 0) return "00:00:00";
//     final h = seconds ~/ 3600;
//     final m = (seconds % 3600) ~/ 60;
//     final s = seconds % 60;
//     String two(int v) => v.toString().padLeft(2, '0');
//     return "${two(h)}:${two(m)}:${two(s)}";
//   }

//   String formatTime(dynamic timeValue) {
//     if (timeValue == null) return "-";
//     final t = DateFormat.Hms().parse(timeValue.toString());
//     return DateFormat("hh:mm a").format(DateTime(2000, 1, 1, t.hour, t.minute));
//   }

//   String formatDate(dynamic dateValue) {
//     if (dateValue == null) return "-";
//     final d = DateTime.parse(dateValue.toString());
//     return DateFormat("dd MMM yyyy").format(d);
//   }

//   Future<void> completeOrder(Map<String, dynamic> o) async {
//     final id = (o['id'] ?? '').toString(); // ✅ UUID safe
//     if (id.isEmpty) return;
//     await _service.markCompleted(id);
//   }

// bool _disposed = false;

// @override
// void dispose() {
//   _disposed = true;
//   _ticker?.cancel();
//   _debounceRefresh?.cancel();
//   if (ordersChannel != null) supabase.removeChannel(ordersChannel!);
//   super.dispose();
// }

// }
import 'dart:async';

import 'package:fabri_sync/Model/employee_head_models.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/manager_service.dart';

class ManagerController extends ChangeNotifier {
  final SupabaseClient supabase;
  late final ManagerService _service;

  ManagerController({SupabaseClient? supabaseClient})
    : supabase = supabaseClient ?? Supabase.instance.client {
    _service = ManagerService(supabase);
  }

  // UI toggles
  bool showProfileCard = false;
  bool showAlertsPanel = false;

  // data
  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> activeOrders = [];
  List<Map<String, dynamic>> deptOrders = [];
  Map<String, DepartmentProgressSummary> orderProgress = {};
  Map<String, Map<String, dynamic>> latestLogsByOrderId = {};
  Map<String, dynamic>? selectedOrder;
  List<OrderItemTracking> selectedOrderItems = [];
  List<Map<String, dynamic>> selectedProgressRows = [];
  List<Map<String, dynamic>> selectedLogs = [];
  DepartmentProgressSummary selectedProgressSummary =
      DepartmentProgressSummary.empty;
  bool detailLoading = false;
  String? detailError;

  // realtime/timers
  RealtimeChannel? ordersChannel;
  RealtimeChannel? progressChannel;
  RealtimeChannel? logsChannel;
  Timer? _ticker;
  Timer? _debounceRefresh;

  // ✅ guard for web/unmount timing issues
  bool _disposed = false;

  // theme constants (same as your file)
  static const List<int> kAdminAppBarGradient = [0xFF0F172A, 0xFF111827];
  static const List<int> kAdminAccentGradient = [0xFF0EA5E9, 0xFF2563EB];

  // init
  Future<void> init() async {
    await loadManager();

    // realtime countdown refresh every second (UI only)
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) return; // ✅ prevents notify after dispose
      notifyListeners();
    });
  }

  Future<void> loadManager() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final res = await _service.loadProfile(user.id);
    profile = res;
    if (_disposed) return;
    notifyListeners();

    final dept = (res['department'] ?? '').toString().toUpperCase();
    if (dept.isEmpty) return;

    await refreshAll(dept);
    if (_disposed) return;

    subscribeOrders(dept);
  }

  Future<void> refreshAll(String dept) async {
    await Future.wait([fetchActiveOrders(dept), fetchDeptOrders(dept)]);
    final selected = selectedOrder;
    if (selected != null && !_disposed) {
      await loadOrderDetails(selected, notifyLoading: false);
    }
  }

  Future<void> fetchActiveOrders(String department) async {
    final dept = department.toUpperCase();

    final list = await _service.fetchActiveInProgress(dept);

    final orderIds = list
        .map((e) => (e['order_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList();

    final qtyMap = await _service.fetchQuantitiesByOrderIds(orderIds);

    for (final o in list) {
      final oid = (o['order_id'] ?? '').toString();
      o['quantity'] = qtyMap[oid] ?? 0;
    }

    activeOrders = list
        .where((o) => (o['order_status'] ?? '').toString() != 'draft')
        .toList();

    await _loadProgressForOrders(dept);
    _syncSelectedOrderAfterRefresh();
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> fetchDeptOrders(String department) async {
    final dept = department.toUpperCase();
    final rows = await _service.fetchDeptOrdersAllStatuses(dept);
    deptOrders = rows
        .where((o) => (o['order_status'] ?? '').toString() != 'draft')
        .toList();
    if (_disposed) return;
    notifyListeners();
  }

  void subscribeOrders(String department) {
    final dept = department.toUpperCase();

    if (ordersChannel != null) {
      supabase.removeChannel(ordersChannel!);
      ordersChannel = null;
    }
    if (progressChannel != null) {
      supabase.removeChannel(progressChannel!);
      progressChannel = null;
    }
    if (logsChannel != null) {
      supabase.removeChannel(logsChannel!);
      logsChannel = null;
    }

    ordersChannel = supabase
        .channel('mgr-orders-$dept')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'department_orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'department',
            value: dept,
          ),
          callback: (_) {
            // ✅ debounced refresh guarded for dispose
            _debounceRefresh?.cancel();
            _debounceRefresh = Timer(const Duration(milliseconds: 250), () {
              if (_disposed) return;
              refreshAll(dept);
            });
          },
        )
        .subscribe();

    progressChannel = supabase
        .channel('mgr-progress-$dept')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'item_department_progress',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'department',
            value: dept,
          ),
          callback: (_) {
            _debounceRefresh?.cancel();
            _debounceRefresh = Timer(const Duration(milliseconds: 250), () {
              if (_disposed) return;
              refreshAll(dept);
            });
          },
        )
        .subscribe();

    logsChannel = supabase
        .channel('mgr-logs-$dept')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'item_progress_logs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'department',
            value: dept,
          ),
          callback: (_) {
            _debounceRefresh?.cancel();
            _debounceRefresh = Timer(const Duration(milliseconds: 250), () {
              if (_disposed) return;
              refreshAll(dept);
            });
          },
        )
        .subscribe();
  }

  // computed stats
  int get total => deptOrders.length;

  int get completed =>
      deptOrders.where((o) => (o['status'] ?? '') == 'completed').length;

  int get inProgress =>
      deptOrders.where((o) => (o['status'] ?? '') == 'inprogress').length;

  int get lateCount => activeOrders.where(isExceeded).length;

  List<Map<String, dynamic>> get nearDeadline =>
      activeOrders.where(isAlert).toList();

  List<Map<String, dynamic>> get exceeded =>
      activeOrders.where(isExceeded).toList();

  List<Map<String, dynamic>> get queuePreview => deptOrders.take(4).toList();

  DepartmentProgressSummary summaryForOrder(Map<String, dynamic> order) {
    final orderId = (order['order_id'] ?? '').toString();
    return orderProgress[orderId] ??
        DepartmentProgressSummary(
          orderId: orderId,
          department: (order['department'] ?? '').toString(),
          totalQuantity: 0,
          completedQuantity: 0,
        );
  }

  Map<String, dynamic>? latestLogForOrder(Map<String, dynamic> order) {
    final orderId = (order['order_id'] ?? '').toString();
    return latestLogsByOrderId[orderId];
  }

  Future<void> loadOrderDetails(
    Map<String, dynamic> order, {
    bool notifyLoading = true,
  }) async {
    final orderId = (order['order_id'] ?? '').toString();
    final dept = (profile?['department'] ?? order['department'] ?? '')
        .toString()
        .toUpperCase();
    if (orderId.isEmpty || dept.isEmpty) return;

    selectedOrder = order;
    detailLoading = true;
    detailError = null;
    if (notifyLoading && !_disposed) notifyListeners();

    try {
      final items = await _service.fetchOrderItems(orderId);
      selectedProgressRows = await _service.fetchDepartmentProgressForOrder(
        orderId,
        dept,
      );
      selectedLogs = await _service.fetchProgressLogs(orderId, dept);
      final progressByItemId = <String, Map<String, dynamic>>{};
      for (final row in selectedProgressRows) {
        final itemId = (row['item_id'] ?? '').toString();
        if (itemId.isNotEmpty) progressByItemId[itemId] = row;
      }

      selectedOrderItems = items
          .map((item) => item.copyWithProgress(progressByItemId[item.id]))
          .toList();
      selectedProgressSummary = _summaryFromItems(
        orderId,
        dept,
        selectedOrderItems,
      );
      orderProgress = {
        ...orderProgress,
        orderId: selectedProgressSummary,
      };
      if (selectedLogs.isNotEmpty) {
        latestLogsByOrderId = {
          ...latestLogsByOrderId,
          orderId: selectedLogs.first,
        };
      }
    } catch (e) {
      detailError = e.toString();
    } finally {
      detailLoading = false;
      if (_disposed) return;
      notifyListeners();
    }
  }

  Future<void> _loadProgressForOrders(String dept) async {
    final summaries = <String, DepartmentProgressSummary>{};
    final latestLogs = <String, Map<String, dynamic>>{};
    for (final order in activeOrders) {
      final orderId = (order['order_id'] ?? '').toString();
      if (orderId.isEmpty) continue;
      summaries[orderId] = await _service.calculateProgress(orderId, dept);
      final latest = await _service.fetchLatestProgressLog(orderId, dept);
      if (latest != null) latestLogs[orderId] = latest;
    }
    orderProgress = summaries;
    latestLogsByOrderId = latestLogs;
  }

  void _syncSelectedOrderAfterRefresh() {
    final selected = selectedOrder;
    if (selected == null) return;
    final selectedOrderId = (selected['order_id'] ?? '').toString();
    for (final order in activeOrders) {
      if ((order['order_id'] ?? '').toString() == selectedOrderId) {
        selectedOrder = order;
        return;
      }
    }
    for (final order in deptOrders) {
      if ((order['order_id'] ?? '').toString() == selectedOrderId) {
        selectedOrder = order;
        return;
      }
    }
    selectedOrder = null;
    selectedOrderItems = [];
    selectedProgressRows = [];
    selectedLogs = [];
    selectedProgressSummary = DepartmentProgressSummary.empty;
  }

  DepartmentProgressSummary _summaryFromItems(
    String orderId,
    String department,
    List<OrderItemTracking> items,
  ) {
    return DepartmentProgressSummary(
      orderId: orderId,
      department: department,
      totalQuantity: items.length,
      completedQuantity: items.where((item) => item.isCompleted).length,
    );
  }

  // toggles
  void toggleProfileCard() {
    showProfileCard = !showProfileCard;
    if (_disposed) return;
    notifyListeners();
  }

  void toggleAlertsPanel() {
    showAlertsPanel = !showAlertsPanel;
    if (_disposed) return;
    notifyListeners();
  }

  void closeAlertsPanel() {
    showAlertsPanel = false;
    if (_disposed) return;
    notifyListeners();
  }

  // helpers (time/alerts)
  DateTime startDateTime(Map<String, dynamic> o) {
    final dateIn = DateTime.parse(o['date_in']);
    final timeIn = DateFormat.Hms().parse(o['time_in']);
    return DateTime(
      dateIn.year,
      dateIn.month,
      dateIn.day,
      timeIn.hour,
      timeIn.minute,
      timeIn.second,
    );
  }

  int remainingSeconds(Map<String, dynamic> o) {
    final expectedHours = (o['expected_hours'] as num).toDouble();
    final expectedSeconds = (expectedHours * 3600).round();

    final start = startDateTime(o);
    final elapsedSeconds = DateTime.now().difference(start).inSeconds;
    return expectedSeconds - elapsedSeconds;
  }

  bool isExceeded(Map<String, dynamic> o) => remainingSeconds(o) <= 0;

  // ALERT RULE: when 3 hours remain
  bool isAlert(Map<String, dynamic> o) {
    final s = remainingSeconds(o);
    return s > 0 && s <= (3 * 3600);
  }

  String formatCountdown(int seconds) {
    if (seconds <= 0) return "00:00:00";
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return "${two(h)}:${two(m)}:${two(s)}";
  }

  String formatTime(dynamic timeValue) {
    if (timeValue == null) return "-";
    final t = DateFormat.Hms().parse(timeValue.toString());
    return DateFormat("hh:mm a").format(DateTime(2000, 1, 1, t.hour, t.minute));
  }

  String formatDate(dynamic dateValue) {
    if (dateValue == null) return "-";
    final d = DateTime.parse(dateValue.toString());
    return DateFormat("dd MMM yyyy").format(d);
  }

  Future<void> completeOrder(Map<String, dynamic> o) async {
    final id = (o['id'] ?? '').toString(); // ✅ UUID safe
    if (id.isEmpty) return;
    return;
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _debounceRefresh?.cancel();
    if (ordersChannel != null) {
      supabase.removeChannel(ordersChannel!);
      ordersChannel = null;
    }
    if (progressChannel != null) {
      supabase.removeChannel(progressChannel!);
      progressChannel = null;
    }
    if (logsChannel != null) {
      supabase.removeChannel(logsChannel!);
      logsChannel = null;
    }
    super.dispose();
  }
}
