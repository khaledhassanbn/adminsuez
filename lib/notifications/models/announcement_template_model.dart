import 'package:cloud_firestore/cloud_firestore.dart';
import 'announcement_model.dart';

/// نموذج قالب الإعلان الجاهز
class AnnouncementTemplateModel {
  final String id;
  final String name; // اسم القالب (للأدمن)
  final String title; // عنوان القالب
  final String body; // نص القالب (يدعم {{userName}} وغيرها)
  final String? imageUrl;
  final AnnouncementCTA? cta;
  final String category; // welcome | renewal | suspension | order | promotion | custom
  final bool isActive;
  final int usageCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  AnnouncementTemplateModel({
    required this.id,
    required this.name,
    required this.title,
    required this.body,
    this.imageUrl,
    this.cta,
    required this.category,
    this.isActive = true,
    this.usageCount = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory AnnouncementTemplateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementTemplateModel(
      id: doc.id,
      name: data['name'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      imageUrl: data['imageUrl'],
      cta: data['cta'] != null
          ? AnnouncementCTA.fromMap(data['cta'] as Map<String, dynamic>)
          : null,
      category: data['category'] ?? 'custom',
      isActive: data['isActive'] ?? true,
      usageCount: (data['usageCount'] ?? 0) as int,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'cta': cta?.toMap(),
      'category': category,
      'isActive': isActive,
      'usageCount': usageCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  /// تحويل التصنيف إلى نص عربي
  String get categoryLabel {
    switch (category) {
      case 'welcome':
        return 'ترحيب';
      case 'renewal':
        return 'تجديد';
      case 'suspension':
        return 'إيقاف';
      case 'order':
        return 'طلبات';
      case 'promotion':
        return 'عروض';
      case 'custom':
        return 'مخصص';
      default:
        return category;
    }
  }

  /// قائمة التصنيفات المتاحة
  static const List<Map<String, String>> categories = [
    {'value': 'welcome', 'label': 'ترحيب'},
    {'value': 'renewal', 'label': 'تجديد'},
    {'value': 'suspension', 'label': 'إيقاف'},
    {'value': 'order', 'label': 'طلبات'},
    {'value': 'promotion', 'label': 'عروض'},
    {'value': 'custom', 'label': 'مخصص'},
  ];
}
