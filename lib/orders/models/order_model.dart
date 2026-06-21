import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج الطلب في تطبيق الأدمن (قراءة فقط من مجموعة orders).
/// يلتقط الحقول الأساسية مع الاحتفاظ بالبيانات الخام للرجوع إليها.
class OrderModel {
  final String id;
  final String orderId;
  final DateTime? createdAt;
  final DateTime? cancelledAt;
  final double totalAmount;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;

  // الحالة
  final String statusRaw;
  final String statusDisplay;

  // العميل
  final String customerName;
  final String customerPhone;
  final String customerId;
  final String customerAddress;

  // المتجر
  final String storeId;
  final String storeName;

  // المندوب
  final String? courierId;
  final String? courierName;

  // الإلغاء
  final String? cancelReason;

  final Map<String, dynamic> raw;

  const OrderModel({
    required this.id,
    required this.orderId,
    required this.createdAt,
    required this.cancelledAt,
    required this.totalAmount,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.statusRaw,
    required this.statusDisplay,
    required this.customerName,
    required this.customerPhone,
    required this.customerId,
    required this.customerAddress,
    required this.storeId,
    required this.storeName,
    required this.courierId,
    required this.courierName,
    required this.cancelReason,
    required this.raw,
  });

  factory OrderModel.fromDocument(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return OrderModel.fromMap(doc.id, data);
  }

  factory OrderModel.fromMap(String id, Map<String, dynamic> data) {
    double toD(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    DateTime? toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    final customerInfo =
        (data['customerInfo'] as Map<String, dynamic>?) ?? const {};
    final deliveryRequest =
        (data['deliveryRequest'] as Map<String, dynamic>?) ?? const {};
    final delivery = (data['delivery'] as Map<String, dynamic>?) ?? const {};
    final currentActor =
        (delivery['currentActor'] as Map<String, dynamic>?) ?? const {};

    // تحديد الحالة بأولوية: حالة المكتب ثم الحالة العامة
    final deliveryStatus = deliveryRequest['status']?.toString();
    final statusRaw = (deliveryStatus != null && deliveryStatus.isNotEmpty)
        ? deliveryStatus
        : (data['status']?.toString() ??
            data['orderStatus']?.toString() ??
            data['lifecycleStatus']?.toString() ??
            '');

    // اسم/معرف المندوب من عدة مصادر محتملة
    final courierId = (data['assignedCourierId'] ??
            deliveryRequest['courierId'] ??
            deliveryRequest['driverId'] ??
            deliveryRequest['assignedDriverId'] ??
            currentActor['id'])
        ?.toString();
    final courierName = (deliveryRequest['assignedDriverName'] ??
            deliveryRequest['driverName'] ??
            deliveryRequest['driver_name'] ??
            currentActor['name'])
        ?.toString();

    return OrderModel(
      id: id,
      orderId: (data['orderId'] ?? id).toString(),
      createdAt: toDate(data['createdAt']) ?? toDate(data['placedAt']),
      cancelledAt: toDate(data['cancelledAt']),
      totalAmount: toD(data['totalAmount']),
      subtotal: toD(data['subtotal']),
      deliveryFee: toD(data['deliveryFee']),
      serviceFee: toD(data['serviceFee']),
      statusRaw: statusRaw,
      statusDisplay: arabicStatus(statusRaw),
      customerName: (customerInfo['name'] ??
              data['customerName'] ??
              'غير محدد')
          .toString(),
      customerPhone: (customerInfo['phone'] ??
              data['customerPhone'] ??
              'غير محدد')
          .toString(),
      customerId:
          (customerInfo['userId'] ?? data['userId'] ?? '').toString(),
      customerAddress: (customerInfo['address'] ??
              data['customerAddress'] ??
              '')
          .toString(),
      storeId:
          (data['storeId'] ?? data['marketId'] ?? '').toString(),
      storeName: (data['storeName'] ?? 'غير محدد').toString(),
      courierId: (courierId == null || courierId.isEmpty) ? null : courierId,
      courierName:
          (courierName == null || courierName.isEmpty) ? null : courierName,
      cancelReason: data['cancelReason']?.toString(),
      raw: data,
    );
  }

  /// ترجمة قيمة الحالة (إنجليزية/مفتاح) إلى نص عربي للعرض.
  static String arabicStatus(String status) {
    switch (status) {
      // مسار التاجر
      case 'pending':
      case 'new':
        return 'قيد المراجعة';
      case 'accepted':
        return 'تم استلام الطلب';
      case 'delivering':
        return 'جارٍ التسليم للدليفري';
      case 'self_delivery':
        return 'التسليم الذاتي';
      case 'completed':
        return 'تم التسليم';
      case 'rejected':
        return 'تم رفض الطلب';
      case 'cancelled':
      case 'cancelled_by_customer':
        return 'تم إلغاء الطلب';
      case 'cancelled_by_merchant':
      case 'merchant_cancelled_order':
        return 'تم إلغاء الطلب من التاجر';
      // مسار المكتب
      case 'assigned':
        return 'تم تعيين مندوب';
      case 'driver_accepted':
        return 'المندوب قبل الطلب';
      case 'picked_up':
        return 'المندوب في الطريق';
      case 'driver_rejected':
        return 'المندوب رفض الطلب';
      case 'customer_rejected':
        return 'الزبون رفض الاستلام';
      case 'returned_to_merchant':
      case 'returned_to_store':
        return 'أُعيد للمتجر';
      case 'searching':
        return 'جارٍ البحث عن مندوب';
      // schema v2
      case 'preparing':
        return 'قيد التحضير';
      case 'ready_for_handoff':
        return 'جاهز للتسليم';
      case 'fulfilled':
        return 'تم إكمال الطلب';
      default:
        if (status.isEmpty) return 'غير معروف';
        return status;
    }
  }
}
