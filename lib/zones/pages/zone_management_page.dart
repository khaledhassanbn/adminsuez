import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../theme/app_color.dart';
import '../services/zone_management_service.dart';

class ZoneManagementPage extends StatefulWidget {
  const ZoneManagementPage({super.key});

  @override
  State<ZoneManagementPage> createState() => _ZoneManagementPageState();
}

class _ZoneManagementPageState extends State<ZoneManagementPage> {
  final ZoneManagementService _service = ZoneManagementService();

  bool _isLoading = true;
  bool _isUploading = false;
  ZoneConfig? _config;
  ZoneValidationResult? _preview;
  String? _pickedFileName;
  List<int>? _pickedBytes;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final config = await _service.getCurrentConfig();
      if (!mounted) return;
      setState(() {
        _config = config;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('فشل تحميل الإعدادات: $e', isError: true);
    }
  }

  Future<void> _pickFile() async {
    try {
      final picked = await _service.pickZoneFile();
      if (picked == null || !mounted) return;

      final validation = _service.validateZoneFile(
        fileName: picked.fileName,
        bytes: picked.bytes,
        currentVersion: _config?.currentZonesVersion,
      );

      setState(() {
        _pickedFileName = picked.fileName;
        _pickedBytes = picked.bytes;
        _preview = validation;
      });
    } catch (e) {
      _showMessage('فشل اختيار الملف: $e', isError: true);
    }
  }

  Future<void> _upload() async {
    if (_preview == null ||
        !_preview!.isValid ||
        _pickedFileName == null ||
        _pickedBytes == null ||
        _preview!.version == null) {
      return;
    }

    setState(() => _isUploading = true);
    try {
      await _service.uploadZoneFile(
        fileName: _pickedFileName!,
        bytes: _pickedBytes!,
        version: _preview!.version!,
      );
      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _pickedFileName = null;
        _pickedBytes = null;
        _preview = null;
      });

      await _loadConfig();
      _showMessage('تم رفع ملف المناطق وتحديث الإعدادات بنجاح');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      _showMessage('فشل الرفع: $e', isError: true);
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: const Text('إدارة المناطق'),
          backgroundColor: AppColors.mainColor,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCurrentConfigCard(),
                  const SizedBox(height: 16),
                  _buildPickFileCard(),
                  if (_preview != null) ...[
                    const SizedBox(height: 16),
                    _buildPreviewCard(),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildCurrentConfigCard() {
    final config = _config;
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'النسخة الحالية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (config == null) ...[
              const Text('لا توجد إعدادات مناطق على السيرفر بعد'),
            ] else ...[
              _infoRow('رقم الإصدار', 'v${config.currentZonesVersion}'),
              _infoRow('اسم الملف', config.fileName.isEmpty ? '—' : config.fileName),
              _infoRow(
                'مسار التخزين',
                config.zonesStoragePath.isEmpty ? '—' : config.zonesStoragePath,
              ),
              _infoRow(
                'آخر تحديث',
                config.updatedAt != null
                    ? dateFormat.format(config.updatedAt!)
                    : '—',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPickFileCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'رفع ملف مناطق جديد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'اختر ملف JSON بصيغة zones_vX.json يحتوي على version و zones مع id لكل منطقة.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickFile,
              icon: const Icon(Icons.upload_file),
              label: Text(_pickedFileName ?? 'اختيار ملف JSON'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final preview = _preview!;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  preview.isValid ? Icons.check_circle : Icons.error,
                  color: preview.isValid ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  preview.isValid ? 'الملف صالح للرفع' : 'الملف غير صالح',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: preview.isValid ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow('رقم الإصدار', preview.version?.toString() ?? '—'),
            _infoRow('عدد المناطق', preview.zoneCount.toString()),
            _infoRow('حجم الملف', _formatFileSize(preview.fileSizeBytes)),
            if (preview.errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'الأخطاء:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              ...preview.errors.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('• $e', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ],
            if (preview.zoneNames.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'أسماء المناطق:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: preview.zoneNames
                    .map(
                      (name) => Chip(
                        label: Text(name),
                        backgroundColor: AppColors.mainColor.withValues(alpha: 0.1),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: preview.isValid && !_isUploading ? _upload : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _isUploading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('رفع وتحديث المناطق'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
