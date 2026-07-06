import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../authentication/guards/AuthGuard.dart';
import '../../theme/app_color.dart';
import '../viewmodels/admin_ad_requests_viewmodel.dart';
import '../widgets/request_card.dart';
import '../widgets/rejection_bottom_sheet.dart';
import '../widgets/loading_snackbar.dart';

class AdminAdRequestsPage extends StatelessWidget {
  const AdminAdRequestsPage({super.key});

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
      create: (_) => AdminAdRequestsViewModel()..loadRequests(),
      child: const _AdminAdRequestsView(),
    );
  }
}

class _AdminAdRequestsView extends StatelessWidget {
  const _AdminAdRequestsView();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'طلبات الإعلانات',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: AppColors.mainColor,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Consumer<AdminAdRequestsViewModel>(
              builder: (context, vm, _) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _ReqFilterChip(
                      label: 'معلقة',
                      selected: vm.filter == RequestFilter.pending,
                      onTap: () => vm.setFilter(RequestFilter.pending),
                    ),
                    _ReqFilterChip(
                      label: 'موافق عليها',
                      selected: vm.filter == RequestFilter.approved,
                      onTap: () => vm.setFilter(RequestFilter.approved),
                    ),
                    _ReqFilterChip(
                      label: 'مرفوضة',
                      selected: vm.filter == RequestFilter.rejected,
                      onTap: () => vm.setFilter(RequestFilter.rejected),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Consumer<AdminAdRequestsViewModel>(
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

            if (viewModel.requests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد طلبات',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => viewModel.loadRequests(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: viewModel.requests.length,
                itemBuilder: (context, index) {
                  final request = viewModel.requests[index];
                  return RequestCard(
                    request: request,
                    onApprove: () => _handleApprove(context, request.id),
                    onReject: () => _handleReject(context, request.id),
                    onDelete: () => _handleDelete(context, request.id),
                    formatDate: viewModel.formatDate,
                    getStatusColor: viewModel.getStatusColor,
                    getStatusText: viewModel.getStatusText,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleApprove(BuildContext context, String requestId) async {
    final viewModel = context.read<AdminAdRequestsViewModel>();

    LoadingSnackBar.show(context, 'جاري إنشاء الإعلان...');
    final success = await viewModel.approveRequest(requestId);
    LoadingSnackBar.hide(context);

    if (success) {
      LoadingSnackBar.showSuccess(
        context,
        'تم الموافقة على الطلب وإنشاء الإعلان بنجاح',
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        context.go('/admin/ads');
      }
    } else {
      LoadingSnackBar.showError(
        context,
        viewModel.errorMessage ?? 'فشل تحديث حالة الطلب',
      );
    }
  }

  Future<void> _handleReject(BuildContext context, String requestId) async {
    final viewModel = context.read<AdminAdRequestsViewModel>();
    final reason = await RejectionBottomSheet.show(context);
    if (reason == null || !context.mounted) return;

    LoadingSnackBar.show(context, 'جاري رفض الطلب واسترداد المبلغ...');
    final success = await viewModel.rejectWithReason(requestId, reason);
    LoadingSnackBar.hide(context);

    if (success) {
      LoadingSnackBar.showSuccess(
        context,
        'تم رفض الطلب واسترداد المبلغ للمستخدم',
      );
    } else {
      LoadingSnackBar.showError(
        context,
        viewModel.errorMessage ?? 'فشل رفض الطلب',
      );
    }
  }

  Future<void> _handleDelete(BuildContext context, String requestId) async {
    final viewModel = context.read<AdminAdRequestsViewModel>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الطلب'),
        content: const Text('هل أنت متأكد من حذف هذا الطلب؟'),
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
      final success = await viewModel.deleteRequest(requestId);

      if (success) {
        LoadingSnackBar.showSuccess(context, 'تم حذف الطلب بنجاح');
      } else {
        LoadingSnackBar.showError(
          context,
          viewModel.errorMessage ?? 'فشل حذف الطلب',
        );
      }
    }
  }
}

class _ReqFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReqFilterChip({
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



