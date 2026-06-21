import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:suez_admin/orders/models/store_dashboard_data.dart';
import 'package:suez_admin/orders/services/store_dashboard_service.dart';

/// لوحة تفصيلية لمتجر واحد: إحصائيات، منتجات، طلبات، وفواتير.
class StoreDashboardPage extends StatefulWidget {
  final String storeId;
  const StoreDashboardPage({super.key, required this.storeId});

  @override
  State<StoreDashboardPage> createState() => _StoreDashboardPageState();
}

class _StoreDashboardPageState extends State<StoreDashboardPage> {
  final _service = StoreDashboardService();

  static const Color _primary = Color(0xFF4E99B4);
  static const Color _accent = Color(0xFF2DC08E);
  static const Color _danger = Color(0xFFE05C5C);
  static const Color _warning = Color(0xFFE8A13C);
  static const Color _surface = Color(0xFFF7FAFB);
  static const Color _textPrimary = Color(0xFF1A2E38);
  static const Color _textSecondary = Color(0xFF6B8A96);
  static const Color _divider = Color(0xFFE2EEF2);

  bool _loading = true;
  String? _error;
  StoreDashboardData? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.loadDashboard(widget.storeId);
      if (!mounted) return;
      setState(() {
        _data = data;
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _surface,
        appBar: AppBar(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          title: Text(
            _data?.store.name ?? 'لوحة المتجر',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: _buildBody(),
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
    final data = _data!;
    return RefreshIndicator(
      onRefresh: _load,
      color: _primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _buildGeneralStats(data),
          const SizedBox(height: 16),
          _buildProductsSection(data),
          const SizedBox(height: 16),
          _buildOrdersSection(data),
          const SizedBox(height: 16),
          _buildInvoicesSection(data),
        ],
      ),
    );
  }

  Widget _buildGeneralStats(StoreDashboardData data) {
    final balance = data.walletBalance;
    return _Section(
      title: 'إحصائيات عامة',
      icon: Icons.insights_rounded,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          _statCard(Icons.inventory_2_rounded, 'المنتجات',
              '${data.totalProducts}', _primary),
          _statCard(Icons.shopping_bag_rounded, 'الطلبات',
              '${data.totalOrders}', _primary),
          _statCard(Icons.check_circle_rounded, 'مكتملة',
              '${data.completedOrders}', _accent),
          _statCard(Icons.cancel_rounded, 'ملغاة',
              '${data.cancelledOrders}', _danger),
          _statCard(Icons.payments_rounded, 'إجمالي المبيعات',
              data.totalSales.toStringAsFixed(2), _accent),
          _statCard(Icons.receipt_long_rounded, 'إجمالي العمولات',
              data.totalCommissions.toStringAsFixed(2), _warning),
          _statCard(Icons.account_balance_wallet_rounded, 'الرصيد الحالي',
              balance.toStringAsFixed(2), balance >= 0 ? _accent : _danger),
          _statCard(Icons.credit_score_rounded, 'الحد الائتماني',
              data.creditLimit.toStringAsFixed(2), _textSecondary),
        ],
      ),
    );
  }

  Widget _buildProductsSection(StoreDashboardData data) {
    return _Section(
      title: 'المنتجات',
      icon: Icons.inventory_2_rounded,
      child: Row(
        children: [
          Expanded(
            child: _miniStat('الإجمالي', '${data.totalProducts}', _primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _miniStat('نشطة', '${data.activeProducts}', _accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                _miniStat('موقوفة', '${data.suspendedProducts}', _danger),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersSection(StoreDashboardData data) {
    return _Section(
      title: 'الطلبات',
      icon: Icons.calendar_month_rounded,
      child: Row(
        children: [
          Expanded(
            child: _miniStat('اليوم', '${data.ordersToday}', _primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _miniStat('هذا الأسبوع', '${data.ordersWeek}', _primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _miniStat('هذا الشهر', '${data.ordersMonth}', _primary),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesSection(StoreDashboardData data) {
    return _Section(
      title: 'الفواتير (${data.invoices.length})',
      icon: Icons.description_rounded,
      child: data.invoices.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'لا توجد فواتير',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: _textSecondary,
                ),
              ),
            )
          : Column(
              children: data.invoices
                  .take(50)
                  .map((inv) => _invoiceTile(inv))
                  .toList(),
            ),
    );
  }

  Widget _invoiceTile(StoreInvoiceItem inv) {
    final dateStr =
        inv.date != null ? DateFormat('yyyy/MM/dd').format(inv.date!) : '—';
    final statusColor = inv.isPaid
        ? _accent
        : (inv.statusLabel == 'مرفوضة' ? _danger : _warning);
    return InkWell(
      onTap: () => context.push('/admin/invoice-lookup?number=${inv.reference}'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.type,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'مرجع: ${inv.reference}  •  $dateStr',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${inv.amount.toStringAsFixed(2)} ج',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              inv.statusLabel,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_left_rounded,
              size: 18, color: _textSecondary),
        ],
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}
