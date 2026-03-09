import 'dart:ui';

import 'package:fabri_sync/Model/datamodel.dart';
import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/view/dashboards/estimated_time_allorders.dart';
import 'package:fabri_sync/view/dashboards/tables/admin_table.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AdminDashboardAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const AdminDashboardAppBar({
    super.key,
    required this.onBack,
    required this.onCreateOrder,
    required this.onToggleProfile,
  });

  final VoidCallback onBack;
  final VoidCallback onCreateOrder;
  final VoidCallback onToggleProfile;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: onBack,
      ),
      title: const Text(
        'Admin Dashboard',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF111827)],
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: "Create New Order",
          icon: const Icon(Icons.add_circle_outline, color: Colors.white),
          onPressed: onCreateOrder,
        ),
        GestureDetector(
          onTap: onToggleProfile,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.account_circle, size: 32, color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
// ------------------

class NoGlowScrollBehavior extends ScrollBehavior {
  const NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
// ----------------------

BoxDecoration glassCard() {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    color: Colors.white.withOpacity(0.05),
    border: Border.all(color: Colors.white.withOpacity(0.12)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

class GlassOverlayCard extends StatelessWidget {
  const GlassOverlayCard({super.key, required this.width, required this.child});

  final double width;
  final Widget child;

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

class ProfileRow extends StatelessWidget {
  const ProfileRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text.isEmpty ? "-" : text,
            style: const TextStyle(fontSize: 15, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
// -----------------------------

class KpiSection extends StatelessWidget {
  const KpiSection({
    super.key,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required this.inProgress,
    required this.pending,
    required this.completed,
    required this.glassCard,
  });

  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final int inProgress;
  final int pending;
  final int completed;
  final BoxDecoration Function() glassCard;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _kpiCard(
        title: 'In Progress',
        value: inProgress.toString(),
        icon: Icons.autorenew_rounded,
        color: Colors.orange,
      ),
      _kpiCard(
        title: 'Pending',
        value: pending.toString(),
        icon: Icons.warning_amber,
        color: Colors.red,
      ),
      _kpiCard(
        title: 'Completed',
        value: completed.toString(),
        icon: Icons.check_circle_outline,
        color: Colors.green,
      ),
    ];

    if (isDesktop) {
      return GridView.builder(
        itemCount: cards.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          mainAxisExtent: 120,
        ),
        itemBuilder: (_, i) => cards[i],
      );
    }

    if (isTablet) {
      return GridView.builder(
        itemCount: cards.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 120,
        ),
        itemBuilder: (_, i) => cards[i],
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final cardW = (c.maxWidth * 0.78).clamp(220.0, 320.0);

        return SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, i) => SizedBox(width: cardW, child: cards[i]),
          ),
        );
      },
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        final valueFont = h < 110 ? 22.0 : 28.0;
        final titleFont = h < 110 ? 12.0 : 14.0;
        final iconSize = h < 110 ? 26.0 : 30.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: glassCard(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: iconSize),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: valueFont,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: titleFont,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ----------------------
class DepartmentProgressSection extends StatelessWidget {
  const DepartmentProgressSection({
    super.key,
    required this.isMobile,
    required this.allOrders,
    required this.glassCard,
  });

  final bool isMobile;
  final List<OrderModel> allOrders;
  final BoxDecoration Function() glassCard;

  @override
  Widget build(BuildContext context) {
    final activeOrders = allOrders
        .where((o) => o.status.toLowerCase() != "completed")
        .toList();

    final Map<String, int> countByDept = {};
    for (final dept in Department.values) {
      final dbDept = _deptDbName(dept);
      countByDept[dbDept] = activeOrders
          .where((o) => o.currentDepartment.toUpperCase() == dbDept)
          .length;
    }

    int maxCount = 0;
    for (final c in countByDept.values) {
      if (c > maxCount) maxCount = c;
    }

    return _cardWrapper(
      title: 'Department Progress Overview',
      child: Column(
        children: Department.values.map((dept) {
          final dbDept = _deptDbName(dept);
          final count = countByDept[dbDept] ?? 0;
          final progress = maxCount == 0 ? 0.0 : (count / maxCount);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: isMobile ? 92 : 140,
                  child: Text(
                    dbDept,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      color: _progressColor(progress),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "$count",
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _progressColor(double value) {
    if (value >= 0.8) return Colors.greenAccent;
    if (value >= 0.4) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String _deptDbName(Department dept) => dept.name.toUpperCase();

  Widget _cardWrapper({String? title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}

// --------------------------------
class EstimatedTimeSection extends StatelessWidget {
  const EstimatedTimeSection({
    super.key,
    required this.perUnitDeptHours,
    required this.orders,
    required this.formatToDaysHours,
    required this.glassCard,
  });

  final Map<String, double> perUnitDeptHours;
  final List<OrderModel> orders;
  final String Function(double) formatToDaysHours;
  final BoxDecoration Function() glassCard;

  @override
  Widget build(BuildContext context) {
    final OrderModel? latestOrder = orders.isNotEmpty ? orders.first : null;

    if (latestOrder == null) {
      return _cardWrapper(
        title: 'Estimated Remaining Time (By Department)',
        child: const Text(
          "No orders available",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    const orderedDepts = [
      'CUTTING',
      'STITCHING',
      'THREADING',
      'QUALITY_CONTROL',
      'PACKING',
      'INSPECTION',
    ];

    String norm(String d) => d.trim().toUpperCase().replaceAll(' ', '_');

    final normalizedPerUnit = <String, double>{};
    perUnitDeptHours.forEach((dept, hrs) {
      normalizedPerUnit[norm(dept)] = hrs;
    });

    final calculated = <String, double>{};
    for (final dept in orderedDepts) {
      final perUnit = normalizedPerUnit[dept] ?? 0.0;
      calculated[dept] = perUnit * latestOrder.quantity;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final isNarrow = c.maxWidth < 520;

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estimated Remaining Time (By Department)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EstimatedTimeAllOrdersScreen(
                                allOrders: orders,
                                perUnitDeptHours: perUnitDeptHours,
                                formatToDaysHours: formatToDaysHours,
                                glassCard: glassCard(),
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'View All Orders',
                          style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                            decorationThickness: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Estimated Remaining Time (By Department)',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EstimatedTimeAllOrdersScreen(
                            allOrders: orders,
                            perUnitDeptHours: perUnitDeptHours,
                            formatToDaysHours: formatToDaysHours,
                            glassCard: glassCard(),
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'View All Orders',
                      style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                        decorationThickness: 2,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            "Order: ${latestOrder.orderId}  •  Qty: ${latestOrder.quantity}",
            style: TextStyle(color: Colors.white.withOpacity(0.75)),
          ),
          const SizedBox(height: 16),
          Column(
            children: orderedDepts.map((dept) {
              final hrs = calculated[dept] ?? 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        dept,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      formatToDaysHours(hrs),
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _cardWrapper({String? title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}
// ----------------------------

class QueueEfficiencySection extends StatelessWidget {
  const QueueEfficiencySection({
    super.key,
    required this.context,
    required this.isDesktop,
    required this.allOrders,
    required this.glassCard,
  });

  final BuildContext context;
  final bool isDesktop;
  final List<OrderModel> allOrders;
  final BoxDecoration Function() glassCard;

  @override
  Widget build(BuildContext context) {
    return isDesktop
        ? Row(
            children: [
              Expanded(child: _orderQueue(context)),
              const SizedBox(width: 20),
              Expanded(child: _efficiencyPanel()),
            ],
          )
        : Column(
            children: [
              _orderQueue(context),
              const SizedBox(height: 20),
              _efficiencyPanel(),
            ],
          );
  }

  Widget _orderQueue(BuildContext context) {
    final preview = allOrders.take(4).toList();

    return _cardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Order Queue Overview',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TableScreen(department: Department.cutting),
                    ),
                  );
                },
                child: const Text(
                  'View Full',
                  style: TextStyle(
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                    decorationThickness: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < 420;
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ID',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Department',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Status',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.white24),
                    ...preview.map(
                      (o) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.orderId,
                              style: const TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              o.currentDepartment,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              o.status,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Divider(color: Colors.white12),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Order ID',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Department',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Status',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white24),
                  ...preview.map(
                    (o) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              o.orderId,
                              style: const TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              o.currentDepartment,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              o.status,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _efficiencyPanel() {
    const orderedDepts = [
      'CUTTING',
      'STITCHING',
      'THREADING',
      'QUALITY_CONTROL',
      'PACKING',
      'INSPECTION',
    ];

    final List<Color> deptColors = [
      Colors.greenAccent,
      Colors.blueAccent,
      Colors.amberAccent,
      Colors.redAccent,
      Colors.purpleAccent,
      Colors.cyanAccent,
    ];

    String norm(String d) => d.trim().toUpperCase().replaceAll(' ', '_');

    final Map<String, int> countByDept = {for (final d in orderedDepts) d: 0};

    for (final o in allOrders) {
      final key = norm(o.currentDepartment.toString());
      if (countByDept.containsKey(key)) {
        countByDept[key] = (countByDept[key] ?? 0) + 1;
      }
    }

    return _cardWrapper(
      title: 'Production Efficiency',
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final h = (c.maxWidth * 0.55).clamp(180.0, 240.0);
              return SizedBox(
                height: h,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 45,
                    sections: orderedDepts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final dept = entry.value;
                      final count = countByDept[dept] ?? 0;

                      return PieChartSectionData(
                        value: count == 0 ? 0.1 : count.toDouble(),
                        color: deptColors[index % deptColors.length],
                        title: '',
                        radius: 55,
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 22,
            runSpacing: 12,
            children: orderedDepts.asMap().entries.map((entry) {
              final index = entry.key;
              final dept = entry.value;
              final count = countByDept[dept] ?? 0;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: deptColors[index % deptColors.length],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$dept ($count)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _cardWrapper({String? title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}
