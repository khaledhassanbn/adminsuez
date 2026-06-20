import 'package:flutter/material.dart';
import '../models/support_conversation.dart';

class ConversationStatusBadge extends StatelessWidget {
  final ConversationStatus status;

  const ConversationStatusBadge({
    super.key,
    required this.status,
  });

  String _statusText() {
    switch (status) {
      case ConversationStatus.open:
        return 'مفتوحة';
      case ConversationStatus.inProgress:
        return 'قيد المتابعة';
      case ConversationStatus.resolved:
        return 'تم الحل';
      case ConversationStatus.closed:
        return 'مغلقة';
    }
  }

  Color _badgeColor() {
    switch (status) {
      case ConversationStatus.open:
        return Colors.blue;
      case ConversationStatus.inProgress:
        return Colors.orange;
      case ConversationStatus.resolved:
        return Colors.green;
      case ConversationStatus.closed:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.8,
        ),
      ),
      child: Text(
        _statusText(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
