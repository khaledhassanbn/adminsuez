import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_color.dart';
import '../models/ad_model.dart';
import '../viewmodels/create_admin_ad_viewmodel.dart';
import '../widgets/loading_snackbar.dart';

class CreateAdminAdPage extends StatelessWidget {
  const CreateAdminAdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateAdminAdViewModel()..loadTargets(),
      child: const _CreateAdminAdView(),
    );
  }
}

class _CreateAdminAdView extends StatefulWidget {
  const _CreateAdminAdView();

  @override
  State<_CreateAdminAdView> createState() => _CreateAdminAdViewState();
}

class _CreateAdminAdViewState extends State<_CreateAdminAdView> {
  final _durationController = TextEditingController(text: '48');

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'إنشاء إعلان من الإدارة',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: AppColors.mainColor,
        ),
        body: Consumer<CreateAdminAdViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoadingTargets) {
              return const Center(child: CircularProgressIndicator());
            }

            final targets = vm.targetType == AdTargetType.craftsman
                ? vm.craftsmen
                : vm.stores;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'صورة الإعلان',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: vm.pickImage,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: vm.selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                vm.selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text('اضغط لاختيار صورة',
                                    style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'مدة العرض (بالساعات)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (v) =>
                        vm.setDurationHours(int.tryParse(v) ?? 0),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'نوع التوجيه',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: AdTargetType.store,
                        label: Text('متجر'),
                      ),
                      ButtonSegment(
                        value: AdTargetType.craftsman,
                        label: Text('حرفي'),
                      ),
                      ButtonSegment(
                        value: AdTargetType.imageOnly,
                        label: Text('صورة فقط'),
                      ),
                    ],
                    selected: {vm.targetType},
                    onSelectionChanged: (s) => vm.setTargetType(s.first),
                  ),
                  if (vm.targetType != AdTargetType.imageOnly) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: vm.selectedTargetId,
                      decoration: InputDecoration(
                        labelText: vm.targetType == AdTargetType.craftsman
                            ? 'اختر الحرفي'
                            : 'اختر المتجر',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: targets.map((t) {
                        return DropdownMenuItem(
                          value: t['id'],
                          child: Text(t['name'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (id) {
                        final target = targets.firstWhere((t) => t['id'] == id);
                        vm.setTarget(id, target['name']);
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: vm.isLoading
                          ? null
                          : () => _submit(context, vm),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                      ),
                      child: vm.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'نشر الإعلان',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    CreateAdminAdViewModel vm,
  ) async {
    LoadingSnackBar.show(context, 'جاري إنشاء الإعلان...');
    final success = await vm.submit();
    LoadingSnackBar.hide(context);

    if (!context.mounted) return;

    if (success) {
      LoadingSnackBar.showSuccess(context, 'تم إنشاء الإعلان بنجاح');
      context.go('/admin/ads-dashboard');
    } else {
      LoadingSnackBar.showError(
        context,
        vm.errorMessage ?? 'فشل إنشاء الإعلان',
      );
    }
  }
}
