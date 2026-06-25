import 'package:flutter/material.dart';

/// ويدجيت اختيار نوع الإرسال
class DeliveryTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;

  const DeliveryTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  static const List<Map<String, dynamic>> types = [
    {
      'value': 'both',
      'label': 'إشعار + رسالة داخلية',
      'icon': Icons.campaign_rounded,
      'color': Color(0xFF4E99B4),
      'desc': 'الأفضل: يصل فوراً ويُحفظ في مركز الرسائل',
    },
    {
      'value': 'push_only',
      'label': 'إشعار فوري فقط',
      'icon': Icons.notifications_active_rounded,
      'color': Color(0xFFFF6B35),
      'desc': 'يظهر كإشعار push فقط، لا يُحفظ في مركز الرسائل',
    },
    {
      'value': 'in_app_only',
      'label': 'رسالة داخلية فقط',
      'icon': Icons.mail_rounded,
      'color': Color(0xFF2ECC71),
      'desc': 'تظهر في مركز الرسائل فقط، بدون إشعار push',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نوع الإرسال',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        ...types.map((type) {
          final isSelected = selectedType == type['value'];
          final color = type['color'] as Color;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => onChanged(type['value'] as String),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.08)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.15)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        type['icon'] as IconData,
                        size: 20,
                        color: isSelected ? color : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type['label'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected ? color : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            type['desc'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: color, size: 22),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
