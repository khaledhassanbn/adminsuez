import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:suez_admin/orders/models/order_model.dart';
import 'package:suez_admin/orders/services/order_lookup_service.dart';

/// أقسام تفاصيل الطلب (بيانات الطلب، العميل، المتجر، المندوب، سجل الحالات).
class OrderDetailsSections extends StatelessWidget {
  final OrderModel order;
  final List<OrderTimelineEntry> timeline;
  final String? resolvedCourierName;

  const OrderDetailsSections({
    super.key,
    required this.order,
    required this.timeline,
    this.resolvedCourierName,
  });

  static const Color _primary = Color(0xFF4E99B4);
  static const Color _danger = Color(0xFFE05C5C);
  static const Color _textPrimary = Color(0xFF1A2E38);
  static const Color _textSecondary = Color(0xFF6B8A96);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildOrderCard(context),
        const SizedBox(height: 12),
        _buildCustomerCard(context),
        const SizedBox(height: 12),
        _buildStoreCard(context),
        const SizedBox(height: 12),
        _buildCourierCard(context),
        const SizedBox(height: 12),
        _buildTimelineCard(context),
      ],
    );
  }

  Widget _buildOrderCard(BuildContext context) {
    final dateStr = order.createdAt != null
        ? DateFormat('yyyy/MM/dd - HH:mm').format(order.createdAt!)
        : '—';
    return OrderSectionCard(
      title: 'بيانات الطلب',
      icon: Icons.receipt_long_rounded,
      child: Column(
        children: [
          _kvRow(context, 'رقم الطلب', order.orderId, copyable: true),
          _kvRow(context, 'تاريخ الإنشاء', dateStr),
          _statusRow(order.statusDisplay),
          _kvRow(
              context, 'قيمة الطلب', '${order.totalAmount.toStringAsFixed(2)} جنيه'),
          if (order.serviceFee > 0)
            _kvRow(context, 'رسوم الخدمة',
                '${order.serviceFee.toStringAsFixed(2)} جنيه'),
          if (order.cancelReason != null && order.cancelReason!.isNotEmpty)
            _kvRow(context, 'سبب الإلغاء', order.cancelReason!,
                valueColor: _danger),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context) {
    return OrderSectionCard(
      title: 'بيانات العميل',
      icon: Icons.person_rounded,
      child: Column(
        children: [
          _kvRow(context, 'اسم العميل', order.customerName),
          _kvRow(context, 'رقم الهاتف', order.customerPhone, copyable: true),
          if (order.customerAddress.isNotEmpty)
            _kvRow(context, 'العنوان', order.customerAddress),
          if (order.customerId.isNotEmpty)
            _kvRow(context, 'معرف العميل', order.customerId, copyable: true),
        ],
      ),
    );
  }

  Widget _buildStoreCard(BuildContext context) {
    return OrderSectionCard(
      title: 'بيانات المتجر',
      icon: Icons.storefront_rounded,
      child: Column(
        children: [
          _kvRow(context, 'اسم المتجر', order.storeName),
          _kvRow(context, 'معرف المتجر', order.storeId, copyable: true),
        ],
      ),
    );
  }

  Widget _buildCourierCard(BuildContext context) {
    final hasCourier =
        order.courierId != null || resolvedCourierName != null;
    return OrderSectionCard(
      title: 'بيانات المندوب',
      icon: Icons.delivery_dining_rounded,
      child: hasCourier
          ? Column(
              children: [
                _kvRow(
                  context,
                  'اسم المندوب',
                  resolvedCourierName ?? order.courierName ?? 'غير محدد',
                ),
                if (order.courierId != null)
                  _kvRow(context, 'معرف المندوب', order.courierId!,
                      copyable: true),
              ],
            )
          : const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'لم يتم تعيين مندوب لهذا الطلب',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: _textSecondary,
                ),
              ),
            ),
    );
  }

  Widget _buildTimelineCard(BuildContext context) {
    return OrderSectionCard(
      title: 'سجل الحالات',
      icon: Icons.timeline_rounded,
      child: timeline.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'لا يوجد سجل حالات لهذا الطلب',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: _textSecondary,
                ),
              ),
            )
          : Column(
              children: timeline.asMap().entries.map((e) {
                final isLast = e.key == timeline.length - 1;
                return OrderTimelineTile(entry: e.value, isLast: isLast);
              }).toList(),
            ),
    );
  }

  Widget _statusRow(String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const SizedBox(
            width: 110,
            child: Text(
              'حالة الطلب',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: _textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kvRow(
    BuildContext context,
    String key,
    String value, {
    bool copyable = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              key,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: _textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? _textPrimary,
              ),
            ),
          ),
          if (copyable)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم النسخ'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: const Icon(Icons.copy_rounded,
                  size: 16, color: _textSecondary),
            ),
        ],
      ),
    );
  }
}

class OrderSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const OrderSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  static const Color _primary = Color(0xFF4E99B4);
  static const Color _textPrimary = Color(0xFF1A2E38);
  static const Color _divider = Color(0xFFE2EEF2);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: _primary, size: 17),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Divider(height: 1, color: _divider),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class OrderTimelineTile extends StatelessWidget {
  final OrderTimelineEntry entry;
  final bool isLast;

  const OrderTimelineTile({super.key, required this.entry, required this.isLast});

  static const Color _primary = Color(0xFF4E99B4);
  static const Color _textPrimary = Color(0xFF1A2E38);
  static const Color _textSecondary = Color(0xFF6B8A96);
  static const Color _divider = Color(0xFFE2EEF2);

  @override
  Widget build(BuildContext context) {
    final timeStr = entry.time != null
        ? DateFormat('yyyy/MM/dd - HH:mm').format(entry.time!)
        : '—';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: _divider),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: _textSecondary,
                    ),
                  ),
                  if (entry.actor != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'بواسطة: ${entry.actor}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                  if (entry.reason != null && entry.reason!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'السبب: ${entry.reason}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
