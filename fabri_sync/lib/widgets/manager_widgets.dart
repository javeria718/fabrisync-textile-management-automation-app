import 'package:fabri_sync/Model/employee_head_models.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/utils/work_duration_formatter.dart';
import 'package:flutter/material.dart';

class ResponsiveHeader extends StatelessWidget {
  final String title;
  final Widget? rightAction;
  final String? subtitle;

  const ResponsiveHeader({
    super.key,
    required this.title,
    this.rightAction,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final narrow = c.maxWidth < 520;

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
              if (rightAction != null) ...[
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerLeft, child: rightAction!),
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
                if (rightAction != null) rightAction!,
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class Glass extends StatelessWidget {
  final double radius;
  final EdgeInsets padding;
  final Widget child;

  const Glass({
    super.key,
    required this.radius,
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: AppDecorations.surface(radius: radius),
      child: child,
    );
  }
}

class GlassOverlayCard extends StatelessWidget {
  final double width;
  final Widget child;

  const GlassOverlayCard({super.key, required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surface(radius: 16),
      child: child,
    );
  }
}

class ManagerKpiSection extends StatelessWidget {
  final bool isDesktop;
  final int total;
  final int inProgress;
  final int completed;
  final int late;

  const ManagerKpiSection({
    super.key,
    required this.isDesktop,
    required this.total,
    required this.inProgress,
    required this.completed,
    required this.late,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _kpiCard("Total", total.toString(), Icons.inventory_2_outlined, AppColors.accentBlue),
      _kpiCard("In Progress", inProgress.toString(), Icons.autorenew_rounded, AppColors.primaryAccent),
      _kpiCard("Completed", completed.toString(), Icons.check_circle_outline, AppColors.accentGreen),
      _kpiCard("Late", late.toString(), Icons.warning_amber_rounded, AppColors.accentOrange),
    ];

    if (isDesktop) {
      return GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 20,
        childAspectRatio: 2.35,
        children: cards,
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, i) => SizedBox(width: 220, child: cards[i]),
      ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return LayoutBuilder(
      builder: (_, c) {
        final h = c.maxHeight;
        final pad = h < 105 ? 12.0 : 16.0;
        final iconSize = h < 105 ? 24.0 : 28.0;
        final valueSize = h < 105 ? 22.0 : 26.0;
        final titleSize = h < 105 ? 11.5 : 13.0;
        final gap = h < 105 ? 2.0 : 4.0;

        return Glass(
          radius: 20,
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: AppDecorations.accentFill(color),
                child: Icon(icon, color: color, size: iconSize),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: valueSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                        height: 1.0,
                      ),
                    ),
                  ),
                  SizedBox(height: gap),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: titleSize,
                        color: AppColors.secondaryText,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class QueuePreviewTable extends StatelessWidget {
  final List<Map<String, dynamic>> queuePreview;
  final String Function(dynamic) formatDate;
  final String Function(dynamic) formatTime;
  final void Function(Map<String, dynamic>)? onViewDetails;
  final String? selectedOrderId;

  const QueuePreviewTable({
    super.key,
    required this.queuePreview,
    required this.formatDate,
    required this.formatTime,
    this.onViewDetails,
    this.selectedOrderId,
  });

  @override
  Widget build(BuildContext context) {
    final visibleRows = queuePreview
        .where((o) => (o['order_status'] ?? '').toString() != 'draft')
        .toList();

    if (visibleRows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            "No history yet",
            style: TextStyle(color: AppColors.secondaryText),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(children: [_h("Order ID"), _h("In"), _h("Out"), _h("Status")]),
        const SizedBox(height: 10),
        const Divider(color: AppColors.divider),
        ...visibleRows.map((o) {
          final orderId = (o['order_id'] ?? '').toString();
          final status = (o['status'] ?? '').toString();
          final selected = selectedOrderId == orderId;
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onViewDetails == null ? null : () => onViewDetails!(o),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: selected
                  ? AppDecorations.softPanel(
                      radius: 12,
                      color: const Color(0xFFF4F0FF),
                    )
                  : null,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      orderId,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "${formatDate(o['date_in'])}\n${formatTime(o['time_in'])}",
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "${formatDate(o['date_out'])}\n${formatTime(o['time_out'])}",
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      status,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _h(String t) {
    return Expanded(
      child: Text(
        t,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
      ),
    );
  }
}

class ActiveOrdersList extends StatelessWidget {
  final List<Map<String, dynamic>> activeOrders;
  final int Function(Map<String, dynamic>) remainingSeconds;
  final bool Function(Map<String, dynamic>) isAlert;
  final String Function(int) formatCountdown;
  final DepartmentProgressSummary Function(Map<String, dynamic>) summaryForOrder;
  final Map<String, dynamic>? Function(Map<String, dynamic>) latestLogForOrder;
  final void Function(Map<String, dynamic>) onViewDetails;
  final String? selectedOrderId;

  static const List<Color> kAccent = [
    AppColors.primaryAccent,
    AppColors.accentBlue,
  ];

  const ActiveOrdersList({
    super.key,
    required this.activeOrders,
    required this.remainingSeconds,
    required this.isAlert,
    required this.formatCountdown,
    required this.summaryForOrder,
    required this.latestLogForOrder,
    required this.onViewDetails,
    this.selectedOrderId,
  });

  @override
  Widget build(BuildContext context) {
    final visibleOrders = activeOrders
        .where((o) => (o['order_status'] ?? '').toString() != 'draft')
        .toList();

    if (visibleOrders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Center(
          child: Text(
            "No active orders",
            style: TextStyle(color: AppColors.secondaryText),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: visibleOrders.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, index) {
        final order = visibleOrders[index];
        final orderId = (order['order_id'] ?? '').toString();
        final expectedHours = (order['expected_hours'] as num?)?.toDouble() ?? 0;
        final remainingSec = remainingSeconds(order);
        final countdown = formatCountdown(remainingSec);
        final danger = remainingSec <= 0;
        final alert = isAlert(order);
        final summary = summaryForOrder(order);
        final latestLog = latestLogForOrder(order);
        final quantity = summary.totalQuantity > 0
            ? summary.totalQuantity
            : (order['quantity'] as num?)?.toInt() ?? 0;
        final completed = summary.completedQuantity;
        final pending = quantity - completed < 0 ? 0 : quantity - completed;
        final progress = quantity <= 0 ? 0.0 : completed / quantity;
        final product = [
          order['product_type'],
          order['product_category'],
        ]
            .map((value) => (value ?? '').toString().trim())
            .where((value) => value.isNotEmpty)
            .join(' | ');

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _orderCard(
            orderId: orderId,
            product: product.isEmpty ? 'No product details' : product,
            expectedHours: expectedHours,
            quantity: quantity,
            completed: completed,
            pending: pending,
            progress: progress,
            countdown: countdown,
            danger: danger,
            alert: alert,
            selected: selectedOrderId == orderId,
            latestLog: latestLog,
            onViewDetails: () => onViewDetails(order),
          ),
        );
      },
    );
  }

  Widget _orderCard({
    required String orderId,
    required String product,
    required double expectedHours,
    required int quantity,
    required int completed,
    required int pending,
    required double progress,
    required String countdown,
    required bool danger,
    required bool alert,
    required bool selected,
    required Map<String, dynamic>? latestLog,
    required VoidCallback onViewDetails,
  }) {
    final latestAt = _formatDateTime(latestLog?['created_at']);
    final latestBy = (latestLog?['actor_name'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surface(
        radius: 18,
        color: selected ? const Color(0xFFF4F0FF) : AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: kAccent,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.monitor_heart_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order $orderId",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _statusChip(
                danger ? 'Late' : 'On time',
                danger
                    ? AppColors.error
                    : alert
                    ? AppColors.accentOrange
                    : AppColors.success,
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metric("Qty", "$quantity"),
              _metric("Completed", "$completed"),
              _metric("Pending", "$pending"),
              _metric("Progress", "${(progress * 100).toStringAsFixed(0)}%"),
              _metric("Expected", formatWorkDuration(expectedHours)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Time left: $countdown",
            style: TextStyle(
              color: danger
                  ? AppColors.error
                  : alert
                  ? AppColors.accentOrange
                  : AppColors.primaryText,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            latestAt == '-'
                ? 'Last update: No tracking activity yet'
                : 'Last update: $latestAt${latestBy.isEmpty ? '' : ' by $latestBy'}',
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onViewDetails,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('View Details'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: AppDecorations.softPanel(radius: 12),
      child: Text(
        "$label: $value",
        style: const TextStyle(
          color: AppColors.primaryText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: AppDecorations.accentFill(color, radius: 999),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class ManagerOrderDetailsPanel extends StatelessWidget {
  final Map<String, dynamic>? selectedOrder;
  final bool loading;
  final String? error;
  final List<OrderItemTracking> items;
  final DepartmentProgressSummary summary;
  final List<Map<String, dynamic>> logs;

  const ManagerOrderDetailsPanel({
    super.key,
    required this.selectedOrder,
    required this.loading,
    required this.error,
    required this.items,
    required this.summary,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    final order = selectedOrder;
    final orderId = (order?['order_id'] ?? '').toString();
    final delayReason = (order?['delay_reason'] ?? '').toString().trim();

    return Glass(
      radius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveHeader(
            title: order == null
                ? 'Department Progress Details'
                : 'Progress Details - $orderId',
            subtitle: order == null
                ? 'Select an active order to inspect item progress and timeline logs.'
                : 'Read-only tracking view for this department.',
          ),
          const SizedBox(height: 16),
          if (order == null)
            const _EmptyState(
              icon: Icons.touch_app_outlined,
              message: 'Select an active order to view item progress.',
            )
          else if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 34),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            _ErrorState(message: error!)
          else ...[
            _SummaryStrip(summary: summary),
            if (delayReason.isNotEmpty) ...[
              const SizedBox(height: 12),
              _InfoBox(
                icon: Icons.warning_amber_rounded,
                title: 'Delay Reason',
                body: delayReason,
                color: AppColors.accentOrange,
              ),
            ],
            const SizedBox(height: 18),
            const Text(
              'Items',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              const _EmptyState(
                icon: Icons.inventory_outlined,
                message: 'No item records generated yet.',
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ManagerItemRow(item: item),
                ),
              ),
            const SizedBox(height: 10),
            const Text(
              'Timeline',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (logs.isEmpty)
              const _EmptyState(
                icon: Icons.timeline_outlined,
                message: 'No tracking logs yet.',
              )
            else
              ...logs.map(
                (log) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TimelineLogRow(log: log),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final DepartmentProgressSummary summary;

  const _SummaryStrip({required this.summary});

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
            spacing: 8,
            runSpacing: 8,
            children: [
              _summaryPill('Total', '${summary.totalQuantity}'),
              _summaryPill('Completed', '${summary.completedQuantity}'),
              _summaryPill('Pending', '${summary.pendingQuantity}'),
              _summaryPill(
                'Progress',
                '${summary.progressPercentage.toStringAsFixed(0)}%',
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

  Widget _summaryPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: AppDecorations.surface(radius: 12, elevated: false),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: AppColors.primaryText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ManagerItemRow extends StatelessWidget {
  final OrderItemTracking item;

  const _ManagerItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final completed = item.isCompleted;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.softPanel(radius: 14),
      child: Wrap(
        spacing: 14,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 240,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemCode,
                  overflow: TextOverflow.ellipsis,
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
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _readonlyChip(
            completed ? 'Completed' : 'Pending',
            completed ? AppColors.success : AppColors.warning,
          ),
          SizedBox(
            width: 180,
            child: Text(
              completed
                  ? 'Completed: ${_formatDateTime(item.completedAt)}'
                  : 'Not completed yet',
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 180,
            child: Text(
              item.completedByName ?? item.completedBy ?? '-',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineLogRow extends StatelessWidget {
  final Map<String, dynamic> log;

  const _TimelineLogRow({required this.log});

  @override
  Widget build(BuildContext context) {
    final eventType = (log['event_type'] ?? '').toString();
    final actor = (log['actor_name'] ?? log['actor_profile_id'] ?? '-')
        .toString();
    final remarks = (log['remarks'] ?? '').toString().trim();
    final delayReason = (log['delay_reason'] ?? '').toString().trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.softPanel(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _eventLabel(eventType),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _formatDateTime(log['created_at']),
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'By: $actor',
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (delayReason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Delay: $delayReason',
              style: const TextStyle(
                color: AppColors.accentOrange,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (remarks.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Remarks: $remarks',
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _InfoBox({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.accentFill(color, radius: 14),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$title: $body',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
      decoration: AppDecorations.softPanel(radius: 14),
      child: Column(
        children: [
          Icon(icon, color: AppColors.secondaryText, size: 32),
          const SizedBox(height: 10),
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

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return _InfoBox(
      icon: Icons.error_outline,
      title: 'Unable to load tracking data',
      body: message,
      color: AppColors.error,
    );
  }
}

Widget _readonlyChip(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: AppDecorations.accentFill(color, radius: 999),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

String _eventLabel(String value) {
  switch (value) {
    case 'item_completed':
      return 'Item completed';
    case 'department_completed':
      return 'Department completed';
    case 'delay_recorded':
      return 'Delay recorded';
    case 'remark_added':
      return 'Remark added';
    default:
      return value.replaceAll('_', ' ');
  }
}

String _formatDateTime(dynamic value) {
  if (value == null) return '-';
  final parsed = value is DateTime ? value : DateTime.tryParse(value.toString());
  if (parsed == null) return '-';
  final local = parsed.toLocal();
  final date =
      '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}

class AlertsPanel extends StatelessWidget {
  final double width;
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> nearDeadline;
  final List<Map<String, dynamic>> exceeded;
  final int Function(Map<String, dynamic>) remainingSeconds;
  final String Function(int) formatCountdown;
  final VoidCallback onClose;

  const AlertsPanel({
    super.key,
    required this.width,
    required this.title,
    required this.subtitle,
    required this.nearDeadline,
    required this.exceeded,
    required this.remainingSeconds,
    required this.formatCountdown,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.appBackground,
          border: Border(left: BorderSide(color: AppColors.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close, color: AppColors.primaryText),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _group(
                label: "Near Deadline (≤ 3 hrs)",
                items: nearDeadline,
                color: AppColors.accentOrange,
                remainingSeconds: remainingSeconds,
                formatCountdown: formatCountdown,
              ),
              const SizedBox(height: 14),
              _group(
                label: "Time Exceeded",
                items: exceeded,
                color: AppColors.error,
                remainingSeconds: remainingSeconds,
                formatCountdown: formatCountdown,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _group({
    required String label,
    required List<Map<String, dynamic>> items,
    required Color color,
    required int Function(Map<String, dynamic>) remainingSeconds,
    required String Function(int) formatCountdown,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppDecorations.surface(radius: 16, elevated: false),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              const Text(
                "No alerts",
                style: TextStyle(color: AppColors.secondaryText),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: AppColors.divider),
                  itemBuilder: (_, i) {
                    final o = items[i];
                    final orderId = (o['order_id'] ?? '').toString();
                    final sec = remainingSeconds(o);
                    final countdown = formatCountdown(sec);

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Order $orderId",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          countdown,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
