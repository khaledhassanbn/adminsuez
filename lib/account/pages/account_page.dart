import 'package:suez_admin/theme/app_color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);

    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل تسجيل الخروج، حاول مرة أخرى')),
      );
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  void _confirmSignOut() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.logout_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'تسجيل الخروج',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'هل تريد تسجيل الخروج من لوحة الإدارة؟',
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _signOut();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('تسجيل الخروج'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'المسؤول';
    final email = user?.email ?? '';
    final avatar = user?.photoURL;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
            children: [
              // Header
              _buildHeader(displayName, email, avatar),
              const SizedBox(height: 24),
              // Admin sections
              _buildAdminSection(),
              const SizedBox(height: 16),
              // App info section
              _buildInfoSection(),
              const SizedBox(height: 24),
              // Sign out button
              _buildSignOutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String email, String? avatar) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, AppColors.mainColor.withOpacity(0.02)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.mainColor.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.mainColor.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.mainColor.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 38,
              backgroundColor: AppColors.mainColor.withOpacity(0.1),
              child: CircleAvatar(
                radius: 36,
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                backgroundColor: const Color(0xFFF8F9FA),
                child: avatar == null
                    ? Text(
                        _initial(name),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainColor,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '🛡️ مسؤول',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSection() {
    return _SectionCard(
      title: 'لوحة الأدمن',
      tiles: [
        _MenuTileData(
          icon: Icons.dashboard_rounded,
          label: 'لوحة التحكم',
          subtitle: 'عرض الإحصائيات والبيانات',
          onTap: () => context.go('/admin/dashboard'),
        ),
        _MenuTileData(
          icon: Icons.card_giftcard_rounded,
          label: 'إدارة الباقات',
          subtitle: 'عرض وتعديل وحذف الباقات',
          onTap: () => context.go('/admin/manage-packages'),
        ),
        _MenuTileData(
          icon: Icons.store_rounded,
          label: 'قائمة المتاجر',
          subtitle: 'عرض جميع المتاجر ومعلوماتها',
          onTap: () => context.go('/admin/stores'),
        ),
        _MenuTileData(
          icon: Icons.category_rounded,
          label: 'إدارة الفئات',
          subtitle: 'إضافة وتعديل وحذف الفئات',
          onTap: () => context.go('/admin/manage-categories'),
        ),
        _MenuTileData(
          icon: Icons.photo_library_rounded,
          label: 'إدارة الإعلانات',
          subtitle: 'تحكم في إعلانات الصفحة الرئيسية',
          onTap: () => context.go('/admin/ads'),
        ),
        _MenuTileData(
          icon: Icons.request_quote_rounded,
          label: 'طلبات الإعلانات',
          subtitle: 'عرض وإدارة طلبات الإعلانات',
          onTap: () => context.go('/admin/ad-requests'),
        ),
        _MenuTileData(
          icon: Icons.business_rounded,
          label: 'إدارة المكاتب',
          subtitle: 'عرض وإدارة مكاتب التوصيل',
          onTap: () => context.go('/admin/offices'),
        ),
        _MenuTileData(
          icon: Icons.delivery_dining_rounded,
          label: 'رسوم التوصيل',
          subtitle: 'إعدادات حساب رسوم التوصيل',
          onTap: () => context.go('/admin/delivery-fee-settings'),
        ),
        _MenuTileData(
          icon: Icons.motorcycle_rounded,
          label: 'طلبات تسجيل المناديب',
          subtitle: 'مراجعة وقبول أو رفض طلبات المناديب الجدد',
          onTap: () => context.go('/admin/courier-requests'),
        ),
        _MenuTileData(
          icon: Icons.report_gmailerrorred_rounded,
          label: 'إدارة البلاغات',
          subtitle: 'مراجعة البلاغات المقدمة من المستخدمين',
          onTap: () => context.go('/admin/reports'),
        ),
        _MenuTileData(
          icon: Icons.support_agent_rounded,
          label: 'مركز الدعم',
          subtitle: 'إدارة محادثات الدعم الفني والرد عليها',
          onTap: () => context.go('/admin/support'),
        ),
        _MenuTileData(
          icon: Icons.admin_panel_settings_rounded,
          label: 'إدارة المسؤولين',
          subtitle: 'تعيين صلاحيات المسؤولين والمشرفين',
          onTap: () => context.go('/admin/roles'),
        ),
        _MenuTileData(
          icon: Icons.delete_sweep_rounded,
          label: 'الحسابات المحذوفة',
          subtitle: 'استعراض واستعادة الحسابات المحذوفة مؤقتاً',
          onTap: () => context.go('/admin/deleted-accounts'),
        ),
        _MenuTileData(
          icon: Icons.history_rounded,
          label: 'سجلات النشاط',
          subtitle: 'عرض سجل العمليات والنشاطات الإدارية',
          onTap: () => context.go('/admin/activity-logs'),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return _SectionCard(
      title: 'معلومات',
      tiles: [
        _MenuTileData(
          icon: Icons.info_outline_rounded,
          label: 'حول التطبيق',
          subtitle: 'لوحة إدارة بازار السويس - إصدار 1.0.0',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSigningOut ? null : _confirmSignOut,
        icon: _isSigningOut
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.logout_rounded),
        label: Text(
          _isSigningOut ? 'جاري تسجيل الخروج...' : 'تسجيل الخروج',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  String _initial(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'م';
    return trimmed.substring(0, 1);
  }
}

// ========== Reusable Widgets ==========

class _SectionCard extends StatelessWidget {
  final String title;
  final List<_MenuTileData> tiles;

  const _SectionCard({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.mainColor.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ...tiles.map((tile) => _MenuTile(data: tile)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _MenuTileData {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuTileData({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });
}

class _MenuTile extends StatelessWidget {
  final _MenuTileData data;

  const _MenuTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Icon(data.icon, color: AppColors.mainColor, size: 24),
            title: Text(
              data.label,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: Color(0xFF1A1A1A),
              ),
            ),
            subtitle: data.subtitle != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data.subtitle!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  )
                : null,
            trailing: const Icon(
              Icons.arrow_back_ios_new,
              size: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ),
      ),
    );
  }
}
