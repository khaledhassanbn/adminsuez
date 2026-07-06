import 'package:flutter/material.dart';
import '../services/ads_service.dart';
import '../services/ad_request_service.dart';

class AdsDashboardViewModel extends ChangeNotifier {
  final AdsService _adsService = AdsService();
  final AdRequestService _requestService = AdRequestService();

  Map<String, dynamic> _stats = {};
  int _pendingCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic> get stats => _stats;
  int get pendingCount => _pendingCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await _adsService.getAdsStats();
      final requests = await _requestService.fetchAllAdRequests();
      _pendingCount = requests.where((r) => r.status == 'pending').length;
    } catch (e) {
      _errorMessage = 'خطأ في تحميل الإحصائيات: ${e.toString()}';
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
