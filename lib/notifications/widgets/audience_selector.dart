import 'package:flutter/material.dart';

/// ويدجيت اختيار الفئة المستهدفة
class AudienceSelector extends StatelessWidget {
  final String selectedAudience;
  final ValueChanged<String> onChanged;
  final bool showIndividual;

  const AudienceSelector({
    super.key,
    required this.selectedAudience,
    required this.onChanged,
    this.showIndividual = false,
  });

  static const List<Map<String, dynamic>> audiences = [
    {
      'value': 'all',
      'label': 'الجميع',
      'icon': Icons.groups_rounded,
      'color': Color(0xFF3498DB),
      'desc': 'جميع المستخدمين',
    },
    {
      'value': 'merchants',
      'label': 'أصحاب المتاجر',
      'icon': Icons.store_rounded,
      'color': Color(0xFF2ECC71),
      'desc': 'التجار وأصحاب المتاجر',
    },
    {
      'value': 'craftsmen',
      'label': 'الحرفيين',
      'icon': Icons.handyman_rounded,
      'color': Color(0xFF9B59B6),
      'desc': 'مقدمي الخدمات',
    },
    {
      'value': 'offices',
      'label': 'مكاتب الشحن',
      'icon': Icons.business_rounded,
      'color': Color(0xFFE67E22),
      'desc': 'مكاتب الشحن والتوصيل',
    },
    {
      'value': 'drivers',
      'label': 'المناديب',
      'icon': Icons.delivery_dining_rounded,
      'color': Color(0xFF1ABC9C),
      'desc': 'مناديب التوصيل',
    },
    {
      'value': 'customers',
      'label': 'العملاء',
      'icon': Icons.person_rounded,
      'color': Color(0xFFE91E63),
      'desc': 'العملاء والمشترين',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الفئة المستهدفة',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: audiences.map((audience) {
            final isSelected = selectedAudience == audience['value'];
            final color = audience['color'] as Color;

            return InkWell(
              onTap: () => onChanged(audience['value'] as String),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.15)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected ? color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      audience['icon'] as IconData,
                      size: 18,
                      color: isSelected ? color : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      audience['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? color : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (selectedAudience != 'all') ...[
          const SizedBox(height: 8),
          Text(
            _getDescription(selectedAudience),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  String _getDescription(String value) {
    final audience = audiences.firstWhere(
      (a) => a['value'] == value,
      orElse: () => {'desc': ''},
    );
    return audience['desc'] as String? ?? '';
  }
}
