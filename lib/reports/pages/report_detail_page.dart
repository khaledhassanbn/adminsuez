import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_report.dart';
import '../services/report_service.dart';
import '../../account/services/admin_account_service.dart';

class AppColors {
  static const Color mainColor = Color(0xFF4E99B4);
  static const Color mainLight = Color(0xFFEDF6FA);
  static const Color mainDark = Color(0xFF2F7A96);
  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color textPrimary = Color(0xFF1A3A45);
  static const Color textSecondary = Color(0xFF8AABBA);
  static const Color bg = Color(0xFFF0F4F6);
  static const Color cardBorder = Color(0xFFD0E8F0);
}

class ReportDetailPage extends StatefulWidget {
  final UserReport report;

  const ReportDetailPage({Key? key, required this.report}) : super(key: key);

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final ReportService _reportService = ReportService();
  final AdminAccountService _adminService = AdminAccountService();
  bool _isLoading = false;
  int _reportCount = 0;
  String? _targetName;

  @override
  void initState() {
    super.initState();
    _loadReportCount();
    _loadTargetName();
  }

  Future<void> _loadReportCount() async {
    try {
      final count = await _reportService.getReportCountForTarget(
        widget.report.targetId,
      );
      setState(() => _reportCount = count);
    } catch (e) {
      debugPrint('Error loading report count: $e');
    }
  }

  Future<void> _loadTargetName() async {
    try {
      final details = await _adminService.getAccountDetails(
        accountId: widget.report.targetId,
        accountType: widget.report.targetType,
      );
      if (details != null) {
        String? name;
        if (widget.report.targetType == 'craftsman') {
          name = details['name'] as String?;
        } else if (widget.report.targetType == 'store') {
          name = details['storeName'] as String? ?? details['name'] as String?;
        } else {
          name = details['name'] as String?;
        }
        if (mounted && name != null && name.isNotEmpty) {
          setState(() => _targetName = name);
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading target name from sub-collection: $e');
    }

    // Fallback: Query the main 'users' collection using targetId as document ID
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.report.targetId)
          .get();
      if (userDoc.exists && mounted) {
        final userData = userDoc.data();
        final name = userData?['name'] as String?;
        if (name != null && name.isNotEmpty) {
          setState(() => _targetName = name);
        }
      }
    } catch (err) {
      debugPrint('Error loading target name from users collection: $err');
    }
  }

