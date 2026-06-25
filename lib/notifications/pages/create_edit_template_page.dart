import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../viewmodels/template_viewmodel.dart';
import '../models/announcement_template_model.dart';
import '../widgets/cta_builder.dart';

/// صفحة إنشاء/تعديل قالب
class CreateEditTemplatePage extends StatefulWidget {
  final String? templateId;

  const CreateEditTemplatePage({super.key, this.templateId});

  @override
  State<CreateEditTemplatePage> createState() => _CreateEditTemplatePageState();
}

class _CreateEditTemplatePageState extends State<CreateEditTemplatePage> {
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.templateId != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<TemplateViewModel>();
      if (_isEdit) {
        vm.loadTemplate(widget.templateId!).then((_) {
          if (!mounted) return;
          _nameController.text = vm.name;
          _titleController.text = vm.title;
          _bodyController.text = vm.body;
        });
      } else {
        vm.resetForm();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'تعديل القالب' : 'إنشاء قالب جديد',
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF9B59B6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<TemplateViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && _isEdit) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // معلومات القالب
                const Text(
                  'معلومات القالب',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 16),

                // اسم القالب
                TextFormField(
                  controller: _nameController,
                  onChanged: vm.setName,
                  decoration: InputDecoration(
                    labelText: 'اسم القالب (للأدمن) *',
                    hintText: 'مثال: رسالة ترحيب جديد',
                    prefixIcon: const Icon(Icons.label_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),

                // التصنيف
                DropdownButtonFormField<String>(
                  value: vm.category,
                  decoration: InputDecoration(
                    labelText: 'التصنيف *',
                    prefixIcon: const Icon(Icons.category_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: AnnouncementTemplateModel.categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat['value'],
                      child: Text(cat['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) vm.setCategory(value);
                  },
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // محتوى القالب
                const Text(
                  'محتوى القالب',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 18, color: Colors.blue[400]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'يمكنك استخدام {{userName}} و {{storeName}} كمتغيرات',
                          style: TextStyle(
                              fontSize: 12, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // العنوان
                TextFormField(
                  controller: _titleController,
                  onChanged: vm.setTitle,
                  decoration: InputDecoration(
                    labelText: 'عنوان القالب *',
                    hintText: 'مثال: مرحباً بك في بازار السويس!',
                    prefixIcon: const Icon(Icons.title_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),

                // النص
                TextFormField(
                  controller: _bodyController,
                  onChanged: vm.setBody,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'نص القالب *',
                    hintText:
                        'مثال: مرحباً {{userName}}! نرحب بك في منصة بازار السويس...',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 70),
                      child: Icon(Icons.message_rounded),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // CTA
                CTABuilder(
                  hasCTA: vm.hasCTA,
                  ctaType: vm.ctaType,
                  ctaLabel: vm.ctaLabel,
                  ctaValue: vm.ctaValue,
                  onHasCTAChanged: vm.setHasCTA,
                  onTypeChanged: vm.setCTAType,
                  onLabelChanged: vm.setCTALabel,
                  onValueChanged: vm.setCTAValue,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // تفعيل/تعطيل
                SwitchListTile(
                  title: const Text(
                    'القالب مفعّل',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  subtitle: const Text(
                    'القوالب المفعّلة تظهر عند إنشاء إعلان جديد',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: vm.isActive,
                  onChanged: vm.setIsActive,
                  activeColor: const Color(0xFF9B59B6),
                  contentPadding: EdgeInsets.zero,
                ),

                // رسائل الخطأ
                if (vm.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red[400], size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            vm.errorMessage!,
                            style: TextStyle(
                                color: Colors.red[700], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // زر الحفظ
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: vm.isLoading ? null : () => _save(vm),
                    icon: vm.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      vm.isLoading
                          ? 'جاري الحفظ...'
                          : (_isEdit ? 'حفظ التعديلات' : 'إنشاء القالب'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B59B6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _save(TemplateViewModel vm) async {
    bool success;
    if (_isEdit) {
      success = await vm.updateTemplate(widget.templateId!);
    } else {
      success = await vm.saveTemplate();
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.successMessage ?? 'تم بنجاح'),
          backgroundColor: const Color(0xFF2ECC71),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      context.go('/admin/notifications/templates');
    }
  }
}
