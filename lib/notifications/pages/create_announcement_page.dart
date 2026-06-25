import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../viewmodels/announcement_viewmodel.dart';
import '../widgets/audience_selector.dart';
import '../widgets/delivery_type_selector.dart';
import '../widgets/cta_builder.dart';
import '../widgets/schedule_picker.dart';

/// صفحة إنشاء إعلان جديد
class CreateAnnouncementPage extends StatefulWidget {
  const CreateAnnouncementPage({super.key});

  @override
  State<CreateAnnouncementPage> createState() => _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState extends State<CreateAnnouncementPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AnnouncementViewModel>().resetForm();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إنشاء إعلان جديد',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<AnnouncementViewModel>(
        builder: (context, vm, _) {
          return Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // حقل العنوان
                    const Text(
                      'محتوى الإعلان',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      onChanged: vm.setTitle,
                      decoration: InputDecoration(
                        labelText: 'عنوان الإعلان *',
                        hintText: 'اكتب عنوان الإعلان هنا...',
                        prefixIcon: const Icon(Icons.title_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // حقل النص
                    TextFormField(
                      controller: _bodyController,
                      onChanged: vm.setBody,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'نص الإعلان *',
                        hintText: 'اكتب محتوى الإعلان هنا...',
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
                    const SizedBox(height: 16),

                    // رفع صورة
                    _buildImageSection(vm),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // الفئة المستهدفة
                    AudienceSelector(
                      selectedAudience: vm.targetAudience,
                      onChanged: vm.setTargetAudience,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // نوع الإرسال
                    DeliveryTypeSelector(
                      selectedType: vm.deliveryType,
                      onChanged: vm.setDeliveryType,
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

                    // وقت الإرسال
                    SchedulePicker(
                      isScheduled: vm.isScheduled,
                      scheduledAt: vm.scheduledAt,
                      onIsScheduledChanged: vm.setIsScheduled,
                      onScheduledAtChanged: vm.setScheduledAt,
                    ),
                    const SizedBox(height: 24),

                    // رسائل الخطأ
                    if (vm.errorMessage != null)
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

                    const SizedBox(height: 16),

                    // زر الإرسال
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: vm.isSending ? null : () => _submit(vm),
                        icon: vm.isSending
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Icon(vm.isScheduled
                                ? Icons.schedule_send_rounded
                                : Icons.send_rounded),
                        label: Text(
                          vm.isSending
                              ? (vm.isUploadingImage
                                  ? 'جاري رفع الصورة...'
                                  : 'جاري الإرسال...')
                              : (vm.isScheduled
                                  ? 'جدولة الإرسال'
                                  : 'إرسال الإعلان الآن'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: vm.isScheduled
                              ? const Color(0xFFF39C12)
                              : const Color(0xFFFF6B35),
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
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageSection(AnnouncementViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.image_rounded, size: 18, color: Color(0xFF4E99B4)),
            const SizedBox(width: 8),
            const Text(
              'صورة/بانر الإعلان',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const Spacer(),
            Text(
              'اختياري',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (vm.imageFile != null || vm.imageUrl != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: vm.imageFile != null
                    ? Image.file(
                        vm.imageFile!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        vm.imageUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: InkWell(
                  onTap: () {
                    vm.setImageFile(null);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: () => _pickImage(vm),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_rounded,
                      size: 36, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'اضغط لرفع صورة أو بانر',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickImage(AnnouncementViewModel vm) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 80,
    );
    if (picked != null) {
      vm.setImageFile(File(picked.path));
    }
  }

  Future<void> _submit(AnnouncementViewModel vm) async {
    final success = await vm.submitAnnouncement();
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
      context.go('/admin/notifications');
    }
  }
}
