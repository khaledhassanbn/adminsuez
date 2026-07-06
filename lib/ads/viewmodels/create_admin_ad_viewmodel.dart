import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ad_model.dart';
import '../services/ads_service.dart';

class CreateAdminAdViewModel extends ChangeNotifier {
  final AdsService _adsService = AdsService();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  int _durationHours = 48;
  String _targetType = AdTargetType.store;
  String? _selectedTargetId;
  String? _selectedTargetName;
  List<Map<String, String>> _stores = [];
  List<Map<String, String>> _craftsmen = [];
  bool _isLoading = false;
  bool _isLoadingTargets = true;
  String? _errorMessage;

  File? get selectedImage => _selectedImage;
  int get durationHours => _durationHours;
  String get targetType => _targetType;
  String? get selectedTargetId => _selectedTargetId;
  String? get selectedTargetName => _selectedTargetName;
  List<Map<String, String>> get stores => _stores;
  List<Map<String, String>> get craftsmen => _craftsmen;
  bool get isLoading => _isLoading;
  bool get isLoadingTargets => _isLoadingTargets;
  String? get errorMessage => _errorMessage;

  Future<void> loadTargets() async {
    _isLoadingTargets = true;
    notifyListeners();
    try {
      _stores = await _adsService.fetchStores();
      _craftsmen = await _adsService.fetchCraftsmen();
    } catch (e) {
      _errorMessage = 'خطأ في تحميل البيانات: ${e.toString()}';
    } finally {
      _isLoadingTargets = false;
      notifyListeners();
    }
  }

  Future<void> pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (image != null) {
      _selectedImage = File(image.path);
      notifyListeners();
    }
  }

  void setDurationHours(int hours) {
    _durationHours = hours;
    notifyListeners();
  }

  void setTargetType(String type) {
    _targetType = type;
    _selectedTargetId = null;
    _selectedTargetName = null;
    notifyListeners();
  }

  void setTarget(String? id, String? name) {
    _selectedTargetId = id;
    _selectedTargetName = name;
    notifyListeners();
  }

  Future<bool> submit() async {
    _errorMessage = null;

    if (_selectedImage == null) {
      _errorMessage = 'يرجى اختيار صورة';
      notifyListeners();
      return false;
    }

    if (_durationHours <= 0) {
      _errorMessage = 'يرجى إدخال مدة صالحة';
      notifyListeners();
      return false;
    }

    if (_targetType != AdTargetType.imageOnly &&
        (_selectedTargetId == null || _selectedTargetId!.isEmpty)) {
      _errorMessage = 'يرجى اختيار الهدف';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final imageUrl = await _adsService.uploadAdImage(_selectedImage!, 0);
      if (imageUrl == null) {
        _errorMessage = 'فشل رفع الصورة';
        return false;
      }

      final success = await _adsService.createAdminAd(
        imageUrl: imageUrl,
        durationHours: _durationHours,
        targetType: _targetType,
        targetId: _targetType == AdTargetType.imageOnly
            ? null
            : _selectedTargetId,
        targetName: _targetType == AdTargetType.imageOnly
            ? null
            : _selectedTargetName,
      );

      if (!success) {
        _errorMessage = 'فشل إنشاء الإعلان';
      }
      return success;
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
