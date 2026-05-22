import 'package:fabri_sync/Model/employee_head_models.dart';
import 'package:fabri_sync/controllers/employee_head_controller.dart';
import 'package:fabri_sync/services/auth_navigation_service.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/widgets/dashboard_shared.dart';
import 'package:fabri_sync/widgets/manager_widgets.dart';
import 'package:flutter/material.dart';

class EmployeeHeadPanel extends StatefulWidget {
  const EmployeeHeadPanel({super.key});

  @override
  State<EmployeeHeadPanel> createState() => _EmployeeHeadPanelState();
}

class _EmployeeHeadPanelState extends State<EmployeeHeadPanel> {
  final EmployeeHeadController controller = EmployeeHeadController();
  bool _showAlertsPanel = false;
  bool _showProfileCard = false;

  void _toggleAlertsPanel() {
    setState(() {
      _showAlertsPanel = !_showAlertsPanel;
      _showProfileCard = false;
    });
  }

  void _toggleProfileCard() {
    setState(() {
      _showProfileCard = !_showProfileCard;
      _showAlertsPanel = false;
    });
  }

  void _closeFloatingPanels() {
    if (_showAlertsPanel || _showProfileCard) {
      setState(() {
        _showAlertsPanel = false;
        _showProfileCard = false;
      });
    }
  }

  List<Map<String, dynamic>> get _nearDeadlineAlerts {
    final now = DateTime.now();
    return controller.activeOrders
        .where((order) {
          final deadline = order.plannedEndDate ?? order.dateOut;
          if (deadline == null) return false;
          final diff = deadline.difference(now);
          return diff.inSeconds >= 0 && diff.inHours < 3;
        })
        .map((order) => {'order_id': order.orderId})
        .toList();
  }

  List<Map<String, dynamic>> get _exceededAlerts {
    final now = DateTime.now();
    return controller.activeOrders
        .where((order) {
          final deadline = order.plannedEndDate ?? order.dateOut;
          return deadline != null && deadline.isBefore(now);
        })
        .map((order) => {'order_id': order.orderId})
        .toList();
  }

  EmployeeHeadOrder? _findAlertOrder(String orderId) {
    for (final order in controller.activeOrders) {
      if (order.orderId == orderId) return order;
    }
    return null;
  }

  int _alertRemainingSeconds(Map<String, dynamic> alert) {
    final orderId = (alert['order_id'] ?? '').toString();
    final order = _findAlertOrder(orderId);
    final deadline = order?.plannedEndDate ?? order?.dateOut;
    if (deadline == null) return 0;
    return deadline.difference(DateTime.now()).inSeconds;
  }

  String _formatAlertCountdown(int seconds) {
    final absSeconds = seconds.abs();
    final hours = absSeconds ~/ 3600;
    final minutes = (absSeconds % 3600) ~/ 60;
    final secs = absSeconds % 60;
    final formatted =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    return seconds < 0 ? '-$formatted' : formatted;
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChanged);
    controller.loadInitialData();
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _logout() async {
    await AuthNavigationService.logoutAndNavigate(context, 'employee_head');
  }

  Future<void> _refresh() async {
    await controller.refreshOrders();
    final selected = controller.selectedOrder;
    if (selected != null) {
      await controller.loadOrderItems(selected.orderId);
    }
  }

  Future<void> _openOrder(EmployeeHeadOrder order) async {
    await controller.loadOrderItems(order.orderId);
  }

