import 'package:flutter/material.dart';
import 'package:suez_admin/commission/services/commission_admin_service.dart';
import 'package:suez_admin/theme/app_color.dart';

class CommissionSettingsPage extends StatefulWidget {
  const CommissionSettingsPage({super.key});

  @override
  State<CommissionSettingsPage> createState() => _CommissionSettingsPageState();
}

class _CommissionSettingsPageState extends State<CommissionSettingsPage>
    with SingleTickerProviderStateMixin {
  final _service = CommissionAdminService();
  final _formKey = GlobalKey<FormState>();
  final _rateController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _thresholdsController = TextEditingController();

  String _type = 'fixed';
  bool _blockOrders = true;
  bool _loading = true;
  bool _saving = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadConfig();
  }

  @override
  void dispose() {
    _rateController.dispose();
    _creditLimitController.dispose();
    _thresholdsController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await _service.getCommissionConfig();
      _rateController.text = _formatNum(config.defaultCommissionRate);
      _creditLimitController.text = _formatNum(config.defaultCreditLimit);
      _thresholdsController.text =
          config.balanceWarningThresholds.map(_formatNum).join(', ');
      _type = config.defaultCommissionType;
      _blockOrders = config.blockOrdersOnCreditExceeded;
    } catch (e) {
      if (mounted) {
        _showSnack('تعذّر تحميل الإعدادات: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _animController.forward();
      }
    }
  }

  String _formatNum(double value) =>
      value == value.roundToDouble()
          ? value.toStringAsFixed(0)
          : value.toString();

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFF2E7D32),
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final rate = double.parse(_rateController.text.trim());
      final thresholds = _thresholdsController.text
          .split(',')
          .map((e) => double.tryParse(e.trim()))
          .whereType<double>()
          .toList();

      await _service.saveGlobalCommissionForAllStores(
        rate: rate,
        type: _type,
        creditLimit: double.parse(_creditLimitController.text.trim()),
        thresholds: thresholds.isEmpty ? const [50, 20, 10, 0] : thresholds,
        blockOrdersOnCreditExceeded: _blockOrders,
      );

      if (!mounted) return;
      _showSnack('تم حفظ الإعدادات بنجاح');
    } catch (e) {
      if (!mounted) return;
      _showSnack('فشل الحفظ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.mainColor),
              )
            : FadeTransition(
                opacity: _fadeAnim,
                child: Form(
                  key: _formKey,
                  child: CustomScrollView(
                    slivers: [
                      _buildSliverAppBar(),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            const SizedBox(height: 20),
                            _commissionCard(),
                            const SizedBox(height: 14),
                            _walletCard(),
                            const SizedBox(height: 14),
                            _thresholdsCard(),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _loading ? null : _saveButton(),
      ),
    );
  }

  // ─── Sliver AppBar with gradient header ──────────────────────────────────────

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppColors.mainColor,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3A7A95),
                AppColors.mainColor,
                Color(0xFF6AB8D4),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -30,
                left: -30,
                child: _decorCircle(120, Colors.white.withValues(alpha: 0.06)),
              ),
              Positioned(
                bottom: -20,
                right: 40,
                child: _decorCircle(80, Colors.white.withValues(alpha: 0.08)),
              ),
              // Content
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.percent_rounded,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'إعدادات العمولة',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'تُطبَّق على جميع المتاجر',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Title shown when collapsed
        title: const Text(
          'إعدادات العمولة',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        titlePadding: const EdgeInsets.only(right: 56, bottom: 14),
      ),
    );
  }

  Widget _decorCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // ─── Commission section ───────────────────────────────────────────────────────

  Widget _commissionCard() {
    return _ProCard(
      icon: Icons.payments_outlined,
      title: 'رسوم الخدمة',
      children: [
        _StyledDropdown(
          value: _type,
          label: 'طريقة الحساب',
          items: const {
            'fixed': 'مبلغ ثابت لكل طلب',
            'percentage': 'نسبة من مجموع المنتجات',
          },
          onChanged: (v) => setState(() => _type = v ?? 'fixed'),
        ),
        const SizedBox(height: 14),
        _StyledTextField(
          controller: _rateController,
          label: _type == 'fixed' ? 'المبلغ (جنيه)' : 'النسبة (%)',
          hint: _type == 'fixed' ? 'مثال: 5' : 'مثال: 10',
          icon: _type == 'fixed' ? Icons.attach_money : Icons.show_chart,
          signed: true,
        ),
        if (_type == 'fixed')
          _HintChip(
              icon: Icons.info_outline,
              text: '5 جنيه = رسوم ثابتة على كل طلب بغض النظر عن قيمته')
        else
          _HintChip(
              icon: Icons.info_outline,
              text: 'تُحسب من إجمالي المنتجات فقط، لا تشمل الشحن'),
      ],
    );
  }

  // ─── Wallet section ───────────────────────────────────────────────────────────

  Widget _walletCard() {
    return _ProCard(
      icon: Icons.account_balance_wallet_outlined,
      title: 'محفظة التاجر',
      children: [
        _StyledTextField(
          controller: _creditLimitController,
          label: 'الحد الائتماني (جنيه)',
          hint: 'مثال: -50',
          icon: Icons.credit_score_outlined,
          signed: true,
        ),
        _HintChip(
          icon: Icons.lock_outline,
          text: 'الطلبات تُمنع عند وصول الرصيد إلى هذا الحد',
        ),
        const SizedBox(height: 6),
        _BlockOrdersToggle(
          value: _blockOrders,
          onChanged: (v) => setState(() => _blockOrders = v),
        ),
      ],
    );
  }

  // ─── Thresholds section ───────────────────────────────────────────────────────

  Widget _thresholdsCard() {
    return _ProCard(
      icon: Icons.notifications_active_outlined,
      title: 'عتبات التنبيه',
      children: [
        _StyledTextField(
          controller: _thresholdsController,
          label: 'أرقام مفصولة بفواصل',
          hint: '50, 20, 10, 0',
          icon: Icons.tune_outlined,
          signed: false,
          isNumeric: false,
          validator: (_) => null, // Optional field
        ),
        _HintChip(
          icon: Icons.campaign_outlined,
          text: 'يُرسل إشعار للتاجر عند اقتراب رصيده من هذه القيم',
        ),
      ],
    );
  }

  // ─── Save FAB ─────────────────────────────────────────────────────────────────

  Widget _saveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.mainColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.mainColor.withValues(alpha: 0.6),
            elevation: 4,
            shadowColor: AppColors.mainColor.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _saving
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Text('جاري الحفظ...',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded, size: 22),
                    SizedBox(width: 10),
                    Text('حفظ الإعدادات',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Reusable sub-widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _ProCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _ProCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.mainColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.mainColor, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2B3C),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Styled text field ────────────────────────────────────────────────────────

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool signed;
  final bool isNumeric;
  final String? Function(String?)? validator;

  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.signed = false,
    this.isNumeric = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric
          ? TextInputType.numberWithOptions(decimal: true, signed: signed)
          : TextInputType.text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.mainColor, size: 20),
        labelStyle:
            const TextStyle(color: Color(0xFF6B7A8D), fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFFB0BEC5)),
        filled: true,
        fillColor: const Color(0xFFF7FAFB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE3EA), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.mainColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFE53935), width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFE53935), width: 1.8),
        ),
      ),
      validator: validator ??
          (v) {
            if (v == null || v.trim().isEmpty) return 'الحقل مطلوب';
            if (double.tryParse(v.trim()) == null) return 'أدخل رقماً صحيحاً';
            return null;
          },
    );
  }
}

