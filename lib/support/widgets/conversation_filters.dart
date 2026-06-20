import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/admin_support_viewmodel.dart';
import '../../theme/app_color.dart';

class ConversationFilters extends StatelessWidget {
  const ConversationFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminSupportViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. شريط البحث
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: (val) => viewModel.setSearchQuery(val),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'بحث باسم المستخدم أو الرسالة أو الكيان...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13.5),
                prefixIcon: Icon(Icons.search, color: AppColors.mainColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),

        // 2. فلاتر الحالة (Filter Chips)
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildStatusChip(context, viewModel, 'all', 'الكل'),
              _buildStatusChip(context, viewModel, 'open', 'مفتوحة'),
              _buildStatusChip(context, viewModel, 'in_progress', 'قيد المتابعة'),
              _buildStatusChip(context, viewModel, 'resolved', 'تم الحل'),
              _buildStatusChip(context, viewModel, 'closed', 'مغلقة'),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 3. فلاتر متقدمة (Dropdowns)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              // فلتر نوع المستخدم
              _buildDropdown(
                label: 'نوع المستخدم',
                value: viewModel.userTypeFilter ?? 'all',
                items: const {
                  'all': 'كل المستخدمين',
                  'customer': 'العملاء',
                  'merchant': 'التجار',
                  'craftsman': 'الصنايعية',
                  'driver': 'المناديب',
                },
                onChanged: (val) => viewModel.setUserTypeFilter(val),
              ),
              const SizedBox(width: 8),

              // فلتر نوع المشكلة
              _buildDropdown(
                label: 'نوع المشكلة',
                value: viewModel.issueTypeFilter ?? 'all',
                items: const {
                  'all': 'كل المشاكل',
                  'store_issue': 'مشاكل المتاجر',
                  'craftsman_issue': 'مشاكل الصنايعية',
                  'driver_issue': 'مشاكل المناديب',
                  'customer_issue': 'مشاكل العملاء',
                  'app_issue': 'مشاكل التطبيق',
                  'general_inquiry': 'استفسار عام',
                },
                onChanged: (val) => viewModel.setIssueTypeFilter(val),
              ),
              const SizedBox(width: 8),

              // فلتر الأولوية
              _buildDropdown(
                label: 'الأولوية',
                value: viewModel.priorityFilter ?? 'all',
                items: const {
                  'all': 'كل الأولويات',
                  'low': 'منخفضة',
                  'medium': 'متوسطة',
                  'high': 'عالية',
                },
                onChanged: (val) => viewModel.setPriorityFilter(val),
              ),
              const SizedBox(width: 8),

              // فلتر مصدر المحادثة
              _buildDropdown(
                label: 'المصدر',
                value: viewModel.sourceFilter ?? 'all',
                items: const {
                  'all': 'كل المصادر',
                  'customer_app': 'تطبيق العملاء',
                  'merchant_app': 'تطبيق التجار',
                  'craftsman_app': 'تطبيق الصنايعية',
                  'driver_app': 'تطبيق المناديب',
                },
                onChanged: (val) => viewModel.setSourceFilter(val),
              ),
              
              if (viewModel.statusFilter != 'all' ||
                  viewModel.userTypeFilter != 'all' ||
                  viewModel.issueTypeFilter != 'all' ||
                  viewModel.priorityFilter != 'all' ||
                  viewModel.sourceFilter != 'all') ...[
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => viewModel.clearFilters(),
                  icon: const Icon(Icons.clear_all_rounded, size: 16, color: Colors.red),
                  label: const Text(
                    'مسح الفلاتر',
                    style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    AdminSupportViewModel viewModel,
    String value,
    String label,
  ) {
    final isSelected = viewModel.statusFilter == value;
    final themeColor = AppColors.mainColor;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            viewModel.setStatusFilter(value);
          }
        },
        selectedColor: themeColor,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? themeColor : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        elevation: isSelected ? 4 : 0,
        pressElevation: 2,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF1E293B),
            fontFamily: 'Tajawal',
          ),
          items: items.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
        ),
      ),
    );
  }
}
