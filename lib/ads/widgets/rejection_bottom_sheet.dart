import 'package:flutter/material.dart';

class RejectionBottomSheet extends StatefulWidget {
  const RejectionBottomSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const RejectionBottomSheet(),
    );
  }

  @override
  State<RejectionBottomSheet> createState() => _RejectionBottomSheetState();
}

class _RejectionBottomSheetState extends State<RejectionBottomSheet> {
  static const _reasons = [
    'صورة غير مناسبة',
    'إعلان مخالف',
    'بيانات ناقصة',
    'جودة منخفضة',
  ];

  final _customController = TextEditingController();
  String? _selected;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'سبب الرفض',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم استرداد المبلغ تلقائياً وإرسال إشعار للمستخدم',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ..._reasons.map(
            (reason) => RadioListTile<String>(
              value: reason,
              groupValue: _selected,
              title: Text(reason),
              onChanged: (v) => setState(() => _selected = v),
            ),
          ),
          RadioListTile<String>(
            value: 'custom',
            groupValue: _selected,
            title: const Text('سبب مخصص'),
            onChanged: (v) => setState(() => _selected = v),
          ),
          if (_selected == 'custom')
            TextField(
              controller: _customController,
              decoration: const InputDecoration(
                hintText: 'اكتب سبب الرفض',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_selected == null) return;
                final reason = _selected == 'custom'
                    ? _customController.text.trim()
                    : _selected!;
                if (reason.isEmpty) return;
                Navigator.pop(context, reason);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('تأكيد الرفض'),
            ),
          ),
        ],
      ),
    );
  }
}
