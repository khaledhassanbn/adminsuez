import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/announcement_template_model.dart';

/// خدمة إدارة قوالب الإعلانات
class TemplateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'announcement_templates';

  // ═══════════════════════════════════════════════════════════════
  // CRUD للقوالب
  // ═══════════════════════════════════════════════════════════════

  /// إنشاء قالب جديد
  Future<String> createTemplate(AnnouncementTemplateModel template) async {
    final docRef = _firestore.collection(_collection).doc();
    final data = template.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['createdBy'] = _auth.currentUser?.uid ?? '';
    await docRef.set(data);
    return docRef.id;
  }

  /// تعديل قالب
  Future<void> updateTemplate(
      String id, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection(_collection).doc(id).update(updates);
  }

  /// تفعيل/تعطيل قالب
  Future<void> toggleTemplateActive(String id, bool isActive) async {
    await _firestore.collection(_collection).doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// حذف قالب
  Future<void> deleteTemplate(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// زيادة عداد الاستخدام
  Future<void> incrementUsageCount(String id) async {
    await _firestore.collection(_collection).doc(id).update({
      'usageCount': FieldValue.increment(1),
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // استعلامات وقراءة البيانات
  // ═══════════════════════════════════════════════════════════════

  /// Stream لجميع القوالب
  Stream<List<AnnouncementTemplateModel>> getTemplatesStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AnnouncementTemplateModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Stream للقوالب المفعّلة فقط (للاستخدام في Dropdown)
  Stream<List<AnnouncementTemplateModel>> getActiveTemplatesStream() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AnnouncementTemplateModel.fromFirestore(doc))
          .toList();
    });
  }

  /// فلترة حسب التصنيف
  Stream<List<AnnouncementTemplateModel>> getTemplatesByCategory(
      String category) {
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AnnouncementTemplateModel.fromFirestore(doc))
          .toList();
    });
  }

  /// جلب قالب واحد
  Future<AnnouncementTemplateModel?> getTemplate(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return AnnouncementTemplateModel.fromFirestore(doc);
  }
}
