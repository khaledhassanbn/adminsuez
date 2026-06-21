import 'package:flutter/material.dart';
import 'package:suez_admin/commission/models/wallet_transaction_model.dart';
import 'package:suez_admin/commission/services/commission_admin_service.dart';
import 'package:suez_admin/theme/app_color.dart';

class WalletManagementPage extends StatefulWidget {
  const WalletManagementPage({super.key});

  @override
  State<WalletManagementPage> createState() => _WalletManagementPageState();
}

class _WalletManagementPageState extends State<WalletManagementPage> {
  final _service = CommissionAdminService();
  String _filter = 'pending';

  Future<void> _approve(WalletTransactionModel tx) async {
    await _service.approveWalletTransaction(tx);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت الموافقة على طلب الشحن')),
    );
  }

  Future<void> _reject(WalletTransactionModel tx) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سبب الرفض'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'اكتب السبب'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    await _service.rejectWalletTransaction(tx: tx, reason: reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم رفض طلب الشحن')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.mainColor,
        title: const Text('إدارة طلبات الشحن'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text('فلتر الحالة:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _filter,
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('معلّق')),
                    DropdownMenuItem(value: 'approved', child: Text('مقبول')),
                    DropdownMenuItem(value: 'rejected', child: Text('مرفوض')),
                    DropdownMenuItem(value: 'all', child: Text('الكل')),
                  ],
                  onChanged: (v) => setState(() => _filter = v ?? 'pending'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<WalletTransactionModel>>(
              stream: _service.getWalletTransactions(),
              builder: (context, snapshot) {
                final rows = snapshot.data ?? [];
                final filtered = _filter == 'all'
                    ? rows
                    : rows.where((e) => e.status == _filter).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('لا توجد طلبات'));
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final tx = filtered[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text('المبلغ: ${tx.amount.toStringAsFixed(2)}'),
                        subtitle: Text(
                          'الحالة: ${tx.status} - المستخدم: ${tx.userId}',
                        ),
                        trailing: tx.status == 'pending'
                            ? Wrap(
                                spacing: 8,
                                children: [
                                  IconButton(
                                    onPressed: () => _approve(tx),
                                    icon: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _reject(tx),
                                    icon: const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
