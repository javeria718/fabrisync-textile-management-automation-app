import 'package:fabri_sync/utils/customcolors.dart';
import 'package:flutter/material.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String department;
  final bool hasAlerts;
  final VoidCallback onAlertsTap;
  final VoidCallback onProfileTap;

  const DashboardAppBar({
    super.key,
    required this.department,
    required this.hasAlerts,
    required this.onAlertsTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.primaryText,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      elevation: 0,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppGradients.adminAccent,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              departmentIcon(department),
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              prettyDepartment(department),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Alerts',
          icon: Stack(
            children: [
              const Icon(
                Icons.notifications_none,
                color: AppColors.primaryText,
              ),
              if (hasAlerts)
                Positioned(
                  right: 0,
                  top: 2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),
          onPressed: onAlertsTap,
        ),
        GestureDetector(
          onTap: onProfileTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.account_circle,
              size: 32,
              color: AppColors.primaryText,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// class DashboardDepartmentInfo extends StatelessWidget {
//   final String department;
//   final String role;

//   const DashboardDepartmentInfo({
//     super.key,
//     required this.department,
//     required this.role,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final pretty = prettyDepartment(department);
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: AppDecorations.surface(radius: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: 44,
//                 height: 44,
//                 decoration: BoxDecoration(
//                   color: AppColors.primaryAccent.withOpacity(0.12),
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 child: const Icon(
//                   Icons.business_center,
//                   color: AppColors.primaryAccent,
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 14),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       '$pretty Operations Dashboard',
//                       style: const TextStyle(
//                         color: AppColors.primaryText,
//                         fontSize: 18,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       '$role • $pretty Department',
//                       style: const TextStyle(
//                         color: AppColors.secondaryText,
//                         fontSize: 13,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             decoration: AppDecorations.accentFill(
//               AppColors.accentBlue,
//               radius: 999,
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(
//                   Icons.apartment_outlined,
//                   size: 16,
//                   color: AppColors.accentBlue,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   '$pretty Department',
//                   style: const TextStyle(
//                     color: AppColors.accentBlue,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
class DashboardDepartmentInfo extends StatelessWidget {
  final String department;
  final String role;

  const DashboardDepartmentInfo({
    super.key,
    required this.department,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final pretty = prettyDepartment(department);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.surface(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.business_center,
                  color: AppColors.primaryAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operations Dashboard',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '$role Panel',
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: AppDecorations.accentFill(
              AppColors.accentBlue,
              radius: 999,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.apartment_outlined,
                  size: 16,
                  color: AppColors.accentBlue,
                ),

                const SizedBox(width: 8),

                Text(
                  pretty,
                  style: const TextStyle(
                    color: AppColors.accentBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardKpiSection extends StatelessWidget {
  final bool isDesktop;
  final List<DashboardKpiItem> items;
  final String title;

  const DashboardKpiSection({
    super.key,
    required this.isDesktop,
    required this.items,
    this.title = 'Department Overview',
  });

  @override
  Widget build(BuildContext context) {
    final cards = items.map((item) {
      return _buildKpiCard(item);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.surface(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          if (isDesktop)
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              childAspectRatio: 2.35,
              children: cards,
            )
          else
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cards.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (_, index) =>
                    SizedBox(width: 220, child: cards[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(DashboardKpiItem item) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final h = constraints.maxHeight;
        final pad = h < 82
            ? 8.0
            : h < 95
            ? 10.0
            : h < 105
            ? 12.0
            : 16.0;
        final iconSize = h < 82
            ? 20.0
            : h < 95
            ? 22.0
            : h < 105
            ? 24.0
            : 28.0;
        final valueSize = h < 82
            ? 18.0
            : h < 95
            ? 20.0
            : h < 105
            ? 22.0
            : 26.0;
        final titleSize = h < 82
            ? 10.0
            : h < 95
            ? 11.0
            : h < 105
            ? 11.5
            : 13.0;
        final gap = h < 95 ? 2.0 : 4.0;

        return Container(
          padding: EdgeInsets.all(pad),
          decoration: AppDecorations.surface(radius: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: AppDecorations.accentFill(item.color),
                child: Icon(item.icon, color: item.color, size: iconSize),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.value,
                          style: TextStyle(
                            fontSize: valueSize,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: gap),

                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: titleSize,
                            color: AppColors.secondaryText,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DashboardKpiItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardKpiItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

String prettyDepartment(String dept) {
  final value = dept.trim().toUpperCase();
  if (value.isEmpty) return 'Department';
  switch (value) {
    case 'QUALITY_CONTROL':
      return 'Quality Control';
    case 'PACKAGING':
      return 'Packaging';
    default:
      return value[0] + value.substring(1).toLowerCase();
  }
}

IconData departmentIcon(String dept) {
  switch (dept.trim().toUpperCase()) {
    case 'CUTTING':
      return Icons.cut;
    case 'STITCHING':
      return Icons.design_services;
    case 'THREADING':
      return Icons.settings;
    case 'QUALITY_CONTROL':
      return Icons.verified_outlined;
    case 'PACKAGING':
      return Icons.inventory_2_outlined;
    default:
      return Icons.engineering;
  }
}
