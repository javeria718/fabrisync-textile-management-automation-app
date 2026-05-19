import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/Model/order_summary_model.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/utils/work_duration_formatter.dart';
import 'package:fabri_sync/view/dashboards/tables/order_details.dart';
import 'package:fabri_sync/view/newOrder/orderInput.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersDataSource extends DataTableSource {
  OrdersDataSource(this.orders, this.context) {
    debugPrint('[ExistingOrders] final table row count: ${orders.length}');
  }

  final List<OrderSummaryModel> orders;
  final BuildContext context;
  final supabase = Supabase.instance.client;

  @override
  DataRow? getRow(int index) {
    if (index >= orders.length) return null;
    final order = orders[index];

    final rowColor = MaterialStateProperty.resolveWith<Color?>((states) {
      if (states.contains(MaterialState.selected)) {
        return AppColors.surfaceMuted;
      }
      return index.isEven ? Colors.white : AppColors.surfaceMuted;
    });

    return DataRow.byIndex(
      index: index,
      color: rowColor,
      cells: [
        DataCell(_plainText((index + 1).toString())),
        DataCell(_orderIdCell(order)),
        DataCell(_productCell(order)),
        DataCell(_plainText(order.quantity.toString())),
        DataCell(_plainText(order.qualityGrade ?? '-')),
        DataCell(_priorityChip(order.priority)),
        DataCell(_plainText(_formatDate(order.requiredDeliveryDate))),
        DataCell(_departmentChip(order.currentDepartment)),
        DataCell(_progressCell(order)),
        DataCell(_plainText(_formatHours(order))),
        DataCell(_plainText(_formatCost(order))),
        DataCell(_statusChip(order.orderStatus)),
        DataCell(_actionMenu(order)),
      ],
    );
  }

  Widget _orderIdCell(OrderSummaryModel order) {
    return InkWell(
      onTap: () => _openDetails(order),
      child: Text(
        order.orderId,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.primaryAccent,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _productCell(OrderSummaryModel order) {
    final type = order.productType ?? 'N/A';
    final category = order.productCategory ?? '-';
    return SizedBox(
      width: 170,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            category,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _plainText(String text) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: AppColors.primaryText),
    );
  }

  Widget _priorityChip(String? priority) {
    final label = _displayText(priority);
    final isRush = label.toLowerCase() == 'rush';
    final color = isRush ? AppColors.accentOrange : AppColors.accentGreen;
    return _chip(label, color);
  }

  Widget _statusChip(String? status) {
    final label = _statusLabel(status);
    final normalized = (status ?? '').toLowerCase();
    Color color;
    if (normalized == 'completed') {
      color = AppColors.accentGreen;
    } else if (normalized == 'inprogress') {
      color = AppColors.accentOrange;
    } else if (normalized == 'pending') {
      color = AppColors.accentBlue;
    } else {
      color = AppColors.accentPink;
    }
    return _chip(label, color);
  }

  Widget _departmentChip(String? department) {
    final label = _departmentLabel(department);
    if (label == '-') return _plainText('-');
    return _chip(label, AppColors.primaryAccent);
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        border: Border.all(color: color.withOpacity(0.24)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _progressCell(OrderSummaryModel order) {
    if (order.totalDepartments <= 0) return _plainText('-');
    final progress = (order.progressPercent / 100).clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: 112,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${order.completedDepartments}/${order.totalDepartments}',
            style: const TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceMuted,
              color: AppColors.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionMenu(OrderSummaryModel order) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.surface,
      onSelected: (value) async {
        if (value == 'view') {
          await _openDetails(order);
        } else if (value == 'edit') {
          await _openEdit(order);
        } else if (value == 'delete') {
          await _deleteOrder(order);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 18, color: AppColors.primaryText),
              SizedBox(width: 8),
              Text('View', style: TextStyle(color: AppColors.primaryText)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18, color: AppColors.primaryText),
              SizedBox(width: 8),
              Text('Edit', style: TextStyle(color: AppColors.primaryText)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: AppColors.error),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
      child: const Icon(Icons.more_vert, color: AppColors.primaryText),
    );
  }

  Future<void> _openDetails(OrderSummaryModel order) async {
    final fullOrder = await _fetchFullOrder(order.orderId);
    if (fullOrder == null) return;
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: fullOrder)),
    );
  }

  Future<void> _openEdit(OrderSummaryModel order) async {
    final fullOrder = await _fetchFullOrder(order.orderId);
    if (fullOrder == null) return;
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderInputScreen(
          existingOrder: fullOrder,
          isEditing: true,
          isDraft: fullOrder.status.toLowerCase() == 'draft',
        ),
      ),
    );
  }

  Future<OrderModel?> _fetchFullOrder(String orderId) async {
    try {
      final row = await supabase
          .from('ordersmain')
          .select()
          .eq('order_id', orderId)
          .maybeSingle();
      if (row == null) {
        _showError('Order $orderId not found');
        return null;
      }
      return OrderModel.fromMap(Map<String, dynamic>.from(row));
    } catch (e) {
      _showError('Failed to load order');
      return null;
    }
  }

  Future<void> _deleteOrder(OrderSummaryModel order) async {
    try {
      await supabase
          .from('department_orders')
          .delete()
          .eq('order_id', order.orderId);
      await supabase
          .from('order_cost_breakdown')
          .delete()
          .eq('order_id', order.orderId);
      await supabase.from('ordersmain').delete().eq('order_id', order.orderId);
      orders.removeWhere((o) => o.orderId == order.orderId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order ${order.orderId} deleted')),
        );
      }
      notifyListeners();
    } catch (e) {
      _showError('Failed to delete order');
    }
  }

  void _showError(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('dd MMM yyyy').format(value);
  }

  String _formatHours(OrderSummaryModel order) {
    final hours = order.estimatedProductionHours ?? order.estimatedTotalTime;
    if (hours == null) return '-';
    return formatWorkDuration(hours);
  }

  String _formatCost(OrderSummaryModel order) {
    final cost = order.costEstimatedTotal ?? order.estimatedTotalCost;
    if (cost == null) return '-';
    return 'PKR ${NumberFormat.decimalPattern().format(cost.round())}';
  }

  String _departmentLabel(String? value) {
    final dept = (value ?? '').trim().replaceAll(' ', '_').toUpperCase();
    if (dept == 'QUALITY_CONTROL') return 'Quality Control';
    if (dept == 'PACKAGING') return 'Packaging';
    if (dept.isEmpty) return '-';

    final normalized = dept.replaceAll('_', ' ').toLowerCase();
    return normalized
        .split(' ')
        .map(
          (segment) => segment.isEmpty
              ? segment
              : '${segment[0].toUpperCase()}${segment.substring(1)}',
        )
        .join(' ');
  }

  String _statusLabel(String? value) {
    final status = (value ?? '').trim().toLowerCase();
    if (status.isEmpty) return '-';
    if (status == 'inprogress') return 'In Progress';
    return status[0].toUpperCase() + status.substring(1);
  }

  String _displayText(String? value) {
    final text = (value ?? '').trim();
    return text.isEmpty ? '-' : text;
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => orders.length;

  @override
  int get selectedRowCount => 0;
}
