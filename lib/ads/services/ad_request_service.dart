import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/ad_request_model.dart';
import '../../notifications/services/announcement_service.dart';

class AdRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AnnouncementService _announcementService = AnnouncementService();

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

  Future<AdRequestModel?> getRequestById(String requestId) async {
    final doc = await _firestore.collection('ad_requests').doc(requestId).get();
    if (!doc.exists) return null;
    return AdRequestModel.fromMap(doc.id, doc.data()!);
  }

  Future<bool> updateRequestStatus(
    String requestId,
    String status, {
    String? adminNotes,
    String? rejectionReason,
    bool refund = false,
  }) async {
    try {
      final request = await getRequestById(requestId);
      if (request == null) return false;

      if (status == 'rejected' && refund && !request.refunded) {
        final refunded = await refundToWallet(request);
        if (!refunded) return false;
      }

      await _firestore.collection('ad_requests').doc(requestId).update({
        'status': status,
        if (adminNotes != null) 'adminNotes': adminNotes,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
        if (status == 'rejected' && refund) 'refunded': true,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': _auth.currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (status == 'approved') {
        await sendAdNotification(
          userId: request.ownerUid,
          userName: request.storeName ?? request.ownerEmail,
          userType: request.isCraftsmanRequest ? 'craftsman' : 'merchant',
          title: 'تمت الموافقة على إعلانك',
          body: 'تمت الموافقة على طلب إعلانك وسيظهر في الصفحة الرئيسية قريباً.',
        );
      } else if (status == 'rejected') {
        await sendAdNotification(
          userId: request.ownerUid,
          userName: request.storeName ?? request.ownerEmail,
          userType: request.isCraftsmanRequest ? 'craftsman' : 'merchant',
          title: 'تم رفض طلب الإعلان',
          body: rejectionReason != null
              ? 'سبب الرفض: $rejectionReason${refund ? ' — تم استرداد المبلغ لمحفظتك.' : ''}'
              : 'تم رفض طلب الإعلان.${refund ? ' تم استرداد المبلغ لمحفظتك.' : ''}',
        );
      }

      return true;
    } catch (e) {
      print('خطأ في تحديث حالة الطلب: $e');
      return false;
    }
  }

  Future<bool> refundToWallet(AdRequestModel request) async {
    if (request.refunded || request.totalPrice <= 0) return true;

    try {
      await _firestore.runTransaction((txn) async {
        final userRef = _firestore.collection('users').doc(request.ownerUid);
        final userDoc = await txn.get(userRef);
        if (!userDoc.exists) throw Exception('المستخدم غير موجود');

        final currentBalance =
            (userDoc.data()?['walletBalance'] ?? 0.0).toDouble();
        final newBalance = currentBalance + request.totalPrice;

        txn.update(userRef, {'walletBalance': newBalance});

        final ledgerRef = _firestore.collection('wallet_ledger').doc();
        txn.set(ledgerRef, {
          'id': ledgerRef.id,
          'storeId': request.storeId ?? '',
          'userId': request.ownerUid,
          'type': 'refund',
          'amount': request.totalPrice,
          'balanceBefore': currentBalance,
          'balanceAfter': newBalance,
          'referenceId': request.id,
          'referenceType': 'ad_request',
          'description': 'استرداد طلب إعلان مرفوض',
          'createdAt': FieldValue.serverTimestamp(),
          'metadata': {
            'adRequestId': request.id,
            'rejectionReason': request.rejectionReason,
          },
        });
      });
      return true;
    } catch (e) {
      print('خطأ في استرداد المبلغ: $e');
      return false;
    }
  }

  Future<void> sendAdNotification({
    required String userId,
    required String userName,
    required String userType,
    required String title,
    required String body,
  }) async {
    try {
      await _announcementService.sendDirectNotification(
        targetUserId: userId,
        targetUserName: userName,
        targetUserType: userType,
        title: title,
        body: body,
        deliveryType: 'both',
      );
    } catch (e) {
      print('خطأ في إرسال إشعار الإعلان: $e');
    }
  }

  Future<bool> deleteAdRequest(String requestId) async {
    try {
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

      await _firestore.collection('ad_requests').doc(requestId).delete();
      return true;
    } catch (e) {
      print('خطأ في حذف طلب الإعلان: $e');
      return false;
    }
  }
}
