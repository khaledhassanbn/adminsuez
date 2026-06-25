import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../viewmodels/template_viewmodel.dart';
import '../widgets/template_card.dart';

/// صفحة إدارة القوالب
class TemplatesPage extends StatelessWidget {
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'القوالب الجاهزة',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF9B59B6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<TemplateViewModel>(
        builder: (context, vm, _) {
          return StreamBuilder(
            stream: vm.templatesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              final templates = snapshot.data ?? [];
              if (templates.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد قوالب بعد',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أنشئ قالبك الأول لتسريع إرسال الإعلانات',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return TemplateCard(
                    template: template,
                    onTap: () => context.go(
                        '/admin/notifications/templates/${template.id}'),
                    onToggleActive: (isActive) {
                      vm.toggleActive(template.id, isActive);
                    },
                    onDelete: () {
                      vm.deleteTemplate(template.id);
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.go('/admin/notifications/templates/create'),
        backgroundColor: const Color(0xFF9B59B6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('قالب جديد',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
