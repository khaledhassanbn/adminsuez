import 'package:flutter/material.dart';
import 'package:suez_admin/orders/models/order_model.dart';
import 'package:suez_admin/orders/services/order_lookup_service.dart';
import 'package:suez_admin/orders/widgets/order_details_sections.dart';

/// صفحة البحث عن طلب برقمه وعرض كامل تفاصيله وسجل حالاته.
class OrderLookupPage extends StatefulWidget {
  final String? initialOrderId;
  const OrderLookupPage({super.key, this.initialOrderId});

  @override
  State<OrderLookupPage> createState() => _OrderLookupPageState();
}

class _OrderLookupPageState extends State<OrderLookupPage> {
  final _service = OrderLookupService();
  final _searchController = TextEditingController();

  static const Color _primary = Color(0xFF4E99B4);
  static const Color _surface = Color(0xFFF7FAFB);
  static const Color _textSecondary = Color(0xFF6B8A96);
  static const Color _divider = Color(0xFFE2EEF2);

  bool _loading = false;
  bool _searched = false;
  OrderModel? _order;
  List<OrderTimelineEntry> _timeline = [];
  String? _resolvedCourierName;

  @override
  void initState() {
    super.initState();
    if (widget.initialOrderId != null && widget.initialOrderId!.isNotEmpty) {
      _searchController.text = widget.initialOrderId!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final orderId = _searchController.text.trim();
    if (orderId.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _searched = true;
      _order = null;
      _timeline = [];
      _resolvedCourierName = null;
    });

    try {
      final order = await _service.getOrder(orderId);
      if (order == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }
      final timeline = await _service.getTimeline(order);
      String? courierName = order.courierName;
      if (courierName == null && order.courierId != null) {
        courierName = await _service.resolveCourierName(order.courierId!);
      }
      if (!mounted) return;
      setState(() {
        _order = order;
        _timeline = timeline;
        _resolvedCourierName = courierName;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء البحث: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _surface,
        appBar: AppBar(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          title: const Text(
            'البحث عن طلب',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
          ),
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              style: const TextStyle(fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: 'أدخل رقم الطلب',
                hintStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: _textSecondary,
                ),
                prefixIcon: const Icon(Icons.receipt_long_rounded,
                    color: _primary),
                filled: true,
                fillColor: _surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _search,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Icon(Icons.search_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    if (!_searched) {
      return _emptyState(
        Icons.search_rounded,
        'ابحث عن طلب باستخدام رقمه لعرض تفاصيله وسجل حالاته',
      );
    }
    if (_order == null) {
      return _emptyState(
        Icons.search_off_rounded,
        'لا يوجد طلب بهذا الرقم',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        OrderDetailsSections(
          order: _order!,
          timeline: _timeline,
          resolvedCourierName: _resolvedCourierName,
        ),
      ],
    );
  }

  Widget _emptyState(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: _textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: _textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
