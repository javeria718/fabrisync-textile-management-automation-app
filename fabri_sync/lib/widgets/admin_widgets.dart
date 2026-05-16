import 'package:fabri_sync/Model/datamodel.dart';
import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/utils/work_duration_formatter.dart';
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
    required this.onOpenDraftOrders,
    required this.onToggleProfile,
  });

  final VoidCallback onBack;
  final VoidCallback onCreateOrder;
  final VoidCallback onOpenDraftOrders;
  final VoidCallback onToggleProfile;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Responsive font sizing
    final titleFontSize = isMobile ? 16.0 : 20.0;

    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.primaryText,
        ),
        onPressed: onBack,
      ),
      title: Text(
        'Admin Dashboard',
        style: TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
      ),
      actions: [
        IconButton(
          tooltip: "Create New Order",
          icon: const Icon(
            Icons.add_circle_outline,
            color: AppColors.primaryAccent,
          ),
          onPressed: onCreateOrder,
        ),
        IconButton(
          tooltip: "Draft Orders",
          icon: const Icon(Icons.drafts_outlined, color: AppColors.primaryText),
          onPressed: onOpenDraftOrders,
        ),
        GestureDetector(
          onTap: onToggleProfile,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.account_circle,
              size: 32,
              color: AppColors.primaryText,
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

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

BoxDecoration glassCard() => AppDecorations.surface(radius: 20);

String _deptLabel(String value) {
  final dept = value.trim().toUpperCase();
  if (dept == 'QUALITY_CONTROL') return 'Quality Control';
  if (dept == 'PACKAGING') return 'Packaging';
  if (dept.isEmpty) return '-';
  return dept;
}

class GlassOverlayCard extends StatelessWidget {
  const GlassOverlayCard({super.key, required this.width, required this.child});

  final double width;
  final Widget child;

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

class ProfileRow extends StatelessWidget {
  const ProfileRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: AppDecorations.accentFill(
            AppColors.accentBlue,
            radius: 12,
          ),
          child: Icon(icon, size: 18, color: AppColors.accentBlue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text.isEmpty ? "-" : text,
            style: const TextStyle(fontSize: 15, color: AppColors.primaryText),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

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
        color: AppColors.accentBlue,
      ),
      _kpiCard(
        title: 'Pending',
        value: pending.toString(),
        icon: Icons.warning_amber,
        color: AppColors.accentOrange,
      ),
      _kpiCard(
        title: 'Completed',
        value: completed.toString(),
        icon: Icons.check_circle_outline,
        color: AppColors.accentGreen,
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
          mainAxisExtent: 140,
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
          mainAxisExtent: 130,
        ),
        itemBuilder: (_, i) => cards[i],
      );
    }

    // Mobile: Responsive horizontal scroll layout
    return LayoutBuilder(
      builder: (context, c) {
        final cardW = (c.maxWidth * 0.78).clamp(180.0, 280.0);
        final cardH = 120.0;
        return SizedBox(
          height: cardH + 16,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) =>
                SizedBox(width: cardW, height: cardH, child: cards[i]),
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
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final maxWidth = constraints.maxWidth;

        // Responsive sizing based on available space
        final isVeryCompact = maxHeight <= 100;
        final isCompact = maxHeight <= 120;

        // Icon sizing
        final iconBoxSize = isVeryCompact ? 36.0 : (isCompact ? 40.0 : 44.0);
        final iconSize = isVeryCompact ? 18.0 : (isCompact ? 20.0 : 24.0);

        // Font sizing with conservative scaling to prevent overflow
        final valueFontSize = isVeryCompact ? 14.0 : (isCompact ? 16.0 : 22.0);
        final titleFontSize = isVeryCompact ? 9.0 : (isCompact ? 10.0 : 12.0);

        // Spacing sizing
        final padding = isVeryCompact ? 10.0 : (isCompact ? 12.0 : 14.0);
        final gap = isVeryCompact ? 6.0 : (isCompact ? 8.0 : 10.0);
        final titleGap = isVeryCompact ? 2.0 : 4.0;

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: glassCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon container
              Container(
                width: iconBoxSize,
                height: iconBoxSize,
                decoration: AppDecorations.accentFill(color),
                child: Icon(icon, color: color, size: iconSize),
              ),
              SizedBox(height: gap),
              // Content: value and title
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Value (KPI number)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxWidth - (padding * 2),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            value,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: valueFontSize,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: titleGap),
                      // Title
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxWidth - (padding * 2),
                        ),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            color: AppColors.secondaryText,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
        .where(
          (o) =>
              o.status.toLowerCase() != "completed" &&
              o.status.toLowerCase() != "draft",
        )
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
                    _deptLabel(dbDept),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
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
                      backgroundColor: AppColors.surfaceMuted,
                      color: _progressColor(progress),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "$count",
                  style: const TextStyle(color: AppColors.secondaryText),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _progressColor(double value) {
    if (value >= 0.8) return AppColors.accentGreen;
    if (value >= 0.4) return AppColors.accentOrange;
    return AppColors.accentPink;
  }

  String _deptDbName(Department dept) => dept.name.toUpperCase();

  String _deptLabel(String value) {
    if (value == 'QUALITY_CONTROL') return 'Quality Control';
    if (value == 'PACKAGING') return 'Packaging';
    return value;
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
                color: AppColors.primaryText,
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

class EstimatedTimeSection extends StatelessWidget {
  const EstimatedTimeSection({
    super.key,
    required this.storedDeptHoursByOrder,
    required this.orders,
    required this.glassCard,
  });

  final Map<String, Map<String, double>> storedDeptHoursByOrder;
  final List<OrderModel> orders;
  final BoxDecoration Function() glassCard;

  @override
  Widget build(BuildContext context) {
    final nonDraftOrders = orders
        .where((o) => o.status.toLowerCase() != 'draft')
        .toList();
    final OrderModel? latestOrder = nonDraftOrders.isNotEmpty
        ? nonDraftOrders.first
        : null;

    if (latestOrder == null) {
      return _cardWrapper(
        title: 'Estimated Remaining Time (By Department)',
        child: const Text(
          "No orders available",
          style: TextStyle(color: AppColors.secondaryText),
        ),
      );
    }

    const orderedDepts = [
      'CUTTING',
      'STITCHING',
      'THREADING',
      'QUALITY_CONTROL',
      'PACKAGING',
      'INSPECTION',
    ];

    final calculated = _storedDepartmentHoursForOrder(
      latestOrder,
      orderedDepts,
    );
    final hasEstimate = calculated.values.any((hrs) => hrs > 0);

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
                        color: AppColors.primaryText,
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
                                allOrders: nonDraftOrders,
                                storedDeptHoursByOrder: storedDeptHoursByOrder,
                                glassCard: glassCard(),
                              ),
                            ),
                          );
                        },
                        child: const Text('View All Orders'),
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
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EstimatedTimeAllOrdersScreen(
                            allOrders: nonDraftOrders,
                            storedDeptHoursByOrder: storedDeptHoursByOrder,
                            glassCard: glassCard(),
                          ),
                        ),
                      );
                    },
                    child: const Text('View All Orders'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            "Order: ${latestOrder.orderId}  •  Qty: ${latestOrder.quantity}",
            style: const TextStyle(color: AppColors.secondaryText),
          ),
          const SizedBox(height: 16),
          if (!hasEstimate)
            const Text(
              'No stored estimate available',
              style: TextStyle(color: AppColors.secondaryText),
            )
          else
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
                          _deptLabel(dept),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        formatWorkDuration(hrs),
                        style: const TextStyle(color: AppColors.secondaryText),
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
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }

  Map<String, double> _storedDepartmentHoursForOrder(
    OrderModel order,
    List<String> orderedDepts,
  ) {
    String norm(String d) => d.trim().toUpperCase().replaceAll(' ', '_');

    final stored = <String, double>{};
    order.estimatedDeptHours?.forEach((dept, hrs) {
      stored[norm(dept)] = hrs;
    });

    if (stored.values.any((hrs) => hrs > 0)) {
      return {for (final dept in orderedDepts) dept: stored[dept] ?? 0.0};
    }

    storedDeptHoursByOrder[order.orderId]?.forEach((dept, hrs) {
      stored[norm(dept)] = hrs;
    });

    if (stored.values.any((hrs) => hrs > 0)) {
      return {for (final dept in orderedDepts) dept: stored[dept] ?? 0.0};
    }
    return {};
  }
}

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
    final nonDraftOrders = allOrders
        .where((o) => o.status.toLowerCase() != 'draft')
        .toList();
    final preview = nonDraftOrders.take(4).toList();

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
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TableScreen()),
                  );
                },
                child: const Text('View Full'),
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
                    _headerText('Order ID'),
                    const SizedBox(height: 6),
                    _headerText('Department'),
                    const SizedBox(height: 6),
                    _headerText('Status'),
                    const SizedBox(height: 8),
                    const Divider(color: AppColors.divider),
                    ...preview.map(
                      (o) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.orderId,
                              style: const TextStyle(
                                color: AppColors.primaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _deptLabel(o.currentDepartment),
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              o.status,
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Divider(color: AppColors.divider),
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
                      Expanded(child: _headerText('Order ID')),
                      Expanded(child: _headerText('Department')),
                      Expanded(child: _headerText('Status')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: AppColors.divider),
                  ...preview.map(
                    (o) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              o.orderId,
                              style: const TextStyle(
                                color: AppColors.primaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _deptLabel(o.currentDepartment),
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              o.status,
                              style: const TextStyle(
                                color: AppColors.secondaryText,
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
      'PACKAGING',
      'INSPECTION',
    ];

    final List<Color> deptColors = [
      AppColors.primaryAccent,
      AppColors.accentBlue,
      AppColors.accentGreen,
      AppColors.accentOrange,
      AppColors.accentYellow,
      AppColors.accentPink,
    ];

    String norm(String d) => d.trim().toUpperCase().replaceAll(' ', '_');

    final Map<String, int> countByDept = {for (final d in orderedDepts) d: 0};

    for (final o in allOrders.where(
      (order) => order.status.toLowerCase() != 'draft',
    )) {
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
                    '${_deptLabel(dept)} ($count)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryText,
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

  Widget _headerText(String text) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
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
                color: AppColors.primaryText,
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
