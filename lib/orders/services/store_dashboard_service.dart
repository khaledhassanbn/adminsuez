import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:suez_admin/commission/services/commission_admin_service.dart';
import 'package:suez_admin/orders/models/store_dashboard_data.dart';
import 'package:suez_admin/stores/models/store_model.dart';

class StoreDashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CommissionAdminService _commission = CommissionAdminService();

  Future<StoreDashboardData> loadDashboard(String storeId) async {
    // معلومات المتجر + الرصيد + الحد الائتماني (نعيد استخدام خدمة العمولة)
    final store = await _commission.getStoreCommission(storeId) ??
        StoreModel(id: storeId, name: storeId, isActive: false);
    final ownerId = await _commission.getOwnerIdForStore(storeId);

    final products = await _loadProductStats(storeId);
    final orders = await _loadOrderStats(storeId);
    final invoices = await _loadInvoices(
      storeId: storeId,
      ownerId: ownerId,
      orderDocs: orders.docs,
    );

    return StoreDashboardData(
      store: store,
      totalProducts: products.total,
      activeProducts: products.active,
      suspendedProducts: products.suspended,
      totalOrders: orders.total,
      completedOrders: orders.completed,
      cancelledOrders: orders.cancelled,
      totalSales: orders.totalSales,
      totalCommissions: store.totalCommissionsPaid,
      ordersToday: orders.today,
      ordersWeek: orders.week,
      ordersMonth: orders.month,
      invoices: invoices,
    );
  }

  Future<_ProductStats> _loadProductStats(String storeId) async {
    try {
      // التكرار عبر فئات المتجر ثم عناصرها (موثوق ولا يحتاج فهرس collectionGroup)
      final categoriesSnap = await _firestore
          .collection('markets')
          .doc(storeId)
          .collection('products')
          .get();

      if (categoriesSnap.docs.isEmpty) {
        return const _ProductStats(total: 0, active: 0, suspended: 0);
      }

      // جلب عناصر كل الفئات بالتوازي
      final itemsSnaps = await Future.wait(
        categoriesSnap.docs.map(
          (cat) => cat.reference.collection('items').get(),
        ),
      );

      int total = 0;
      int active = 0;
      int suspended = 0;
      for (final itemsSnap in itemsSnaps) {
        for (final item in itemsSnap.docs) {
          total++;
          final status = item.data()['status'];
          if (status == false) {
            suspended++;
          } else {
            active++;
          }
        }
      }

      // احتياطي: إذا لم توجد عناصر لكن المتجر يسجّل totalProducts
      if (total == 0) {
        final marketDoc =
            await _firestore.collection('markets').doc(storeId).get();
        final totalProducts =
            (marketDoc.data()?['totalProducts'] as num?)?.toInt() ?? 0;
        if (totalProducts > 0) {
          return _ProductStats(
            total: totalProducts,
            active: totalProducts,
            suspended: 0,
          );
        }
      }

      return _ProductStats(
        total: total,
        active: active,
        suspended: suspended,
      );
    } catch (_) {
      return const _ProductStats(total: 0, active: 0, suspended: 0);
    }
  }

  Future<_OrderStats> _loadOrderStats(String storeId) async {
    final snap = await _firestore
        .collection('orders')
        .where('storeId', isEqualTo: storeId)
        .get();

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    int completed = 0;
    int cancelled = 0;
    int today = 0;
    int week = 0;
    int month = 0;
    double totalSales = 0;

    for (final doc in snap.docs) {
      final data = doc.data();
      final isCancelled = _isCancelled(data);
      final isCompleted = _isCompleted(data);

      if (isCancelled) cancelled++;
      if (isCompleted) {
        completed++;
        totalSales += _toD(data['totalAmount']);
      }

      final createdAt = _toDate(data['createdAt']) ?? _toDate(data['placedAt']);
      if (createdAt != null) {
        if (!createdAt.isBefore(startOfDay)) today++;
        if (!createdAt.isBefore(startOfWeek)) week++;
        if (!createdAt.isBefore(startOfMonth)) month++;
      }
    }

    return _OrderStats(
      docs: snap.docs,
      total: snap.docs.length,
      completed: completed,
      cancelled: cancelled,
      totalSales: totalSales,
      today: today,
      week: week,
      month: month,
    );
  }

  Future<List<StoreInvoiceItem>> _loadInvoices({
    required String storeId,
    required String? ownerId,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> orderDocs,
  }) async {
    final invoices = <StoreInvoiceItem>[];

    // 1) رسوم الخدمة/العمولة من الطلبات
    for (final doc in orderDocs) {
      final data = doc.data();
      final fee = _toD(data['serviceFee']);
      if (fee <= 0) continue;
      final deducted = data['commissionDeducted'] == true;
      invoices.add(
        StoreInvoiceItem(
          reference: (data['orderId'] ?? doc.id).toString(),
          date: _toDate(data['commissionDeductedAt']) ??
              _toDate(data['completedAt']) ??
              _toDate(data['createdAt']),
          type: 'رسوم خدمة (طلب)',
          amount: fee,
          statusLabel: deducted ? 'مسددة' : 'غير مسددة',
          isPaid: deducted,
        ),
      );
    }

    // 2) فواتير الاشتراك (تجديد يدوي/تلقائي) من wallet_ledger
    try {
      final ledger = await _firestore
          .collection('wallet_ledger')
          .where('storeId', isEqualTo: storeId)
          .get();
      for (final doc in ledger.docs) {
        final data = doc.data();
        final type = data['type']?.toString() ?? '';
        if (type != 'subscription_payment' && type != 'auto_renewal') continue;
        invoices.add(
          StoreInvoiceItem(
            reference: doc.id,
            date: _toDate(data['createdAt']),
            type: type == 'auto_renewal' ? 'اشتراك (تجديد تلقائي)' : 'اشتراك',
            amount: _toD(data['amount']).abs(),
            statusLabel: 'مسددة',
            isPaid: true,
          ),
        );
      }
    } catch (_) {}

    // 3) فواتير الإيداع/الشحن من wallet_transactions
    if (ownerId != null && ownerId.isNotEmpty) {
      try {
        final deposits = await _firestore
            .collection('wallet_transactions')
            .where('userId', isEqualTo: ownerId)
            .get();
        for (final doc in deposits.docs) {
          final data = doc.data();
          final status = data['status']?.toString() ?? 'pending';
          invoices.add(
            StoreInvoiceItem(
              reference: doc.id,
              date: _toDate(data['createdAt']),
              type: 'شحن محفظة',
              amount: _toD(data['amount']),
              statusLabel: _depositStatusLabel(status),
              isPaid: status == 'approved',
            ),
          );
        }
      } catch (_) {}
    }

    invoices.sort((a, b) {
      if (a.date == null && b.date == null) return 0;
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return b.date!.compareTo(a.date!);
    });
    return invoices;
  }

  String _depositStatusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'مسددة';
      case 'rejected':
        return 'مرفوضة';
      default:
        return 'معلقة';
    }
  }

  bool _isCompleted(Map<String, dynamic> data) {
    final orderStatus = (data['orderStatus'] ?? '').toString();
    final lifecycle = (data['lifecycleStatus'] ?? '').toString();
    final status = (data['status'] ?? '').toString();
    if (orderStatus == 'completed') return true;
    if (lifecycle == 'fulfilled') return true;
    if (status == 'تم التسليم للطيار' || status == 'تم التسليم') return true;
    if (status.toLowerCase() == 'delivered' ||
        status.toLowerCase() == 'completed') {
      return true;
    }
    final deliveryStatus =
        (data['deliveryRequest']?['status'] ?? '').toString();
    if (deliveryStatus == 'completed') return true;
    return false;
  }

  bool _isCancelled(Map<String, dynamic> data) {
    if (data['cancelReason'] != null &&
        data['cancelReason'].toString().isNotEmpty) {
      return true;
    }
    final orderStatus = (data['orderStatus'] ?? '').toString();
    final status = (data['status'] ?? '').toString();
    final lifecycle = (data['lifecycleStatus'] ?? '').toString();
    const cancelStatuses = {
      'cancelled',
      'cancelled_by_customer',
      'cancelled_by_merchant',
      'rejected',
    };
    if (cancelStatuses.contains(orderStatus)) return true;
    if (cancelStatuses.contains(status)) return true;
    if (lifecycle == 'cancelled') return true;
    if (status.contains('إلغاء') || status.contains('رفض')) return true;
    return false;
  }

  double _toD(dynamic v) => (v is num) ? v.toDouble() : 0.0;

  DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}

class _ProductStats {
  final int total;
  final int active;
  final int suspended;
  const _ProductStats({
    required this.total,
    required this.active,
    required this.suspended,
  });
}

class _OrderStats {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final int total;
  final int completed;
  final int cancelled;
  final double totalSales;
  final int today;
  final int week;
  final int month;
  const _OrderStats({
    required this.docs,
    required this.total,
    required this.completed,
    required this.cancelled,
    required this.totalSales,
    required this.today,
    required this.week,
    required this.month,
  });
}
