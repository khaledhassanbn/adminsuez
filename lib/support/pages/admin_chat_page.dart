import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_support_service.dart';
import '../viewmodels/admin_support_viewmodel.dart';
import '../models/support_conversation.dart';
import '../models/support_message.dart';
import '../widgets/admin_chat_bubble.dart';
import '../widgets/admin_chat_input_bar.dart';
import '../widgets/linked_entity_card.dart';
import '../widgets/user_profile_card.dart';
import '../../theme/app_color.dart';

class AdminChatPage extends StatefulWidget {
  final String conversationId;

  const AdminChatPage({
    super.key,
    required this.conversationId,
  });

  @override
  State<AdminChatPage> createState() => _AdminChatPageState();
}

class _AdminChatPageState extends State<AdminChatPage> {
  final AdminSupportService _supportService = AdminSupportService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // تصفير عداد الإدارة عند فتح المحادثة
    _supportService.markAsReadByAdmin(widget.conversationId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// تنفيذ إجراءات تغيير الحالة
  Future<void> _changeStatus(ConversationStatus status) async {
    try {
      await context.read<AdminSupportViewModel>().updateStatus(widget.conversationId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث حالة المحادثة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحديث الحالة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// تنفيذ إجراءات تغيير الأولوية
  Future<void> _changePriority(ConversationPriority priority) async {
    try {
      await context.read<AdminSupportViewModel>().updatePriority(widget.conversationId, priority);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تغيير الأولوية بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تغيير الأولوية: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('support_conversations')
            .doc(widget.conversationId)
            .snapshots(),
        builder: (context, conversationSnapshot) {
          if (conversationSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!conversationSnapshot.hasData || !conversationSnapshot.data!.exists) {
            return Scaffold(
              appBar: AppBar(backgroundColor: AppColors.mainColor),
              body: const Center(child: Text('المحادثة غير موجودة أو تم حذفها')),
            );
          }

          final conversation = SupportConversation.fromFirestore(conversationSnapshot.data!);

          // تصفير عداد غير المقروءة في الخلفية في حال وصول رسالة جديدة وأنت داخل الشاشة
          if (conversation.unreadAdminCount > 0) {
            _supportService.markAsReadByAdmin(widget.conversationId);
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF1F5F9),
            appBar: AppBar(
              backgroundColor: AppColors.mainColor,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.userName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${conversation.userTypeDisplayName} · ${conversation.issueTypeDisplayName}',
                    style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                  ),
                ],
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
            ),
            body: Column(
              children: [
                // 1. الكارت المرفق بالكيانات (متجر، صنايعي، مندوب، طلب)
                if (conversation.hasRelatedEntity)
                  LinkedEntityCard(
                    merchantId: conversation.relatedMerchantId,
                    merchantName: conversation.relatedMerchantName,
                    craftsmanId: conversation.relatedCraftsmanId,
                    craftsmanName: conversation.relatedCraftsmanName,
                    driverId: conversation.relatedDriverId,
                    driverName: conversation.relatedDriverName,
                    orderId: conversation.relatedOrderId,
                  ),

                // 2. بطاقة صاحب البلاغ داخل المحادثة (الاسم، الهاتف، نوع الحساب، التسجيل)
                UserProfileCard(userId: conversation.userId),

                // 3. الإجراءات السريعة (Quick Actions) وتغيير الأولوية
                _buildQuickActionsBar(conversation),

                // 4. رسائل المحادثة
                Expanded(
                  child: StreamBuilder<List<SupportMessage>>(
                    stream: _supportService.getMessages(widget.conversationId),
                    builder: (context, messagesSnapshot) {
                      if (messagesSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = messagesSnapshot.data ?? [];

                      // التمرير التلقائي لأسفل عند تحميل الرسائل أو وصول رسالة جديدة
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'لا توجد رسائل بعد في هذه المحادثة',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          return AdminChatBubble(message: msg);
                        },
                      );
                    },
                  ),
                ),

                // 5. شريط الكتابة السفلي
                AdminChatInputBar(conversationId: widget.conversationId),
              ],
            ),
          );
        },
      ),
    );
  }

  /// بناء شريط الإجراءات السريعة
  Widget _buildQuickActionsBar(SupportConversation conversation) {
    final status = conversation.status;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text(
              'الإجراءات السريعة:',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 8),

            // زر حل المشكلة
            if (status != ConversationStatus.resolved)
              _buildActionChip(
                label: 'حل المشكلة',
                icon: Icons.check_circle_rounded,
                color: Colors.green,
                onTap: () => _changeStatus(ConversationStatus.resolved),
              ),

            // زر إغلاق المحادثة
            if (status != ConversationStatus.closed)
              _buildActionChip(
                label: 'إغلاق المحادثة',
                icon: Icons.cancel_rounded,
                color: Colors.grey[700]!,
                onTap: () => _changeStatus(ConversationStatus.closed),
              ),

            // زر إعادة فتح المحادثة
            if (status == ConversationStatus.resolved || status == ConversationStatus.closed)
              _buildActionChip(
                label: 'إعادة فتح',
                icon: Icons.replay_rounded,
                color: Colors.blue,
                onTap: () => _changeStatus(ConversationStatus.open),
              ),

            const SizedBox(width: 8),
            Container(width: 1, height: 16, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(width: 8),

            // منيو الأولوية
            PopupMenuButton<ConversationPriority>(
              onSelected: (p) => _changePriority(p),
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: ConversationPriority.high,
                  child: Text('أولوية عالية 🔴', style: TextStyle(fontFamily: 'Tajawal', fontSize: 13)),
                ),
                const PopupMenuItem(
                  value: ConversationPriority.medium,
                  child: Text('أولوية متوسطة 🟡', style: TextStyle(fontFamily: 'Tajawal', fontSize: 13)),
                ),
                const PopupMenuItem(
                  value: ConversationPriority.low,
                  child: Text('أولوية منخفضة 🟢', style: TextStyle(fontFamily: 'Tajawal', fontSize: 13)),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_rounded, size: 14, color: AppColors.mainColor),
                    const SizedBox(width: 4),
                    Text(
                      'الأولوية: ${conversation.priorityDisplayName}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ActionChip(
        onPressed: onTap,
        backgroundColor: color.withOpacity(0.1),
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        side: BorderSide(color: color.withOpacity(0.2), width: 0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        avatar: Icon(icon, color: color, size: 14),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
      ),
    );
  }
}
