import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_support_service.dart';
import '../../theme/app_color.dart';

class LinkedEntityCard extends StatefulWidget {
  final String? merchantId;
  final String? merchantName;
  final String? craftsmanId;
  final String? craftsmanName;
  final String? driverId;
  final String? driverName;
  final String? orderId;

  const LinkedEntityCard({
    super.key,
    this.merchantId,
    this.merchantName,
    this.craftsmanId,
    this.craftsmanName,
    this.driverId,
    this.driverName,
    this.orderId,
  });

  @override
  State<LinkedEntityCard> createState() => _LinkedEntityCardState();
}

class _LinkedEntityCardState extends State<LinkedEntityCard> {
  final AdminSupportService _supportService = AdminSupportService();

  bool get _hasEntity =>
      (widget.merchantId != null && widget.merchantId!.isNotEmpty) ||
      (widget.craftsmanId != null && widget.craftsmanId!.isNotEmpty) ||
      (widget.driverId != null && widget.driverId!.isNotEmpty) ||
      (widget.orderId != null && widget.orderId!.isNotEmpty);

  String _entityTitle() {
    if (widget.merchantId != null && widget.merchantId!.isNotEmpty) {
      return 'المتجر المرتبط: ${widget.merchantName ?? widget.merchantId}';
    }
    if (widget.craftsmanId != null && widget.craftsmanId!.isNotEmpty) {
      return 'الصنايعي المرتبط: ${widget.craftsmanName ?? widget.craftsmanId}';
    }
    if (widget.driverId != null && widget.driverId!.isNotEmpty) {
      return 'المندوب المرتبط: ${widget.driverName ?? widget.driverId}';
    }
    if (widget.orderId != null && widget.orderId!.isNotEmpty) {
      return 'الطلب المرتبط: #${widget.orderId}';
    }
    return '';
  }

  IconData _entityIcon() {
    if (widget.merchantId != null && widget.merchantId!.isNotEmpty) {
      return Icons.store_rounded;
    }
    if (widget.craftsmanId != null && widget.craftsmanId!.isNotEmpty) {
      return Icons.construction_rounded;
    }
    if (widget.driverId != null && widget.driverId!.isNotEmpty) {
      return Icons.motorcycle_rounded;
    }
    if (widget.orderId != null && widget.orderId!.isNotEmpty) {
      return Icons.receipt_long_rounded;
    }
    return Icons.link_rounded;
  }

  Future<void> _handleViewDetails(BuildContext context) async {
    // 1. إذا كان مندوب: نوجهه لصفحة طلب المندوب الحالية في لوحة الإدارة
    if (widget.driverId != null && widget.driverId!.isNotEmpty) {
      context.push('/admin/courier-request/${widget.driverId}');
      return;
    }

    // 2. الباقي: نعرض بياناتهم في BottomSheet تفاعلي رائع
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _EntityDetailsBottomSheet(
        merchantId: widget.merchantId,
        craftsmanId: widget.craftsmanId,
        orderId: widget.orderId,
        supportService: _supportService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasEntity) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.mainColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.mainColor.withOpacity(0.18),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _entityIcon(),
            color: AppColors.mainColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _entityTitle(),
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.mainColor.withOpacity(0.9),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _handleViewDetails(context),
            icon: const Icon(Icons.open_in_new_rounded, size: 13),
            label: const Text(
              'عرض',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntityDetailsBottomSheet extends StatefulWidget {
  final String? merchantId;
  final String? craftsmanId;
  final String? orderId;
  final AdminSupportService supportService;

  const _EntityDetailsBottomSheet({
    this.merchantId,
    this.craftsmanId,
    this.orderId,
    required this.supportService,
  });

  @override
  State<_EntityDetailsBottomSheet> createState() => _EntityDetailsBottomSheetState();
}

class _EntityDetailsBottomSheetState extends State<_EntityDetailsBottomSheet> {
  bool _loading = true;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      Map<String, dynamic>? res;
      if (widget.merchantId != null) {
        res = await widget.supportService.getMerchantDetails(widget.merchantId!);
      } else if (widget.craftsmanId != null) {
        res = await widget.supportService.getCraftsmanDetails(widget.craftsmanId!);
      } else if (widget.orderId != null) {
        res = await widget.supportService.getOrderDetails(widget.orderId!);
      }
      
      setState(() {
        _data = res;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : _error != null
                ? SizedBox(
                    height: 200,
                    child: Center(
                      child: Text('خطأ أثناء تحميل البيانات: $_error'),
                    ),
                  )
                : _data == null
                    ? const SizedBox(
                        height: 200,
                        child: Center(
                          child: Text('لم يتم العثور على أي بيانات في السجلات'),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                widget.merchantId != null 
                                    ? Icons.store_rounded 
                                    : (widget.craftsmanId != null 
                                        ? Icons.construction_rounded 
                                        : Icons.receipt_long_rounded),
                                color: AppColors.mainColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                widget.merchantId != null
                                    ? 'تفاصيل المتجر'
                                    : (widget.craftsmanId != null ? 'تفاصيل الصنايعي' : 'تفاصيل الطلب'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ..._buildFields(),
                        ],
                      ),
      ),
    );
  }

  List<Widget> _buildFields() {
    final fields = <Widget>[];

    if (widget.merchantId != null) {
      fields.add(_buildDetailRow('اسم المتجر:', _data!['storeName'] ?? _data!['name'] ?? 'غير محدد'));
      fields.add(_buildDetailRow('صاحب المتجر (UID):', _data!['ownerUid'] ?? 'غير محدد'));
      fields.add(_buildDetailRow('حالة الحساب:', _data!['adminStatus'] ?? 'غير محدد'));
      fields.add(_buildDetailRow('الفئة:', _data!['categoryName'] ?? 'غير محدد'));
      fields.add(_buildDetailRow('إجمالي المنتجات:', '${_data!['totalProducts'] ?? 0} منتج'));
    } else if (widget.craftsmanId != null) {
      fields.add(_buildDetailRow('الاسم:', _data!['name'] ?? 'غير محدد'));
      fields.add(_buildDetailRow('المهنة:', _data!['professionName'] ?? 'غير محدد'));
      fields.add(_buildDetailRow('حالة الحساب الإدارية:', _data!['adminStatus'] ?? 'غير محدد'));
      fields.add(_buildDetailRow('التقييم:', '${_data!['rating'] ?? 0.0} / 5.0'));
      fields.add(_buildDetailRow('رقم الهاتف:', _data!['phoneNumber'] ?? 'غير محدد'));
    } else if (widget.orderId != null) {
      fields.add(_buildDetailRow('رقم الطلب:', '#${widget.orderId}'));
      fields.add(_buildDetailRow('حالة الطلب الحالية:', _data!['status'] ?? 'غير محدد'));
      fields.add(_buildDetailRow('إجمالي السعر:', '${_data!['totalPrice'] ?? _data!['total'] ?? 0} جنيه'));
      fields.add(_buildDetailRow('اسم العميل:', _data!['userName'] ?? _data!['customerName'] ?? 'غير محدد'));
      fields.add(_buildDetailRow('طريقة الدفع:', _data!['paymentMethod'] ?? 'غير محدد'));
    }

    return fields;
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
