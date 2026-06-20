import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;
import '../services/admin_support_service.dart';
import '../../theme/app_color.dart';

class UserProfileCard extends StatefulWidget {
  final String userId;

  const UserProfileCard({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<UserProfileCard> {
  final AdminSupportService _supportService = AdminSupportService();
  bool _isLoading = true;
  bool _isCollapsed = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final data = await _supportService.getUserDetails(widget.userId);
      if (mounted) {
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatRegistrationDate(dynamic dateField) {
    if (dateField == null) return 'غير محدد';
    DateTime? dateTime;

    if (dateField is Timestamp) {
      dateTime = dateField.toDate();
    } else if (dateField is String) {
      dateTime = DateTime.tryParse(dateField);
    }

    if (dateTime != null) {
      return intl.DateFormat('yyyy/MM/dd', 'ar').format(dateTime);
    }
    return 'غير محدد';
  }

  String _getRoleDisplayName(String? role) {
    if (role == null) return 'عميل / مستخدم';
    switch (role.toLowerCase()) {
      case 'admin':
        return 'مسؤول (Admin)';
      case 'store_owner':
      case 'merchant':
        return 'تاجر (Merchant)';
      case 'craftsman':
        return 'صنايعي (Craftsman)';
      case 'courier':
      case 'driver':
        return 'مندوب توصيل (Driver)';
      case 'user':
      default:
        return 'عميل (Customer)';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_userData == null) {
      return const SizedBox.shrink();
    }

    final name = _userData!['name'] ?? 'مستخدم غير معروف';
    final phone = _userData!['phone'] ?? _userData!['phoneNumber'] ?? 'لا يوجد رقم هاتف';
    final role = _userData!['role'] ?? 'user';
    final registrationDate = _formatRegistrationDate(_userData!['createdAt'] ?? _userData!['registrationDate']);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.15),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          onExpansionChanged: (expanded) {
            setState(() {
              _isCollapsed = !expanded;
            });
          },
          leading: Icon(
            Icons.account_box_rounded,
            color: AppColors.mainColor,
          ),
          title: Text(
            'بيانات صاحب البلاغ: $name',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          trailing: Icon(
            _isCollapsed ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
            color: Colors.grey[600],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildProfileRow(Icons.phone_iphone_rounded, 'رقم الهاتف:', phone),
                  _buildProfileRow(Icons.badge_rounded, 'نوع الحساب:', _getRoleDisplayName(role)),
                  _buildProfileRow(Icons.calendar_month_rounded, 'تاريخ التسجيل:', registrationDate),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              fontSize: 12.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
