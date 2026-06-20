import 'package:flutter/material.dart';
import 'package:suez_admin/packages/create_package_page.dart';
import 'package:suez_admin/packages/manage_packages_page.dart';
import 'package:suez_admin/stores/stores_list_page.dart';
import 'package:suez_admin/categories/manage_categories_page.dart';
import 'package:suez_admin/categories/create_edit_category_page.dart';
import 'package:suez_admin/dashboard/dashboard_page.dart';
import 'package:suez_admin/ads/views/admin_ads_page.dart';
import 'package:suez_admin/ads/views/admin_ad_requests_page.dart';
import 'package:suez_admin/offices/offices_list_page.dart';
import 'package:suez_admin/offices/create_edit_office_page.dart';
import 'package:suez_admin/delivery_fee/delivery_fee_settings_page.dart';
import 'package:suez_admin/courier_requests/courier_requests_page.dart';
import 'package:suez_admin/courier_requests/courier_request_detail_page.dart';
import 'package:suez_admin/account/pages/account_page.dart';
import 'package:suez_admin/reports/models/user_report.dart';
import 'package:suez_admin/reports/pages/reports_list_page.dart';
import 'package:suez_admin/reports/pages/report_detail_page.dart';
import 'package:suez_admin/security/pages/deleted_accounts_page.dart';
import 'package:suez_admin/security/pages/admin_roles_page.dart';
import 'package:suez_admin/activity_logs/pages/activity_logs_page.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:suez_admin/authentication/guards/AuthGuard.dart';

// Guard function to check if user is admin
bool isAdminRoute(BuildContext context) {
  final authGuard = Provider.of<AuthGuard>(context, listen: false);
  return authGuard.userStatus == 'admin';
}

final adminRoutes = [
  GoRoute(
    path: '/admin/dashboard',
    builder: (context, state) => const DashboardPage(),
  ),
  GoRoute(
    path: '/admin/create-package',
    builder: (context, state) => const CreatePackagePage(),
  ),
  GoRoute(
    path: '/admin/manage-packages',
    builder: (context, state) => const ManagePackagesPage(),
  ),
  GoRoute(
    path: '/admin/stores',
    builder: (context, state) => const StoresListPage(),
  ),
  GoRoute(
    path: '/admin/manage-categories',
    builder: (context, state) => const ManageCategoriesPage(),
  ),
  GoRoute(
    path: '/admin/create-category',
    builder: (context, state) => const CreateEditCategoryPage(),
  ),
  GoRoute(
    path: '/admin/edit-category/:categoryId',
    builder: (context, state) {
      final categoryId = state.pathParameters['categoryId']!;
      return CreateEditCategoryPage(categoryId: categoryId);
    },
  ),
  GoRoute(
    path: '/admin/ads',
    builder: (context, state) => const AdminAdsPage(),
  ),
  GoRoute(
    path: '/admin/ad-requests',
    builder: (context, state) => const AdminAdRequestsPage(),
  ),
  GoRoute(
    path: '/admin/offices',
    builder: (context, state) => const OfficesListPage(),
  ),
  GoRoute(
    path: '/admin/create-office',
    builder: (context, state) => const CreateEditOfficePage(),
  ),
  GoRoute(
    path: '/admin/edit-office/:officeId',
    builder: (context, state) {
      final officeId = state.pathParameters['officeId']!;
      return CreateEditOfficePage(officeId: officeId);
    },
  ),
  GoRoute(
    path: '/admin/delivery-fee-settings',
    builder: (context, state) => const DeliveryFeeSettingsPage(),
  ),
  GoRoute(
    path: '/admin/courier-requests',
    builder: (context, state) => const CourierRequestsPage(),
  ),
  GoRoute(
    path: '/admin/courier-request/:requestId',
    builder: (context, state) {
      final requestId = state.pathParameters['requestId']!;
      final extraData = state.extra as Map<String, dynamic>?;
      return CourierRequestDetailPage(
        requestId: requestId,
        initialData: extraData,
      );
    },
  ),
  // صفحة الحساب
  GoRoute(
    path: '/AccountPage',
    builder: (context, state) => const AccountPage(),
  ),
  // البلاغات
  GoRoute(
    path: '/admin/reports',
    builder: (context, state) => const ReportsListPage(),
  ),
  GoRoute(
    path: '/admin/reports/:reportId',
    builder: (context, state) {
      final report = state.extra as UserReport;
      return ReportDetailPage(report: report);
    },
  ),
  GoRoute(
    path: '/admin/roles',
    builder: (context, state) => const AdminRolesPage(),
  ),
  GoRoute(
    path: '/admin/add-admin',
    builder: (context, state) => const AddAdminPage(),
  ),
  GoRoute(
    path: '/admin/deleted-accounts',
    builder: (context, state) => const DeletedAccountsPage(),
  ),
  GoRoute(
    path: '/admin/activity-logs',
    builder: (context, state) => const ActivityLogsPage(),
  ),
];
