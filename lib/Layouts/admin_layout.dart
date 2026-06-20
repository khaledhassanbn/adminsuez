import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'widgets/admin_bottom_navigation.dart';
import 'package:suez_admin/router/widgets/app_back_guard.dart';
import 'package:suez_admin/support/viewmodels/admin_support_viewmodel.dart';

/// Layout wrapper for admin pages that adds bottom navigation bar
/// Similar to MarketLayout - wraps child in Scaffold with bottom nav
class AdminLayout extends StatelessWidget {
  final Widget child;
  const AdminLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getIndexFromRoute(context);
    final viewModel = context.watch<AdminSupportViewModel>();

    if (viewModel.newTicketAlertName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final alertName = viewModel.newTicketAlertName;
        if (alertName != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.campaign_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'تذكرة دعم جديدة من: $alertName',
                    style: const TextStyle(fontFamily: 'Tajawal'),
                  ),
                ],
              ),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'عرض',
                textColor: Colors.white,
                onPressed: () {
                  context.push('/admin/support');
                },
              ),
            ),
          );
          viewModel.clearAlert();
        }
      });
    }

    // Wrap child in Scaffold with bottom navigation bar
    // Child pages should not have their own Scaffold to avoid nesting
    return AppBackGuard(
      homePath: '/admin/dashboard',
      child: Scaffold(
        body: child,
        bottomNavigationBar: AdminBottomNavigation(currentIndex: currentIndex),
      ),
    );
  }

  int _getIndexFromRoute(BuildContext context) {
    final route = GoRouterState.of(context).matchedLocation;
    if (route.startsWith('/admin/dashboard')) {
      return 0;
    }
    if (route.startsWith('/admin/create-package') ||
        route.startsWith('/admin/manage-packages') ||
        route.startsWith('/admin/manage-categories') ||
        route.startsWith('/admin/create-category') ||
        route.startsWith('/admin/edit-category')) {
      return 1;
    }
    if (route.startsWith('/admin/stores')) {
      return 2;
    }
    if (route.startsWith('/AccountPage')) {
      return 3;
    }
    // الصفحة الافتراضية (لوحة التحكم)
    return 0;
  }
}
