import 'package:flutter/material.dart';
import '../models/announcement_template_model.dart';
import '../models/announcement_model.dart';
import '../services/template_service.dart';

/// ViewModel لإدارة القوالب
class TemplateViewModel extends ChangeNotifier {
  final TemplateService _service = TemplateService();

  // ═══════════════════════════════════════════════════════════════
  // حالة النموذج (إنشاء/تعديل قالب)
  // ═══════════════════════════════════════════════════════════════

  String _name = '';
  String _title = '';
  String _body = '';
  String? _imageUrl;
  String _category = 'custom';
  bool _isActive = true;
  bool _hasCTA = false;
  String _ctaType = 'open_page';
  String _ctaLabel = '';
  String _ctaValue = '';

  // حالة التحميل
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // فلاتر
  String _categoryFilter = 'all';
  String _activeFilter = 'all';

  // ═══════════════════════════════════════════════════════════════
  // Getters
  // ═══════════════════════════════════════════════════════════════

  String get name => _name;
  String get title => _title;
  String get body => _body;
  String? get imageUrl => _imageUrl;
  String get category => _category;
  bool get isActive => _isActive;
  bool get hasCTA => _hasCTA;
  String get ctaType => _ctaType;
  String get ctaLabel => _ctaLabel;
  String get ctaValue => _ctaValue;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  String get categoryFilter => _categoryFilter;
  String get activeFilter => _activeFilter;

  // ═══════════════════════════════════════════════════════════════
  // Setters
  // ═══════════════════════════════════════════════════════════════

  void setName(String value) {
    _name = value;
    notifyListeners();
  }

  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void setBody(String value) {
    _body = value;
    notifyListeners();
  }

  void setImageUrl(String? value) {
    _imageUrl = value;
    notifyListeners();
  }

  void setCategory(String value) {
    _category = value;
    notifyListeners();
  }

  void setIsActive(bool value) {
    _isActive = value;
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

  void setCategoryFilter(String value) {
    _categoryFilter = value;
    notifyListeners();
  }

  void setActiveFilter(String value) {
    _activeFilter = value;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // تحميل قالب للتعديل
  // ═══════════════════════════════════════════════════════════════

  Future<void> loadTemplate(String templateId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final template = await _service.getTemplate(templateId);
      if (template != null) {
        _name = template.name;
        _title = template.title;
        _body = template.body;
        _imageUrl = template.imageUrl;
        _category = template.category;
        _isActive = template.isActive;
        if (template.cta != null) {
          _hasCTA = true;
          _ctaType = template.cta!.type;
          _ctaLabel = template.cta!.label;
          _ctaValue = template.cta!.value;
        }
      }
    } catch (e) {
      _errorMessage = 'خطأ في تحميل القالب: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // حفظ القالب
  // ═══════════════════════════════════════════════════════════════

  String? validate() {
    if (_name.trim().isEmpty) return 'يرجى إدخال اسم القالب';
    if (_title.trim().isEmpty) return 'يرجى إدخال عنوان القالب';
    if (_body.trim().isEmpty) return 'يرجى إدخال نص القالب';
    if (_hasCTA && _ctaLabel.trim().isEmpty) return 'يرجى إدخال نص زر الإجراء';
    if (_hasCTA && _ctaValue.trim().isEmpty) {
      return 'يرجى إدخال قيمة زر الإجراء';
    }
    return null;
  }

  /// حفظ قالب جديد
  Future<bool> saveTemplate() async {
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

      final now = DateTime.now();
      final template = AnnouncementTemplateModel(
        id: '',
        name: _name.trim(),
        title: _title.trim(),
        body: _body.trim(),
        imageUrl: _imageUrl,
        cta: _hasCTA
            ? AnnouncementCTA(
                type: _ctaType,
                label: _ctaLabel.trim(),
                value: _ctaValue.trim(),
              )
            : null,
        category: _category,
        isActive: _isActive,
        createdAt: now,
        updatedAt: now,
        createdBy: '',
      );

      await _service.createTemplate(template);
      _successMessage = 'تم إنشاء القالب بنجاح';
      resetForm();
      return true;
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تحديث قالب موجود
  Future<bool> updateTemplate(String templateId) async {
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

      await _service.updateTemplate(templateId, {
        'name': _name.trim(),
        'title': _title.trim(),
        'body': _body.trim(),
        'imageUrl': _imageUrl,
        'cta': _hasCTA
            ? AnnouncementCTA(
                type: _ctaType,
                label: _ctaLabel.trim(),
                value: _ctaValue.trim(),
              ).toMap()
            : null,
        'category': _category,
        'isActive': _isActive,
      });

      _successMessage = 'تم تحديث القالب بنجاح';
      return true;
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تبديل حالة التفعيل
  Future<void> toggleActive(String templateId, bool isActive) async {
    try {
      await _service.toggleTemplateActive(templateId, isActive);
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      notifyListeners();
    }
  }

  /// حذف قالب
  Future<void> deleteTemplate(String templateId) async {
    try {
      await _service.deleteTemplate(templateId);
      _successMessage = 'تم حذف القالب';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Streams
  // ═══════════════════════════════════════════════════════════════

  Stream<List<AnnouncementTemplateModel>> get templatesStream {
    return _service.getTemplatesStream();
  }

  Stream<List<AnnouncementTemplateModel>> get activeTemplatesStream {
    return _service.getActiveTemplatesStream();
  }

  // ═══════════════════════════════════════════════════════════════
  // إعادة تعيين
  // ═══════════════════════════════════════════════════════════════

  void resetForm() {
    _name = '';
    _title = '';
    _body = '';
    _imageUrl = null;
    _category = 'custom';
    _isActive = true;
    _hasCTA = false;
    _ctaType = 'open_page';
    _ctaLabel = '';
    _ctaValue = '';
    _errorMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearFilters() {
    _categoryFilter = 'all';
    _activeFilter = 'all';
    notifyListeners();
  }
}
