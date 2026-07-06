import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/ad_model.dart';

class AdsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // جلب جميع الإعلانات
  Future<List<AdModel>> fetchAds() async {
    try {
      final doc = await _firestore
          .collection('app_settings')
          .doc('home_ads')
          .get();

      if (!doc.exists || doc.data()?['ads'] == null) {
        return [];
      }

      final adsData = doc.data()!['ads'];
      if (adsData is! List) {
        return [];
      }

      final ads = adsData
          .map((ad) {
            if (ad is Map) {
              return AdModel.fromMap(Map<String, dynamic>.from(ad));
            }
            return null;
          })
          .whereType<AdModel>()
          .toList();

      // ترتيب الإعلانات حسب slotId
      ads.sort((a, b) => a.slotId.compareTo(b.slotId));

      return ads;
    } catch (e) {
      print('خطأ في جلب الإعلانات: $e');
      return [];
    }
  }

  // جلب الإعلانات النشطة والصالحة فقط (للعرض في الصفحة الرئيسية)
  Future<List<AdModel>> fetchActiveAds() async {
    try {
      final allAds = await fetchAds();
      return allAds.where((ad) => ad.isValid).toList();
    } catch (e) {
      print('خطأ في جلب الإعلانات النشطة: $e');
      return [];
    }
  }

  // رفع صورة الإعلان إلى Firebase Storage
  Future<String?> uploadAdImage(File imageFile, int slotId) async {
    try {
      final String fileName =
          'ad_slot_${slotId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('ads/$fileName');

      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('خطأ في رفع الصورة: $e');
      return null;
    }
  }

  // تحديث إعلان معين
  Future<bool> updateAd(AdModel ad) async {
    try {
      // جلب جميع الإعلانات الحالية
      final doc = await _firestore
          .collection('app_settings')
          .doc('home_ads')
          .get();

      List<Map<String, dynamic>> ads = [];

      if (doc.exists && doc.data()?['ads'] != null) {
        final adsData = doc.data()!['ads'];
        if (adsData is List) {
          ads = adsData
              .map((item) {
                if (item is Map<String, dynamic>) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              })
              .where((item) => item.isNotEmpty)
              .toList();
        }
      }

      // تحديث الإعلان المحدد
      final index = ads.indexWhere((a) => a['slotId'] == ad.slotId);

      if (index != -1) {
        ads[index] = ad.toMap();
      } else {
        ads.add(ad.toMap());
      }

      // حفظ التحديثات
      await _firestore.collection('app_settings').doc('home_ads').set({
        'ads': ads,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('خطأ في تحديث الإعلان: $e');
      return false;
    }
  }

  // إضافة إعلان جديد
  Future<bool> addAd(AdModel ad) async {
    try {
      final allAds = await fetchAds();

      // تحديد slotId جديد (أكبر slotId + 1)
      int newSlotId = 1;
      if (allAds.isNotEmpty) {
        newSlotId =
            allAds.map((a) => a.slotId).reduce((a, b) => a > b ? a : b) + 1;
      }

      final newAd = ad.copyWith(slotId: newSlotId);
      return await updateAd(newAd);
    } catch (e) {
      print('خطأ في إضافة الإعلان: $e');
      return false;
    }
  }

  // حذف إعلان
  Future<bool> deleteAd(int slotId) async {
    try {
      final doc = await _firestore
          .collection('app_settings')
          .doc('home_ads')
          .get();

      if (!doc.exists || doc.data()?['ads'] == null) {
        return false;
      }

      final adsData = doc.data()!['ads'];
      if (adsData is! List) {
        return false;
      }

      List<Map<String, dynamic>> ads = adsData
          .map((item) {
            if (item is Map<String, dynamic>) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          })
          .where((item) => item.isNotEmpty && item['slotId'] != slotId)
          .toList();

      // حفظ التحديثات
      await _firestore.collection('app_settings').doc('home_ads').set({
        'ads': ads,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('خطأ في حذف الإعلان: $e');
      return false;
    }
  }

  // حذف صورة الإعلان
  Future<bool> deleteAdImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('خطأ في حذف الصورة: $e');
      return false;
    }
  }

  Future<bool> pauseAd(int slotId) async {
    try {
      final allAds = await fetchAds();
      final adIndex = allAds.indexWhere((ad) => ad.slotId == slotId);
      if (adIndex == -1) return false;
      return updateAd(allAds[adIndex].copyWith(isPaused: true));
    } catch (e) {
      print('خطأ في إيقاف الإعلان: $e');
      return false;
    }
  }

  Future<bool> resumeAd(int slotId) async {
    try {
      final allAds = await fetchAds();
      final adIndex = allAds.indexWhere((ad) => ad.slotId == slotId);
      if (adIndex == -1) return false;
      final ad = allAds[adIndex];
      return updateAd(
        ad.copyWith(
          isPaused: false,
          isActive: true,
          startTime: ad.startTime ?? DateTime.now(),
        ),
      );
    } catch (e) {
      print('خطأ في استئناف الإعلان: $e');
      return false;
    }
  }

  Future<bool> createAdminAd({
    required String imageUrl,
    required int durationHours,
    required String targetType,
    String? targetId,
    String? targetName,
  }) async {
    final newAd = AdModel(
      slotId: 0,
      imageUrl: imageUrl,
      targetStoreId: targetId,
      targetType: targetType,
      durationHours: durationHours,
      isActive: true,
      isPaused: false,
      startTime: DateTime.now(),
      createdBy: AdCreatedBy.admin,
      ownerName: targetName,
      price: 0,
    );
    return addAd(newAd);
  }

  Future<Map<String, dynamic>> getAdsStats() async {
    final allAds = await fetchAds();
    final requestsSnap = await _firestore.collection('ad_requests').get();
    final requests = requestsSnap.docs;

    double revenue = 0;
    int active = 0;
    int scheduled = 0;
    int paused = 0;
    int expired = 0;

    for (final ad in allAds) {
      if (ad.isValid) {
        active++;
      } else if (ad.isScheduled) {
        scheduled++;
      } else if (ad.isPaused && !ad.isExpired) {
        paused++;
      } else if (ad.isExpired) {
        expired++;
      }
      if (ad.price > 0) revenue += ad.price;
    }

    return {
      'active': active,
      'scheduled': scheduled,
      'paused': paused,
      'expired': expired,
      'pendingRequests': requests.where((d) => d.data()['status'] == 'pending').length,
      'rejectedRequests': requests.where((d) => d.data()['status'] == 'rejected').length,
      'revenue': revenue,
      'totalAds': allAds.length,
    };
  }

  Future<List<Map<String, String>>> fetchCraftsmen() async {
    try {
      final snapshot = await _firestore.collection('craftsmen').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': (data['name'] ?? data['displayName'] ?? 'حرفي').toString(),
        };
      }).toList();
    } catch (e) {
      print('خطأ في جلب الحرفيين: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> fetchAllTargets() async {
    final stores = await fetchStores();
    final craftsmen = await fetchCraftsmen();
    return [...stores, ...craftsmen];
  }

  // تبديل حالة الإعلان (تشغيل/إيقاف)
  Future<bool> toggleAdStatus(int slotId, bool newIsActive) async {
    try {
      final allAds = await fetchAds();
      final adIndex = allAds.indexWhere((ad) => ad.slotId == slotId);

      if (adIndex == -1) return false;

      final ad = allAds[adIndex];
      DateTime? newStartTime = ad.startTime;
      var newIsPaused = ad.isPaused;

      if (newIsActive) {
        newIsPaused = false;
        if (newStartTime == null || ad.isExpired) {
          newStartTime = DateTime.now();
        }
      }

      final updatedAd = ad.copyWith(
        isActive: newIsActive,
        isPaused: newIsPaused,
        startTime: newStartTime,
      );

      return await updateAd(updatedAd);
    } catch (e) {
      print('خطأ في تبديل حالة الإعلان: $e');
      return false;
    }
  }

  // جلب جميع المتاجر لاستخدامها في Dropdown
  Future<List<Map<String, String>>> fetchStores() async {
    try {
      final snapshot = await _firestore.collection('markets').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, 'name': (data['name'] ?? 'متجر').toString()};
      }).toList();
    } catch (e) {
      print('خطأ في جلب المتاجر: $e');
      return [];
    }
  }

  // حذف صور الإعلانات المنتهية تلقائياً
  Future<int> deleteExpiredAdsImages() async {
    int deletedCount = 0;
    try {
      final allAds = await fetchAds();

      // فلترة الإعلانات المنتهية فقط
      final expiredAds = allAds.where((ad) {
        // إعلان منتهي إذا كان:
        // 1. غير نشط (isActive = false) أو
        // 2. نشط لكن انتهت مدته (isValid = false)
        return !ad.isValid && ad.imageUrl != null && ad.imageUrl!.isNotEmpty;
      }).toList();

      // حذف صور الإعلانات المنتهية
      for (final ad in expiredAds) {
        try {
          if (ad.imageUrl != null && ad.imageUrl!.isNotEmpty) {
            await deleteAdImage(ad.imageUrl!);
            deletedCount++;

            // تحديث الإعلان لإزالة رابط الصورة
            final updatedAd = ad.copyWith(imageUrl: null);
            await updateAd(updatedAd);
          }
        } catch (e) {
          print('خطأ في حذف صورة الإعلان ${ad.slotId}: $e');
          // نستمر في حذف باقي الصور حتى لو فشل حذف واحدة
        }
      }

      print('تم حذف $deletedCount صورة للإعلانات المنتهية');
      return deletedCount;
    } catch (e) {
      print('خطأ في حذف صور الإعلانات المنتهية: $e');
      return deletedCount;
    }
  }
}
