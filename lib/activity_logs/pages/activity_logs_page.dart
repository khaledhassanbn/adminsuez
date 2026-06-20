import 'package:flutter/material.dart';
import 'package:suez_admin/activity_logs/repositories/admin_log_repository.dart';
import 'package:suez_admin/activity_logs/models/admin_log_model.dart';
import 'package:suez_admin/theme/app_color.dart';

class ActivityLogsPage extends StatelessWidget {
  const ActivityLogsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final repo = AdminLogRepository();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('سجلات النشاط'),
        backgroundColor: AppColors.mainColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<List<AdminLogModel>>(
        stream: repo.watchRecent(limit: 100),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const Center(child: Text('لا توجد سجلات'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                title: Text(log.actionType.labelAr),
                subtitle: Text('${log.adminName} • ${log.targetName ?? log.targetId}'),
                trailing: Text(
                  log.createdAt != null
                      ? '${log.createdAt!.day}/${log.createdAt!.month}'
                      : '',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
