import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:suez_admin/authentication/guards/AuthGuard.dart';
import 'package:suez_admin/theme/app_color.dart';
import 'package:intl/intl.dart' as intl;

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authGuard = context.watch<AuthGuard>();

    if (authGuard.userStatus != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('غير مصرح'),
          backgroundColor: AppColors.mainColor,
        ),
        body: const Center(child: Text('غير مصرح لك بالوصول إلى هذه الصفحة')),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'مسؤول النظام';
    final photoUrl = user?.photoURL;
    
    String formattedDate = '';
    try {
      formattedDate = intl.DateFormat('EEEE, d MMMM y', 'ar').format(DateTime.now());
    } catch (e) {
      formattedDate = DateTime.now().toString().split(' ')[0];
    }

    // قوائم الصفحات المقسمة حسب الفئات
    final List<CategoryGroup> categories = [
      CategoryGroup(
        title: 'إدارة المتاجر والمنتجات',
        color: AppColors.mainColor,
        items: [
          GridMenuItem(
            title: 'قائمة المتاجر',
            icon: Icons.store_rounded,
            route: '/admin/stores',
          ),
          GridMenuItem(
            title: 'باقات الاشتراك',
            icon: Icons.card_giftcard_rounded,
            route: '/admin/manage-packages',
          ),
          GridMenuItem(
            title: 'فئات المنتجات',
            icon: Icons.category_rounded,
            route: '/admin/manage-categories',
          ),
        ],
      ),
      CategoryGroup(
        title: 'المناديب والتوصيل',
        color: const Color(0xFFE67E22),
        items: [
          GridMenuItem(
            title: 'طلبات المناديب',
            icon: Icons.motorcycle_rounded,
            route: '/admin/courier-requests',
            badgeStream: FirebaseFirestore.instance
                .collection('courier_requests')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
          ),
          GridMenuItem(
            title: 'مكاتب التوصيل',
            icon: Icons.business_rounded,
            route: '/admin/offices',
          ),
          GridMenuItem(
            title: 'رسوم التوصيل',
            icon: Icons.delivery_dining_rounded,
            route: '/admin/delivery-fee-settings',
          ),
          GridMenuItem(
            title: 'إعدادات طلب المناديب',
            icon: Icons.toggle_on_rounded,
            route: '/admin/courier-settings',
          ),
        ],
      ),
      CategoryGroup(
        title: 'العملاء والدعم الفني',
        color: const Color(0xFF9B59B6),
        items: [
          GridMenuItem(
            title: 'مركز الدعم',
            icon: Icons.support_agent_rounded,
            route: '/admin/support',
            badgeStream: FirebaseFirestore.instance
                .collection('support_conversations')
                .where('status', isEqualTo: 'open')
                .snapshots(),
          ),
          GridMenuItem(
            title: 'بلاغات المستخدمين',
            icon: Icons.report_gmailerrorred_rounded,
            route: '/admin/reports',
            badgeStream: FirebaseFirestore.instance
                .collection('user_reports')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
          ),
        ],
      ),
      CategoryGroup(
        title: 'الإعلانات والترويج',
        color: const Color(0xFF2ECC71),
        items: [
          GridMenuItem(
            title: 'طلبات الإعلانات',
            icon: Icons.request_quote_rounded,
            route: '/admin/ad-requests',
            badgeStream: FirebaseFirestore.instance
                .collection('ad_requests')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
          ),
          GridMenuItem(
            title: 'إعلانات الهيدر',
            icon: Icons.photo_library_rounded,
            route: '/admin/ads-dashboard',
          ),
          GridMenuItem(
            title: 'الإعلانات المنبثقة',
            icon: Icons.featured_play_list_rounded,
            route: '/admin/promotional-popups',
          ),
          GridMenuItem(
            title: 'الإشعارات العامة',
            icon: Icons.notifications_active_rounded,
            route: '/admin/notifications',
          ),
        ],
      ),
      CategoryGroup(
        title: 'المالية والعمولات',
        color: const Color(0xFF1ABC9C),
        items: [
          GridMenuItem(
            title: 'طلبات المحفظة',
            icon: Icons.account_balance_wallet_outlined,
            route: '/admin/wallet-management',
            badgeStream: FirebaseFirestore.instance
                .collection('wallet_transactions')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
          ),
          GridMenuItem(
            title: 'إعدادات العمولات',
            icon: Icons.payments_outlined,
            route: '/admin/commission-settings',
          ),
          GridMenuItem(
            title: 'السجل المالي',
            icon: Icons.account_balance_rounded,
            route: '/admin/finance-ledger',
          ),
        ],
      ),
      CategoryGroup(
        title: 'الطلب والفواتير',
        color: const Color(0xFF34495E),
        items: [
          GridMenuItem(
            title: 'البحث عن طلب',
            icon: Icons.manage_search_rounded,
            route: '/admin/order-lookup',
          ),
          GridMenuItem(
            title: 'البحث عن فاتورة',
            icon: Icons.receipt_rounded,
            route: '/admin/invoice-lookup',
          ),
        ],
      ),
      CategoryGroup(
        title: 'إدارة النظام والأمان',
        color: const Color(0xFFE74C3C),
        items: [
          GridMenuItem(
            title: 'إحصائيات النظام',
            icon: Icons.analytics_rounded,
            route: '/admin/stats-dashboard',
          ),
          GridMenuItem(
            title: 'صلاحيات المشرفين',
            icon: Icons.admin_panel_settings_rounded,
            route: '/admin/roles',
          ),
          GridMenuItem(
            title: 'سجلات النشاط',
            icon: Icons.history_rounded,
            route: '/admin/activity-logs',
          ),
          GridMenuItem(
            title: 'الحسابات المحذوفة',
            icon: Icons.delete_sweep_rounded,
            route: '/admin/deleted-accounts',
          ),
          GridMenuItem(
            title: 'إدارة المناطق',
            icon: Icons.map_rounded,
            route: '/admin/zone-management',
          ),
        ],
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ترويسة الصفحة الرئيسية الأنيقة
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: AppColors.mainColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.mainColor,
                        AppColors.mainColor.withOpacity(0.85),
                        const Color(0xFF3D7A8F),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // خلفية دائرية للجماليات
                      Positioned(
                        left: -50,
                        top: -50,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -30,
                        bottom: -30,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.04),
                          ),
                        ),
                      ),
                      // بيانات الأدمن الترحيبية
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    backgroundImage: photoUrl != null
                                        ? NetworkImage(photoUrl)
                                        : null,
                                    child: photoUrl == null
                                        ? Text(
                                            displayName.isNotEmpty ? displayName[0] : 'أ',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'أهلاً بك، $displayName 👋',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Tajawal',
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formattedDate,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.85),
                                            fontSize: 12,
                                            fontFamily: 'Tajawal',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              centerTitle: true,
              title: const Text(
                'بوابة الإدارة',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),

            // قائمة الفئات
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = categories[index];
                    return _buildCategoryCard(context, category);
                  },
                  childCount: categories.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryGroup category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان الفئة
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 20,
                  decoration: BoxDecoration(
                    color: category.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  category.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFECEFF1)),

          // أزرار الفئة
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
              ),
              itemCount: category.items.length,
              itemBuilder: (context, index) {
                final item = category.items[index];
                return _buildGridButton(context, item, category.color);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridButton(BuildContext context, GridMenuItem item, Color accentColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push(item.route);
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // حاوية الأيقونة
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    color: accentColor,
                    size: 28,
                  ),
                ),
                // الشارة الحمراء التنبيهية
                if (item.badgeStream != null)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: item.badgeStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final count = snapshot.data!.docs.length;
                          if (count > 0) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                count > 99 ? '99+' : count.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // اسم الصفحة
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF37474F),
                fontFamily: 'Tajawal',
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// كلاس لتنظيم المجموعات
class CategoryGroup {
  final String title;
  final Color color;
  final List<GridMenuItem> items;

  CategoryGroup({
    required this.title,
    required this.color,
    required this.items,
  });
}

// كلاس لزر القائمة
class GridMenuItem {
  final String title;
  final IconData icon;
  final String route;
  final Stream<QuerySnapshot<Map<String, dynamic>>>? badgeStream;

  GridMenuItem({
    required this.title,
    required this.icon,
    required this.route,
    this.badgeStream,
  });
}
