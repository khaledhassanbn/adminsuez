import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../authentication/guards/AuthGuard.dart';
import '../../theme/app_color.dart';
import '../viewmodels/admin_ads_viewmodel.dart';
import '../widgets/ad_slot_card.dart';
import '../widgets/loading_snackbar.dart';
import 'ads_reorder_page.dart';

class AdminAdsPage extends StatelessWidget {
  const AdminAdsPage({super.key});

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
      create: (_) => AdminAdsViewModel()..loadData(),
      child: const _AdminAdsView(),
    );
  }
}

class _AdminAdsView extends StatelessWidget {
  const _AdminAdsView();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'إدارة الإعلانات',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: AppColors.mainColor,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Consumer<AdminAdsViewModel>(
              builder: (context, vm, _) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'الكل',
                      selected: vm.filter == AdFilter.all,
                      onTap: () => vm.setFilter(AdFilter.all),
                    ),
                    _FilterChip(
                      label: 'نشطة',
                      selected: vm.filter == AdFilter.active,
                      onTap: () => vm.setFilter(AdFilter.active),
                    ),
                    _FilterChip(
                      label: 'متوقفة',
                      selected: vm.filter == AdFilter.paused,
                      onTap: () => vm.setFilter(AdFilter.paused),
                    ),
                    _FilterChip(
                      label: 'منتهية',
                      selected: vm.filter == AdFilter.expired,
                      onTap: () => vm.setFilter(AdFilter.expired),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.swap_vert, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdsReorderPage(),
                  ),
                ).then((_) {
                  context.read<AdminAdsViewModel>().loadData();
                });
              },
              tooltip: 'ترتيب الإعلانات',
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _handleAddNewAd(context),
              tooltip: 'إضافة إعلان جديد',
            ),
          ],
        ),
        body: Consumer<AdminAdsViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.errorMessage != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                LoadingSnackBar.showError(context, viewModel.errorMessage!);
                viewModel.clearError();
              });
            }

            if (viewModel.ads.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => viewModel.loadData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.campaign,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد إعلانات فعالة',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _handleAddNewAd(context),
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة إعلان جديد'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mainColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => viewModel.loadData(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: viewModel.ads.length,
                itemBuilder: (context, index) {
                  final ad = viewModel.ads[index];
                  return AdSlotCard(
                    key: ValueKey('ad_${ad.slotId}_$index'),
                    ad: ad,
                    stores: viewModel.stores,
                    craftsmen: viewModel.craftsmen,
                    onPickImage: () => _handlePickImage(context, ad.slotId),
                    onSave: (updatedAd) => _handleSaveAd(context, updatedAd),
                    onDelete: () => _handleDeleteAd(context, ad.slotId),
                    onToggleStatus: () =>
                        _handleToggleStatus(context, ad.slotId, ad.isActive),
                    onPause: () => _handlePause(context, ad.slotId),
                    onResume: () => _handleResume(context, ad.slotId),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleAddNewAd(BuildContext context) async {
    final viewModel = context.read<AdminAdsViewModel>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة إعلان جديد'),
        content: const Text('هل تريد إضافة إعلان جديد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      LoadingSnackBar.show(context, 'جاري إضافة الإعلان...');
      final success = await viewModel.addNewAd();
      LoadingSnackBar.hide(context);

      if (success) {
        LoadingSnackBar.showSuccess(context, 'تم إضافة الإعلان بنجاح');
      } else {
        LoadingSnackBar.showError(
          context,
          viewModel.errorMessage ?? 'فشل إضافة الإعلان',
        );
      }
    }
  }

  Future<void> _handleDeleteAd(BuildContext context, int slotId) async {
    final viewModel = context.read<AdminAdsViewModel>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: const Text('هل أنت متأكد من حذف هذا الإعلان؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      LoadingSnackBar.show(context, 'جاري حذف الإعلان...');
      final success = await viewModel.deleteAd(slotId);
      LoadingSnackBar.hide(context);

      if (success) {
        LoadingSnackBar.showSuccess(context, 'تم حذف الإعلان بنجاح');
      } else {
        LoadingSnackBar.showError(
          context,
          viewModel.errorMessage ?? 'فشل حذف الإعلان',
        );
      }
    }
  }

  Future<void> _handleToggleStatus(
    BuildContext context,
    int slotId,
    bool isActive,
  ) async {
    final viewModel = context.read<AdminAdsViewModel>();

    LoadingSnackBar.show(context, 'جاري تحديث حالة الإعلان...');
    final success = await viewModel.toggleAdStatus(slotId, isActive);
    if (!context.mounted) return;
    LoadingSnackBar.hide(context);

    if (success) {
      LoadingSnackBar.showSuccess(
        context,
        isActive ? 'تم إيقاف الإعلان' : 'تم تفعيل الإعلان',
      );
    } else {
      LoadingSnackBar.showError(
        context,
        viewModel.errorMessage ?? 'فشل تغيير حالة الإعلان',
      );
    }
  }

  Future<void> _handlePickImage(BuildContext context, int slotId) async {
    final viewModel = context.read<AdminAdsViewModel>();

    LoadingSnackBar.show(context, 'جاري رفع الصورة...');
    final imageUrl = await viewModel.pickAndUploadImage(slotId);
    LoadingSnackBar.hide(context);

    if (imageUrl != null) {
      LoadingSnackBar.showSuccess(context, 'تم رفع الصورة بنجاح');
    } else {
      LoadingSnackBar.showError(
        context,
        viewModel.errorMessage ?? 'فشل رفع الصورة',
      );
    }
  }

  Future<void> _handleSaveAd(BuildContext context, ad) async {
    final viewModel = context.read<AdminAdsViewModel>();

    LoadingSnackBar.show(context, 'جاري حفظ الإعلان...');
    final success = await viewModel.saveAd(ad);
    LoadingSnackBar.hide(context);

    if (success) {
      LoadingSnackBar.showSuccess(context, 'تم حفظ الإعلان بنجاح');
    } else {
      LoadingSnackBar.showError(
        context,
        viewModel.errorMessage ?? 'فشل حفظ الإعلان',
      );
    }
  }

  Future<void> _handlePause(BuildContext context, int slotId) async {
    final viewModel = context.read<AdminAdsViewModel>();
    LoadingSnackBar.show(context, 'جاري إيقاف الإعلان...');
    final success = await viewModel.pauseAd(slotId);
    if (!context.mounted) return;
    LoadingSnackBar.hide(context);
    if (success) {
      LoadingSnackBar.showSuccess(context, 'تم إيقاف الإعلان');
    } else {
      LoadingSnackBar.showError(
        context,
        viewModel.errorMessage ?? 'فشل إيقاف الإعلان',
      );
    }
  }

  Future<void> _handleResume(BuildContext context, int slotId) async {
    final viewModel = context.read<AdminAdsViewModel>();
    LoadingSnackBar.show(context, 'جاري استئناف الإعلان...');
    final success = await viewModel.resumeAd(slotId);
    if (!context.mounted) return;
    LoadingSnackBar.hide(context);
    if (success) {
      LoadingSnackBar.showSuccess(context, 'تم استئناف الإعلان');
    } else {
      LoadingSnackBar.showError(
        context,
        viewModel.errorMessage ?? 'فشل استئناف الإعلان',
      );
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Material(
        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.mainColor : Colors.white,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}



