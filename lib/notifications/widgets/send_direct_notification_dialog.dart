import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/announcement_viewmodel.dart';

/// حوار إرسال إشعار فردي — يُستخدم من صفحات تفاصيل المستخدمين
class SendDirectNotificationDialog extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final String targetUserType; // merchant | craftsman | driver | customer

  const SendDirectNotificationDialog({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    required this.targetUserType,
  });

  /// عرض الحوار بشكل مبسط
  static Future<void> show(
    BuildContext context, {
    required String targetUserId,
    required String targetUserName,
    required String targetUserType,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SendDirectNotificationDialog(
        targetUserId: targetUserId,
        targetUserName: targetUserName,
        targetUserType: targetUserType,
      ),
    );
  }

  @override
  State<SendDirectNotificationDialog> createState() =>
      _SendDirectNotificationDialogState();
}

class _SendDirectNotificationDialogState
    extends State<SendDirectNotificationDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _deliveryType = 'both';
  bool _isSending = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  String get _userTypeLabel {
    switch (widget.targetUserType) {
      case 'merchant':
        return 'تاجر';
      case 'craftsman':
        return 'حرفي';
      case 'driver':
        return 'مندوب';
      case 'customer':
        return 'عميل';
      default:
        return 'مستخدم';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // المقبض
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // العنوان
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4E99B4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Color(0xFF4E99B4),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إرسال إشعار فردي',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      Text(
                        'إلى $_userTypeLabel: ${widget.targetUserName}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // حقل العنوان
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'عنوان الإشعار',
                hintText: 'مثال: رسالة مهمة',
                prefixIcon: const Icon(Icons.title_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // حقل النص
            TextFormField(
              controller: _bodyController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'نص الإشعار',
                hintText: 'اكتب محتوى الإشعار هنا...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 50),
                  child: Icon(Icons.message_rounded),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // نوع الإرسال
            const Text(
              'نوع الإرسال',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTypeChip('both', 'الكل', Icons.campaign_rounded),
                const SizedBox(width: 8),
                _buildTypeChip(
                    'push_only', 'Push', Icons.notifications_active_rounded),
                const SizedBox(width: 8),
                _buildTypeChip(
                    'in_app_only', 'داخلي', Icons.mail_rounded),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[400], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style:
                            TextStyle(color: Colors.red[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // زر الإرسال
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _send,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isSending ? 'جاري الإرسال...' : 'إرسال الإشعار',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4E99B4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String value, String label, IconData icon) {
    final isSelected = _deliveryType == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _deliveryType = value),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4E99B4).withOpacity(0.1)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4E99B4)
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: isSelected
                      ? const Color(0xFF4E99B4)
                      : Colors.grey[600]),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF4E99B4)
                      : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'يرجى إدخال عنوان الإشعار');
      return;
    }
    if (_bodyController.text.trim().isEmpty) {
      setState(() => _error = 'يرجى إدخال نص الإشعار');
      return;
    }

    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      final vm = context.read<AnnouncementViewModel>();
      final success = await vm.sendDirectNotification(
        targetUserId: widget.targetUserId,
        targetUserName: widget.targetUserName,
        targetUserType: widget.targetUserType,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        deliveryType: _deliveryType,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'تم إرسال الإشعار إلى ${widget.targetUserName} بنجاح'),
              backgroundColor: const Color(0xFF2ECC71),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          setState(() => _error = vm.errorMessage ?? 'فشل الإرسال');
        }
      }
    } catch (e) {
      setState(() => _error = 'خطأ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}
