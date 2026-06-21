import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:suez_admin/commission/models/wallet_ledger_model.dart';
import 'package:suez_admin/commission/services/commission_admin_service.dart';

/// لوحة الإدارة المالية: عرض كل الحركات المالية لكل المتاجر مع بحث وفلاتر.
class FinanceLedgerPage extends StatefulWidget {
  const FinanceLedgerPage({super.key});

  @override
  State<FinanceLedgerPage> createState() => _FinanceLedgerPageState();
}

class _FinanceLedgerPageState extends State<FinanceLedgerPage> {
  final _service = CommissionAdminService();
  final _searchController = TextEditingController();

  // ── Design tokens ──────────────────────────────────────────────
  static const Color _primary = Color(0xFF4E99B4);
  static const Color _accent = Color(0xFF2DC08E);
  static const Color _danger = Color(0xFFE05C5C);
  static const Color _surface = Color(0xFFF7FAFB);
  static const Color _textPrimary = Color(0xFF1A2E38);
  static const Color _textSecondary = Color(0xFF6B8A96);
  static const Color _divider = Color(0xFFE2EEF2);

  static const Map<String, String> _typeNames = {
    'wallet_recharge': 'شحن محفظة',
    'subscription_payment': 'دفع اشتراك',
    'order_commission': 'عمولة طلب',
    'manual_adjustment': 'تعديل يدوي',
    'refund': 'استرداد',
    'auto_renewal': 'تجديد تلقائي',
  };

  bool _loading = true;
  String? _error;
  List<WalletLedgerModel> _all = [];
  Map<String, String> _storeNames = {};

  String _search = '';
  String? _typeFilter; // null = الكل
  String? _storeFilter; // null = الكل
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getGlobalLedger(),
        _service.getStoreNamesMap(),
      ]);
      if (!mounted) return;
      setState(() {
        _all = results[0] as List<WalletLedgerModel>;
        _storeNames = results[1] as Map<String, String>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _storeName(String storeId) {
    final name = _storeNames[storeId];
    if (name == null || name.isEmpty) return storeId;
    return name;
  }

  String _typeName(String type) => _typeNames[type] ?? type;

  List<WalletLedgerModel> get _filtered {
    final q = _search.trim().toLowerCase();
    return _all.where((e) {
      if (_typeFilter != null && e.type != _typeFilter) return false;
      if (_storeFilter != null && e.storeId != _storeFilter) return false;
      if (_dateRange != null && e.createdAt != null) {
        final d = e.createdAt!;
        final start = DateTime(
          _dateRange!.start.year,
          _dateRange!.start.month,
          _dateRange!.start.day,
        );
        final end = DateTime(
          _dateRange!.end.year,
          _dateRange!.end.month,
          _dateRange!.end.day,
          23,
          59,
          59,
        );
        if (d.isBefore(start) || d.isAfter(end)) return false;
      }
      if (q.isNotEmpty) {
        final haystack = [
          _storeName(e.storeId),
          e.description,
          e.referenceId ?? '',
          _typeName(e.type),
        ].join(' ').toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
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
            'الإدارة المالية',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: Column(
          children: [
            _buildFilters(),
            _buildSummaryBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(fontFamily: 'Cairo'),
            decoration: InputDecoration(
              hintText: 'بحث باسم المتجر أو رقم المرجع أو الوصف',
              hintStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: _textSecondary,
              ),
              prefixIcon: const Icon(Icons.search_rounded, color: _primary),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                    )
                  : null,
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildTypeDropdown()),
              const SizedBox(width: 8),
              Expanded(child: _buildStoreDropdown()),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range_rounded, size: 18),
                  label: Text(
                    _dateRange == null
                        ? 'فلترة بالتاريخ'
                        : '${DateFormat('yyyy/MM/dd').format(_dateRange!.start)} - ${DateFormat('yyyy/MM/dd').format(_dateRange!.end)}',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textSecondary,
                    side: const BorderSide(color: _divider, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (_dateRange != null || _typeFilter != null ||
                  _storeFilter != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() {
                    _dateRange = null;
                    _typeFilter = null;
                    _storeFilter = null;
                  }),
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  color: _danger,
                  tooltip: 'مسح الفلاتر',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<String?>(
      value: _typeFilter,
      isExpanded: true,
      decoration: _dropdownDecoration('نوع العملية'),
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 13,
        color: _textPrimary,
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('كل الأنواع', style: TextStyle(fontFamily: 'Cairo')),
        ),
        ..._typeNames.entries.map(
          (e) => DropdownMenuItem<String?>(
            value: e.key,
            child: Text(e.value, style: const TextStyle(fontFamily: 'Cairo')),
          ),
        ),
      ],
      onChanged: (v) => setState(() => _typeFilter = v),
    );
  }

  Widget _buildStoreDropdown() {
    final entries = _storeNames.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return DropdownButtonFormField<String?>(
      value: _storeFilter,
      isExpanded: true,
      decoration: _dropdownDecoration('المتجر'),
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 13,
        color: _textPrimary,
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('كل المتاجر', style: TextStyle(fontFamily: 'Cairo')),
        ),
        ...entries.map(
          (e) => DropdownMenuItem<String?>(
            value: e.key,
            child: Text(
              e.value,
              style: const TextStyle(fontFamily: 'Cairo'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: (v) => setState(() => _storeFilter = v),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: 'Cairo',
        color: _textSecondary,
        fontSize: 12,
      ),
      filled: true,
      fillColor: _surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
    );
  }

  Widget _buildSummaryBar() {
    final items = _filtered;
    double credit = 0;
    double debit = 0;
    for (final e in items) {
      if (e.amount >= 0) {
        credit += e.amount;
      } else {
        debit += e.amount;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            '${items.length} عملية',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const Spacer(),
          _summaryChip('وارد', credit, _accent),
          const SizedBox(width: 8),
          _summaryChip('صادر', debit, _danger),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(2)}',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'حدث خطأ: $_error',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Cairo', color: _danger),
          ),
        ),
      );
    }
    final items = _filtered;
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, color: _textSecondary, size: 48),
            SizedBox(height: 12),
            Text(
              'لا توجد حركات مطابقة',
              style: TextStyle(fontFamily: 'Cairo', color: _textSecondary),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: _primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _buildLedgerCard(items[index]),
      ),
    );
  }

  Widget _buildLedgerCard(WalletLedgerModel e) {
    final isPositive = e.amount >= 0;
    final amountColor = isPositive ? _accent : _danger;
    final dateStr = e.createdAt != null
        ? DateFormat('yyyy/MM/dd - HH:mm').format(e.createdAt!)
        : '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: amountColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPositive
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: amountColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _storeName(e.storeId),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _typeName(e.type),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isPositive ? '+' : ''}${e.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: amountColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _divider),
          const SizedBox(height: 8),
          if (e.description.isNotEmpty) ...[
            Text(
              e.description,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _infoChip(Icons.access_time_rounded, dateStr),
              _infoChip(
                Icons.account_balance_wallet_outlined,
                '${e.balanceBefore.toStringAsFixed(2)} ← ${e.balanceAfter.toStringAsFixed(2)}',
              ),
              if (e.referenceId != null && e.referenceId!.isNotEmpty)
                _infoChip(Icons.tag_rounded, e.referenceId!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            color: _textSecondary,
          ),
        ),
      ],
    );
  }
}
