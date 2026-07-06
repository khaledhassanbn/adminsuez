import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ad_model.dart';
import '../services/ads_service.dart';

enum AdFilter { all, active, paused, expired }

class AdminAdsViewModel extends ChangeNotifier {
  final AdsService _adsService = AdsService();
  final ImagePicker _imagePicker = ImagePicker();

  List<AdModel> _allAds = [];
  List<AdModel> _ads = [];
  List<Map<String, String>> _stores = [];
  List<Map<String, String>> _craftsmen = [];
  AdFilter _filter = AdFilter.all;
  bool _isLoading = true;
  String? _errorMessage;

  List<AdModel> get ads => _ads;
  List<Map<String, String>> get stores => _stores;
  List<Map<String, String>> get craftsmen => _craftsmen;
  AdFilter get filter => _filter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadData({bool silent = false}) async {
    if (!silent) _setLoading(true);
    _errorMessage = null;

    try {
      _allAds = await _adsService.fetchAds();
      _stores = await _adsService.fetchStores();
      _craftsmen = await _adsService.fetchCraftsmen();
      _applyFilter();
    } catch (e) {
      _errorMessage = 'خطأ في تحميل البيانات: ${e.toString()}';
    } finally {
      if (!silent) _setLoading(false);
      else notifyListeners();
    }
  }

  void _sortNewestFirst(List<AdModel> ads) {
    ads.sort((a, b) {
      final aTime = a.startTime;
      final bTime = b.startTime;
      if (aTime != null && bTime != null) {
        return bTime.compareTo(aTime);
      }
      if (aTime != null) return -1;
      if (bTime != null) return 1;
      return b.slotId.compareTo(a.slotId);
    });
  }

  void setFilter(AdFilter filter) {
    _filter = filter;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    switch (_filter) {
      case AdFilter.active:
        _ads = _allAds.where((ad) => ad.isValid).toList();
      case AdFilter.paused:
        _ads = _allAds.where((ad) => ad.isPaused && !ad.isExpired).toList();
      case AdFilter.expired:
        _ads = _allAds.where((ad) => ad.isExpired).toList();
      case AdFilter.all:
        _ads = List.from(_allAds);
    }
    _sortNewestFirst(_ads);
  }

  Future<bool> addNewAd() async {
    final newAd = AdModel(slotId: 0, durationHours: 24, isActive: false);
    return addAd(newAd);
  }

  Future<bool> addAd(AdModel ad) async {
    _errorMessage = null;
    try {
      final success = await _adsService.addAd(ad);
      if (success) {
        await loadData();
        return true;
      }
      _errorMessage = 'فشل إضافة الإعلان';
      return false;
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return false;
    }
  }

  Future<bool> deleteAd(int slotId) async {
    _errorMessage = null;
    try {
      final success = await _adsService.deleteAd(slotId);
      if (success) {
        await loadData(silent: true);
        return true;
      }
      _errorMessage = 'فشل حذف الإعلان';
      return false;
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return false;
    }
  }

  Future<bool> pauseAd(int slotId) async {
    _errorMessage = null;
    try {
      final success = await _adsService.pauseAd(slotId);
      if (success) {
        await loadData(silent: true);
        return true;
      }
      _errorMessage = 'فشل إيقاف الإعلان';
      return false;
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return false;
    }
  }

  Future<bool> resumeAd(int slotId) async {
    _errorMessage = null;
    try {
      final success = await _adsService.resumeAd(slotId);
      if (success) {
        await loadData(silent: true);
        return true;
      }
      _errorMessage = 'فشل استئناف الإعلان';
      return false;
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return false;
    }
  }

  Future<bool> toggleAdStatus(int slotId, bool isActive) async {
    _errorMessage = null;
    try {
      final success = await _adsService.toggleAdStatus(slotId, !isActive);
      if (success) {
        await loadData(silent: true);
        return true;
      }
      _errorMessage = 'فشل تغيير حالة الإعلان';
      return false;
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return false;
    }
  }

  Future<String?> pickAndUploadImage(int slotId) async {
    _errorMessage = null;
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      final imageUrl = await _adsService.uploadAdImage(
        File(image.path),
        slotId,
      );

      if (imageUrl == null) {
        _errorMessage = 'فشل رفع الصورة';
        return null;
      }

      final adIndex = _ads.indexWhere((ad) => ad.slotId == slotId);
      final allIndex = _allAds.indexWhere((ad) => ad.slotId == slotId);
      if (adIndex != -1) {
        final updatedAd = _ads[adIndex].copyWith(imageUrl: imageUrl);
        final saved = await _adsService.updateAd(updatedAd);
        if (saved) {
          _ads[adIndex] = updatedAd;
          if (allIndex != -1) _allAds[allIndex] = updatedAd;
          notifyListeners();
        }
      }

      return imageUrl;
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return null;
    }
  }

  Future<bool> saveAd(AdModel ad) async {
    _errorMessage = null;

    if (ad.imageUrl == null || ad.imageUrl!.isEmpty) {
      _errorMessage = 'يرجى اختيار صورة للإعلان';
      return false;
    }

    if (ad.durationHours <= 0) {
      _errorMessage = 'يرجى إدخال مدة صالحة';
      return false;
    }

    try {
      final success = await _adsService.updateAd(ad);
      if (success) {
        await loadData(silent: true);
        return true;
      }
      _errorMessage = 'فشل حفظ الإعلان';
      return false;
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
