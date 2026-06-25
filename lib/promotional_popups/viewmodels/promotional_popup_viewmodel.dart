import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/promotional_popup_model.dart';
import '../services/promotional_popup_service.dart';

/// ViewModel لإدارة الإعلانات المنبثقة
class PromotionalPopupViewModel extends ChangeNotifier {
  final PromotionalPopupService _service = PromotionalPopupService();

  // حالة النموذج
  String? _title;
  String? _description;
  File? _imageFile;
  String? _imageUrl;
  String _targetAudience = 'all';
  bool _isActive = true;
  int _priority = 0;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  int _maxImpressions = 0;
  bool _isDismissible = true;
  bool _hasCTA = false;
  String _ctaType = 'open_page';
  String _ctaValue = '';

  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _errorMessage;
  String? _successMessage;

  // Getters
  String? get title => _title;
  String? get description => _description;
  File? get imageFile => _imageFile;
  String? get imageUrl => _imageUrl;
  String get targetAudience => _targetAudience;
  bool get isActive => _isActive;
  int get priority => _priority;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  int get maxImpressions => _maxImpressions;
  bool get isDismissible => _isDismissible;
  bool get hasCTA => _hasCTA;
  String get ctaType => _ctaType;
  String get ctaValue => _ctaValue;
  bool get isLoading => _isLoading;
  bool get isUploadingImage => _isUploadingImage;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // Setters
  void setTitle(String? v) { _title = v; notifyListeners(); }
  void setDescription(String? v) { _description = v; notifyListeners(); }
  void setImageFile(File? v) { _imageFile = v; notifyListeners(); }
  void setImageUrl(String? v) { _imageUrl = v; notifyListeners(); }
  void setTargetAudience(String v) { _targetAudience = v; notifyListeners(); }
  void setIsActive(bool v) { _isActive = v; notifyListeners(); }
  void setPriority(int v) { _priority = v; notifyListeners(); }
  void setStartDate(DateTime v) { _startDate = v; notifyListeners(); }
  void setEndDate(DateTime v) { _endDate = v; notifyListeners(); }
  void setMaxImpressions(int v) { _maxImpressions = v; notifyListeners(); }
  void setIsDismissible(bool v) { _isDismissible = v; notifyListeners(); }
  void setHasCTA(bool v) { _hasCTA = v; notifyListeners(); }
  void setCTAType(String v) { _ctaType = v; notifyListeners(); }
  void setCTAValue(String v) { _ctaValue = v; notifyListeners(); }

  /// تحميل إعلان للتعديل
  Future<void> loadPopup(String popupId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final popup = await _service.getPopup(popupId);
      if (popup != null) {
        _title = popup.title;
        _description = popup.description;
        _imageUrl = popup.imageUrl;
        _targetAudience = popup.targetAudience;
        _isActive = popup.isActive;
        _priority = popup.priority;
        _startDate = popup.startDate;
        _endDate = popup.endDate;
        _maxImpressions = popup.maxImpressions;
        _isDismissible = popup.isDismissible;
        if (popup.cta != null) {
          _hasCTA = true;
          _ctaType = popup.cta!.type;
          _ctaValue = popup.cta!.value;
        }
      }
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// التحقق
  String? validate() {
    if (_imageFile == null && (_imageUrl == null || _imageUrl!.isEmpty)) {
      return 'يرجى رفع صورة الإعلان';
    }
    if (_endDate.isBefore(_startDate)) {
      return 'تاريخ الانتهاء يجب أن يكون بعد تاريخ البداية';
    }
    return null;
  }

  /// حفظ إعلان منبثق جديد
  Future<bool> savePopup() async {
    final error = validate();
    if (error != null) {
      _errorMessage = error;
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // رفع الصورة
      String finalImageUrl = _imageUrl ?? '';
      if (_imageFile != null) {
        _isUploadingImage = true;
        notifyListeners();
        finalImageUrl = await _service.uploadPopupImage(_imageFile!);
        _isUploadingImage = false;
        notifyListeners();
      }

      final now = DateTime.now();
      final popup = PromotionalPopupModel(
        id: '',
        title: _title,
        description: _description,
        imageUrl: finalImageUrl,
        cta: _hasCTA
            ? PromotionalPopupCTA(type: _ctaType, value: _ctaValue)
            : null,
        targetAudience: _targetAudience,
        isActive: _isActive,
        priority: _priority,
        startDate: _startDate,
        endDate: _endDate,
        maxImpressions: _maxImpressions,
        isDismissible: _isDismissible,
        createdAt: now,
        updatedAt: now,
        createdBy: '',
      );

      await _service.createPopup(popup);
      _successMessage = 'تم إنشاء الإعلان المنبثق بنجاح';
      resetForm();
      return true;
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      _isUploadingImage = false;
      notifyListeners();
    }
  }

  /// تحديث إعلان
  Future<bool> updatePopup(String popupId) async {
    final error = validate();
    if (error != null) {
      _errorMessage = error;
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      String finalImageUrl = _imageUrl ?? '';
      if (_imageFile != null) {
        _isUploadingImage = true;
        notifyListeners();
        finalImageUrl = await _service.uploadPopupImage(_imageFile!);
        _isUploadingImage = false;
      }

      await _service.updatePopup(popupId, {
        'title': _title,
        'description': _description,
        'imageUrl': finalImageUrl,
        'cta': _hasCTA
            ? PromotionalPopupCTA(type: _ctaType, value: _ctaValue).toMap()
            : null,
        'targetAudience': _targetAudience,
        'isActive': _isActive,
        'priority': _priority,
        'startDate': Timestamp.fromDate(_startDate),
        'endDate': Timestamp.fromDate(_endDate),
        'maxImpressions': _maxImpressions,
        'isDismissible': _isDismissible,
      });

      _successMessage = 'تم تحديث الإعلان المنبثق';
      return true;
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      _isUploadingImage = false;
      notifyListeners();
    }
  }

  /// تبديل التفعيل
  Future<void> toggleActive(String popupId, bool isActive) async {
    try {
      await _service.togglePopupActive(popupId, isActive);
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      notifyListeners();
    }
  }

  /// حذف
  Future<void> deletePopup(String popupId) async {
    try {
      await _service.deletePopup(popupId);
      _successMessage = 'تم حذف الإعلان المنبثق';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Streams
  Stream<List<PromotionalPopupModel>> get popupsStream {
    return _service.getPopupsStream();
  }

  void resetForm() {
    _title = null;
    _description = null;
    _imageFile = null;
    _imageUrl = null;
    _targetAudience = 'all';
    _isActive = true;
    _priority = 0;
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 30));
    _maxImpressions = 0;
    _isDismissible = true;
    _hasCTA = false;
    _ctaType = 'open_page';
    _ctaValue = '';
    _errorMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
