import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'dart:io';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';

/// ViewModel لإدارة الإعلانات والإشعارات
class AnnouncementViewModel extends ChangeNotifier {
  final AnnouncementService _service = AnnouncementService();

  // ═══════════════════════════════════════════════════════════════
  // حالة النموذج (إنشاء إعلان جديد)
  // ═══════════════════════════════════════════════════════════════

  String _title = '';
  String _body = '';
  File? _imageFile;
  String? _imageUrl;
  String _deliveryType = 'both';
  String _targetAudience = 'all';
  String? _targetUserId;
  String? _targetUserName;
  String? _targetUserType;
  bool _hasCTA = false;
  String _ctaType = 'open_page';
  String _ctaLabel = '';
  String _ctaValue = '';
  bool _isScheduled = false;
  DateTime? _scheduledAt;
  String? _selectedTemplateId;

  // ═══════════════════════════════════════════════════════════════
  // حالة التحميل والأخطاء
  // ═══════════════════════════════════════════════════════════════

  bool _isLoading = false;
  bool _isSending = false;
  bool _isUploadingImage = false;
  String? _errorMessage;
  String? _successMessage;

  // ═══════════════════════════════════════════════════════════════
  // فلاتر صفحة السجل
  // ═══════════════════════════════════════════════════════════════

  String _statusFilter = 'all';
  String _audienceFilter = 'all';

  // ═══════════════════════════════════════════════════════════════
  // Getters
  // ═══════════════════════════════════════════════════════════════

  String get title => _title;
  String get body => _body;
  File? get imageFile => _imageFile;
  String? get imageUrl => _imageUrl;
  String get deliveryType => _deliveryType;
  String get targetAudience => _targetAudience;
  String? get targetUserId => _targetUserId;
  String? get targetUserName => _targetUserName;
  String? get targetUserType => _targetUserType;
  bool get hasCTA => _hasCTA;
  String get ctaType => _ctaType;
  String get ctaLabel => _ctaLabel;
  String get ctaValue => _ctaValue;
  bool get isScheduled => _isScheduled;
  DateTime? get scheduledAt => _scheduledAt;
  String? get selectedTemplateId => _selectedTemplateId;

  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isUploadingImage => _isUploadingImage;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  String get statusFilter => _statusFilter;
  String get audienceFilter => _audienceFilter;

  // ═══════════════════════════════════════════════════════════════
  // Setters
  // ═══════════════════════════════════════════════════════════════

  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void setBody(String value) {
    _body = value;
    notifyListeners();
  }

  void setImageFile(File? file) {
    _imageFile = file;
    notifyListeners();
  }

  void setDeliveryType(String value) {
    _deliveryType = value;
    notifyListeners();
  }

  void setTargetAudience(String value) {
    _targetAudience = value;
    notifyListeners();
  }

  void setTargetUser({
    required String userId,
    required String userName,
    required String userType,
  }) {
    _targetUserId = userId;
    _targetUserName = userName;
    _targetUserType = userType;
    _targetAudience = 'individual';
    notifyListeners();
  }

  void setHasCTA(bool value) {
    _hasCTA = value;
    notifyListeners();
  }

  void setCTAType(String value) {
    _ctaType = value;
    notifyListeners();
  }

  void setCTALabel(String value) {
    _ctaLabel = value;
    notifyListeners();
  }

  void setCTAValue(String value) {
    _ctaValue = value;
    notifyListeners();
  }

  void setIsScheduled(bool value) {
    _isScheduled = value;
    if (!value) _scheduledAt = null;
    notifyListeners();
  }

  void setScheduledAt(DateTime? value) {
    _scheduledAt = value;
    notifyListeners();
  }

  void setSelectedTemplateId(String? value) {
    _selectedTemplateId = value;
    notifyListeners();
  }

  void setStatusFilter(String value) {
    _statusFilter = value;
    notifyListeners();
  }

