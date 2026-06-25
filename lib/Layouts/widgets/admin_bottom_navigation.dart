import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_color.dart';

class AdminBottomNavigation extends StatelessWidget {
  final int currentIndex;
  const AdminBottomNavigation({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _handleTap(context, index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.mainColor,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'الرئيسية',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics),
          label: 'الإحصائيات',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.support_agent_outlined),
          activeIcon: Icon(Icons.support_agent),
          label: 'الدعم الفني',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'حسابي',
        ),
      ],
    );
  }

  void _handleTap(BuildContext context, int index) {
    final currentRoute = GoRouterState.of(context).matchedLocation;

    switch (index) {
      case 0:
        // الرئيسية
        if (currentRoute != '/admin/dashboard') {
          context.go('/admin/dashboard');
        }
        break;
      case 1:
        // الإحصائيات
        if (currentRoute != '/admin/stats-dashboard') {
          context.go('/admin/stats-dashboard');
        }
        break;
      case 2:
        // الدعم الفني
        if (!currentRoute.startsWith('/admin/support')) {
          context.go('/admin/support');
        }
        break;
      case 3:
        // حسابي
        if (currentRoute != '/AccountPage') {
          context.go('/AccountPage');
        }
        break;
    }
  }
}
