import 'package:flutter/material.dart';

/// ويدجيت بناء زر الإجراء (CTA)
class CTABuilder extends StatelessWidget {
  final bool hasCTA;
  final String ctaType;
  final String ctaLabel;
  final String ctaValue;
  final ValueChanged<bool> onHasCTAChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onLabelChanged;
  final ValueChanged<String> onValueChanged;

  const CTABuilder({
    super.key,
    required this.hasCTA,
    required this.ctaType,
    required this.ctaLabel,
    required this.ctaValue,
    required this.onHasCTAChanged,
    required this.onTypeChanged,
    required this.onLabelChanged,
    required this.onValueChanged,
  });

  static const List<Map<String, dynamic>> ctaTypes = [
    {'value': 'open_page', 'label': 'فتح صفحة', 'icon': Icons.open_in_new},
    {'value': 'open_store', 'label': 'فتح متجر', 'icon': Icons.store_rounded},
    {'value': 'open_order', 'label': 'فتح طلب', 'icon': Icons.receipt_long},
    {
      'value': 'open_product',
      'label': 'فتح منتج',
      'icon': Icons.shopping_bag_rounded,
    },
    {
      'value': 'external_link',
      'label': 'رابط خارجي',
      'icon': Icons.link_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Switch تفعيل/إلغاء CTA
        SwitchListTile(
          title: const Text(
            'إضافة زر إجراء (CTA)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          subtitle: const Text(
            'زر يظهر مع الإعلان لتنفيذ إجراء محدد',
            style: TextStyle(fontSize: 12),
          ),
          value: hasCTA,
          onChanged: onHasCTAChanged,
          activeColor: const Color(0xFF4E99B4),
          contentPadding: EdgeInsets.zero,
        ),

        if (hasCTA) ...[
          const SizedBox(height: 12),

          // نوع الإجراء
          DropdownButtonFormField<String>(
            value: ctaType,
            decoration: InputDecoration(
              labelText: 'نوع الإجراء',
              prefixIcon: const Icon(Icons.touch_app_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: ctaTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type['value'] as String,
                child: Row(
                  children: [
                    Icon(type['icon'] as IconData,
                        size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(type['label'] as String),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onTypeChanged(value);
            },
          ),
          const SizedBox(height: 12),

          // نص الزر
          TextFormField(
            initialValue: ctaLabel,
            decoration: InputDecoration(
              labelText: 'نص الزر',
              hintText: 'مثال: تصفح الآن',
              prefixIcon: const Icon(Icons.text_fields_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: onLabelChanged,
          ),
          const SizedBox(height: 12),

          // القيمة (المعرف أو الرابط)
          TextFormField(
            initialValue: ctaValue,
            decoration: InputDecoration(
              labelText: _getValueLabel(ctaType),
              hintText: _getValueHint(ctaType),
              prefixIcon: Icon(_getValueIcon(ctaType)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: onValueChanged,
          ),
        ],
      ],
    );
  }

  String _getValueLabel(String type) {
    switch (type) {
      case 'open_store':
        return 'معرّف المتجر (Market ID)';
      case 'open_order':
        return 'معرّف الطلب (Order ID)';
      case 'open_product':
        return 'معرّف المنتج (Product ID)';
      case 'external_link':
        return 'الرابط (URL)';
      default:
        return 'اسم الصفحة أو المعرّف';
    }
  }

  String _getValueHint(String type) {
    switch (type) {
      case 'open_store':
        return 'أدخل معرّف المتجر';
      case 'open_order':
        return 'أدخل معرّف الطلب';
      case 'open_product':
        return 'أدخل معرّف المنتج';
      case 'external_link':
        return 'https://example.com';
      default:
        return 'أدخل المعرّف أو اسم الصفحة';
    }
  }

  IconData _getValueIcon(String type) {
    switch (type) {
      case 'external_link':
        return Icons.link_rounded;
      default:
        return Icons.tag_rounded;
    }
  }
}
