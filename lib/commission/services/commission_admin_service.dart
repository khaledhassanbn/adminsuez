import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:suez_admin/commission/models/commission_config_model.dart';
import 'package:suez_admin/commission/models/wallet_ledger_model.dart';
import 'package:suez_admin/commission/models/wallet_transaction_model.dart';
import 'package:suez_admin/stores/models/store_model.dart';

class CommissionAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<CommissionConfigModel> getCommissionConfig() async {
    final doc = await _firestore.collection('commission_config').doc('default').get();
    if (!doc.exists) {
      final fallback = CommissionConfigModel(
        updatedAt: DateTime.now(),
        updatedBy: _auth.currentUser?.uid,
      );
      await _firestore.collection('commission_config').doc('default').set(
            fallback.toMap(),
            SetOptions(merge: true),
          );
      return fallback;
    }
    return CommissionConfigModel.fromDocument(doc);
  }

  Future<void> saveGlobalCommissionForAllStores({
    required double rate,
    required String type,
    required double creditLimit,
    required List<double> thresholds,
    required bool blockOrdersOnCreditExceeded,
  }) async {
    await updateCommissionConfig(
      rate: rate,
      type: type,
      creditLimit: creditLimit,
      thresholds: thresholds,
      blockOrdersOnCreditExceeded: blockOrdersOnCreditExceeded,
    );
    await applyCommissionToAllStores(rate: rate, type: type);
  }

  Future<void> updateCommissionConfig({
    required double rate,
    required String type,
    required double creditLimit,
    required List<double> thresholds,
    required bool blockOrdersOnCreditExceeded,
  }) async {
    await _firestore.collection('commission_config').doc('default').set({
      'defaultCommissionRate': rate,
      'defaultCommissionType': type,
      'defaultCreditLimit': creditLimit,
      'balanceWarningThresholds': thresholds,
      'blockOrdersOnCreditExceeded': blockOrdersOnCreditExceeded,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid,
    }, SetOptions(merge: true));
  }

  Future<void> applyCommissionToAllStores({
    required double rate,
    required String type,
  }) async {
    final stores = await _firestore.collection('markets').get();
    const batchSize = 400;
    final docs = stores.docs;

    for (var i = 0; i < docs.length; i += batchSize) {
      final batch = _firestore.batch();
      final chunk = docs.skip(i).take(batchSize);
      for (final doc in chunk) {
        batch.set(doc.reference, {
          'commissionRate': rate,
          'commissionType': type,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
    }
  }

  Future<void> updateStoreCommission({
    required String storeId,
    required double rate,
    required String type,
    required double creditLimit,
  }) async {
    await _firestore.collection('markets').doc(storeId).set({
      'commissionRate': rate,
      'commissionType': type,
      'creditLimit': creditLimit,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> resetStoreToDefaultCommission(String storeId) async {
    final config = await getCommissionConfig();
    await updateStoreCommission(
      storeId: storeId,
      rate: config.defaultCommissionRate,
      type: config.defaultCommissionType,
      creditLimit: config.defaultCreditLimit,
    );
  }

  Future<StoreModel?> getStoreCommission(String storeId) async {
    final doc = await _firestore.collection('markets').doc(storeId).get();
    if (!doc.exists) return null;
    final store = StoreModel.fromDocument(doc);
    final ownerId = (doc.data()?['ownerId'] ?? '').toString();
    if (ownerId.isEmpty) return store;
    final userDoc = await _firestore.collection('users').doc(ownerId).get();
    final walletBalance = (userDoc.data()?['walletBalance'] ?? 0).toDouble();
    return store.copyWith(walletBalance: walletBalance);
  }

  Stream<List<WalletLedgerModel>> getStoreWalletLedger(String storeId) {
    return _firestore
        .collection('wallet_ledger')
        .where('storeId', isEqualTo: storeId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map(WalletLedgerModel.fromDocument).toList());
  }

  /// سجل مالي موحد لكل المتاجر (مرتب تنازلياً بالتاريخ).
  /// الفلترة (نوع/متجر/تاريخ/بحث) تتم في الواجهة لتفادي الحاجة لفهارس مركّبة.
  Future<List<WalletLedgerModel>> getGlobalLedger({int limit = 500}) async {
    final snap = await _firestore
        .collection('wallet_ledger')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(WalletLedgerModel.fromDocument).toList();
  }

  /// خريطة معرّف المتجر إلى اسمه (لعرض أسماء المتاجر في السجل المالي).
  Future<Map<String, String>> getStoreNamesMap() async {
    final snap = await _firestore.collection('markets').get();
    final map = <String, String>{};
    for (final doc in snap.docs) {
      final name = (doc.data()['name'] ?? '').toString();
      map[doc.id] = name.isEmpty ? doc.id : name;
    }
    return map;
  }

  Stream<List<WalletTransactionModel>> getWalletTransactions() {
    return _firestore
        .collection('wallet_transactions')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((s) => s.docs.map(WalletTransactionModel.fromDocument).toList());
  }

  Future<void> approveWalletTransaction(WalletTransactionModel tx) async {
    await _firestore.runTransaction((txn) async {
      final txRef = _firestore.collection('wallet_transactions').doc(tx.id);
      final txSnap = await txn.get(txRef);
      if (!txSnap.exists) throw Exception('العملية غير موجودة');
      final data = txSnap.data() ?? {};
      if (data['status'] != 'pending') return;

      final userRef = _firestore.collection('users').doc(tx.userId);
      txn.update(userRef, {'walletBalance': FieldValue.increment(tx.amount)});
      txn.update(txRef, {
        'status': 'approved',
        'adminId': _auth.currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectWalletTransaction({
    required WalletTransactionModel tx,
    required String reason,
  }) async {
    await _firestore.collection('wallet_transactions').doc(tx.id).update({
      'status': 'rejected',
      'rejectReason': reason,
      'adminId': _auth.currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> manualAdjustment({
    required String storeId,
    required String userId,
    required double amount,
    required String description,
  }) async {
    await _firestore.runTransaction((txn) async {
      final userRef = _firestore.collection('users').doc(userId);
      final userSnap = await txn.get(userRef);
      final before = (userSnap.data()?['walletBalance'] ?? 0).toDouble();
      final after = before + amount;
      txn.update(userRef, {'walletBalance': after});

      final ledgerRef = _firestore.collection('wallet_ledger').doc();
      txn.set(ledgerRef, {
        'id': ledgerRef.id,
        'storeId': storeId,
        'userId': userId,
        'type': 'manual_adjustment',
        'amount': amount,
        'balanceBefore': before,
        'balanceAfter': after,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': {
          'adminId': _auth.currentUser?.uid,
        },
      });
    });
  }

  Future<Map<String, int>> getCommissionStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));

    final all = await _firestore
        .collection('wallet_ledger')
        .where('type', isEqualTo: 'order_commission')
        .get();
    final today = await _firestore
        .collection('wallet_ledger')
        .where('type', isEqualTo: 'order_commission')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();
    final week = await _firestore
        .collection('wallet_ledger')
        .where('type', isEqualTo: 'order_commission')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .get();

    int sum(QuerySnapshot snap) {
      return snap.docs.fold<int>(0, (prev, doc) {
        final amount = ((doc.data() as Map<String, dynamic>)['amount'] ?? 0).toDouble();
        return (prev + amount.abs().round()).toInt();
      });
    }

    return {
      'total': sum(all),
      'today': sum(today),
      'week': sum(week),
    };
  }

  Future<int> getStoresNearCreditLimitCount() async {
    final markets = await _firestore.collection('markets').get();
    int count = 0;
    for (final market in markets.docs) {
      final m = market.data();
      final ownerId = (m['ownerId'] ?? '').toString();
      if (ownerId.isEmpty) continue;
      final creditLimit = (m['creditLimit'] ?? -50).toDouble();
      final user = await _firestore.collection('users').doc(ownerId).get();
      final balance = (user.data()?['walletBalance'] ?? 0).toDouble();
      if (balance <= creditLimit + 10) count++;
    }
    return count;
  }

  Future<int> getNegativeBalanceStoresCount() async {
    final markets = await _firestore.collection('markets').get();
    int count = 0;
    for (final market in markets.docs) {
      final ownerId = (market.data()['ownerId'] ?? '').toString();
      if (ownerId.isEmpty) continue;
      final user = await _firestore.collection('users').doc(ownerId).get();
      final balance = (user.data()?['walletBalance'] ?? 0).toDouble();
      if (balance < 0) count++;
    }
    return count;
  }

  Future<String?> getOwnerIdForStore(String storeId) async {
    final doc = await _firestore.collection('markets').doc(storeId).get();
    return doc.data()?['ownerId']?.toString();
  }

  void debugLog(String message) {
    debugPrint('[CommissionAdminService] $message');
  }
}
