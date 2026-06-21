import 'package:suez_admin/stores/models/store_model.dart';

/// فاتورة افتراضية مشتقة من البيانات الموجودة (طلبات/اشتراكات/إيداعات).
class StoreInvoiceItem {
  final String reference;
  final DateTime? date;
  final String type;
  final double amount;
  final String statusLabel;
  final bool isPaid;

  const StoreInvoiceItem({
    required this.reference,
    required this.date,
    required this.type,
    required this.amount,
    required this.statusLabel,
    required this.isPaid,
  });
}

/// كل بيانات لوحة متجر واحد.
class StoreDashboardData {
  final StoreModel store;

  // المنتجات
  final int totalProducts;
  final int activeProducts;
  final int suspendedProducts;

  // الطلبات
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double totalSales;
  final double totalCommissions;

  // إحصائيات زمنية
  final int ordersToday;
  final int ordersWeek;
  final int ordersMonth;

  // الفواتير
  final List<StoreInvoiceItem> invoices;

  const StoreDashboardData({
    required this.store,
    required this.totalProducts,
    required this.activeProducts,
    required this.suspendedProducts,
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.totalSales,
    required this.totalCommissions,
    required this.ordersToday,
    required this.ordersWeek,
    required this.ordersMonth,
    required this.invoices,
  });

  double get walletBalance => store.walletBalance ?? 0.0;
  double get creditLimit => store.creditLimit;
}
