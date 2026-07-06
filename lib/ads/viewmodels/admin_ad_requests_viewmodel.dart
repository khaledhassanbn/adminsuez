import 'package:flutter/material.dart';
import '../models/ad_request_model.dart';
import '../models/ad_model.dart';
import '../services/ad_request_service.dart';
import '../services/ads_service.dart';

enum RequestFilter { pending, approved, rejected, all }

class AdminAdRequestsViewModel extends ChangeNotifier {
  final AdRequestService _adRequestService = AdRequestService();
  final AdsService _adsService = AdsService();

  List<AdRequestModel> _allRequests = [];
  List<AdRequestModel> _requests = [];
  RequestFilter _filter = RequestFilter.pending;
  bool _isLoading = true;
  String? _errorMessage;

  List<AdRequestModel> get requests => _requests;
  RequestFilter get filter => _filter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadRequests() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _allRequests = await _adRequestService.fetchAllAdRequests();
      _applyFilter();
    } catch (e) {
      _errorMessage = 'خطأ في تحميل الطلبات: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  void setFilter(RequestFilter filter) {
    _filter = filter;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    switch (_filter) {
      case RequestFilter.pending:
        _requests = _allRequests.where((r) => r.status == 'pending').toList();
      case RequestFilter.approved:
        _requests = _allRequests.where((r) => r.status == 'approved').toList();
      case RequestFilter.rejected:
        _requests = _allRequests.where((r) => r.status == 'rejected').toList();
      case RequestFilter.all:
        _requests = List.from(_allRequests);
    }
  }

  Future<bool> approveRequest(String requestId) async {
    _errorMessage = null;

    try {
      final request = _allRequests.firstWhere((r) => r.id == requestId);

      final targetType = request.isCraftsmanRequest
          ? AdTargetType.craftsman
          : AdTargetType.store;

      final newAd = AdModel(
        slotId: 0,
        imageUrl: request.imageUrl,
        targetStoreId: request.storeId,
        targetType: targetType,
        durationHours: request.days * 24,
        isActive: true,
        isPaused: false,
        startTime: DateTime.now(),
        createdBy: request.isCraftsmanRequest
            ? AdCreatedBy.craftsman
            : AdCreatedBy.merchant,
        ownerUid: request.ownerUid,
        ownerName: request.storeName,
        price: request.totalPrice,
        requestId: request.id,
      );

      final adCreated = await _adsService.addAd(newAd);
      if (!adCreated) {
        _errorMessage = 'فشل إنشاء الإعلان';
        return false;
      }

      final success = await _adRequestService.updateRequestStatus(
        requestId,
        'approved',
      );

      if (success) {
        await loadRequests();
        return true;
      }
      _errorMessage = 'فشل تحديث حالة الطلب';
      return false;
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return false;
    }
  }

  Future<bool> rejectWithReason(String requestId, String reason) async {
    _errorMessage = null;

    try {
      final success = await _adRequestService.updateRequestStatus(
        requestId,
        'rejected',
        rejectionReason: reason,
        refund: true,
      );

      if (success) {
        await loadRequests();
        return true;
      }
      _errorMessage = 'فشل رفض الطلب';
      return false;
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return false;
    }
  }

  Future<bool> deleteRequest(String requestId) async {
    _errorMessage = null;

    try {
      final success = await _adRequestService.deleteAdRequest(requestId);
      if (success) {
        await loadRequests();
        return true;
      }
      _errorMessage = 'فشل حذف الطلب';
      return false;
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return false;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'approved':
        return 'موافق عليه';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  String formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
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
