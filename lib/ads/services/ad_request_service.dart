import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/ad_request_model.dart';
class AdRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // جلب جميع طلبات الإعلانات (للإدمن)
  Future<List<AdRequestModel>> fetchAllAdRequests() async {
    try {
      final snapshot = await _firestore
          .collection('ad_requests')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AdRequestModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('خطأ في جلب طلبات الإعلانات: $e');
      return [];
    }
  }

  // جلب طلبات الإعلانات الخاصة بتاجر معين
  Future<List<AdRequestModel>> fetchUserAdRequests(String ownerUid) async {
    try {
      final snapshot = await _firestore
          .collection('ad_requests')
          .where('ownerUid', isEqualTo: ownerUid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AdRequestModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('خطأ في جلب طلبات الإعلانات: $e');
      return [];
    }
  }

  // تحديث حالة الطلب (للإدمن)
  Future<bool> updateRequestStatus(
    String requestId,
    String status, {
    String? adminNotes,
  }) async {
    try {
      await _firestore.collection('ad_requests').doc(requestId).update({
        'status': status,
        if (adminNotes != null) 'adminNotes': adminNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('خطأ في تحديث حالة الطلب: $e');
      return false;
    }
  }

  // حذف طلب إعلان
  Future<bool> deleteAdRequest(String requestId) async {
    try {
      // جلب الطلب أولاً لحذف الصورة
      final doc = await _firestore
          .collection('ad_requests')
          .doc(requestId)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['imageUrl'] != null) {
          try {
            final ref = _storage.refFromURL(data['imageUrl']);
            await ref.delete();
          } catch (e) {
            print('خطأ في حذف الصورة: $e');
          }
        }
      }

      // حذف الطلب
      await _firestore.collection('ad_requests').doc(requestId).delete();
      return true;
    } catch (e) {
      print('خطأ في حذف طلب الإعلان: $e');
      return false;
    }
  }
}
