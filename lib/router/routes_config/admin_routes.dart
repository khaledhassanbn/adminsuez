import 'package:flutter/material.dart';
import 'package:suez_admin/packages/create_package_page.dart';
import 'package:suez_admin/packages/manage_packages_page.dart';
import 'package:suez_admin/stores/stores_list_page.dart';
import 'package:suez_admin/categories/manage_categories_page.dart';
import 'package:suez_admin/categories/create_edit_category_page.dart';
import 'package:suez_admin/dashboard/dashboard_page.dart';
import 'package:suez_admin/dashboard/sales_analytics_page.dart';
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
import 'package:suez_admin/support/pages/support_dashboard_page.dart';
import 'package:suez_admin/support/pages/support_conversations_page.dart';
import 'package:suez_admin/support/pages/admin_chat_page.dart';
import 'package:suez_admin/commission/pages/commission_settings_page.dart';
import 'package:suez_admin/commission/pages/wallet_management_page.dart';
import 'package:suez_admin/commission/pages/store_commission_page.dart';
import 'package:suez_admin/finance/pages/finance_ledger_page.dart';
import 'package:suez_admin/orders/pages/order_lookup_page.dart';
import 'package:suez_admin/orders/pages/store_dashboard_page.dart';
import 'package:suez_admin/orders/pages/invoice_lookup_page.dart';

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
    path: '/admin/sales-analytics',
    builder: (context, state) => const SalesAnalyticsPage(),
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
  // مركز الدعم
  GoRoute(
    path: '/admin/support',
    builder: (context, state) => const SupportDashboardPage(),
  ),
  GoRoute(
    path: '/admin/support/conversations',
    builder: (context, state) {
      final statusFilter = state.uri.queryParameters['status'];
      return SupportConversationsPage(initialStatusFilter: statusFilter);
    },
  ),
  GoRoute(
    path: '/admin/support/chat/:conversationId',
    builder: (context, state) {
      final conversationId = state.pathParameters['conversationId']!;
      return AdminChatPage(conversationId: conversationId);
    },
  ),
  GoRoute(
    path: '/admin/commission-settings',
    builder: (context, state) => const CommissionSettingsPage(),
  ),
  GoRoute(
    path: '/admin/wallet-management',
    builder: (context, state) => const WalletManagementPage(),
  ),
  GoRoute(
    path: '/admin/store-commission/:storeId',
    builder: (context, state) {
      final storeId = state.pathParameters['storeId']!;
      return StoreCommissionPage(storeId: storeId);
    },
  ),
  GoRoute(
    path: '/admin/finance-ledger',
    builder: (context, state) => const FinanceLedgerPage(),
  ),
  GoRoute(
    path: '/admin/order-lookup',
    builder: (context, state) {
      final orderId = state.uri.queryParameters['orderId'];
      return OrderLookupPage(initialOrderId: orderId);
    },
  ),
  GoRoute(
    path: '/admin/store-dashboard/:storeId',
    builder: (context, state) {
      final storeId = state.pathParameters['storeId']!;
      return StoreDashboardPage(storeId: storeId);
    },
  ),
  GoRoute(
    path: '/admin/invoice-lookup',
    builder: (context, state) {
      final number = state.uri.queryParameters['number'];
      return InvoiceLookupPage(initialNumber: number);
    },
  ),
];