  Future<void> _markItemComplete(OrderItemTracking item) async {
    final success = await controller.markItemComplete(item);
    if (!mounted) return;

    if (success) {
      _showSuccessSnack('${item.itemCode} marked as completed');
    } else if (controller.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _completeDepartment() async {
    if (!controller.canCompleteSelectedDepartment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All items must be completed before completing this department.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    String? delayReason;
    String? delayRemarks;
    if (controller.selectedOrderIsLate) {
      final input = await _showLateCompletionDialog();
      if (input == null) return;
      delayReason = input.reason;
      delayRemarks = input.remarks;
    } else {
      final confirmed = await _showCompletionConfirmDialog();
      if (confirmed != true) return;
    }

    final success = await controller.completeSelectedDepartment(
      delayReason: delayReason,
      delayRemarks: delayRemarks,
    );
    if (!mounted) return;

    if (success) {
      final result = controller.lastCompletionResult;
      _showSuccessSnack(
        result?.message ?? 'Department completed and sent forward.',
      );
    } else if (controller.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSuccessSnack(String message) {
    if (!mounted) return;
    final snack = SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      backgroundColor: AppColors.success,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  Future<bool?> _showCompletionConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Complete Department?'),
          content: const Text(
            'All items are complete. This will send the order to the next department.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Complete'),
            ),
          ],
        );
      },
    );
  }

