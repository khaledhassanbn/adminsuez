import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../viewmodels/announcement_viewmodel.dart';
import '../widgets/announcement_card.dart';

/// صفحة سجل الإعلانات المرسلة
class AnnouncementsHistoryPage extends StatelessWidget {
  const AnnouncementsHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'سجل الإعلانات',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF3498DB),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilters(context),
            tooltip: 'فلترة',
          ),
        ],
      ),
      body: Consumer<AnnouncementViewModel>(
        builder: (context, vm, _) {
          return Column(
            children: [
              // شريط الفلاتر النشطة
              if (vm.statusFilter != 'all' || vm.audienceFilter != 'all')
                _buildActiveFiltersBar(context, vm),

              // قائمة الإعلانات
              Expanded(
                child: StreamBuilder(
                  stream: vm.filteredAnnouncements,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }

                    final announcements = snapshot.data ?? [];
                    if (announcements.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_rounded,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد إعلانات',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500],
                              ),
                            ),
                            if (vm.statusFilter != 'all' ||
                                vm.audienceFilter != 'all') ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: vm.clearFilters,
                                child: const Text('مسح الفلاتر'),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: announcements.length,
                      itemBuilder: (context, index) {
                        final announcement = announcements[index];
                        return AnnouncementCard(
                          announcement: announcement,
                          onTap: () => context.go(
                              '/admin/notifications/${announcement.id}'),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/admin/notifications/create'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('إعلان جديد',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildActiveFiltersBar(
      BuildContext context, AnnouncementViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFF8F9FA),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_rounded, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          if (vm.statusFilter != 'all')
            _buildFilterChip(
              label: _getStatusLabel(vm.statusFilter),
              onRemove: () => vm.setStatusFilter('all'),
            ),
          if (vm.audienceFilter != 'all') ...[
            const SizedBox(width: 8),
            _buildFilterChip(
              label: _getAudienceLabel(vm.audienceFilter),
              onRemove: () => vm.setAudienceFilter('all'),
            ),
          ],
          const Spacer(),
          TextButton(
            onPressed: vm.clearFilters,
            child: const Text('مسح الكل', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF4E99B4).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4E99B4).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4E99B4),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: Color(0xFF4E99B4)),
          ),
        ],
      ),
    );
  }

  void _showFilters(BuildContext context) {
    final vm = context.read<AnnouncementViewModel>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'فلترة الإعلانات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // فلتر الحالة
                  const Text('الحالة',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterOption('all', 'الكل', vm.statusFilter,
                          (v) {
                        vm.setStatusFilter(v);
                        setModalState(() {});
                      }),
                      _buildFilterOption(
                          'sent', 'تم الإرسال', vm.statusFilter, (v) {
                        vm.setStatusFilter(v);
                        setModalState(() {});
                      }),
                      _buildFilterOption(
                          'scheduled', 'مجدول', vm.statusFilter, (v) {
                        vm.setStatusFilter(v);
                        setModalState(() {});
                      }),
                      _buildFilterOption('draft', 'مسودة', vm.statusFilter,
                          (v) {
                        vm.setStatusFilter(v);
                        setModalState(() {});
                      }),
                      _buildFilterOption('failed', 'فشل', vm.statusFilter,
                          (v) {
                        vm.setStatusFilter(v);
                        setModalState(() {});
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // فلتر الفئة
                  const Text('الفئة المستهدفة',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterOption('all', 'الكل', vm.audienceFilter,
                          (v) {
                        vm.setAudienceFilter(v);
                        setModalState(() {});
                      }),
                      _buildFilterOption(
                          'merchants', 'تجار', vm.audienceFilter, (v) {
                        vm.setAudienceFilter(v);
                        setModalState(() {});
                      }),
                      _buildFilterOption(
                          'drivers', 'مناديب', vm.audienceFilter, (v) {
                        vm.setAudienceFilter(v);
                        setModalState(() {});
                      }),
                      _buildFilterOption(
                          'customers', 'عملاء', vm.audienceFilter, (v) {
                        vm.setAudienceFilter(v);
                        setModalState(() {});
                      }),
                      _buildFilterOption(
                          'individual', 'فردي', vm.audienceFilter, (v) {
                        vm.setAudienceFilter(v);
                        setModalState(() {});
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4E99B4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('تطبيق'),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOption(String value, String label, String currentValue,
      ValueChanged<String> onChanged) {
    final isSelected = currentValue == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onChanged(value),
      selectedColor: const Color(0xFF4E99B4).withOpacity(0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? const Color(0xFF4E99B4) : Colors.grey[700],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'sent':
        return 'تم الإرسال';
      case 'scheduled':
        return 'مجدول';
      case 'draft':
        return 'مسودة';
      case 'failed':
        return 'فشل';
      default:
        return status;
    }
  }

  String _getAudienceLabel(String audience) {
    switch (audience) {
      case 'merchants':
        return 'تجار';
      case 'drivers':
        return 'مناديب';
      case 'customers':
        return 'عملاء';
      case 'individual':
        return 'فردي';
      default:
        return audience;
    }
  }
}