// ─── Styled dropdown ──────────────────────────────────────────────────────────

class _StyledDropdown extends StatelessWidget {
  final String value;
  final String label;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  const _StyledDropdown({
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppColors.mainColor),
      style: const TextStyle(
          fontSize: 14, color: Color(0xFF1A2B3C), fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.settings_outlined,
            color: AppColors.mainColor, size: 20),
        labelStyle:
            const TextStyle(color: Color(0xFF6B7A8D), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF7FAFB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE3EA), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.mainColor, width: 1.8),
        ),
      ),
      items: items.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ─── Hint chip ────────────────────────────────────────────────────────────────

class _HintChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HintChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.mainColor.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF4E99B4).withValues(alpha: 0.85),
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Block orders toggle ──────────────────────────────────────────────────────

class _BlockOrdersToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _BlockOrdersToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: value
            ? AppColors.mainColor.withValues(alpha: 0.06)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? AppColors.mainColor.withValues(alpha: 0.2)
              : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'منع الطلبات عند تجاوز الحد',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: value
                        ? AppColors.mainColor
                        : Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'الطلبات الجارية لا تُلغى',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.mainColor,
            inactiveThumbColor: Colors.orange.shade400,
            inactiveTrackColor: Colors.orange.shade100,
          ),
        ],
      ),
    );
  }
}