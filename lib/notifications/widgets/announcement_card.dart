import 'package:flutter/material.dart';
import '../models/announcement_model.dart';
import 'package:intl/intl.dart';

/// بطاقة إعلان في القائمة
class AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback? onTap;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصف العلوي: العنوان + الحالة
            Row(
              children: [
                Expanded(
                  child: Text(
                    announcement.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 8),

            // نص الإعلان (مقتطف)
            Text(
              announcement.body,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // الصف السفلي: الفئة المستهدفة + النوع + التاريخ
            Row(
              children: [
                _buildAudienceBadge(),
                const SizedBox(width: 8),
                _buildDeliveryTypeIcon(),
                const Spacer(),
                Icon(Icons.access_time_rounded,
                    size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(announcement.sentAt ?? announcement.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    switch (announcement.status) {
      case 'sent':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'scheduled':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFF57C00);
        break;
      case 'sending':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
        break;
      case 'failed':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        break;
      case 'partial':
        bgColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFFF8F00);
        break;
      default: // draft
        bgColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF757575);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        announcement.statusLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildAudienceBadge() {
    final color = _getAudienceColor(announcement.targetAudience);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getAudienceIcon(announcement.targetAudience),
              size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            announcement.targetAudienceLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTypeIcon() {
    IconData icon;
    String tooltip;
    switch (announcement.deliveryType) {
      case 'push_only':
        icon = Icons.notifications_active_rounded;
        tooltip = 'إشعار فوري فقط';
        break;
      case 'in_app_only':
        icon = Icons.mail_rounded;
        tooltip = 'رسالة داخلية فقط';
        break;
      default:
        icon = Icons.campaign_rounded;
        tooltip = 'إشعار + رسالة داخلية';
    }

    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: 16, color: Colors.grey[500]),
    );
  }

  Color _getAudienceColor(String audience) {
    switch (audience) {
      case 'all':
        return const Color(0xFF3498DB);
      case 'merchants':
        return const Color(0xFF2ECC71);
      case 'craftsmen':
        return const Color(0xFF9B59B6);
      case 'offices':
        return const Color(0xFFE67E22);
      case 'drivers':
        return const Color(0xFF1ABC9C);
      case 'customers':
        return const Color(0xFFE91E63);
      case 'individual':
        return const Color(0xFF607D8B);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  IconData _getAudienceIcon(String audience) {
    switch (audience) {
      case 'all':
        return Icons.groups_rounded;
      case 'merchants':
        return Icons.store_rounded;
      case 'craftsmen':
        return Icons.handyman_rounded;
      case 'offices':
        return Icons.business_rounded;
      case 'drivers':
        return Icons.delivery_dining_rounded;
      case 'customers':
        return Icons.person_rounded;
      case 'individual':
        return Icons.person_pin_rounded;
      default:
        return Icons.group_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return DateFormat('yyyy/MM/dd HH:mm').format(date);
  }
}
