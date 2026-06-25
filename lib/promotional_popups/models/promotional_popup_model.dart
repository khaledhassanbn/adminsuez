import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج الإعلان المنبثق داخل التطبيق
class PromotionalPopupModel {
  final String id;
  final String? title;
  final String? description;
  final String imageUrl; // إجبارية
  final PromotionalPopupCTA? cta;
  final String targetAudience; // all | merchants | craftsmen | drivers | customers
  final bool isActive;
  final int priority; // الأعلى يظهر أولاً
  final DateTime startDate;
  final DateTime endDate;
  final int maxImpressions; // 0 = بلا حد
  final bool isDismissible;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  PromotionalPopupModel({
    required this.id,
    this.title,
    this.description,
    required this.imageUrl,
    this.cta,
    required this.targetAudience,
    this.isActive = true,
    this.priority = 0,
    required this.startDate,
    required this.endDate,
    this.maxImpressions = 0,
    this.isDismissible = true,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory PromotionalPopupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PromotionalPopupModel(
      id: doc.id,
      title: data['title'],
      description: data['description'],
      imageUrl: data['imageUrl'] ?? '',
      cta: data['cta'] != null
          ? PromotionalPopupCTA.fromMap(data['cta'] as Map<String, dynamic>)
          : null,
      targetAudience: data['targetAudience'] ?? 'all',
      isActive: data['isActive'] ?? true,
      priority: (data['priority'] ?? 0) as int,
      startDate:
          (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      maxImpressions: (data['maxImpressions'] ?? 0) as int,
      isDismissible: data['isDismissible'] ?? true,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'cta': cta?.toMap(),
      'targetAudience': targetAudience,
      'isActive': isActive,
      'priority': priority,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'maxImpressions': maxImpressions,
      'isDismissible': isDismissible,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  /// هل الإعلان نشط حالياً (ضمن المدة + مفعّل)
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// تحويل targetAudience إلى نص عربي
  String get targetAudienceLabel {
    switch (targetAudience) {
      case 'all':
        return 'الجميع';
      case 'merchants':
        return 'أصحاب المتاجر';
      case 'craftsmen':
        return 'الحرفيين';
      case 'drivers':
        return 'المناديب';
      case 'customers':
        return 'العملاء';
      default:
        return targetAudience;
    }
  }
}

/// نموذج CTA للإعلان المنبثق
class PromotionalPopupCTA {
  final String type; // open_store | open_product | open_order | open_page | external_link
  final String value;

  PromotionalPopupCTA({
    required this.type,
    required this.value,
  });

  factory PromotionalPopupCTA.fromMap(Map<String, dynamic> map) {
    return PromotionalPopupCTA(
      type: map['type'] ?? 'open_page',
      value: map['value'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'value': value,
    };
  }
}
