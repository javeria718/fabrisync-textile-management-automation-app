import 'dart:ui';
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
                  color: Colors.white,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.70),
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
                      color: Colors.white,
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
                style: TextStyle(
                  color: Colors.white.withOpacity(0.70),
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
// -----------------

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
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassOverlayCard extends StatelessWidget {
  final double width;
  final Widget child;

  const GlassOverlayCard({super.key, required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// --------------------
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
      _kpiCard(
        "Total",
        total.toString(),
        Icons.inventory_2_outlined,
        Colors.cyanAccent,
      ),
      _kpiCard(
        "In Progress",
        inProgress.toString(),
        Icons.autorenew_rounded,
        Colors.orangeAccent,
      ),
      _kpiCard(
        "Completed",
        completed.toString(),
        Icons.check_circle_outline,
        Colors.greenAccent,
      ),
      _kpiCard(
        "Late",
        late.toString(),
        Icons.warning_amber_rounded,
        Colors.redAccent,
      ),
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
              Icon(icon, color: color, size: iconSize),
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
                        color: Colors.white,
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
                        color: Colors.white.withOpacity(0.70),
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
// -------------------------------------------

class QueuePreviewTable extends StatelessWidget {
  final List<Map<String, dynamic>> queuePreview;
  final String Function(dynamic) formatDate;
  final String Function(dynamic) formatTime;

  const QueuePreviewTable({
    super.key,
    required this.queuePreview,
    required this.formatDate,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    if (queuePreview.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            "No history yet",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(children: [_h("Order ID"), _h("In"), _h("Out"), _h("Status")]),
        const SizedBox(height: 10),
        Divider(color: Colors.white.withOpacity(0.14)),
        ...queuePreview.map((o) {
          final status = (o['status'] ?? '').toString();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    (o['order_id'] ?? '').toString(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "${formatDate(o['date_in'])}\n${formatTime(o['time_in'])}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "${formatDate(o['date_out'])}\n${formatTime(o['time_out'])}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    status,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.82),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
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
        style: TextStyle(color: Colors.white.withOpacity(0.60), fontSize: 12),
      ),
    );
  }
}
// --------------------------

class ActiveOrdersList extends StatelessWidget {
  final List<Map<String, dynamic>> activeOrders;
  final int Function(Map<String, dynamic>) remainingSeconds;
  final bool Function(Map<String, dynamic>) isAlert;
  final String Function(int) formatCountdown;
  final Future<void> Function(Map<String, dynamic>) onComplete;

  static const List<Color> kAccent = [Color(0xFF0EA5E9), Color(0xFF2563EB)];

  const ActiveOrdersList({
    super.key,
    required this.activeOrders,
    required this.remainingSeconds,
    required this.isAlert,
    required this.formatCountdown,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (activeOrders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Center(
          child: Text(
            "No active orders",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: activeOrders.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, index) {
        final o = activeOrders[index];
        final orderId = (o['order_id'] ?? '').toString();
        final expectedHours = (o['expected_hours'] as num).toDouble();
        final qty = (o['quantity'] ?? 0).toString();

        final remainingSec = remainingSeconds(o);
        final countdown = formatCountdown(remainingSec);

        final danger = remainingSec <= 0;
        final alert = isAlert(o);

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _orderGlassCard(
            orderId: orderId,
            expectedHours: expectedHours,
            quantity: qty,
            countdown: countdown,
            danger: danger,
            alert: alert,
            onComplete: () => onComplete(o),
          ),
        );
      },
    );
  }

  Widget _orderGlassCard({
    required String orderId,
    required double expectedHours,
    required String quantity,
    required String countdown,
    required bool danger,
    required bool alert,
    required VoidCallback onComplete,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kAccent[0].withOpacity(0.90),
                      kAccent[1].withOpacity(0.90),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.receipt_long, color: Colors.white),
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
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Expected: ${expectedHours.toStringAsFixed(1)} hrs",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Qty: $quantity",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      countdown,
                      style: TextStyle(
                        color: danger
                            ? Colors.redAccent
                            : alert
                            ? Colors.amberAccent
                            : Colors.white.withOpacity(0.92),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: danger ? Colors.redAccent : Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  elevation: 0,
                ),
                onPressed: onComplete,
                child: const Text("Complete"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// --------------------

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
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.22),
          border: Border(
            left: BorderSide(color: Colors.white.withOpacity(0.12)),
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
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
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.70),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _group(
                    label: "Near Deadline (≤ 3 hrs)",
                    items: nearDeadline,
                    color: Colors.amberAccent,
                    remainingSeconds: remainingSeconds,
                    formatCountdown: formatCountdown,
                  ),
                  const SizedBox(height: 14),
                  _group(
                    label: "Time Exceeded",
                    items: exceeded,
                    color: Colors.redAccent,
                    remainingSeconds: remainingSeconds,
                    formatCountdown: formatCountdown,
                  ),
                ],
              ),
            ),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
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
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (items.isEmpty)
                  Text(
                    "No alerts",
                    style: TextStyle(color: Colors.white.withOpacity(0.70)),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: Colors.white.withOpacity(0.12)),
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
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              countdown,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
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
        ),
      ),
    );
  }
}
