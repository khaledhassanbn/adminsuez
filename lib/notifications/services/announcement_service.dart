import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:async';
import 'dart:io';
import '../models/announcement_model.dart';

/// خدمة إدارة الإعلانات والإشعارات — Firestore + Cloud Functions
class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west1');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _collection = 'announcements';
  static const String _errorLogsCollection = 'announcement_error_logs';
  static const String _adminLogsCollection = 'announcement_admin_logs';

  // ═══════════════════════════════════════════════════════════════
  // إنشاء وإرسال الإعلانات
  // ═══════════════════════════════════════════════════════════════

  /// إنشاء إعلان جديد كمسودة في Firestore
  Future<String> createAnnouncement(AnnouncementModel announcement) async {
    final docRef = _firestore.collection(_collection).doc();
    final data = announcement.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);

    // تسجيل العملية الإدارية
    await _logAdminAction(
      announcementId: docRef.id,
      action: 'created',
      details: {
        'title': announcement.title,
        'targetAudience': announcement.targetAudience,
        'deliveryType': announcement.deliveryType,
      },
    );

    return docRef.id;
  }

  /// استدعاء Cloud Function لإرسال الإعلان — أو النشر المباشر لرسائل داخلية فقط
  Future<Map<String, dynamic>> sendAnnouncement(String announcementId) async {
    final announcement = await getAnnouncement(announcementId);
    if (announcement == null) {
      throw Exception('الإعلان غير موجود');
    }

    // رسالة داخلية فقط — لا تحتاج Cloud Function
    if (announcement.deliveryType == 'in_app_only') {
      return _publishInAppOnly(announcementId);
    }

    try {
      // لا نُحدّث الحالة إلى sending هنا — Cloud Function تتولى ذلك.
      // (تحديثها مسبقاً كان يجعل الـ Function تتخطى الإرسال فعلياً)
      final callable = _functions.httpsCallable('sendAnnouncement');
      final result = await callable
          .call<dynamic>({'announcementId': announcementId})
          .timeout(const Duration(seconds: 120));

      await _logAdminAction(
        announcementId: announcementId,
        action: 'sent',
        details: Map<String, dynamic>.from(result.data as Map? ?? {}),
      );

      return Map<String, dynamic>.from(result.data as Map? ?? {});
    } on FirebaseFunctionsException catch (e) {
      if (announcement.deliveryType == 'both') {
        await _publishInAppOnly(announcementId, partial: true);
        throw Exception(
          'وصلت الرسالة لمركز الرسائل، لكن فشل إرسال الإشعار الفوري: ${e.message ?? e.code}',
        );
      }
      await _markFailed(announcementId);
      rethrow;
    } on TimeoutException {
      if (announcement.deliveryType == 'both') {
        await _publishInAppOnly(announcementId, partial: true);
        throw Exception(
          'وصلت الرسالة لمركز الرسائل، لكن انتهت مهلة إرسال الإشعار الفوري.',
        );
      }
      await _markFailed(announcementId);
      rethrow;
    } catch (e) {
      if (announcement.deliveryType == 'both') {
        try {
          await _publishInAppOnly(announcementId, partial: true);
        } catch (_) {}
      } else {
        await _markFailed(announcementId);
      }
      rethrow;
    }
  }

  /// إعادة إرسال إعلان عالق في حالة sending أو failed
  Future<Map<String, dynamic>> retrySend(String announcementId) async {
    await _firestore.collection(_collection).doc(announcementId).update({
      'status': 'draft',
    });
    return sendAnnouncement(announcementId);
  }

  Future<Map<String, dynamic>> _publishInAppOnly(
    String announcementId, {
    bool partial = false,
  }) async {
    await _firestore.collection(_collection).doc(announcementId).update({
      'status': partial ? 'partial' : 'sent',
      'sentAt': FieldValue.serverTimestamp(),
      'stats.targetedCount': 0,
      'stats.pushSentCount': 0,
      'stats.pushFailedCount': 0,
    });

    await _logAdminAction(
      announcementId: announcementId,
      action: 'sent',
      details: {'mode': partial ? 'in_app_fallback' : 'in_app_only'},
    );

    return {
      'success': true,
      'message': partial
          ? 'تم نشر الرسالة داخل التطبيق (إشعار فوري غير متاح)'
          : 'تم نشر الرسالة في مركز الرسائل',
    };
  }

  Future<void> _markFailed(String announcementId) async {
    await _firestore.collection(_collection).doc(announcementId).update({
      'status': 'failed',
    });
  }

  /// إنشاء إعلان وإرساله فوراً (خطوة واحدة)
  Future<Map<String, dynamic>> createAndSend(
      AnnouncementModel announcement) async {
    final id = await createAnnouncement(announcement);
    return sendAnnouncement(id);
  }

  /// جدولة إرسال إعلان
  Future<void> scheduleAnnouncement(
      String announcementId, DateTime scheduledAt) async {
    await _firestore.collection(_collection).doc(announcementId).update({
      'status': 'scheduled',
      'scheduledAt': Timestamp.fromDate(scheduledAt),
    });

    await _logAdminAction(
      announcementId: announcementId,
      action: 'scheduled',
      details: {'scheduledAt': scheduledAt.toIso8601String()},
    );
  }

  /// إرسال إشعار فردي (من صفحة تفاصيل المستخدم)
  Future<Map<String, dynamic>> sendDirectNotification({
    required String targetUserId,
    required String targetUserName,
    required String targetUserType,
    required String title,
    required String body,
    String deliveryType = 'both',
    String? templateId,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendDirectNotification');
      final result = await callable.call<dynamic>({
        'targetUserId': targetUserId,
        'targetUserName': targetUserName,
        'targetUserType': targetUserType,
        'title': title,
        'body': body,
        'deliveryType': deliveryType,
        'templateId': templateId,
      });
      return Map<String, dynamic>.from(result.data as Map? ?? {});
    } catch (e) {
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // استعلامات وقراءة البيانات
  // ═══════════════════════════════════════════════════════════════

  /// Stream لجميع الإعلانات مع فلاتر اختيارية (فلترة محلية لتجنب composite indexes)
  Stream<List<AnnouncementModel>> getAnnouncementsStream({
    String? statusFilter,
    String? targetAudienceFilter,
    int limit = 50,
  }) {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) {
      var list = snapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .toList();

      if (statusFilter != null && statusFilter != 'all') {
        list = list.where((a) => a.status == statusFilter).toList();
      }

      if (targetAudienceFilter != null && targetAudienceFilter != 'all') {
        list =
            list.where((a) => a.targetAudience == targetAudienceFilter).toList();
      }

      if (list.length > limit) {
        list = list.sublist(0, limit);
      }

      return list;
    });
  }

  /// جلب إعلان واحد
  Future<AnnouncementModel?> getAnnouncement(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return AnnouncementModel.fromFirestore(doc);
  }

  /// Stream لإعلان واحد (للتحديث الحي)
  Stream<AnnouncementModel?> getAnnouncementStream(String id) {
    return _firestore.collection(_collection).doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AnnouncementModel.fromFirestore(doc);
    });
  }

  /// جلب سجل الأخطاء لإعلان محدد
  Stream<List<AnnouncementErrorLog>> getErrorLogs(String announcementId) {
    return _firestore
        .collection(_errorLogsCollection)
        .where('announcementId', isEqualTo: announcementId)
        .snapshots()
        .map((snapshot) {
      final logs = snapshot.docs
          .map((doc) => AnnouncementErrorLog.fromFirestore(doc))
          .toList();
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return logs;
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // إحصائيات Dashboard
  // ═══════════════════════════════════════════════════════════════

  /// إحصائيات سريعة للوحة التحكم
  Stream<Map<String, int>> getDashboardStats() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      int total = 0;
      int sent = 0;
      int scheduled = 0;
      int failed = 0;
      int sentToday = 0;

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      for (final doc in snapshot.docs) {
        final data = doc.data();
        total++;

        final status = data['status'] ?? '';
        if (status == 'sent') sent++;
        if (status == 'scheduled') scheduled++;
        if (status == 'failed' || status == 'partial') failed++;

        // إعلانات تم إرسالها اليوم
        final sentAt = (data['sentAt'] as Timestamp?)?.toDate();
        if (sentAt != null && sentAt.isAfter(startOfDay)) {
          sentToday++;
        }
      }

      return {
        'total': total,
        'sent': sent,
        'scheduled': scheduled,
        'failed': failed,
        'sentToday': sentToday,
      };
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // رفع الصور
  // ═══════════════════════════════════════════════════════════════

  /// رفع صورة البانر إلى Firebase Storage
  Future<String> uploadAnnouncementImage(File file) async {
    final fileName =
        'announcement_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref('announcements/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // ═══════════════════════════════════════════════════════════════
  // إلغاء ومساعدات
  // ═══════════════════════════════════════════════════════════════

  /// إلغاء إعلان مجدول
  Future<void> cancelScheduledAnnouncement(String announcementId) async {
    await _firestore.collection(_collection).doc(announcementId).update({
      'status': 'draft',
      'scheduledAt': null,
    });

    await _logAdminAction(
      announcementId: announcementId,
      action: 'cancelled',
      details: {},
    );
  }

  /// حذف مسودة
  Future<void> deleteDraft(String announcementId) async {
    await _firestore.collection(_collection).doc(announcementId).delete();
  }

  // ═══════════════════════════════════════════════════════════════
  // سجل العمليات الإدارية
  // ═══════════════════════════════════════════════════════════════

  Future<void> _logAdminAction({
    required String announcementId,
    required String action,
    required Map<String, dynamic> details,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection(_adminLogsCollection).add({
      'announcementId': announcementId,
      'action': action,
      'adminUid': user.uid,
      'adminName': user.displayName ?? 'أدمن',
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
