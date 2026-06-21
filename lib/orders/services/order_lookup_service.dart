import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:suez_admin/orders/models/order_model.dart';

/// عنصر واحد في الخط الزمني (Timeline) للطلب.
class OrderTimelineEntry {
  final String title;
  final DateTime? time;
  final String? actor; // من قام بالتغيير (نص عربي)
  final String? reason; // سبب (مثل سبب الإلغاء)
  final String source; // statusHistory | events

  const OrderTimelineEntry({
    required this.title,
    required this.time,
    this.actor,
    this.reason,
    required this.source,
  });
}

class OrderLookupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// جلب الطلب برقمه (وهو نفسه معرّف المستند).
  Future<OrderModel?> getOrder(String orderId) async {
    final trimmed = orderId.trim();
    if (trimmed.isEmpty) return null;

    final doc = await _firestore.collection('orders').doc(trimmed).get();
    if (doc.exists) {
      return OrderModel.fromDocument(doc);
    }

    // محاولة احتياطية: البحث بحقل orderId
    final query = await _firestore
        .collection('orders')
        .where('orderId', isEqualTo: trimmed)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return OrderModel.fromDocument(query.docs.first);
    }
    return null;
  }

  /// سجل الحالات الكامل: دمج statusHistory مع subcollection events.
  Future<List<OrderTimelineEntry>> getTimeline(OrderModel order) async {
    final entries = <OrderTimelineEntry>[];

    // 1) statusHistory داخل المستند
    final history = order.raw['statusHistory'];
    if (history is List) {
      for (final item in history) {
        if (item is Map) {
          final status = item['status']?.toString() ?? '';
          entries.add(
            OrderTimelineEntry(
              title: OrderModel.arabicStatus(status),
              time: _toDate(item['time']),
              actor: _actorArabic(item['by']?.toString()),
              reason: null,
              source: 'statusHistory',
            ),
          );
        }
      }
    }

    // 2) subcollection events (Schema v2)
    try {
      final eventsSnap = await _firestore
          .collection('orders')
          .doc(order.id)
          .collection('events')
          .orderBy('timestamp')
          .get();
      for (final doc in eventsSnap.docs) {
        final data = doc.data();
        final type = data['type']?.toString() ?? '';
        final metadata =
            (data['metadata'] as Map<String, dynamic>?) ?? const {};
        entries.add(
          OrderTimelineEntry(
            title: _eventArabic(type),
            time: _toDate(data['timestamp']),
            actor: _actorArabic(data['actorType']?.toString()),
            reason: (metadata['reason'] ??
                    metadata['cancelReason'] ??
                    metadata['payload']?['reason'])
                ?.toString(),
            source: 'events',
          ),
        );
      }
    } catch (_) {
      // الـ subcollection قد لا تكون موجودة للطلبات القديمة
    }

    // إضافة سبب الإلغاء كعنصر صريح إن لم يظهر في الأحداث
    if (order.cancelReason != null && order.cancelReason!.isNotEmpty) {
      final hasCancel = entries.any((e) =>
          e.title.contains('إلغاء') || (e.reason?.isNotEmpty ?? false));
      if (!hasCancel) {
        entries.add(
          OrderTimelineEntry(
            title: 'تم إلغاء الطلب',
            time: order.cancelledAt,
            actor: null,
            reason: _cancelReasonArabic(order.cancelReason!),
            source: 'events',
          ),
        );
      }
    }

    // ترتيب تصاعدي بالزمن (العناصر بدون وقت في النهاية)
    entries.sort((a, b) {
      if (a.time == null && b.time == null) return 0;
      if (a.time == null) return 1;
      if (b.time == null) return -1;
      return a.time!.compareTo(b.time!);
    });

    return entries;
  }

  /// محاولة جلب اسم المندوب من courier_requests عند توفر المعرف فقط.
  Future<String?> resolveCourierName(String courierId) async {
    if (courierId.isEmpty) return null;
    try {
      // مباشرة بمعرف المستند
      final byDoc =
          await _firestore.collection('courier_requests').doc(courierId).get();
      if (byDoc.exists) {
        final d = byDoc.data() ?? {};
        final name = (d['name'] ?? d['fullName'] ?? d['courierName'])
            ?.toString();
        if (name != null && name.isNotEmpty) return name;
      }
      // البحث بحقل courierUid / uid
      for (final field in ['courierUid', 'uid', 'userId']) {
        final q = await _firestore
            .collection('courier_requests')
            .where(field, isEqualTo: courierId)
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) {
          final d = q.docs.first.data();
          final name = (d['name'] ?? d['fullName'] ?? d['courierName'])
              ?.toString();
          if (name != null && name.isNotEmpty) return name;
        }
      }
    } catch (_) {}
    return null;
  }

  DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  String? _actorArabic(String? actor) {
    switch (actor) {
      case 'customer':
        return 'العميل';
      case 'merchant':
        return 'التاجر';
      case 'courier':
        return 'المندوب';
      case 'office':
        return 'المكتب';
      case 'admin':
        return 'الأدمن';
      case 'system':
        return 'النظام';
      default:
        return null;
    }
  }

  String _eventArabic(String type) {
    switch (type) {
      case 'order.placed':
        return 'تم إنشاء الطلب';
      case 'order.merchant_accepted':
        return 'قبِل التاجر الطلب';
      case 'order.merchant_rejected':
        return 'رفض التاجر الطلب';
      case 'order.preparation_started':
        return 'بدأ تحضير الطلب';
      case 'order.ready_for_handoff':
        return 'الطلب جاهز للتسليم';
      case 'order.fulfilled':
        return 'تم إكمال الطلب';
      case 'order.cancelled':
        return 'تم إلغاء الطلب';
      case 'delivery.mode_selected':
        return 'تم اختيار طريقة التوصيل';
      case 'delivery.search_started':
        return 'بدأ البحث عن مندوب';
      case 'delivery.completed':
        return 'تم التوصيل';
      case 'delivery.failed':
        return 'فشل التوصيل';
      case 'delivery.returned_to_store':
        return 'أُعيد الطلب للمتجر';
      case 'admin.override':
        return 'تدخّل إداري';
      case 'escalation.needs_attention_90':
        return 'تنبيه: تأخّر الطلب';
      default:
        return type;
    }
  }

  String _cancelReasonArabic(String reason) {
    switch (reason) {
      case 'cancelled_by_customer':
        return 'إلغاء من العميل';
      case 'merchant_sent_to_office':
        return 'أرسل التاجر الطلب لمكتب';
      case 'merchant_delivering_self':
        return 'التاجر يسلّم بنفسه';
      case 'merchant_cancelled_order':
        return 'إلغاء من التاجر';
      default:
        return reason;
    }
  }
}
