import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/services/new_order_service.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/view/newOrder/orderInput.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DraftOrdersScreen extends StatefulWidget {
  const DraftOrdersScreen({super.key});

  @override
  State<DraftOrdersScreen> createState() => _DraftOrdersScreenState();
}

class _DraftOrdersScreenState extends State<DraftOrdersScreen> {
  final NewOrderService _service = NewOrderService();
  bool loading = true;
  List<OrderModel> drafts = [];

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    setState(() => loading = true);
    try {
      final rows = await _service.fetchDraftOrders();
      if (!mounted) return;
      setState(() {
        drafts = rows;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load drafts: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _openDraft(OrderModel order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderInputScreen(
          existingOrder: order,
          isEditing: true,
          isDraft: true,
        ),
      ),
    );
    if (mounted) _loadDrafts();
  }

  Future<void> _deleteDraft(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Draft?'),
        content: Text('Delete draft ${order.orderId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteDraft(order.orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Draft ${order.orderId} deleted')));
      _loadDrafts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete draft: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 720;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.primaryText,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Draft Orders',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: AppColors.primaryText),
            onPressed: _loadDrafts,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: gradientOrderBackground(
        child: SafeArea(
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryAccent,
                  ),
                )
              : drafts.isEmpty
              ? const Center(
                  child: Text(
                    'No draft orders',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.all(isMobile ? 14 : 20),
                  itemCount: drafts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final order = drafts[index];
                    return _DraftOrderCard(
                      order: order,
                      onOpen: () => _openDraft(order),
                      onDelete: () => _deleteDraft(order),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _DraftOrderCard extends StatelessWidget {
  const _DraftOrderCard({
    required this.order,
    required this.onOpen,
    required this.onDelete,
  });

  final OrderModel order;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final requiredDate = order.requiredDeliveryDate == null
        ? '-'
        : dateFmt.format(order.requiredDeliveryDate!);
    final savedDate = dateFmt.format(order.createdAt);
    final isExpired =
        order.isDraftExpired ||
        (order.draftExpiresAt != null &&
            DateTime.now().isAfter(order.draftExpiresAt!));
    final statusLabel = isExpired ? 'Expired Draft' : 'Draft';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surface(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderId,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              _StatusChip(status: statusLabel, isExpired: isExpired),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _InfoTile('Category', order.productCategory ?? '-'),
              _InfoTile('Type', order.productType ?? '-'),
              _InfoTile('Quantity', order.quantity.toString()),
              _InfoTile('Delivery', requiredDate),
              _InfoTile('Quality', order.qualityGrade ?? '-'),
              _InfoTile('Saved', savedDate),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Draft'),
              ),
              ElevatedButton.icon(
                onPressed: isExpired ? null : onOpen,
                icon: const Icon(Icons.edit_outlined),
                label: Text(isExpired ? 'Expired' : 'Continue'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, this.isExpired = false});

  final String status;
  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isExpired
        ? AppColors.error.withAlpha(36)
        : AppColors.accentOrange.withAlpha(36);
    final borderColor = isExpired
        ? AppColors.error.withAlpha(61)
        : AppColors.accentOrange.withAlpha(61);
    final textColor = isExpired ? AppColors.error : AppColors.accentOrange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
