import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:suez_admin/orders/models/invoice_details.dart';
import 'package:suez_admin/orders/services/invoice_lookup_service.dart';
import 'package:suez_admin/orders/widgets/order_details_sections.dart';

/// صفحة البحث عن فاتورة برقمها وعرض تفاصيلها.
/// فواتير الطلبات تعرض تفاصيل الطلب الكاملة (عميل، مندوب، حالة، مراحل).
class InvoiceLookupPage extends StatefulWidget {
  final String? initialNumber;
  const InvoiceLookupPage({super.key, this.initialNumber});

  @override
  State<InvoiceLookupPage> createState() => _InvoiceLookupPageState();
}

class _InvoiceLookupPageState extends State<InvoiceLookupPage> {
  final _service = InvoiceLookupService();
  final _searchController = TextEditingController();

  static const Color _primary = Color(0xFF4E99B4);
  static const Color _accent = Color(0xFF2DC08E);
  static const Color _danger = Color(0xFFE05C5C);
  static const Color _warning = Color(0xFFE8A13C);
  static const Color _surface = Color(0xFFF7FAFB);
  static const Color _textPrimary = Color(0xFF1A2E38);
  static const Color _textSecondary = Color(0xFF6B8A96);
  static const Color _divider = Color(0xFFE2EEF2);

  bool _loading = false;
  bool _searched = false;
  InvoiceDetails? _invoice;

  @override
  void initState() {
    super.initState();
    if (widget.initialNumber != null && widget.initialNumber!.isNotEmpty) {
      _searchController.text = widget.initialNumber!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final number = _searchController.text.trim();
    if (number.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _searched = true;
      _invoice = null;
    });
    try {
      final invoice = await _service.lookup(number);
      if (!mounted) return;
      setState(() {
        _invoice = invoice;
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
            'البحث عن فاتورة',
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
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              style: const TextStyle(fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: 'أدخل رقم الفاتورة أو رقم الطلب',
                hintStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: _textSecondary,
                ),
                prefixIcon:
                    const Icon(Icons.description_rounded, color: _primary),
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
        Icons.description_outlined,
        'ابحث برقم الفاتورة أو رقم الطلب لعرض التفاصيل',
      );
    }
    if (_invoice == null) {
      return _emptyState(
        Icons.search_off_rounded,
        'لا توجد فاتورة بهذا الرقم',
      );
    }
    return _buildInvoiceDetails(_invoice!);
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

  Widget _buildInvoiceDetails(InvoiceDetails inv) {
    if (inv.isOrderInvoice) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _buildInvoiceHeader(inv),
          const SizedBox(height: 12),
          OrderDetailsSections(
            order: inv.order!,
            timeline: inv.timeline ?? const [],
            resolvedCourierName: inv.courierName,
          ),
        ],
      );
    }

    final dateStr = inv.date != null
        ? DateFormat('yyyy/MM/dd - HH:mm').format(inv.date!)
        : '—';
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        _buildInvoiceHeader(inv),
        const SizedBox(height: 12),
        _detailsCard([
          _row('رقم الفاتورة', inv.number),
          _row('التاريخ', dateStr),
          _row('المتجر', inv.storeName),
          if (inv.storeId.isNotEmpty) _row('معرف المتجر', inv.storeId),
          ...inv.extraFields.map((f) => _row(f.label, f.value)),
        ]),
      ],
    );
  }

  Widget _buildInvoiceHeader(InvoiceDetails inv) {
    final statusColor = inv.isPaid
        ? _accent
        : (inv.statusLabel == 'مرفوضة' ? _danger : _warning);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [_primary, Color(0xFF6BB8D0)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  inv.type,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  inv.statusLabel,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'رقم الفاتورة: ${inv.number}',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${inv.amount.toStringAsFixed(2)} جنيه',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsCard(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
      ),
      child: Column(children: rows),
    );
  }

  Widget _row(String key, String value) {
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
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
