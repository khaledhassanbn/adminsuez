import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_support_service.dart';
import '../viewmodels/admin_support_viewmodel.dart';
import '../widgets/support_stats_card.dart';
import '../widgets/conversation_list_tile.dart';
import '../models/support_conversation.dart';
import '../../theme/app_color.dart';

class SupportDashboardPage extends StatefulWidget {
  const SupportDashboardPage({super.key});

  @override
  State<SupportDashboardPage> createState() => _SupportDashboardPageState();
}

class _SupportDashboardPageState extends State<SupportDashboardPage> {
  final AdminSupportService _supportService = AdminSupportService();

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
            'مركز الدعم الفني',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: StreamBuilder<Map<String, int>>(
          stream: _supportService.getDashboardStats(),
          builder: (context, statsSnapshot) {
            if (statsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats = statsSnapshot.data ?? {
              'open': 0,
              'inProgress': 0,
              'resolved': 0,
              'closed': 0,
              'total': 0,
              'unreadTotal': 0,
            };

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // بنر التنبيهات لتذاكر الدعم الجديدة
                if (viewModel.newTicketAlertName != null)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.campaign_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'طلب دعم فني جديد!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'أرسل المستخدم ${viewModel.newTicketAlertName} تذكرة دعم جديدة الآن.',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => viewModel.clearAlert(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // قسم الإحصائيات الرئيسي
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // كارت الرسائل غير المقروءة (بارز ومميز باللون الأحمر)
                      if (stats['unreadTotal']! > 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.mark_chat_unread_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'لديك ${stats['unreadTotal']} رسائل غير مقروءة',
                                      style: const TextStyle(
                                        color: Color(0xFF991B1B),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'يرجى الرد على استفسارات المستخدمين بأسرع وقت.',
                                      style: TextStyle(
                                        color: Color(0xFFB91C1C),
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  viewModel.clearFilters();
                                  // تصفية المحادثات لعرض المفتوحة أو قيد المتابعة فقط
                                  viewModel.setStatusFilter('all');
                                  context.push('/admin/support/conversations');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('عرض'),
                              ),
                            ],
                          ),
                        ),

                      // شبكة الكروت الرئيسية
                      SupportStatsCard(
                        title: 'مفتوحة (بانتظار الرد)',
                        count: '${stats['open']}',
                        icon: Icons.mark_chat_unread_outlined,
                        color: Colors.blue,
                        onTap: () {
                          viewModel.clearFilters();
                          viewModel.setStatusFilter('open');
                          context.push('/admin/support/conversations');
                        },
                      ),
                      SupportStatsCard(
                        title: 'قيد المتابعة والحل',
                        count: '${stats['inProgress']}',
                        icon: Icons.hourglass_top_rounded,
                        color: Colors.orange,
                        onTap: () {
                          viewModel.clearFilters();
                          viewModel.setStatusFilter('in_progress');
                          context.push('/admin/support/conversations');
                        },
                      ),
                      SupportStatsCard(
                        title: 'تم حلها بنجاح',
                        count: '${stats['resolved']}',
                        icon: Icons.check_circle_outline_rounded,
                        color: Colors.green,
                        onTap: () {
                          viewModel.clearFilters();
                          viewModel.setStatusFilter('resolved');
                          context.push('/admin/support/conversations');
                        },
                      ),
                      SupportStatsCard(
                        title: 'إجمالي المحادثات في النظام',
                        count: '${stats['total']}',
                        icon: Icons.chat_rounded,
                        color: AppColors.mainColor,
                        onTap: () {
                          viewModel.clearFilters();
                          context.push('/admin/support/conversations');
                        },
                      ),
                    ]),
                  ),
                ),

                // عنوان النشاطات الأخيرة
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'آخر التحديثات والنشاطات',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            viewModel.clearFilters();
                            context.push('/admin/support/conversations');
                          },
                          child: const Text('عرض الكل'),
                        ),
                      ],
                    ),
                  ),
                ),

                // قائمة النشاطات الأخيرة
                StreamBuilder<List<SupportConversation>>(
                  stream: _supportService.getRecentActivity(limit: 5),
                  builder: (context, recentSnapshot) {
                    if (recentSnapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    }

                    final recent = recentSnapshot.data ?? [];

                    if (recent.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'لا توجد محادثات دعم حالية في النظام',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final conv = recent[index];
                          return ConversationListTile(
                            conversation: conv,
                            onTap: () => context.push('/admin/support/chat/${conv.id}'),
                          );
                        },
                        childCount: recent.length,
                      ),
                    );
                  },
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
    );
  }
}
