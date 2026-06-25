import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/promotional_popup_model.dart';

/// خدمة إدارة الإعلانات المنبثقة
class PromotionalPopupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _collection = 'promotional_popups';

  /// إنشاء إعلان منبثق جديد
  Future<String> createPopup(PromotionalPopupModel popup) async {
    final docRef = _firestore.collection(_collection).doc();
    final data = popup.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['createdBy'] = _auth.currentUser?.uid ?? '';
    await docRef.set(data);
    return docRef.id;
  }

  /// تعديل إعلان منبثق
  Future<void> updatePopup(String id, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection(_collection).doc(id).update(updates);
  }

  /// تفعيل/تعطيل
  Future<void> togglePopupActive(String id, bool isActive) async {
    await _firestore.collection(_collection).doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// حذف إعلان منبثق
  Future<void> deletePopup(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Stream لجميع الإعلانات المنبثقة
  Stream<List<PromotionalPopupModel>> getPopupsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('priority', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PromotionalPopupModel.fromFirestore(doc))
          .toList();
    });
  }

  /// جلب إعلان واحد
  Future<PromotionalPopupModel?> getPopup(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return PromotionalPopupModel.fromFirestore(doc);
  }

  /// رفع صورة الإعلان
  Future<String> uploadPopupImage(File file) async {
    final fileName = 'popup_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref('promotional_popups/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}
