import 'package:flutter/material.dart';

import '../../theme/app_color.dart';
import '../models/independent_courier_settings.dart';
import '../services/independent_courier_settings_service.dart';

class IndependentCourierSettingsPage extends StatefulWidget {
  const IndependentCourierSettingsPage({super.key});

  @override
  State<IndependentCourierSettingsPage> createState() =>
      _IndependentCourierSettingsPageState();
}

class _IndependentCourierSettingsPageState
    extends State<IndependentCourierSettingsPage> {
  final _service = IndependentCourierSettingsService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _enabled = true;

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
        _enabled = settings.enabled;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('فشل في تحميل الإعدادات', isError: true);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final success = await _service.updateSettings(
      IndependentCourierSettings(enabled: _enabled),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    _showMessage(
      success ? 'تم حفظ الإعدادات بنجاح' : 'فشل في حفظ الإعدادات',
      isError: !success,
    );
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إعدادات طلب المناديب'),
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
                    Card(
                      elevation: 0,
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.blue.shade100),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'عند إيقاف هذه الميزة، لن يتمكن التجار من طلب مناديب '
                          'لتوصيل الطلبات. يمكنك أيضاً التحكم في كل متجر على حدة '
                          'من صفحة عمولة المتجر.',
                          style: TextStyle(height: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'تفعيل طلب المناديب لجميع المتاجر',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          _enabled
                              ? 'الميزة مفعّلة — التجار يمكنهم طلب مناديب'
                              : 'الميزة معطّلة — ستظهر رسالة "هذه الخدمة غير متاحة حاليا"',
                        ),
                        value: _enabled,
                        activeColor: AppColors.mainColor,
                        onChanged: (v) => setState(() => _enabled = v),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
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
                                  color: Colors.white,
                                ),
                              )
                            : const Text('حفظ الإعدادات'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
