import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج الإعلان/الإشعار
class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String deliveryType; // push_only | in_app_only | both
  final String targetAudience; // all | merchants | craftsmen | offices | drivers | customers | custom | individual
  final String? targetUserId; // للإرسال الفردي
  final String? targetUserName;
  final String? targetUserType;
  final Map<String, dynamic>? targetFilter;
  final String? templateId;
  final AnnouncementCTA? cta;
  final String status; // draft | scheduled | sending | sent | failed | partial
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime createdAt;
  final String createdBy;
  final String createdByName;
  final String idempotencyKey;
  final AnnouncementStats stats;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.deliveryType,
    required this.targetAudience,
    this.targetUserId,
    this.targetUserName,
    this.targetUserType,
    this.targetFilter,
    this.templateId,
    this.cta,
    required this.status,
    this.scheduledAt,
    this.sentAt,
    required this.createdAt,
    required this.createdBy,
    required this.createdByName,
    required this.idempotencyKey,
    required this.stats,
  });

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      imageUrl: data['imageUrl'],
      deliveryType: data['deliveryType'] ?? 'both',
      targetAudience: data['targetAudience'] ?? 'all',
      targetUserId: data['targetUserId'],
      targetUserName: data['targetUserName'],
      targetUserType: data['targetUserType'],
      targetFilter: data['targetFilter'] as Map<String, dynamic>?,
      templateId: data['templateId'],
      cta: data['cta'] != null
          ? AnnouncementCTA.fromMap(data['cta'] as Map<String, dynamic>)
          : null,
      status: data['status'] ?? 'draft',
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate(),
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      idempotencyKey: data['idempotencyKey'] ?? '',
      stats: AnnouncementStats.fromMap(
        data['stats'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'deliveryType': deliveryType,
      'targetAudience': targetAudience,
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'targetUserType': targetUserType,
      'targetFilter': targetFilter,
      'templateId': templateId,
      'cta': cta?.toMap(),
      'status': status,
      'scheduledAt':
          scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'idempotencyKey': idempotencyKey,
      'stats': stats.toMap(),
    };
  }

  /// تحويل targetAudience إلى نص عربي للعرض
  String get targetAudienceLabel {
    switch (targetAudience) {
      case 'all':
        return 'الجميع';
      case 'merchants':
        return 'أصحاب المتاجر';
      case 'craftsmen':
        return 'الحرفيين';
      case 'offices':
        return 'مكاتب الشحن';
      case 'drivers':
        return 'المناديب';
      case 'customers':
        return 'العملاء';
      case 'individual':
        return 'مستخدم محدد: ${targetUserName ?? targetUserId ?? ''}';
      case 'custom':
        return 'مخصص';
      default:
        return targetAudience;
    }
  }

  /// تحويل deliveryType إلى نص عربي
  String get deliveryTypeLabel {
    switch (deliveryType) {
      case 'push_only':
        return 'إشعار فوري فقط';
      case 'in_app_only':
        return 'رسالة داخلية فقط';
      case 'both':
        return 'إشعار فوري + رسالة داخلية';
      default:
        return deliveryType;
    }
  }

  /// تحويل status إلى نص عربي
  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'مسودة';
      case 'scheduled':
        return 'مجدول';
      case 'sending':
        return 'جاري الإرسال';
      case 'sent':
        return 'تم الإرسال';
      case 'failed':
        return 'فشل';
      case 'partial':
        return 'إرسال جزئي';
      default:
        return status;
    }
  }
}

/// نموذج زر الإجراء (Call To Action)
class AnnouncementCTA {
  final String type; // open_page | open_store | open_order | open_product | external_link
  final String label;
  final String value;

  AnnouncementCTA({
    required this.type,
    required this.label,
    required this.value,
  });

  factory AnnouncementCTA.fromMap(Map<String, dynamic> map) {
    return AnnouncementCTA(
      type: map['type'] ?? 'open_page',
      label: map['label'] ?? '',
      value: map['value'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'label': label,
      'value': value,
    };
  }

  /// تحويل type إلى نص عربي
  String get typeLabel {
    switch (type) {
      case 'open_page':
        return 'فتح صفحة';
      case 'open_store':
        return 'فتح متجر';
      case 'open_order':
        return 'فتح طلب';
      case 'open_product':
        return 'فتح منتج';
      case 'external_link':
        return 'رابط خارجي';
      default:
        return type;
    }
  }
}

/// نموذج الإحصائيات المجمعة
class AnnouncementStats {
  final int targetedCount;
  final int pushSentCount;
  final int pushFailedCount;
  final int inAppReadCount;

  AnnouncementStats({
    this.targetedCount = 0,
    this.pushSentCount = 0,
    this.pushFailedCount = 0,
    this.inAppReadCount = 0,
  });

  factory AnnouncementStats.fromMap(Map<String, dynamic> map) {
    return AnnouncementStats(
      targetedCount: _asInt(map['targetedCount']),
      pushSentCount: _asInt(map['pushSentCount']),
      pushFailedCount: _asInt(map['pushFailedCount']),
      inAppReadCount: _asInt(map['inAppReadCount']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'targetedCount': targetedCount,
      'pushSentCount': pushSentCount,
      'pushFailedCount': pushFailedCount,
      'inAppReadCount': inAppReadCount,
    };
  }

  /// نسبة نجاح الإرسال
  double get successRate {
    if (targetedCount == 0) return 0;
    return (pushSentCount / targetedCount) * 100;
  }
}

/// نموذج سجل الأخطاء
class AnnouncementErrorLog {
  final String id;
  final String announcementId;
  final String errorType;
  final String errorMessage;
  final int failedTokensCount;
  final List<String> sampleFailedTokens;
  final DateTime timestamp;

  AnnouncementErrorLog({
    required this.id,
    required this.announcementId,
    required this.errorType,
    required this.errorMessage,
    required this.failedTokensCount,
    required this.sampleFailedTokens,
    required this.timestamp,
  });

  factory AnnouncementErrorLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementErrorLog(
      id: doc.id,
      announcementId: data['announcementId'] ?? '',
      errorType: data['errorType'] ?? '',
      errorMessage: data['errorMessage'] ?? '',
      failedTokensCount: AnnouncementStats._asInt(data['failedTokensCount']),
      sampleFailedTokens:
          List<String>.from(data['sampleFailedTokens'] ?? []),
      timestamp:
          (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
