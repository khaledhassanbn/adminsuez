import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../authentication/guards/AuthGuard.dart';
import '../../theme/app_color.dart';
import '../viewmodels/ads_dashboard_viewmodel.dart';
import '../widgets/stats_card.dart';
import '../widgets/loading_snackbar.dart';

class AdsDashboardPage extends StatelessWidget {
  const AdsDashboardPage({super.key});

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

    return ChangeNotifierProvider(
      create: (_) => AdsDashboardViewModel()..loadStats(),
      child: const _AdsDashboardView(),
    );
  }
}

class _AdsDashboardView extends StatelessWidget {
  const _AdsDashboardView();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'لوحة إعلانات الهيدر',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: AppColors.mainColor,
          elevation: 0,
        ),
        body: Consumer<AdsDashboardViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.errorMessage != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                LoadingSnackBar.showError(context, vm.errorMessage!);
                vm.clearError();
              });
            }

            final stats = vm.stats;

            return RefreshIndicator(
              onRefresh: () => vm.loadStats(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                    children: [
                      StatsCard(
                        label: 'نشطة',
                        value: '${stats['active'] ?? 0}',
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      StatsCard(
                        label: 'مجدولة',
                        value: '${stats['scheduled'] ?? 0}',
                        icon: Icons.schedule,
                        color: Colors.blue,
                      ),
                      StatsCard(
                        label: 'معلقة',
                        value: '${vm.pendingCount}',
                        icon: Icons.hourglass_top,
                        color: Colors.orange,
                      ),
                      StatsCard(
                        label: 'مرفوضة',
                        value: '${stats['rejectedRequests'] ?? 0}',
                        icon: Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                      StatsCard(
                        label: 'متوقفة',
                        value: '${stats['paused'] ?? 0}',
                        icon: Icons.pause_circle_outline,
                        color: Colors.amber,
                      ),
                      StatsCard(
                        label: 'منتهية',
                        value: '${stats['expired'] ?? 0}',
                        icon: Icons.timer_off_outlined,
                        color: Colors.grey,
                      ),
                      StatsCard(
                        label: 'أرباح (جنيه)',
                        value: '${(stats['revenue'] ?? 0).toStringAsFixed(0)}',
                        icon: Icons.payments_outlined,
                        color: AppColors.mainColor,
                      ),
                      StatsCard(
                        label: 'إجمالي الإعلانات',
                        value: '${stats['totalAds'] ?? 0}',
                        icon: Icons.campaign_outlined,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'إجراءات سريعة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _QuickActionTile(
                    icon: Icons.add_photo_alternate,
                    title: 'إنشاء إعلان من الإدارة',
                    subtitle: 'إعلان مجاني بدون طلب',
                    onTap: () => context.push('/admin/create-admin-ad'),
                  ),
                  _QuickActionTile(
                    icon: Icons.request_quote,
                    title: 'طلبات الإعلانات',
                    subtitle: '${vm.pendingCount} طلب معلق',
                    badge: vm.pendingCount > 0 ? '${vm.pendingCount}' : null,
                    onTap: () => context.push('/admin/ad-requests'),
                  ),
                  _QuickActionTile(
                    icon: Icons.photo_library,
                    title: 'إدارة الإعلانات',
                    subtitle: 'عرض وتعديل كل الإعلانات',
                    onTap: () => context.push('/admin/ads'),
                  ),
                  _QuickActionTile(
                    icon: Icons.swap_vert,
                    title: 'ترتيب الإعلانات',
                    subtitle: 'تغيير ترتيب الظهور',
                    onTap: () => context.push('/admin/ads-reorder'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.mainColor.withOpacity(0.1),
          child: Icon(icon, color: AppColors.mainColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
            : const Icon(Icons.arrow_back_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
