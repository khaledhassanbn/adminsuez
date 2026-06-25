import 'package:flutter/material.dart';
import '../models/announcement_template_model.dart';

/// بطاقة قالب في القائمة
class TemplateCard extends StatelessWidget {
  final AnnouncementTemplateModel template;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggleActive;
  final VoidCallback? onDelete;

  const TemplateCard({
    super.key,
    required this.template,
    this.onTap,
    this.onToggleActive,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(template.category);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: template.isActive
                ? Colors.grey.shade200
                : Colors.red.shade100,
          ),
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
            Row(
              children: [
                // التصنيف
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getCategoryIcon(template.category),
                          size: 14, color: catColor),
                      const SizedBox(width: 4),
                      Text(
                        template.categoryLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: catColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // حالة التفعيل
                if (onToggleActive != null)
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: template.isActive,
                      onChanged: onToggleActive,
                      activeColor: const Color(0xFF4E99B4),
                    ),
                  ),
                // حذف
                if (onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 20, color: Colors.red[300]),
                    onPressed: () => _confirmDelete(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // اسم القالب
            Text(
              template.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: template.isActive
                    ? const Color(0xFF2C3E50)
                    : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),

            // عنوان القالب
            Text(
              template.title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // نص القالب (مقتطف)
            Text(
              template.body,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            // عدد الاستخدامات
            Row(
              children: [
                Icon(Icons.repeat_rounded, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  'استُخدم ${template.usageCount} مرة',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                if (!template.isActive) ...[
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'معطّل',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[400],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف القالب'),
        content: Text('هل أنت متأكد من حذف القالب "${template.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'welcome':
        return const Color(0xFF2ECC71);
      case 'renewal':
        return const Color(0xFF3498DB);
      case 'suspension':
        return const Color(0xFFE74C3C);
      case 'order':
        return const Color(0xFFF39C12);
      case 'promotion':
        return const Color(0xFF9B59B6);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'welcome':
        return Icons.waving_hand_rounded;
      case 'renewal':
        return Icons.autorenew_rounded;
      case 'suspension':
        return Icons.block_rounded;
      case 'order':
        return Icons.receipt_long_rounded;
      case 'promotion':
        return Icons.local_offer_rounded;
      default:
        return Icons.article_rounded;
    }
  }
}
