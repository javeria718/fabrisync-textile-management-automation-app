import 'package:fabri_sync/Model/employee_head_models.dart';
import 'package:fabri_sync/services/employee_head_service.dart';
import 'package:flutter/foundation.dart';

class EmployeeHeadController extends ChangeNotifier {
  EmployeeHeadController({EmployeeHeadService? service})
    : _service = service ?? EmployeeHeadService();

  final EmployeeHeadService _service;

  bool loading = false;
  bool ordersLoading = false;
  bool itemsLoading = false;
  bool completingDepartment = false;
  String? markingItemId;
  String? error;
  DepartmentCompletionResult? lastCompletionResult;

  EmployeeHeadProfile? profile;
  List<EmployeeHeadOrder> activeOrders = [];
  EmployeeHeadOrder? selectedOrder;
  List<OrderItemTracking> selectedOrderItems = [];
  Map<String, DepartmentProgressSummary> orderProgress = {};
  DepartmentProgressSummary progressSummary = DepartmentProgressSummary.empty;

  // KPI stats
  int totalOrders = 0;
  int inProgressOrders = 0;
  int completedOrders = 0;
  int lateOrders = 0;
  List<EmployeeHeadOrder> lateOrdersList = [];

  bool _disposed = false;

  String? get department => profile?.department;
  int get totalQuantity => progressSummary.totalQuantity;
  int get completedQuantity => progressSummary.completedQuantity;
  int get pendingQuantity => progressSummary.pendingQuantity;
  double get progressPercentage => progressSummary.progressPercentage;
  bool get canCompleteSelectedDepartment =>
      selectedOrder != null &&
      progressSummary.totalQuantity > 0 &&
      progressSummary.completedQuantity == progressSummary.totalQuantity &&
      progressSummary.progressPercentage == 100;
  bool get selectedOrderIsLate {
    final order = selectedOrder;
    if (order == null) return false;
    return _service.isEmployeeHeadOrderLate(order);
  }

  Future<void> loadInitialData() async {
    loading = true;
    error = null;
    _notify();

    try {
      profile = await _service.getCurrentEmployeeHeadProfile();
      await refreshOrders();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> refreshOrders() async {
    final dept = department;
    if (dept == null || dept.isEmpty) {
      activeOrders = [];
      _notify();
      return;
    }

    ordersLoading = true;
    error = null;
    _notify();

    try {
      activeOrders = await _service.fetchActiveDepartmentOrders(dept);
      await _loadProgressForOrders(dept);
      if (selectedOrder != null) {
        selectedOrder = _findOrder(selectedOrder!.orderId);
      }

      // Calculate KPIs
      totalOrders = activeOrders.length;
      inProgressOrders = activeOrders
          .where((o) => o.status.toLowerCase() == 'inprogress')
          .length;
      completedOrders = activeOrders
          .where((o) => o.status.toLowerCase() == 'completed')
          .length;
      lateOrdersList = activeOrders
          .where((o) => _service.isEmployeeHeadOrderLate(o))
          .toList();
      lateOrders = lateOrdersList.length;
    } catch (e) {
      error = e.toString();
    } finally {
      ordersLoading = false;
      _notify();
    }
  }

  Future<void> loadOrderItems(String orderId) async {
    final dept = department;
    if (dept == null || dept.isEmpty) {
      error = 'Employee Head department is missing.';
      _notify();
      return;
    }

    itemsLoading = true;
    error = null;
    selectedOrder = _findOrder(orderId);
    _notify();

    try {
      final items = await _service.fetchOrderItems(orderId);
      final progressRows = await _service.fetchDepartmentProgressForOrder(
        orderId,
        dept,
      );
      final progressByItemId = <String, Map<String, dynamic>>{};
      for (final row in progressRows) {
        final itemId = (row['item_id'] ?? '').toString();
        if (itemId.isNotEmpty) {
          progressByItemId[itemId] = row;
        }
      }

      selectedOrderItems = items
          .map((item) => item.copyWithProgress(progressByItemId[item.id]))
          .toList();
      progressSummary = _summaryFromItems(orderId, dept, selectedOrderItems);
      orderProgress = {...orderProgress, orderId: progressSummary};
    } catch (e) {
      error = e.toString();
    } finally {
      itemsLoading = false;
      _notify();
    }
  }

  Future<bool> markItemComplete(OrderItemTracking item) async {
    final dept = department;
    if (dept == null || dept.isEmpty) {
      error = 'Employee Head department is missing.';
      _notify();
      return false;
    }

    if (item.isCompleted) {
      return false;
    }

    markingItemId = item.id;
    error = null;
    _notify();

    try {
      progressSummary = await _service.markItemComplete(
        orderId: item.orderId,
        itemId: item.id,
        department: dept,
        departmentOrderId: _departmentOrderIdFor(item.orderId),
      );
      orderProgress = {...orderProgress, item.orderId: progressSummary};
      await loadOrderItems(item.orderId);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      markingItemId = null;
      _notify();
    }
  }

  Future<bool> completeSelectedDepartment({
    String? delayReason,
    String? delayRemarks,
  }) async {
    final order = selectedOrder;
    final dept = department;
    if (order == null || dept == null || dept.isEmpty) {
      error = 'Select an active order before completing the department.';
      _notify();
      return false;
    }

    if (!canCompleteSelectedDepartment) {
      error = 'All items must be completed before completing this department.';
      _notify();
      return false;
    }

    completingDepartment = true;
    error = null;
    lastCompletionResult = null;
    _notify();

    try {
      lastCompletionResult = await _service.completeDepartment(
        orderId: order.orderId,
        department: dept,
        departmentOrderId: order.departmentOrderId,
        delayReason: delayReason,
        delayRemarks: delayRemarks,
      );
      await refreshOrders();
      selectedOrder = null;
      selectedOrderItems = [];
      progressSummary = DepartmentProgressSummary.empty;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      completingDepartment = false;
      _notify();
    }
  }

  EmployeeHeadOrder? _findOrder(String orderId) {
    for (final order in activeOrders) {
      if (order.orderId == orderId) return order;
    }
    return null;
  }

  DepartmentProgressSummary summaryForOrder(EmployeeHeadOrder order) {
    return orderProgress[order.orderId] ??
        DepartmentProgressSummary(
          orderId: order.orderId,
          department: order.department,
          totalQuantity: 0,
          completedQuantity: 0,
        );
  }

  Future<void> _loadProgressForOrders(String department) async {
    final summaries = <String, DepartmentProgressSummary>{};
    for (final order in activeOrders) {
      summaries[order.orderId] = await _service.calculateProgress(
        order.orderId,
        department,
      );
    }
    orderProgress = summaries;
  }

  String? _departmentOrderIdFor(String orderId) {
    final order = selectedOrder?.orderId == orderId
        ? selectedOrder
        : _findOrder(orderId);
    final id = order?.departmentOrderId.trim();
    if (id == null || id.isEmpty) return null;
    return id;
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

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
