import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/admin_support_viewmodel.dart';
import '../widgets/conversation_filters.dart';
import '../widgets/conversation_list_tile.dart';
import '../models/support_conversation.dart';
import '../../theme/app_color.dart';

class SupportConversationsPage extends StatefulWidget {
  final String? initialStatusFilter;

  const SupportConversationsPage({
    super.key,
    this.initialStatusFilter,
  });

  @override
  State<SupportConversationsPage> createState() => _SupportConversationsPageState();
}

class _SupportConversationsPageState extends State<SupportConversationsPage> {
  @override
  void initState() {
    super.initState();
    // إعداد التصفية المبدئية إذا كانت ممررة من الـ Dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialStatusFilter != null) {
        context.read<AdminSupportViewModel>().setStatusFilter(widget.initialStatusFilter);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminSupportViewModel>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: AppColors.mainColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'إدارة محادثات الدعم',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                // تصفير مؤقت لتحديث الواجهة
                final currentFilter = viewModel.statusFilter;
                viewModel.setStatusFilter(null);
                Future.delayed(const Duration(milliseconds: 100), () {
                  viewModel.setStatusFilter(currentFilter);
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // قسم الفلاتر العلوي
            const ConversationFilters(),

            // قائمة المحادثات الحية
            Expanded(
              child: StreamBuilder<List<SupportConversation>>(
                stream: viewModel.filteredConversations,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'حدث خطأ أثناء تحميل البيانات: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  var conversations = snapshot.data ?? [];

                  // فلترة البحث محلياً لتقليل الضغط على قاعدة البيانات ودعم البحث الديناميكي السريع
                  final query = (viewModel.searchQuery ?? '').trim().toLowerCase();
                  if (query.isNotEmpty) {
                    conversations = conversations.where((c) {
                      return c.userName.toLowerCase().contains(query) ||
                          c.lastMessage.toLowerCase().contains(query) ||
                          c.relatedEntityName.toLowerCase().contains(query) ||
                          c.issueTypeDisplayName.toLowerCase().contains(query) ||
                          c.userTypeDisplayName.toLowerCase().contains(query);
                    }).toList();
                  }

                  if (conversations.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'لا توجد محادثات تطابق فلاتر البحث الحالية',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'حاول تغيير الفلاتر أو شروط البحث.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conv = conversations[index];
                      return ConversationListTile(
                        conversation: conv,
                        onTap: () => context.push('/admin/support/chat/${conv.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
