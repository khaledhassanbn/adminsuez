import 'package:suez_admin/orders/models/order_model.dart';
import 'package:suez_admin/orders/services/order_lookup_service.dart';

enum InvoiceKind { order, ledger, deposit }

/// صف معلومات (مفتاح/قيمة) لعرضه ضمن تفاصيل الفاتورة.
class InvoiceField {
  final String label;
  final String value;
  const InvoiceField(this.label, this.value);
}

/// تفاصيل فاتورة افتراضية بعد البحث عنها برقمها.
class InvoiceDetails {
  final String number;
  final InvoiceKind kind;
  final String type;
  final double amount;
  final DateTime? date;
  final String statusLabel;
  final bool isPaid;
  final String storeId;
  final String storeName;
  final List<InvoiceField> extraFields;

  /// بيانات الطلب الكاملة (لفواتير رسوم الخدمة)
  final OrderModel? order;
  final List<OrderTimelineEntry>? timeline;
  final String? courierName;

  const InvoiceDetails({
    required this.number,
    required this.kind,
    required this.type,
    required this.amount,
    required this.date,
    required this.statusLabel,
    required this.isPaid,
    required this.storeId,
    required this.storeName,
    required this.extraFields,
    this.order,
    this.timeline,
    this.courierName,
  });

  bool get isOrderInvoice => kind == InvoiceKind.order && order != null;
}
