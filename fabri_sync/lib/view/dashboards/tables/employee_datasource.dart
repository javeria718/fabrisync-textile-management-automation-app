import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/utils/work_duration_formatter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeOrdersDataSource extends DataTableSource {
  EmployeeOrdersDataSource(this.orders, this.context) {
    debugPrint('[EmployeeOrders] final table row count: ${orders.length}');
  }

  final List<Map<String, dynamic>> orders;
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
        DataCell(_plainText((order['quantity'] ?? 0).toString())),
        DataCell(_priorityChip(order['priority'])),
        DataCell(_dateInCell(order)),
        DataCell(_expectedTimeCell(order)),
        DataCell(_departmentProgressCell(order)),
        DataCell(_statusChip(order['status'])),
      ],
    );
  }

  Widget _orderIdCell(Map<String, dynamic> order) {
    final orderId = (order['order_id'] ?? '').toString();
    return InkWell(
      onTap: () => _openDetails(orderId),
      child: Text(
        orderId,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.primaryAccent,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _productCell(Map<String, dynamic> order) {
    final type = (order['product_type'] ?? 'N/A').toString();
    final category = (order['product_category'] ?? '-').toString();
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

  Widget _priorityChip(dynamic priority) {
    final label = _displayText(priority);
    final isRush = label.toLowerCase() == 'rush';
    final color = isRush ? AppColors.accentOrange : AppColors.accentGreen;
    return _chip(label, color);
  }

  Widget _dateInCell(Map<String, dynamic> order) {
    final dateIn = order['date_in'];
    if (dateIn == null) return _plainText('-');
    final date = DateTime.parse(dateIn.toString());
    return _plainText(DateFormat('dd MMM yyyy').format(date));
  }

  Widget _expectedTimeCell(Map<String, dynamic> order) {
    final hours = order['expected_hours'];
    if (hours == null) return _plainText('-');
    return _plainText(formatWorkDuration(hours as num));
  }

  Widget _departmentProgressCell(Map<String, dynamic> order) {
    final status = (order['status'] ?? '').toString().toLowerCase();
    double progressValue;
    String progressText;

    switch (status) {
      case 'completed':
        progressValue = 1.0;
        progressText = '100%';
        break;
      case 'inprogress':
        progressValue = 0.5;
        progressText = '50%';
        break;
      case 'pending':
      default:
        progressValue = 0.0;
        progressText = '0%';
        break;
    }

    return SizedBox(
      width: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            progressText,
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
              value: progressValue,
              minHeight: 6,
              backgroundColor: AppColors.surfaceMuted,
              color: AppColors.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(dynamic status) {
    final label = _statusLabel(status);
    final normalized = (status ?? '').toString().toLowerCase();
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

  Future<void> _openDetails(String orderId) async {
    try {
      final row = await supabase
          .from('ordersmain')
          .select()
          .eq('order_id', orderId)
          .maybeSingle();
      if (row == null) {
        _showError('Order $orderId not found');
        return;
      }
      // Assuming OrderModel exists
      // final fullOrder = OrderModel.fromMap(Map<String, dynamic>.from(row));
      if (!context.mounted) return;
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: fullOrder)),
      // );
      _showError('Order details view not implemented yet');
    } catch (e) {
      _showError('Failed to load order details');
    }
  }

  void _showError(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  String _statusLabel(dynamic value) {
    final status = (value ?? '').toString().trim().toLowerCase();
    if (status.isEmpty) return '-';
    if (status == 'inprogress') return 'In Progress';
    return status[0].toUpperCase() + status.substring(1);
  }

  String _displayText(dynamic value) {
    final text = (value ?? '').trim().toString();
    return text.isEmpty ? '-' : text;
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => orders.length;

  @override
  int get selectedRowCount => 0;
}
