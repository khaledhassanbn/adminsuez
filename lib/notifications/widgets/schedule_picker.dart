import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ويدجيت اختيار وقت الإرسال
class SchedulePicker extends StatelessWidget {
  final bool isScheduled;
  final DateTime? scheduledAt;
  final ValueChanged<bool> onIsScheduledChanged;
  final ValueChanged<DateTime?> onScheduledAtChanged;

  const SchedulePicker({
    super.key,
    required this.isScheduled,
    required this.scheduledAt,
    required this.onIsScheduledChanged,
    required this.onScheduledAtChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'وقت الإرسال',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),

        // خيارات الإرسال
        Row(
          children: [
            Expanded(
              child: _buildOption(
                context: context,
                icon: Icons.flash_on_rounded,
                label: 'إرسال فوري',
                isSelected: !isScheduled,
                color: const Color(0xFF2ECC71),
                onTap: () => onIsScheduledChanged(false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildOption(
                context: context,
                icon: Icons.schedule_rounded,
                label: 'جدولة',
                isSelected: isScheduled,
                color: const Color(0xFFF39C12),
                onTap: () => onIsScheduledChanged(true),
              ),
            ),
          ],
        ),

        // اختيار التاريخ والوقت
        if (isScheduled) ...[
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectDateTime(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF39C12).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFFF39C12),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تاريخ ووقت الإرسال',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scheduledAt != null
                              ? DateFormat('yyyy/MM/dd — HH:mm')
                                  .format(scheduledAt!)
                              : 'اضغط لاختيار التاريخ والوقت',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: scheduledAt != null
                                ? const Color(0xFF2C3E50)
                                : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.edit_calendar_rounded,
                    color: Color(0xFFF39C12),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey[500], size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final now = DateTime.now();

    // اختيار التاريخ
    final date = await showDatePicker(
      context: context,
      initialDate: scheduledAt ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4E99B4),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;

    // اختيار الوقت
    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        scheduledAt ?? now.add(const Duration(hours: 1)),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4E99B4),
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null) return;

    final scheduled = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    onScheduledAtChanged(scheduled);
  }
}
