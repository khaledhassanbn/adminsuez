import 'package:flutter/material.dart';
import '../models/announcement_model.dart';

/// بطاقة إحصائيات الإعلان
class AnnouncementStatsCard extends StatelessWidget {
  final AnnouncementStats stats;

  const AnnouncementStatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4E99B4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Color(0xFF4E99B4),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'إحصائيات الإعلان',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // شبكة الإحصائيات
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.groups_rounded,
                  label: 'المستهدفون',
                  value: stats.targetedCount.toString(),
                  color: const Color(0xFF3498DB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle_rounded,
                  label: 'تم الإرسال',
                  value: stats.pushSentCount.toString(),
                  color: const Color(0xFF2ECC71),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.error_rounded,
                  label: 'فشل الإرسال',
                  value: stats.pushFailedCount.toString(),
                  color: const Color(0xFFE74C3C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.visibility_rounded,
                  label: 'مرات القراءة',
                  value: stats.inAppReadCount.toString(),
                  color: const Color(0xFF9B59B6),
                ),
              ),
            ],
          ),

          // شريط نسبة النجاح
          if (stats.targetedCount > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'نسبة النجاح',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
                const Spacer(),
                Text(
                  '${stats.successRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getSuccessRateColor(stats.successRate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: stats.successRate / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getSuccessRateColor(stats.successRate),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSuccessRateColor(double rate) {
    if (rate >= 90) return const Color(0xFF2ECC71);
    if (rate >= 70) return const Color(0xFFF39C12);
    if (rate >= 50) return const Color(0xFFE67E22);
    return const Color(0xFFE74C3C);
  }
}
