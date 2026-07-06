import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/delivery_fee_service.dart';
import 'services/delivery_fee_settings.dart';
import 'services/delivery_fee_zone.dart';
import '../../theme/app_color.dart';

/// صفحة إعدادات رسوم التوصيل للأدمن — نظام نطاقات المسافة
class DeliveryFeeSettingsPage extends StatefulWidget {
  const DeliveryFeeSettingsPage({super.key});

  @override
  State<DeliveryFeeSettingsPage> createState() => _DeliveryFeeSettingsPageState();
}

class _DeliveryFeeSettingsPageState extends State<DeliveryFeeSettingsPage> {
  final DeliveryFeeService _service = DeliveryFeeService();

  bool _isLoading = true;
  bool _isSaving = false;
  List<DeliveryFeeZone> _zones = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _service.getSettings(forceRefresh: true);
      if (!mounted) return;
      setState(() {
        _zones = List<DeliveryFeeZone>.from(settings.sortedZones);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('فشل في تحميل الإعدادات', isError: true);
    }
  }

  Future<void> _saveSettings() async {
    final validationError = DeliveryFeeSettings.validateZones(_zones);
    if (validationError != null) {
      _showMessage(validationError, isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final sortedZones = List<DeliveryFeeZone>.from(_zones)
        ..sort((a, b) => a.from.compareTo(b.from));
      final newSettings = DeliveryFeeSettings(zones: sortedZones);
      final success = await _service.updateSettings(newSettings);
      if (!mounted) return;

      if (success) {
        setState(() {
          _zones = sortedZones;
          _isSaving = false;
        });
        _showMessage('تم حفظ النطاقات بنجاح');
      } else {
        setState(() => _isSaving = false);
        _showMessage('فشل في حفظ الإعدادات', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('حدث خطأ: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _showZoneDialog({DeliveryFeeZone? zone, int? index}) async {
    final result = await showDialog<DeliveryFeeZone>(
      context: context,
      builder: (dialogContext) => _ZoneEditorDialog(
        zone: zone,
        isEditing: zone != null && index != null,
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      if (index != null) {
        _zones[index] = result;
      } else {
        _zones.add(result);
      }
      _zones.sort((a, b) => a.from.compareTo(b.from));
    });
  }

  Future<void> _deleteZone(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف النطاق'),
          content: Text(
            'هل أنت متأكد من حذف النطاق '
            '${_formatNum(_zones[index].from)} - ${_formatNum(_zones[index].to)} كم؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _zones.removeAt(index));
    }
  }

  void _moveZone(int index, int direction) {
    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= _zones.length) return;
    setState(() {
      final zone = _zones.removeAt(index);
      _zones.insert(newIndex, zone);
    });
  }

  String _formatNum(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إعدادات رسوم التوصيل'),
          backgroundColor: AppColors.mainColor,
          foregroundColor: Colors.white,
          actions: [
            if (!_isLoading)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadSettings,
                tooltip: 'تحديث',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(),
                    const SizedBox(height: 12),
                    _buildZonesList(),
                    const SizedBox(height: 16),
                    _buildAddZoneButton(),
                    const SizedBox(height: 24),
                    _buildPreviewCard(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نظام نطاقات المسافة',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'يتم تحديد رسوم التوصيل حسب نطاق المسافة. '
                  'إذا تجاوزت المسافة آخر نطاق، تُطبَّق رسوم آخر نطاق.',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        const Icon(Icons.map, color: AppColors.mainColor, size: 24),
        const SizedBox(width: 8),
        Text(
          'نطاقات المسافة (${_zones.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildZonesList() {
    if (_zones.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(Icons.layers_clear, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'لا توجد نطاقات. أضف نطاقاً جديداً.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(_zones.length, (index) {
        final zone = _zones[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildZoneChip('من', '${_formatNum(zone.from)} كم'),
                      _buildZoneChip('إلى', '${_formatNum(zone.to)} كم'),
                      _buildZoneChip(
                        'الرسوم',
                        '${_formatNum(zone.fee)} ج',
                        highlight: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildZoneAction(
                        icon: Icons.arrow_upward,
                        tooltip: 'تحريك لأعلى',
                        onPressed: index > 0 ? () => _moveZone(index, -1) : null,
                      ),
                      _buildZoneAction(
                        icon: Icons.arrow_downward,
                        tooltip: 'تحريك لأسفل',
                        onPressed:
                            index < _zones.length - 1 ? () => _moveZone(index, 1) : null,
                      ),
                      _buildZoneAction(
                        icon: Icons.edit,
                        tooltip: 'تعديل',
                        color: AppColors.mainColor,
                        onPressed: () => _showZoneDialog(zone: zone, index: index),
                      ),
                      _buildZoneAction(
                        icon: Icons.delete,
                        tooltip: 'حذف',
                        color: Colors.red,
                        onPressed: () => _deleteZone(index),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildZoneChip(String label, String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? AppColors.mainColor.withValues(alpha: 0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              color: highlight ? AppColors.mainColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20, color: color),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  Widget _buildAddZoneButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showZoneDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة نطاق'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.mainColor,
          side: const BorderSide(color: AppColors.mainColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    if (_zones.isEmpty) return const SizedBox.shrink();

    final settings = DeliveryFeeSettings(zones: _zones);
    final examples = [1.0, 2.0, 3.7, 6.2, 11.0];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معاينة الحساب (قبل الحفظ)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade900,
            ),
          ),
          const SizedBox(height: 12),
          ...examples.map((distance) {
            final fee = _service.calculateDeliveryFee(distance, settings);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$distance كم',
                    style: TextStyle(color: Colors.green.shade800),
                  ),
                  Text(
                    '${fee.toStringAsFixed(0)} جنيه',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mainColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'حفظ النطاقات',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

/// حوار إضافة/تعديل نطاق — يدير الـ controllers داخلياً لتجنب dispose المبكر
class _ZoneEditorDialog extends StatefulWidget {
  final DeliveryFeeZone? zone;
  final bool isEditing;

  const _ZoneEditorDialog({
    this.zone,
    required this.isEditing,
  });

  @override
  State<_ZoneEditorDialog> createState() => _ZoneEditorDialogState();
}

class _ZoneEditorDialogState extends State<_ZoneEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  late final TextEditingController _feeController;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(
      text: widget.zone?.from.toString() ?? '',
    );
    _toController = TextEditingController(
      text: widget.zone?.to.toString() ?? '',
    );
    _feeController = TextEditingController(
      text: widget.zone?.fee.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  String? _validateField(String? value, {required double min}) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    final number = double.tryParse(value.trim());
    if (number == null) {
      return 'أدخل رقم صحيح';
    }
    if (number < min) {
      return 'يجب أن يكون أكبر من أو يساوي $min';
    }
    return null;
  }

  void _submit() {
    setState(() => _inlineError = null);

    if (!_formKey.currentState!.validate()) return;

    final from = double.parse(_fromController.text.trim());
    final to = double.parse(_toController.text.trim());
    final fee = double.parse(_feeController.text.trim());

    if (from >= to) {
      setState(() => _inlineError = 'قيمة "من" يجب أن تكون أقل من "إلى"');
      return;
    }
    if (fee <= 0) {
      setState(() => _inlineError = 'الرسوم يجب أن تكون أكبر من صفر');
      return;
    }

    Navigator.pop(
      context,
      DeliveryFeeZone(from: from, to: to, fee: fee),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(widget.isEditing ? 'تعديل نطاق' : 'إضافة نطاق'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildField(
                  controller: _fromController,
                  label: 'من (كم)',
                  validator: (v) => _validateField(v, min: 0),
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _toController,
                  label: 'إلى (كم)',
                  validator: (v) => _validateField(v, min: 0.01),
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _feeController,
                  label: 'الرسوم (جنيه)',
                  validator: (v) => _validateField(v, min: 0.01),
                ),
                if (_inlineError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _inlineError!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
              foregroundColor: Colors.white,
            ),
            child: Text(widget.isEditing ? 'تحديث' : 'إضافة'),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }
}