  void setAudienceFilter(String value) {
    _audienceFilter = value;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // تحميل قالب مسبق
  // ═══════════════════════════════════════════════════════════════

  void loadFromTemplate({
    required String templateId,
    required String title,
    required String body,
    String? imageUrl,
    AnnouncementCTA? cta,
  }) {
    _selectedTemplateId = templateId;
    _title = title;
    _body = body;
    _imageUrl = imageUrl;
    if (cta != null) {
      _hasCTA = true;
      _ctaType = cta.type;
      _ctaLabel = cta.label;
      _ctaValue = cta.value;
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // التحقق من صحة البيانات
  // ═══════════════════════════════════════════════════════════════

  String? validate() {
    if (_title.trim().isEmpty) return 'يرجى إدخال عنوان الإعلان';
    if (_body.trim().isEmpty) return 'يرجى إدخال نص الإعلان';
    if (_isScheduled && _scheduledAt == null) return 'يرجى تحديد وقت الإرسال';
    if (_isScheduled && _scheduledAt!.isBefore(DateTime.now())) {
      return 'وقت الإرسال يجب أن يكون في المستقبل';
    }
    if (_hasCTA && _ctaLabel.trim().isEmpty) return 'يرجى إدخال نص زر الإجراء';
    if (_hasCTA && _ctaValue.trim().isEmpty) {
      return 'يرجى إدخال قيمة زر الإجراء';
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════
  // إرسال الإعلان
  // ═══════════════════════════════════════════════════════════════

  Future<bool> submitAnnouncement() async {
    final validationError = validate();
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    try {
      _isSending = true;
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();

      // رفع الصورة إن وجدت
      String? uploadedImageUrl = _imageUrl;
      if (_imageFile != null) {
        _isUploadingImage = true;
        notifyListeners();
        uploadedImageUrl =
            await _service.uploadAnnouncementImage(_imageFile!);
        _isUploadingImage = false;
        notifyListeners();
      }

      final user = FirebaseAuth.instance.currentUser;
      final announcement = AnnouncementModel(
        id: '',
        title: _title.trim(),
        body: _body.trim(),
        imageUrl: uploadedImageUrl,
        deliveryType: _deliveryType,
        targetAudience: _targetAudience,
        targetUserId: _targetUserId,
        targetUserName: _targetUserName,
        targetUserType: _targetUserType,
        templateId: _selectedTemplateId,
        cta: _hasCTA
            ? AnnouncementCTA(
                type: _ctaType,
                label: _ctaLabel.trim(),
                value: _ctaValue.trim(),
              )
            : null,
        status: _isScheduled ? 'scheduled' : 'draft',
        scheduledAt: _isScheduled ? _scheduledAt : null,
        createdAt: DateTime.now(),
        createdBy: user?.uid ?? '',
        createdByName: user?.displayName ?? 'أدمن',
        idempotencyKey: const Uuid().v4(),
        stats: AnnouncementStats(),
      );

      if (_isScheduled) {
        // حفظ وجدولة
        final id = await _service.createAnnouncement(announcement);
        await _service.scheduleAnnouncement(id, _scheduledAt!);
        _successMessage = 'تم جدولة الإعلان بنجاح';
      } else {
        // إنشاء وإرسال فوري
        await _service.createAndSend(announcement);
        _successMessage = 'تم إرسال الإعلان بنجاح';
      }

      resetForm();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      return false;
    } finally {
      _isSending = false;
      _isUploadingImage = false;
      notifyListeners();
    }
  }

  /// إرسال إشعار فردي
  Future<bool> sendDirectNotification({
    required String targetUserId,
    required String targetUserName,
    required String targetUserType,
    required String title,
    required String body,
    String deliveryType = 'both',
  }) async {
    try {
      _isSending = true;
      _errorMessage = null;
      notifyListeners();

      await _service.sendDirectNotification(
        targetUserId: targetUserId,
        targetUserName: targetUserName,
        targetUserType: targetUserType,
        title: title,
        body: body,
        deliveryType: deliveryType,
      );

      _successMessage = 'تم إرسال الإشعار بنجاح إلى $targetUserName';
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<bool> retryAnnouncement(String announcementId) async {
    try {
      _isSending = true;
      _errorMessage = null;
      notifyListeners();
      await _service.retrySend(announcementId);
      _successMessage = 'تم إرسال الإعلان بنجاح';
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  String _formatError(Object e) {
    if (e is FirebaseFunctionsException) {
      switch (e.code) {
        case 'permission-denied':
          return 'ليس لديك صلاحية الإرسال. تأكد أن حسابك مسجّل كأدمن.';
        case 'unauthenticated':
          return 'يجب تسجيل الدخول أولاً.';
        case 'not-found':
          return 'خدمة الإرسال غير متوفرة على السيرفر. تأكد من نشر Cloud Functions.';
        default:
          return 'فشل الإرسال: ${e.message ?? e.code}';
      }
    }
    if (e is TimeoutException) {
      return 'انتهت مهلة الإرسال. جرّب نوع "رسالة داخلية فقط" للاختبار.';
    }
    final text = e.toString();
    if (text.startsWith('Exception: ')) {
      return text.substring(11);
    }
    return 'حدث خطأ: $text';
  }

  // ═══════════════════════════════════════════════════════════════
  // Streams
  // ═══════════════════════════════════════════════════════════════

  /// Stream للإعلانات مع الفلاتر الحالية
  Stream<List<AnnouncementModel>> get filteredAnnouncements {
    return _service.getAnnouncementsStream(
      statusFilter: _statusFilter,
      targetAudienceFilter: _audienceFilter,
    );
  }

  /// إحصائيات Dashboard
  Stream<Map<String, int>> get dashboardStats {
    return _service.getDashboardStats();
  }

  // ═══════════════════════════════════════════════════════════════
  // إعادة تعيين النموذج
  // ═══════════════════════════════════════════════════════════════

  void resetForm() {
    _title = '';
    _body = '';
    _imageFile = null;
    _imageUrl = null;
    _deliveryType = 'both';
    _targetAudience = 'all';
    _targetUserId = null;
    _targetUserName = null;
    _targetUserType = null;
    _hasCTA = false;
    _ctaType = 'open_page';
    _ctaLabel = '';
    _ctaValue = '';
    _isScheduled = false;
    _scheduledAt = null;
    _selectedTemplateId = null;
    _errorMessage = null;
    // لا نمسح _successMessage حتى يراها المستخدم
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = 'all';
    _audienceFilter = 'all';
    notifyListeners();
  }
}
