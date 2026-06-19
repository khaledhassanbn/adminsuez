import 'package:suez_admin/core/errors/not_found_page.dart';
import 'package:suez_admin/Layouts/admin_layout.dart';
import 'package:suez_admin/router/app_navigation.dart';
import 'package:suez_admin/authentication/guards/AuthGuard.dart';
import 'package:suez_admin/splash_screen.dart';
import 'package:suez_admin/authentication/pages/google_login_page.dart';
import 'package:go_router/go_router.dart';

import 'routes_config/admin_routes.dart';

/// إنشاء الـ Router الخاص بتطبيق الأدمن فقط
Future<GoRouter> createRouter(AuthGuard authGuard) async {
  try {
    await authGuard.loadUserStatus();
    authGuard.startStatusListener();

    final router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: authGuard,
      errorBuilder: (context, state) => const NotFoundPage(),
      redirect: (context, state) {
        final loggedIn = authGuard.isAuthenticated;
        final isAdmin = authGuard.userStatus == 'admin';
        final path = state.uri.path;

        // صفحة Splash — لا تحتاج حماية
        if (path == '/') return null;

        // صفحة تسجيل الدخول
        if (path == '/login') {
          // إذا كان مسجل دخول وأدمن، نوجهه للوحة التحكم
          if (loggedIn && isAdmin) return '/admin/dashboard';
          return null;
        }

        // باقي الصفحات تحتاج تسجيل دخول + أدمن
        if (!loggedIn) return '/login';
        if (!isAdmin) return '/login';

        return null;
      },
      routes: [
        // صفحة Splash الرئيسية
        GoRoute(
          path: '/',
          builder: (_, __) => const SplashScreen(),
        ),
        // صفحة تسجيل الدخول
        GoRoute(
          path: '/login',
          builder: (_, __) => const GoogleLoginPage(),
        ),
        // صفحة 404
        GoRoute(
          path: '/not-found',
          builder: (_, __) => const NotFoundPage(),
        ),
        // صفحات الأدمن داخل AdminLayout
        ShellRoute(
          builder: (context, state, child) {
            return AdminLayout(child: child);
          },
          routes: [...adminRoutes],
        ),
      ],
    );

    registerAppRouter(router);
    return router;
  } catch (e) {
    print('❌ Error creating router: $e');
    return GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const GoogleLoginPage(),
        ),
      ],
    );
  }
}