  Future<void> _launchPersonalPage() async {
    final targetId = widget.report.targetId;
    final type = widget.report.targetType;
    String urlString = '';
    if (type == 'craftsman') {
      urlString = 'https://bazaarsuez.com/craftsman/$targetId';
    } else if (type == 'store') {
      urlString = 'https://bazaarsuez.com/market/$targetId';
    } else {
      return;
    }

    try {
      final Uri url = Uri.parse(urlString);
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(url);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح الرابط: $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.mainColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 12),
                  _buildInfoCard(),
                  const SizedBox(height: 12),
                  _buildReasonCard(),
                  if (widget.report.status != 'pending') ...[
                    const SizedBox(height: 12),
                    _buildResolutionCard(),
                  ],
                  if (widget.report.status == 'pending') ...[
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.mainColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'تفاصيل البلاغ',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeaderCard() {
    return _card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'رقم البلاغ',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '#RPT-${widget.report.id.substring(0, widget.report.id.length > 8 ? 8 : widget.report.id.length).toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              _statusBadge(widget.report.status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.mainColor,
                child: Text(
                  widget.report.targetTypeDisplayName.isNotEmpty
                      ? widget.report.targetTypeDisplayName[0]
                      : 'م',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _targetName ?? widget.report.targetId,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.report.targetTypeDisplayName} · ID: ${widget.report.targetId.substring(0, widget.report.targetId.length > 8 ? 8 : widget.report.targetId.length)}',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.info_outline, 'معلومات البلاغ'),
          _infoRow(
            icon: Icons.person_outline,
            label: 'نوع المبلغ عنه',
            value: widget.report.targetTypeDisplayName,
          ),
          _divider(),
          _infoRow(
            icon: Icons.calendar_today_outlined,
            label: 'تاريخ البلاغ',
            value: _formatDateTime(widget.report.createdAt.toDate()),
          ),
          if (_reportCount > 0) ...[
            _divider(),
            _infoRow(
              icon: Icons.flag_outlined,
              label: 'إجمالي البلاغات على هذا الحساب',
              valueWidget: _countPill(_reportCount),
              iconColor: AppColors.warning,
              iconBg: const Color(0xFFFEF9EC),
            ),
          ],
          if (widget.report.targetType == 'craftsman' ||
              widget.report.targetType == 'store') ...[
            _divider(),
            _infoRow(
              icon: Icons.visibility_outlined,
              label: 'عرض الصفحة الشخصية',
              valueWidget: GestureDetector(
                onTap: _launchPersonalPage,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    widget.report.targetType == 'craftsman'
                        ? 'عرض ملف الصنايعي'
                        : 'عرض صفحة المتجر',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              iconColor: AppColors.mainColor,
              iconBg: AppColors.mainLight,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReasonCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.report_gmailerrorred_outlined, 'سبب البلاغ'),
          const SizedBox(height: 4),
          Text(
            widget.report.reason,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF3A5A67),
              height: 1.75,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionCard() {
    final isResolved = widget.report.status == 'resolved';
    return Container(
      decoration: BoxDecoration(
        color: isResolved ? const Color(0xFFF0FDF4) : const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isResolved ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isResolved ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: isResolved ? AppColors.success : AppColors.danger,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                isResolved ? 'تم حل البلاغ' : 'تم رفض البلاغ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isResolved ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.report.resolution ?? '',
            style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568), height: 1.7),
          ),
          if (widget.report.resolvedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'تاريخ: ${_formatDateTime(widget.report.resolvedAt!.toDate())}',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _actionButton(
              icon: Icons.check_circle_outline,
              label: 'حل البلاغ',
              color: AppColors.mainColor,
              onTap: _showResolveDialog,
            )),
            const SizedBox(width: 10),
            Expanded(child: _actionButton(
              icon: Icons.cancel_outlined,
              label: 'رفض البلاغ',
              color: const Color(0xFF5F6B7A),
              onTap: _showDismissDialog,
            )),
          ],
        ),
        const SizedBox(height: 10),
        _actionButton(
          icon: Icons.delete_outline,
          label: 'حذف الحساب المبلغ عنه',
          color: AppColors.danger,
          onTap: _confirmDeleteAccount,
          fullWidth: true,
        ),
      ],
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 0.7),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _sectionTitle(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.mainColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.mainColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    String? value,
    Widget? valueWidget,
    Color iconColor = AppColors.mainColor,
    Color iconBg = AppColors.mainLight,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 3),
                if (valueWidget != null)
                  valueWidget
                else
                  Text(
                    value ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        height: 0.5,
        color: const Color(0xFFEEF5F8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  Widget _countPill(int count) {
    final isHigh = count > 2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isHigh ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flag,
            size: 13,
            color: isHigh ? AppColors.danger : AppColors.warning,
          ),
          const SizedBox(width: 5),
          Text(
            '$count بلاغات',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isHigh ? const Color(0xFF991B1B) : const Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final map = {
      'pending': ('قيد المراجعة', const Color(0xFFFFF3CD), const Color(0xFF856404)),
      'resolved': ('تم الحل', const Color(0xFFD1FAE5), const Color(0xFF065F46)),
      'dismissed': ('مرفوض', const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
    };
    final s = map[status] ?? ('غير معروف', Colors.grey[100]!, Colors.grey[700]!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: s.$2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(s.$1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: s.$3)),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: _isLoading ? null : onTap,
      ),
    );
  }

  // ─── Dialogs & Actions ──────────────────────────────────────────────────────

  Future<void> _showResolveDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _styledDialog(
        title: 'حل البلاغ',
        titleColor: AppColors.mainColor,
        icon: Icons.check_circle_outline,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('يرجى كتابة تفاصيل الحل (10 أحرف على الأقل)',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            _styledTextField(controller, 'تفاصيل الحل', 'اشرح كيف تم حل البلاغ...', 4),
          ],
        ),
        confirmLabel: 'حل البلاغ',
        confirmColor: AppColors.mainColor,
        onConfirm: () {
          if (controller.text.trim().length < 10) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('يجب أن يكون النص 10 أحرف على الأقل')),
            );
            return;
          }
          Navigator.pop(context, true);
        },
      ),
    );
    if (result == true) await _resolveReport(controller.text);
  }

  Future<void> _showDismissDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _styledDialog(
        title: 'رفض البلاغ',
        titleColor: const Color(0xFF5F6B7A),
        icon: Icons.cancel_outlined,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('يرجى كتابة سبب الرفض',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            _styledTextField(controller, 'سبب الرفض', '', 3),
          ],
        ),
        confirmLabel: 'رفض البلاغ',
        confirmColor: const Color(0xFF5F6B7A),
        onConfirm: () => Navigator.pop(context, true),
      ),
    );
    if (result == true) await _dismissReport(controller.text);
  }

  Future<void> _confirmDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _styledDialog(
        title: 'تأكيد الحذف',
        titleColor: AppColors.danger,
        icon: Icons.delete_outline,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'هل أنت متأكد من حذف الحساب؟\nسيتم تحويل المستخدم لحساب عادي.',
                style: TextStyle(fontSize: 13, color: Color(0xFF7F1D1D), height: 1.6),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        confirmLabel: 'نعم، احذف الحساب',
        confirmColor: AppColors.danger,
        onConfirm: () => Navigator.pop(context, true),
      ),
    );
    if (confirm == true) await _deleteAccount();
  }

  Dialog _styledDialog({
    required String title,
    required Color titleColor,
    required IconData icon,
    required Widget content,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: titleColor, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: titleColor),
            ),
            const SizedBox(height: 16),
            content,
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFD0E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('إلغاء',
                        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(confirmLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _styledTextField(
    TextEditingController controller,
    String label,
    String hint,
    int maxLines,
  ) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.mainColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.mainColor, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.mainLight,
      ),
    );
  }

  // ─── Service Calls ──────────────────────────────────────────────────────────

  Future<void> _resolveReport(String resolution) async {
    setState(() => _isLoading = true);
    try {
      final adminId = _adminService.getCurrentAdminId();
      if (adminId == null) throw Exception('لم يتم تسجيل الدخول');
      await _reportService.resolveReport(
        reportId: widget.report.id,
        adminId: adminId,
        resolution: resolution,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حل البلاغ بنجاح')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _dismissReport(String reason) async {
    setState(() => _isLoading = true);
    try {
      final adminId = _adminService.getCurrentAdminId();
      if (adminId == null) throw Exception('لم يتم تسجيل الدخول');
      await _reportService.dismissReport(
        reportId: widget.report.id,
        adminId: adminId,
        reason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفض البلاغ')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);
    try {
      final adminId = _adminService.getCurrentAdminId();
      if (adminId == null) throw Exception('لم يتم تسجيل الدخول');
      await _adminService.deleteAccount(
        accountId: widget.report.targetId,
        accountType: widget.report.targetType,
        adminId: adminId,
        reason: 'حذف بسبب البلاغات المتعددة',
      );
      await _reportService.resolveReport(
        reportId: widget.report.id,
        adminId: adminId,
        resolution: 'تم حذف الحساب وتفويض البلاغ',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الحساب بنجاح')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy - hh:mm a', 'ar').format(date);
  }
}