  Future<_DelayCompletionInput?> _showLateCompletionDialog() async {
    final reasonController = TextEditingController();
    final remarksController = TextEditingController();

    final result = await showDialog<_DelayCompletionInput>(
      context: context,
      builder: (context) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Late Completion Remarks'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'This department is late. Add a reason and remarks before sending it forward.',
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Delay reason',
                        hintText: 'Material shortage, machine issue...',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: remarksController,
                      decoration: const InputDecoration(
                        labelText: 'Delay remarks',
                        hintText: 'Add useful completion notes',
                      ),
                      minLines: 3,
                      maxLines: 4,
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          errorText!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final reason = reasonController.text.trim();
                    final remarks = remarksController.text.trim();
                    if (reason.isEmpty || remarks.isEmpty) {
                      setDialogState(() {
                        errorText = 'Delay reason and remarks are required.';
                      });
                      return;
                    }
                    Navigator.of(context).pop(
                      _DelayCompletionInput(reason: reason, remarks: remarks),
                    );
                  },
                  child: const Text('Complete'),
                ),
              ],
            );
          },
        );
      },
    );

    reasonController.dispose();
    remarksController.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final department = controller.profile?.department ?? '';
    final isDesktop = MediaQuery.of(context).size.width >= 980;
    final hasAlerts = controller.lateOrders > 0;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: DashboardAppBar(
        department: department,
        hasAlerts: hasAlerts,
        onAlertsTap: _toggleAlertsPanel,
        onProfileTap: _toggleProfileCard,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: gradientOrderBackground(child: const SizedBox.expand()),
          ),
          Positioned.fill(
            child: SafeArea(
              child: controller.loading
                  ? const Center(child: CircularProgressIndicator())
                  : GestureDetector(
                      onTap: _closeFloatingPanels,
                      behavior: HitTestBehavior.translucent,
                      child: RefreshIndicator(
                        onRefresh: _refresh,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1180,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      DashboardDepartmentInfo(
                                        department: department,
                                        role: 'Employee Head',
                                      ),
                                      const SizedBox(height: 20),
                                      DashboardKpiSection(
                                        isDesktop: isDesktop,
                                        items: [
                                          DashboardKpiItem(
                                            label: 'Total Orders',
                                            value: controller.totalOrders
                                                .toString(),
                                            icon: Icons.inventory_2_outlined,
                                            color: AppColors.accentBlue,
                                          ),
                                          DashboardKpiItem(
                                            label: 'In Progress',
                                            value: controller.inProgressOrders
                                                .toString(),
                                            icon: Icons.autorenew_rounded,
                                            color: AppColors.primaryAccent,
                                          ),
                                          DashboardKpiItem(
                                            label: 'Completed',
                                            value: controller.completedOrders
                                                .toString(),
                                            icon: Icons.check_circle_outline,
                                            color: AppColors.accentGreen,
                                          ),
                                          DashboardKpiItem(
                                            label: 'Late',
                                            value: controller.lateOrders
                                                .toString(),
                                            icon: Icons.warning_amber_rounded,
                                            color: AppColors.accentOrange,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      if (hasAlerts) ...[
                                        _AlertsSection(
                                          lateOrders: controller.lateOrdersList,
                                        ),
                                        const SizedBox(height: 18),
                                      ],
                                      if (controller.error != null) ...[
                                        _ErrorPanel(message: controller.error!),
                                        const SizedBox(height: 18),
                                      ],
                                      if (isDesktop)
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              flex: 5,
                                              child: _ordersPanel(),
                                            ),
                                            const SizedBox(width: 18),
                                            Expanded(
                                              flex: 6,
                                              child: _itemsPanel(),
                                            ),
                                          ],
                                        )
                                      else ...[
                                        _ordersPanel(),
                                        const SizedBox(height: 18),
                                        _itemsPanel(),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            top: 0,
            bottom: 0,
            right: _showAlertsPanel ? 0 : -340,
            child: AlertsPanel(
              width: 340,
              title: 'Alerts',
              subtitle: 'Orders with ≤ 3 hours remaining',
              nearDeadline: _nearDeadlineAlerts,
              exceeded: _exceededAlerts,
              remainingSeconds: _alertRemainingSeconds,
              formatCountdown: _formatAlertCountdown,
              onClose: _toggleAlertsPanel,
            ),
          ),
          if (_showProfileCard)
            Positioned(
              top: kToolbarHeight + 10,
              right: 16,
              child: _HeaderFloatingPanel(
                title: 'Profile',
                child: _ProfilePanelContent(
                  profile: controller.profile,
                  onLogout: _logout,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ordersPanel() {
    final orders = controller.activeOrders;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.surface(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelTitle(
            icon: Icons.assignment_outlined,
            title: 'Active Department Orders',
            trailing: controller.ordersLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    '${orders.length}',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          if (orders.isEmpty)
            const _EmptyPanel(
              icon: Icons.inbox_outlined,
              message: 'No active orders for this department right now.',
            )
          else
            ...orders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrderCard(
                  order: order,
                  summary: controller.summaryForOrder(order),
                  selected: controller.selectedOrder?.orderId == order.orderId,
                  onViewItems: () => _openOrder(order),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _itemsPanel() {
    final selectedOrder = controller.selectedOrder;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.surface(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelTitle(
            icon: Icons.inventory_2_outlined,
            title: selectedOrder == null
                ? 'Order Items'
                : 'Items for ${selectedOrder.orderNumber}',
            trailing: selectedOrder == null
                ? null
                : Text(
                    '${controller.completedQuantity}/${controller.totalQuantity}',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          if (selectedOrder == null)
            const _EmptyPanel(
              icon: Icons.touch_app_outlined,
              message: 'Select an order to view item progress.',
            )
          else if (controller.itemsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 44),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.selectedOrderItems.isEmpty)
            const _EmptyPanel(
              icon: Icons.inventory_outlined,
              message:
                  'No item records found for this order yet. Items will be generated when order item generation is added.',
            )
          else ...[
            _ProgressSummaryBar(summary: controller.progressSummary),
            const SizedBox(height: 14),
            _DepartmentCompletionPanel(
              canComplete: controller.canCompleteSelectedDepartment,
              isLate: controller.selectedOrderIsLate,
              isLoading: controller.completingDepartment,
              onComplete: _completeDepartment,
            ),
            const SizedBox(height: 14),
            ...controller.selectedOrderItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ItemRow(
                  item: item,
                  isMarking: controller.markingItemId == item.id,
                  onMarkComplete: () => _markItemComplete(item),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderFloatingPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _HeaderFloatingPanel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        decoration: AppDecorations.surface(radius: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _AlertPanelContent extends StatelessWidget {
  final List<EmployeeHeadOrder> lateOrders;

  const _AlertPanelContent({required this.lateOrders});

  @override
  Widget build(BuildContext context) {
    if (lateOrders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No late orders at the moment.',
          style: const TextStyle(color: AppColors.secondaryText),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: lateOrders.map((order) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.schedule, color: AppColors.error, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${order.orderNumber} • ${order.productType ?? 'Product'}',
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProfilePanelContent extends StatelessWidget {
  final EmployeeHeadProfile? profile;
  final VoidCallback onLogout;

  const _ProfilePanelContent({required this.profile, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final name = _fallback(profile?.fullName, 'Employee Head');
    final email = _fallback(profile?.email, 'No email available');
    final department = departmentLabel(profile?.department);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            email,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            department,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onLogout,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.summary,
    required this.selected,
    required this.onViewItems,
  });

  final EmployeeHeadOrder order;
  final DepartmentProgressSummary summary;
  final bool selected;
  final VoidCallback onViewItems;

  @override
  Widget build(BuildContext context) {
    final total = summary.totalQuantity > 0
        ? summary.totalQuantity
        : order.quantity;
    final completed = summary.completedQuantity;
    final pending = total - completed < 0 ? 0 : total - completed;
    final progress = total <= 0 ? 0.0 : completed / total;
    final product = [
      order.productType,
      order.productCategory,
    ].where((value) => _hasText(value)).join(' | ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.softPanel(
        radius: 14,
        color: selected ? const Color(0xFFF4F0FF) : AppColors.surfaceMuted,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.isEmpty ? 'No product details' : product,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusChip(
                label: '${(progress * 100).toStringAsFixed(0)}%',
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1).toDouble(),
              minHeight: 8,
              backgroundColor: AppColors.border,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricPill(label: 'Total', value: '$total'),
              _MetricPill(label: 'Completed', value: '$completed'),
              _MetricPill(label: 'Pending', value: '$pending'),
              if (order.expectedHours != null)
                _MetricPill(
                  label: 'Expected',
                  value: formatHours(order.expectedHours!),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onViewItems,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('View Items'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.isMarking,
    required this.onMarkComplete,
  });

  final OrderItemTracking item;
  final bool isMarking;
  final VoidCallback onMarkComplete;

  @override
  Widget build(BuildContext context) {
    final completed = item.isCompleted;
    final itemInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.itemCode,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Item #${item.itemNo}',
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    final statusChip = _StatusChip(
      label: completed ? 'Completed' : 'Pending',
      icon: completed ? Icons.check_circle_outline : Icons.schedule,
      color: completed ? AppColors.success : AppColors.warning,
    );
    final completedText = Text(
      completed
          ? 'Completed: ${formatDateTime(item.completedAt)}'
          : 'Not completed yet',
      style: const TextStyle(
        color: AppColors.secondaryText,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
    final actionButton = completed
        ? OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.done, size: 18),
            label: const Text('Done'),
          )
        : ElevatedButton.icon(
            onPressed: isMarking ? null : onMarkComplete,
            icon: isMarking
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, size: 18),
            label: const Text('Mark Complete'),
          );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.softPanel(radius: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                itemInfo,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerLeft, child: statusChip),
                const SizedBox(height: 10),
                completedText,
                const SizedBox(height: 12),
                actionButton,
              ],
            );
          }

          return Wrap(
            spacing: 14,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              SizedBox(width: 260, child: itemInfo),
              statusChip,
              SizedBox(width: 190, child: completedText),
              SizedBox(width: 162, child: actionButton),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressSummaryBar extends StatelessWidget {
  const _ProgressSummaryBar({required this.summary});

  final DepartmentProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final progress = (summary.progressPercentage / 100).clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.softPanel(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricPill(label: 'Total', value: '${summary.totalQuantity}'),
              _MetricPill(
                label: 'Completed',
                value: '${summary.completedQuantity}',
              ),
              _MetricPill(
                label: 'Pending',
                value: '${summary.pendingQuantity}',
              ),
              _MetricPill(
                label: 'Progress',
                value: '${summary.progressPercentage.toStringAsFixed(0)}%',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentCompletionPanel extends StatelessWidget {
  const _DepartmentCompletionPanel({
    required this.canComplete,
    required this.isLate,
    required this.isLoading,
    required this.onComplete,
  });

  final bool canComplete;
  final bool isLate;
  final bool isLoading;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final color = canComplete
        ? isLate
              ? AppColors.warning
              : AppColors.success
        : AppColors.secondaryText;
    final message = canComplete
        ? isLate
              ? 'All items are complete, but this department is late. Delay reason and remarks are required.'
              : 'All items are complete. Ready to send to the next department.'
        : 'All items must be completed before completing this department.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.softPanel(radius: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final button = ElevatedButton.icon(
            onPressed: canComplete && !isLoading ? onComplete : null,
            icon: isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_outlined, size: 18),
            label: const Text('Complete Department'),
          );
          final info = Row(
            children: [
              Icon(
                canComplete ? Icons.check_circle_outline : Icons.info_outline,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [info, const SizedBox(height: 12), button],
            );
          }

          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 14),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryAccent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: AppDecorations.softPanel(
        radius: 12,
        color: AppColors.surface,
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: AppDecorations.accentFill(color, radius: 999),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 34),
      decoration: AppDecorations.softPanel(radius: 14),
      child: Column(
        children: [
          Icon(icon, color: AppColors.secondaryText, size: 34),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.accentFill(AppColors.error, radius: 14),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsSection extends StatelessWidget {
  final List<EmployeeHeadOrder> lateOrders;

  const _AlertsSection({required this.lateOrders});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.surface(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelTitle(
            icon: Icons.warning_outlined,
            title: 'Late Orders',
            trailing: Text(
              '${lateOrders.length}',
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...lateOrders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: AppDecorations.softPanel(radius: 12),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: AppColors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${order.orderNumber} - ${order.productType ?? 'Product'}',
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmployeeHeadKpiSection extends StatelessWidget {
  final bool isDesktop;
  final int total;
  final int inProgress;
  final int completed;
  final int late;

  const EmployeeHeadKpiSection({
    super.key,
    required this.isDesktop,
    required this.total,
    required this.inProgress,
    required this.completed,
    required this.late,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.surface(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Department Overview',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (isDesktop)
            Row(
              children: [
                _kpiCard(
                  'Total Orders',
                  total.toString(),
                  AppColors.primaryAccent,
                ),
                const SizedBox(width: 16),
                _kpiCard(
                  'In Progress',
                  inProgress.toString(),
                  AppColors.accentBlue,
                ),
                const SizedBox(width: 16),
                _kpiCard('Completed', completed.toString(), AppColors.success),
                const SizedBox(width: 16),
                _kpiCard('Late', late.toString(), AppColors.error),
              ],
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _kpiCard(
                        'Total Orders',
                        total.toString(),
                        AppColors.primaryAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _kpiCard(
                        'In Progress',
                        inProgress.toString(),
                        AppColors.accentBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _kpiCard(
                        'Completed',
                        completed.toString(),
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _kpiCard('Late', late.toString(), AppColors.error),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  static Widget _kpiCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.accentFill(color, radius: 12),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DelayCompletionInput {
  const _DelayCompletionInput({required this.reason, required this.remarks});

  final String reason;
  final String remarks;
}

String departmentLabel(String? value) {
  final dept = (value ?? '').trim().toUpperCase();
  if (dept.isEmpty) return '-';
  if (dept == 'QUALITY_CONTROL') return 'Quality Control';
  if (dept == 'PACKAGING') return 'Packaging';
  return dept[0] + dept.substring(1).toLowerCase();
}

String formatHours(double hours) {
  if (hours == hours.roundToDouble()) {
    return '${hours.toInt()}h';
  }
  return '${hours.toStringAsFixed(1)}h';
}

String formatDateTime(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  final date =
      '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}

String _fallback(String? value, String fallback) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return fallback;
  return text;
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
