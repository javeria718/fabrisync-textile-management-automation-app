import 'package:fabri_sync/controllers/admin_controller.dart';
import 'package:fabri_sync/services/auth_navigation_service.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:fabri_sync/view/dashboards/draft_orders.dart';
import 'package:fabri_sync/view/newOrder/orderInput.dart';
import 'package:fabri_sync/widgets/admin_widgets.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final AdminDashboardController controller;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = AdminDashboardController()..addListener(_onCtrl);
    controller.init();
  }

  void _onCtrl() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onCtrl);
    controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        final isMobile = w < 600;
        final isTablet = w >= 600 && w < 1024;
        final isDesktop = w >= 1024;
        final isWide = w >= 1400;

        final horizontalPad = isWide
            ? 48.0
            : isDesktop
            ? 32.0
            : isTablet
            ? 22.0
            : 14.0;

        final verticalPad = isDesktop ? 24.0 : 16.0;

        final maxContentWidth = isWide
            ? 1320.0
            : isDesktop
            ? 1180.0
            : double.infinity;

        final activeDashboardOrders = controller.allOrders
            .where((o) => o.status.toLowerCase() != 'draft')
            .toList();

        final inProgress = activeDashboardOrders
            .where((o) => o.status.toLowerCase() == 'inprogress')
            .length;

        final pending = activeDashboardOrders
            .where(
              (o) =>
                  o.status.toLowerCase() == 'pending' ||
                  o.status.toLowerCase() == 'delayed',
            )
            .length;

        final completed = activeDashboardOrders
            .where((o) => o.status.toLowerCase() == 'completed')
            .length;

        final profileCardWidth = (w * 0.33).clamp(260.0, 340.0);

        return Scaffold(
          backgroundColor: AppColors.appBackground,
          appBar: AdminDashboardAppBar(
            onBack: () async {
              await AuthNavigationService.logoutAndNavigate(context, 'admin');
            },
            onCreateOrder: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderInputScreen()),
              );
            },
            onOpenDraftOrders: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DraftOrdersScreen()),
              );
            },
            onToggleProfile: controller.toggleProfileCard,
          ),
          body: controller.loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryAccent,
                  ),
                )
              : Stack(
                  children: [
                    Positioned.fill(
                      child: gradientOrderBackground(
                        child: const SizedBox.expand(),
                      ),
                    ),
                    Positioned.fill(
                      child: SafeArea(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: maxContentWidth,
                            ),
                            child: ScrollConfiguration(
                              behavior: const NoGlowScrollBehavior(),
                              child: ListView(
                                controller: _scrollController,
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPad,
                                  vertical: verticalPad,
                                ),
                                children: [
                                  KpiSection(
                                    isMobile: isMobile,
                                    isTablet: isTablet,
                                    isDesktop: isDesktop,
                                    inProgress: inProgress,
                                    pending: pending,
                                    completed: completed,
                                    glassCard: glassCard,
                                  ),
                                  const SizedBox(height: 22),
                                  DepartmentProgressSection(
                                    isMobile: isMobile,
                                    allOrders: activeDashboardOrders,
                                    glassCard: glassCard,
                                  ),
                                  const SizedBox(height: 22),
                                  EstimatedTimeSection(
                                    storedDeptHoursByOrder:
                                        controller.storedDeptHoursByOrder,
                                    orders: activeDashboardOrders,
                                    glassCard: glassCard,
                                  ),
                                  const SizedBox(height: 22),
                                  QueueEfficiencySection(
                                    context: context,
                                    isDesktop: isDesktop,
                                    allOrders: activeDashboardOrders,
                                    glassCard: glassCard,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (controller.showProfileCard)
                      Positioned(
                        top: kToolbarHeight + 10,
                        right: 16,
                        child: Material(
                          color: Colors.transparent,
                          child: GlassOverlayCard(
                            width: profileCardWidth,
                            child: controller.profile == null
                                ? const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      'Loading profile...',
                                      style: TextStyle(
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ProfileRow(
                                        icon: Icons.person,
                                        text:
                                            (controller.profile!['full_name'] ??
                                                    '')
                                                .toString(),
                                      ),
                                      const SizedBox(height: 10),
                                      ProfileRow(
                                        icon: Icons.email,
                                        text:
                                            (controller.profile!['email'] ?? '')
                                                .toString(),
                                      ),
                                      const SizedBox(height: 10),
                                      ProfileRow(
                                        icon: Icons.phone,
                                        text:
                                            (controller.profile!['phone_number'] ??
                                                    '')
                                                .toString(),
                                      ),
                                      const SizedBox(height: 14),
                                      const Divider(color: AppColors.divider),
                                      const SizedBox(height: 12),
                                      GestureDetector(
                                        onTap: () async {
                                          if (!mounted) return;
                                          await AuthNavigationService.logoutAndNavigate(
                                            context,
                                            'admin',
                                          );
                                        },
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppColors.error,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Text(
                                            'Logout',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
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
      },
    );
  }
}
