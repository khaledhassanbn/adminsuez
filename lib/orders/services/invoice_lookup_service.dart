import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:suez_admin/orders/models/invoice_details.dart';
import 'package:suez_admin/orders/models/order_model.dart';
import 'package:suez_admin/orders/services/order_lookup_service.dart';

/// البحث عن فاتورة افتراضية برقمها.
/// فواتير الطلبات تعرض تفاصيل الطلب الكاملة (مندوب، حالة، مراحل).
class InvoiceLookupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OrderLookupService _orderLookup = OrderLookupService();

  Future<InvoiceDetails?> lookup(String number) async {
    final id = number.trim();
    if (id.isEmpty) return null;

    // 1) طلب (رسوم خدمة) — بحث برقم الطلب أو معرّف المستند
    final order = await _orderLookup.getOrder(id);
    if (order != null) {
      return _fromOrder(order);
    }

    // 2) سجل محفظة (اشتراك/عمولة/تعديل يدوي)
    final ledgerDoc =
        await _firestore.collection('wallet_ledger').doc(id).get();
    if (ledgerDoc.exists) {
      return _fromLedger(ledgerDoc);
    }

    // 3) طلب شحن (إيداع)
    final txDoc =
        await _firestore.collection('wallet_transactions').doc(id).get();
    if (txDoc.exists) {
      return await _fromTransaction(txDoc);
    }

    return null;
  }

  Future<InvoiceDetails> _fromOrder(OrderModel order) async {
    final data = order.raw;
    final fee = order.serviceFee > 0
        ? order.serviceFee
        : _toD(data['serviceFee']);
    final deducted = data['commissionDeducted'] == true;

    final timeline = await _orderLookup.getTimeline(order);
    String? courierName = order.courierName;
    if (courierName == null && order.courierId != null) {
      courierName = await _orderLookup.resolveCourierName(order.courierId!);
    }

    return InvoiceDetails(
      number: order.orderId,
      kind: InvoiceKind.order,
      type: 'رسوم خدمة (طلب)',
      amount: fee,
      date: _toDate(data['commissionDeductedAt']) ??
          _toDate(data['completedAt']) ??
          order.createdAt,
      statusLabel: deducted ? 'مسددة' : 'غير مسددة',
      isPaid: deducted,
      storeId: order.storeId,
      storeName: order.storeName,
      extraFields: const [],
      order: order,
      timeline: timeline,
      courierName: courierName,
    );
  }

  Future<InvoiceDetails> _fromLedger(DocumentSnapshot doc) async {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final storeId = (data['storeId'] ?? '').toString();
    final type = (data['type'] ?? '').toString();
    final metadata = (data['metadata'] as Map<String, dynamic>?) ?? const {};

    return InvoiceDetails(
      number: doc.id,
      kind: InvoiceKind.ledger,
      type: _ledgerTypeLabel(type),
      amount: _toD(data['amount']).abs(),
      date: _toDate(data['createdAt']),
      statusLabel: 'مسددة',
      isPaid: true,
      storeId: storeId,
      storeName: await _storeName(storeId),
      extraFields: [
        if ((data['description'] ?? '').toString().isNotEmpty)
          InvoiceField('الوصف', data['description'].toString()),
        InvoiceField('الرصيد قبل',
            '${_toD(data['balanceBefore']).toStringAsFixed(2)} جنيه'),
        InvoiceField('الرصيد بعد',
            '${_toD(data['balanceAfter']).toStringAsFixed(2)} جنيه'),
        if ((metadata['packageName'] ?? '').toString().isNotEmpty)
          InvoiceField('الباقة', metadata['packageName'].toString()),
        if ((data['referenceId'] ?? '').toString().isNotEmpty)
          InvoiceField('المرجع', data['referenceId'].toString()),
      ],
    );
  }

  Future<InvoiceDetails> _fromTransaction(DocumentSnapshot doc) async {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final userId = (data['userId'] ?? '').toString();
    final status = (data['status'] ?? 'pending').toString();

    String storeId = '';
    String storeName = '—';
    if (userId.isNotEmpty) {
      final q = await _firestore
          .collection('markets')
          .where('ownerId', isEqualTo: userId)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) {
        storeId = q.docs.first.id;
        storeName = (q.docs.first.data()['name'] ?? storeId).toString();
      }
    }

    return InvoiceDetails(
      number: doc.id,
      kind: InvoiceKind.deposit,
      type: 'شحن محفظة (إيداع)',
      amount: _toD(data['amount']),
      date: _toDate(data['createdAt']),
      statusLabel: _depositStatusLabel(status),
      isPaid: status == 'approved',
      storeId: storeId,
      storeName: storeName,
      extraFields: [
        if ((data['phoneNumber'] ?? '').toString().isNotEmpty)
          InvoiceField('رقم الهاتف', data['phoneNumber'].toString()),
        if ((data['notes'] ?? '').toString().isNotEmpty)
          InvoiceField('ملاحظات', data['notes'].toString()),
      ],
    );
  }

  Future<String> _storeName(String storeId) async {
    if (storeId.isEmpty) return '—';
    try {
      final doc = await _firestore.collection('markets').doc(storeId).get();
      final name = (doc.data()?['name'] ?? '').toString();
      return name.isEmpty ? storeId : name;
    } catch (_) {
      return storeId;
    }
  }

  String _ledgerTypeLabel(String type) {
    switch (type) {
      case 'subscription_payment':
        return 'اشتراك';
      case 'auto_renewal':
        return 'اشتراك (تجديد تلقائي)';
      case 'order_commission':
        return 'عمولة طلب';
      case 'manual_adjustment':
        return 'تعديل يدوي';
      case 'refund':
        return 'استرداد';
      case 'wallet_recharge':
        return 'شحن محفظة';
      default:
        return type;
    }
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

  double _toD(dynamic v) => (v is num) ? v.toDouble() : 0.0;

  DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}
