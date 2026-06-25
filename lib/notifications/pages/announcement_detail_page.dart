import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';
import '../viewmodels/announcement_viewmodel.dart';
import '../widgets/announcement_stats_card.dart';

/// صفحة تفاصيل الإعلان + الإحصائيات
class AnnouncementDetailPage extends StatelessWidget {
  final String announcementId;

  const AnnouncementDetailPage({
    super.key,
    required this.announcementId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تفاصيل الإعلان',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4E99B4),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<AnnouncementModel?>(
        stream: AnnouncementService().getAnnouncementStream(announcementId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          final announcement = snapshot.data;
          if (announcement == null) {
            return const Center(
              child: Text('الإعلان غير موجود',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // معاينة الإعلان
                _buildPreviewCard(announcement),
                const SizedBox(height: 20),

                // الإحصائيات
                AnnouncementStatsCard(stats: announcement.stats),
                const SizedBox(height: 20),

                // تفاصيل إضافية
                _buildDetailsCard(announcement),
                const SizedBox(height: 20),

                if (announcement.status == 'sending' ||
                    announcement.status == 'failed' ||
                    announcement.status == 'partial')
                  _buildRetryCard(context, announcement),

                // سجل الأخطاء
                if (announcement.stats.pushFailedCount > 0)
                  _buildErrorLogs(),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreviewCard(AnnouncementModel announcement) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.preview_rounded,
                  color: Color(0xFF4E99B4), size: 22),
              const SizedBox(width: 8),
              const Text(
                'معاينة الإعلان',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const Spacer(),
              _buildStatusBadge(announcement.status, announcement.statusLabel),
            ],
          ),
          const SizedBox(height: 16),

          // الصورة
          if (announcement.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: announcement.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              ),
            ),
          if (announcement.imageUrl != null) const SizedBox(height: 16),

          // العنوان
          Text(
            announcement.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),

          // النص
          Text(
            announcement.body,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),

          // CTA
          if (announcement.cta != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.touch_app_rounded),
                label: Text(announcement.cta!.label),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4E99B4),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFF4E99B4).withOpacity(0.7),
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            Text(
              '${announcement.cta!.typeLabel}: ${announcement.cta!.value}',
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsCard(AnnouncementModel announcement) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تفاصيل الإرسال',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.groups_rounded,
            label: 'الفئة المستهدفة',
            value: announcement.targetAudienceLabel,
          ),
          _buildDetailRow(
            icon: Icons.campaign_rounded,
            label: 'نوع الإرسال',
            value: announcement.deliveryTypeLabel,
          ),
          _buildDetailRow(
            icon: Icons.person_rounded,
            label: 'بواسطة',
            value: announcement.createdByName,
          ),
          _buildDetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'تاريخ الإنشاء',
            value: DateFormat('yyyy/MM/dd HH:mm')
                .format(announcement.createdAt),
          ),
          if (announcement.sentAt != null)
            _buildDetailRow(
              icon: Icons.send_rounded,
              label: 'تاريخ الإرسال',
              value: DateFormat('yyyy/MM/dd HH:mm')
                  .format(announcement.sentAt!),
            ),
          if (announcement.scheduledAt != null)
            _buildDetailRow(
              icon: Icons.schedule_rounded,
              label: 'مجدول في',
              value: DateFormat('yyyy/MM/dd HH:mm')
                  .format(announcement.scheduledAt!),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryCard(BuildContext context, AnnouncementModel announcement) {
    final isStuck = announcement.status == 'sending';
    final isFailed = announcement.status == 'failed';
    final isPartial = announcement.status == 'partial';

    return Consumer<AnnouncementViewModel>(
      builder: (context, vm, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isFailed
                  ? Colors.red.shade200
                  : isPartial
                      ? Colors.orange.shade200
                      : Colors.amber.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isStuck
                        ? Icons.hourglass_top_rounded
                        : isFailed
                            ? Icons.error_outline_rounded
                            : Icons.warning_amber_rounded,
                    color: isFailed
                        ? Colors.red[400]
                        : isPartial
                            ? Colors.orange[700]
                            : Colors.amber[800],
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isStuck
                          ? 'الإعلان عالق في حالة «جاري الإرسال»'
                          : isFailed
                              ? 'فشل إرسال الإعلان'
                              : 'وصلت الرسالة داخل التطبيق فقط',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isFailed
                            ? Colors.red[700]
                            : isPartial
                                ? Colors.orange[800]
                                : Colors.amber[900],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isStuck
                    ? 'اضغط «إعادة الإرسال» لإكمال العملية. أو أنشئ إعلاناً جديداً بنوع «رسالة داخلية فقط» للاختبار بدون إشعار فوري.'
                    : isFailed
                        ? 'تأكد من نشر Cloud Functions على السيرفر، ثم أعد المحاولة.'
                        : 'الإشعار الفوري (push) لم يصل. يمكنك إعادة المحاولة أو ترك الرسالة كما هي في مركز الرسائل.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
              ),
              if (vm.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  vm.errorMessage!,
                  style: TextStyle(fontSize: 12, color: Colors.red[600]),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: vm.isSending
                      ? null
                      : () async {
                          final ok =
                              await vm.retryAnnouncement(announcement.id);
                          if (!context.mounted) return;
                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    vm.successMessage ?? 'تم الإرسال بنجاح'),
                                backgroundColor: const Color(0xFF2ECC71),
                              ),
                            );
                          }
                        },
                  icon: vm.isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(vm.isSending ? 'جاري الإرسال...' : 'إعادة الإرسال'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4E99B4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorLogs() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  color: Colors.red[400], size: 22),
              const SizedBox(width: 8),
              Text(
                'سجل الأخطاء',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<AnnouncementErrorLog>>(
            stream: AnnouncementService().getErrorLogs(announcementId),
            builder: (context, snapshot) {
              final errors = snapshot.data ?? [];
              if (errors.isEmpty) {
                return Text(
                  'لا توجد تفاصيل أخطاء مسجلة',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                );
              }

              return Column(
                children: errors.map((error) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          error.errorType,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          error.errorMessage,
                          style: TextStyle(
                              fontSize: 12, color: Colors.red[600]),
                        ),
                        Text(
                          'توكنات فاشلة: ${error.failedTokensCount}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, String label) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'sent':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'scheduled':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFF57C00);
        break;
      case 'failed':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        break;
      case 'sending':
        bgColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFF9A825);
        break;
      case 'partial':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        break;
      default:
        bgColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF757575);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
