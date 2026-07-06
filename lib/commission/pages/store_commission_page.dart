import 'package:flutter/material.dart';
import 'package:suez_admin/commission/models/wallet_ledger_model.dart';
import 'package:suez_admin/commission/services/commission_admin_service.dart';
import 'package:suez_admin/notifications/widgets/send_direct_notification_dialog.dart';
import 'package:suez_admin/stores/models/store_model.dart';
import 'package:suez_admin/stores/services/stores_service.dart';
import 'package:suez_admin/theme/app_color.dart';

class StoreCommissionPage extends StatefulWidget {
  final String storeId;
  const StoreCommissionPage({super.key, required this.storeId});

  @override
  State<StoreCommissionPage> createState() => _StoreCommissionPageState();
}

class _StoreCommissionPageState extends State<StoreCommissionPage>
    with SingleTickerProviderStateMixin {
  final _service = CommissionAdminService();
  final _storesService = StoresService();
  final _formKey = GlobalKey<FormState>();
  final _rateController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _adjustAmountController = TextEditingController();
  final _adjustReasonController = TextEditingController();
  String _type = 'fixed';
  StoreModel? _store;
  String? _ownerId;
  bool _loading = true;
  bool _savingCommission = false;
  bool _savingAdjust = false;
  bool _savingCourier = false;
  String _courierOverride = 'inherit';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ── Design tokens ──────────────────────────────────────────────
  static const Color _primary = Color(0xFF4E99B4);
  static const Color _primaryDark = Color(0xFF357A96);
  static const Color _primaryLight = Color(0xFFE8F4F8);
  static const Color _accent = Color(0xFF2DC08E); // teal-green for positive
  static const Color _danger = Color(0xFFE05C5C);
  static const Color _surface = Color(0xFFF7FAFB);
  static const Color _cardBg = Colors.white;
  static const Color _textPrimary = Color(0xFF1A2E38);
  static const Color _textSecondary = Color(0xFF6B8A96);
  static const Color _divider = Color(0xFFE2EEF2);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadStore();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _rateController.dispose();
    _creditLimitController.dispose();
    _adjustAmountController.dispose();
    _adjustReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadStore() async {
    final store = await _service.getStoreCommission(widget.storeId);
    final ownerId = await _service.getOwnerIdForStore(widget.storeId);
    if (!mounted) return;
    setState(() {
      _store = store;
      _ownerId = ownerId;
      _rateController.text = (store?.commissionRate ?? 5.0).toString();
      _creditLimitController.text = (store?.creditLimit ?? -50).toString();
      _type = store?.commissionType ?? 'fixed';
      _courierOverride = _courierOverrideFromStore(store);
      _loading = false;
    });
    _fadeController.forward();
  }

  String _courierOverrideFromStore(StoreModel? store) {
    if (store?.independentCourierEnabled == null) return 'inherit';
    return store!.independentCourierEnabled! ? 'enabled' : 'disabled';
  }

  bool? _courierOverrideToNullable(String value) {
    switch (value) {
      case 'enabled':
        return true;
      case 'disabled':
        return false;
      default:
        return null;
    }
  }

  Future<void> _saveCourierOverride() async {
    setState(() => _savingCourier = true);
    final result = await _storesService.updateIndependentCourierEnabled(
      widget.storeId,
      _courierOverrideToNullable(_courierOverride),
    );
    await _loadStore();
    if (!mounted) return;
    setState(() => _savingCourier = false);
    _showSnack(
      result['message']?.toString() ?? 'تم التحديث',
      isSuccess: result['success'] == true,
    );
  }

  Future<void> _saveStoreCommission() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _savingCommission = true);
    await _service.updateStoreCommission(
      storeId: widget.storeId,
      rate: double.parse(_rateController.text.trim()),
      type: _type,
      creditLimit: double.parse(_creditLimitController.text.trim()),
    );
    await _loadStore();
    if (!mounted) return;
    setState(() => _savingCommission = false);
    _showSnack('تم تحديث إعدادات العمولة بنجاح', isSuccess: true);
  }

  Future<void> _resetDefault() async {
    final confirmed = await _showConfirmDialog(
      'إعادة الإعدادات الافتراضية',
      'هل تريد إعادة المتجر إلى إعدادات العمولة الافتراضية؟',
    );
    if (!confirmed) return;
    await _service.resetStoreToDefaultCommission(widget.storeId);
    await _loadStore();
    if (!mounted) return;
    _showSnack('تمت إعادة الإعدادات الافتراضية', isSuccess: true);
  }

  Future<void> _manualAdjust() async {
    if (_ownerId == null) return;
    final amount = double.tryParse(_adjustAmountController.text.trim());
    final reason = _adjustReasonController.text.trim();
    if (amount == null || reason.isEmpty) {
      _showSnack('يرجى إدخال المبلغ والسبب', isSuccess: false);
      return;
    }
    setState(() => _savingAdjust = true);
    await _service.manualAdjustment(
      storeId: widget.storeId,
      userId: _ownerId!,
      amount: amount,
      description: reason,
    );
    _adjustAmountController.clear();
    _adjustReasonController.clear();
    await _loadStore();
    if (!mounted) return;
    setState(() => _savingAdjust = false);
    _showSnack('تم تنفيذ التعديل اليدوي على المحفظة', isSuccess: true);
  }

  void _showSnack(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(message, style: const TextStyle(fontFamily: 'Cairo')),
          ],
        ),
        backgroundColor: isSuccess ? _accent : _danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            content: Text(
              content,
              style: const TextStyle(fontFamily: 'Cairo', color: _textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: _textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _primary),
              const SizedBox(height: 16),
              const Text(
                'جارٍ التحميل...',
                style: TextStyle(
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _surface,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    _buildStatsRow(),
                    const SizedBox(height: 20),
                    _buildCourierSettingsCard(),
                    const SizedBox(height: 20),
                    _buildCommissionForm(),
                    const SizedBox(height: 20),
                    _buildManualAdjustCard(),
                    const SizedBox(height: 20),
                    _buildLedgerSection(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      stretch: true,
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      actions: [
        if (_ownerId != null)
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'إرسال إشعار',
            onPressed: () => SendDirectNotificationDialog.show(
              context,
              targetUserId: _ownerId!,
              targetUserName: _store?.name ?? 'صاحب المتجر',
              targetUserType: 'merchant',
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primaryDark, _primary, Color(0xFF6BB8D0)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _store?.name ?? 'المتجر',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const Text(
                              'إدارة العمولة والمحفظة',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        title: Text(
          _store?.name ?? 'عمولة المتجر',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16),
      ),
    );
  }

  Widget _buildStatsRow() {
    final balance = _store?.walletBalance ?? 0.0;
    final totalCommissions = _store?.totalCommissionsPaid ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.account_balance_wallet_rounded,
            label: 'رصيد المحفظة',
            value: balance.toStringAsFixed(2),
            unit: 'جنيه',
            valueColor: balance >= 0 ? _accent : _danger,
            iconBg: balance >= 0
                ? _accent.withOpacity(0.12)
                : _danger.withOpacity(0.12),
            iconColor: balance >= 0 ? _accent : _danger,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.receipt_long_rounded,
            label: 'إجمالي العمولات',
            value: totalCommissions.toStringAsFixed(2),
            unit: 'جنيه',
            valueColor: _primary,
            iconBg: _primaryLight,
            iconColor: _primary,
          ),
        ),
      ],
    );
  }

  Widget _buildCourierSettingsCard() {
    return _SectionCard(
      title: 'طلب المناديب',
      icon: Icons.delivery_dining_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تحكم في إتاحة خدمة طلب المناديب لهذا المتجر. '
            'الإعداد الموروث يتبع التفعيل العام من لوحة الأدمن.',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: _textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'inherit',
                label: Text('موروث'),
                icon: Icon(Icons.sync_rounded, size: 18),
              ),
              ButtonSegment(
                value: 'enabled',
                label: Text('مفعّل'),
                icon: Icon(Icons.check_circle_outline, size: 18),
              ),
              ButtonSegment(
                value: 'disabled',
                label: Text('معطّل'),
                icon: Icon(Icons.block_rounded, size: 18),
              ),
            ],
            selected: {_courierOverride},
            onSelectionChanged: (selection) {
              setState(() => _courierOverride = selection.first);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savingCourier ? null : _saveCourierOverride,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _savingCourier
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('حفظ إعداد المناديب'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionForm() {
    return _SectionCard(
      title: 'إعدادات العمولة',
      icon: Icons.tune_rounded,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _rateController,
                    label: 'قيمة العمولة',
                    prefixIcon: Icons.percent_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) =>
                        double.tryParse(v ?? '') == null ? 'رقم غير صالح' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _buildDropdown(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _creditLimitController,
              label: 'الحد الائتماني',
              prefixIcon: Icons.credit_score_rounded,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              validator: (v) =>
                  double.tryParse(v ?? '') == null ? 'رقم غير صالح' : null,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _PrimaryButton(
                    label: 'حفظ التغييرات',
                    icon: Icons.save_rounded,
                    loading: _savingCommission,
                    onPressed: _saveStoreCommission,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: _resetDefault,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text(
                      'افتراضي',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textSecondary,
                      side: const BorderSide(color: _divider, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _type,
      decoration: InputDecoration(
        labelText: 'نوع العمولة',
        labelStyle: const TextStyle(fontFamily: 'Cairo', color: _textSecondary),
        prefixIcon: const Icon(Icons.category_rounded, color: _primary, size: 20),
        filled: true,
        fillColor: _surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
      items: const [
        DropdownMenuItem(
          value: 'fixed',
          child: Text('ثابتة', style: TextStyle(fontFamily: 'Cairo')),
        ),
        DropdownMenuItem(
          value: 'percentage',
          child: Text('نسبة مئوية', style: TextStyle(fontFamily: 'Cairo')),
        ),
      ],
      onChanged: (v) => setState(() => _type = v ?? 'fixed'),
    );
  }

  Widget _buildManualAdjustCard() {
    return _SectionCard(
      title: 'تعديل يدوي للمحفظة',
      icon: Icons.edit_note_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _adjustAmountController,
                  label: 'المبلغ (+/-)',
                  prefixIcon: Icons.attach_money_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _adjustReasonController,
            label: 'سبب التعديل',
            prefixIcon: Icons.notes_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _PrimaryButton(
            label: 'تنفيذ التعديل',
            icon: Icons.bolt_rounded,
            loading: _savingAdjust,
            onPressed: _manualAdjust,
            color: _primaryDark,
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12, right: 4),
          child: Row(
            children: [
              Icon(Icons.history_rounded, color: _primary, size: 22),
              SizedBox(width: 8),
              Text(
                'سجل المحفظة',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),
        StreamBuilder<List<WalletLedgerModel>>(
          stream: _service.getStoreWalletLedger(widget.storeId),
          builder: (context, snapshot) {
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _divider),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          color: _textSecondary, size: 40),
                      SizedBox(height: 10),
                      Text(
                        'لا توجد حركات مالية بعد',
                        style: TextStyle(
                          color: _textSecondary,
                          fontFamily: 'Cairo',
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Container(
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _divider),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final e = entry.value;
                  final isLast = idx == items.length - 1;
                  return _LedgerTile(item: e, showDivider: !isLast);
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontFamily: 'Cairo', color: _textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontFamily: 'Cairo', color: _textSecondary, fontSize: 13),
        prefixIcon: Icon(prefixIcon, color: _primary, size: 20),
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _danger, width: 1.5),
        ),
      ),
    );
  }
}

// ── Reusable Widgets ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color valueColor;
  final Color iconBg;
  final Color iconColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.valueColor,
    required this.iconBg,
    required this.iconColor,
  });

  static const Color _textPrimary = Color(0xFF1A2E38);
  static const Color _textSecondary = Color(0xFF6B8A96);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EEF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onPressed;
  final Color color;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onPressed,
    this.color = const Color(0xFF4E99B4),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(0.6),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  final WalletLedgerModel item;
  final bool showDivider;

  const _LedgerTile({required this.item, required this.showDivider});

  static const Color _accent = Color(0xFF2DC08E);
  static const Color _danger = Color(0xFFE05C5C);
  static const Color _primary = Color(0xFF4E99B4);
  static const Color _textPrimary = Color(0xFF1A2E38);
  static const Color _textSecondary = Color(0xFF6B8A96);
  static const Color _divider = Color(0xFFE2EEF2);
  static const Color _surface = Color(0xFFF7FAFB);

  @override
  Widget build(BuildContext context) {
    final isPositive = item.amount >= 0;
    final amountColor = isPositive ? _accent : _danger;
    final amountBg = isPositive
        ? _accent.withOpacity(0.08)
        : _danger.withOpacity(0.08);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isPositive
                      ? _accent.withOpacity(0.1)
                      : _danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPositive
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: amountColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _divider),
                          ),
                          child: Text(
                            item.type,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              color: _textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${item.balanceBefore.toStringAsFixed(2)} ← ${item.balanceAfter.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: amountBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${item.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: _divider),
          ),
      ],
    );
  }
}