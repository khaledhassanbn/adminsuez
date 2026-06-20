import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/support_conversation.dart';
import '../models/support_message.dart';

class AdminSupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'support_conversations';
  static const String _messagesSubcollection = 'messages';

  // ═══════════════════════════════════════════════════════════════
  // DASHBOARD STATS
  // ═══════════════════════════════════════════════════════════════

  /// إحصائيات Dashboard (Stream)
  Stream<Map<String, int>> getDashboardStats() {
    return _firestore.collection(_collection).snapshots().map((snap) {
      int open = 0;
      int inProgress = 0;
      int resolved = 0;
      int closed = 0;
      int unreadTotal = 0;
      int low = 0;
      int medium = 0;
      int high = 0;

      for (final doc in snap.docs) {
        final data = doc.data();
        final status = (data['status'] ?? 'open').toString().toLowerCase();
        final unread = (data['unreadAdminCount'] ?? 0) as int;
        final priority = (data['priority'] ?? 'medium').toString().toLowerCase();

        switch (status) {
          case 'open':
            open++;
            break;
          case 'in_progress':
          case 'inprogress':
            inProgress++;
            break;
          case 'resolved':
            resolved++;
            break;
          case 'closed':
            closed++;
            break;
        }

        switch (priority) {
          case 'low':
            low++;
            break;
          case 'high':
            high++;
            break;
          case 'medium':
          default:
            medium++;
            break;
        }

        unreadTotal += unread;
      }

      return {
        'open': open,
        'inProgress': inProgress,
        'resolved': resolved,
        'closed': closed,
        'total': snap.docs.length,
        'unreadTotal': unreadTotal,
        'low': low,
        'medium': medium,
        'high': high,
      };
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // CONVERSATIONS
  // ═══════════════════════════════════════════════════════════════

  /// جلب جميع المحادثات (Stream) مع فلاتر
  Stream<List<SupportConversation>> getAllConversations({
    String? statusFilter,       // open, in_progress, resolved, closed
    String? userTypeFilter,     // customer, merchant, craftsman, driver
    String? issueTypeFilter,    // store_issue, craftsman_issue, etc.
    String? priorityFilter,     // low, medium, high
    String? sourceFilter,       // customer_app, merchant_app, craftsman_app, driver_app
  }) {
    Query query = _firestore.collection(_collection);

    // ترتيب تنازلي حسب وقت التحديث
    query = query.orderBy('updatedAt', descending: true);

    return query.snapshots().map((snap) {
      var conversations = snap.docs
          .map((doc) => SupportConversation.fromFirestore(doc))
          .toList();

      // فلترة محلية لأن Firestore لا يدعم فلترة متعددة على حقول مختلفة بسهولة بدون فهارس مركبة معقدة
      if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
        conversations = conversations.where((c) {
          String sStr;
          switch (c.status) {
            case ConversationStatus.open: sStr = 'open'; break;
            case ConversationStatus.inProgress: sStr = 'in_progress'; break;
            case ConversationStatus.resolved: sStr = 'resolved'; break;
            case ConversationStatus.closed: sStr = 'closed'; break;
          }
          return sStr == statusFilter;
        }).toList();
      }

      if (userTypeFilter != null && userTypeFilter.isNotEmpty && userTypeFilter != 'all') {
        conversations = conversations.where((c) => c.userType.toLowerCase() == userTypeFilter.toLowerCase()).toList();
      }

      if (issueTypeFilter != null && issueTypeFilter.isNotEmpty && issueTypeFilter != 'all') {
        conversations = conversations.where((c) {
          final issueTypeSanitized = c.issueType.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), '_').toLowerCase();
          final filterSanitized = issueTypeFilter.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), '_').toLowerCase();
          return issueTypeSanitized == filterSanitized;
        }).toList();
      }

      if (priorityFilter != null && priorityFilter.isNotEmpty && priorityFilter != 'all') {
        conversations = conversations.where((c) {
          String pStr;
          switch (c.priority) {
            case ConversationPriority.low: pStr = 'low'; break;
            case ConversationPriority.medium: pStr = 'medium'; break;
            case ConversationPriority.high: pStr = 'high'; break;
          }
          return pStr == priorityFilter;
        }).toList();
      }

      if (sourceFilter != null && sourceFilter.isNotEmpty && sourceFilter != 'all') {
        conversations = conversations.where((c) => c.source == sourceFilter).toList();
      }

      return conversations;
    });
  }

  /// بحث في المحادثات بالاسم، آخر رسالة، أو الكيانات المرتبطة
  Future<List<SupportConversation>> searchConversations(String query) async {
    if (query.trim().isEmpty) return [];

    final snap = await _firestore
        .collection(_collection)
        .orderBy('updatedAt', descending: true)
        .limit(100)
        .get();

    final q = query.toLowerCase();
    return snap.docs
        .map((doc) => SupportConversation.fromFirestore(doc))
        .where((c) =>
            c.userName.toLowerCase().contains(q) ||
            c.relatedEntityName.toLowerCase().contains(q) ||
            c.lastMessage.toLowerCase().contains(q))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // MESSAGES
  // ═══════════════════════════════════════════════════════════════

  /// جلب رسائل محادثة (Stream)
  Stream<List<SupportMessage>> getMessages(String conversationId) {
    return _firestore
        .collection(_collection)
        .doc(conversationId)
        .collection(_messagesSubcollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SupportMessage.fromFirestore(doc))
            .toList());
  }

  /// إرسال رد من الإدارة
  Future<void> sendAdminReply({
    required String conversationId,
    String? text,
    String? imageUrl,
  }) async {
    final admin = _auth.currentUser;
    if (admin == null) throw Exception('يجب تسجيل الدخول كمسؤول');

    final messageRef = _firestore
        .collection(_collection)
        .doc(conversationId)
        .collection(_messagesSubcollection)
        .doc();

    await messageRef.set({
      'id': messageRef.id,
      'senderId': admin.uid,
      'senderType': 'admin',
      'text': text ?? '',
      'imageUrl': imageUrl ?? '',
      'isSystem': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // تحديث المحادثة
    await _firestore.collection(_collection).doc(conversationId).update({
      'lastMessage': text != null && text.isNotEmpty ? text : '📷 صورة مرفقة',
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadUserCount': FieldValue.increment(1),
      'unreadAdminCount': 0, // تصفير العداد للإدارة لأن الأدمن هو من رد
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // STATUS & PRIORITY MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  /// تغيير حالة المحادثة مع إرسال رسالة نظام تلقائية
  Future<void> updateStatus(String conversationId, ConversationStatus newStatus) async {
    String statusStr;
    switch (newStatus) {
      case ConversationStatus.open:
        statusStr = 'open';
        break;
      case ConversationStatus.inProgress:
        statusStr = 'in_progress';
        break;
      case ConversationStatus.resolved:
        statusStr = 'resolved';
        break;
      case ConversationStatus.closed:
        statusStr = 'closed';
        break;
    }

    await _firestore.collection(_collection).doc(conversationId).update({
      'status': statusStr,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // رسالة النظام
    String statusMessage;
    switch (newStatus) {
      case ConversationStatus.open:
        statusMessage = 'تم إعادة فتح المحادثة لمتابعة طلبك.';
        break;
      case ConversationStatus.inProgress:
        statusMessage = 'تم تحويل حالة المحادثة إلى: جارى المتابعة والحل.';
        break;
      case ConversationStatus.resolved:
        statusMessage = 'تم حل المشكلة وتثبيتها كـ "محلولة". يمكنك فتح طلب جديد إذا واجهتك مشاكل أخرى.';
        break;
      case ConversationStatus.closed:
        statusMessage = 'تم إغلاق المحادثة من قبل المسؤول.';
        break;
    }

    final messageRef = _firestore
        .collection(_collection)
        .doc(conversationId)
        .collection(_messagesSubcollection)
        .doc();

    await messageRef.set({
      'id': messageRef.id,
      'senderId': 'system',
      'senderType': 'system',
      'text': statusMessage,
      'imageUrl': '',
      'isSystem': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// تغيير أولوية المحادثة مع إرسال رسالة نظام
  Future<void> updatePriority(String conversationId, ConversationPriority newPriority) async {
    String priorityStr;
    switch (newPriority) {
      case ConversationPriority.low:
        priorityStr = 'low';
        break;
      case ConversationPriority.medium:
        priorityStr = 'medium';
        break;
      case ConversationPriority.high:
        priorityStr = 'high';
        break;
    }

    await _firestore.collection(_collection).doc(conversationId).update({
      'priority': priorityStr,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // ترجمة الأولوية للعربية للرسالة النظام
    String pStr;
    switch (newPriority) {
      case ConversationPriority.low:
        pStr = 'منخفضة';
        break;
      case ConversationPriority.medium:
        pStr = 'متوسطة';
        break;
      case ConversationPriority.high:
        pStr = 'عالية';
        break;
    }

    final messageRef = _firestore
        .collection(_collection)
        .doc(conversationId)
        .collection(_messagesSubcollection)
        .doc();

    await messageRef.set({
      'id': messageRef.id,
      'senderId': 'system',
      'senderType': 'system',
      'text': 'تم تغيير أولوية هذه المحادثة من قبل الإدارة إلى: $pStr',
      'imageUrl': '',
      'isSystem': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// تصفير عداد غير المقروءة للإدارة
  Future<void> markAsReadByAdmin(String conversationId) async {
    await _firestore.collection(_collection).doc(conversationId).update({
      'unreadAdminCount': 0,
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // LINKED ENTITIES
  // ═══════════════════════════════════════════════════════════════

  /// جلب بيانات المستخدم
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (_) {
      return null;
    }
  }

  /// جلب بيانات المتجر المرتبط
  Future<Map<String, dynamic>?> getMerchantDetails(String merchantId) async {
    if (merchantId.isEmpty) return null;
    try {
      final doc = await _firestore.collection('markets').doc(merchantId).get();
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (_) {
      return null;
    }
  }

  /// جلب بيانات الصنايعي المرتبط
  Future<Map<String, dynamic>?> getCraftsmanDetails(String craftsmanId) async {
    if (craftsmanId.isEmpty) return null;
    try {
      final doc = await _firestore.collection('craftsmen').doc(craftsmanId).get();
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (_) {
      return null;
    }
  }

  /// جلب بيانات المندوب المرتبط
  Future<Map<String, dynamic>?> getDriverDetails(String driverId) async {
    if (driverId.isEmpty) return null;
    try {
      final doc = await _firestore.collection('courier_requests').doc(driverId).get();
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (_) {
      return null;
    }
  }

  /// جلب بيانات الطلب المرتبط
  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    if (orderId.isEmpty) return null;
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // RECENT ACTIVITY
  // ═══════════════════════════════════════════════════════════════

  /// آخر المحادثات المحدثة (للـ Dashboard)
  Stream<List<SupportConversation>> getRecentActivity({int limit = 5}) {
    return _firestore
        .collection(_collection)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SupportConversation.fromFirestore(doc))
            .toList());
  }
}
