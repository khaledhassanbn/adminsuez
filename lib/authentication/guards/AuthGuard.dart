import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// AuthGuard كلاس لإدارة حالة تسجيل الدخول وحالة المستخدم
class AuthGuard extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _statusSubscription;

  /// Flag to track if this ChangeNotifier has been disposed
  bool _isDisposed = false;

  /// Safe wrapper for notifyListeners that checks disposal state
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  AuthGuard() {
    _authSubscription = _auth.authStateChanges().listen((user) async {
      _statusSubscription?.cancel();
      _statusSubscription = null;

      if (user == null) {
        userStatus = null;
        _safeNotifyListeners();
        return;
      }

      await loadUserStatus();
      _startStatusListener(user.uid);
    });
  }

  User? get currentUser => _auth.currentUser;
  String? userStatus; // user | admin | market_owner

  /// ✅ هل المستخدم داخل التطبيق؟
  bool get isAuthenticated => currentUser != null;

  /// ✅ هل المستخدم أدمن؟
  bool get isAdmin => userStatus == 'admin';

  /// ✅ هل المستخدم صاحب متجر؟
  bool get isMarketOwner => userStatus == 'market_owner';

  /// 🔹 تحميل حالة المستخدم عند التشغيل
  Future<void> loadUserStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      userStatus = null;
      debugPrint('👤 No user logged in');
      return;
    }

    try {
      debugPrint('👤 Loading status for user: ${user.uid}');
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        userStatus = data?['status'] ?? 'user';
        debugPrint('✅ User status loaded: $userStatus');
      } else {
        userStatus = 'user';
        debugPrint('⚠️ User document not found, defaulting to user');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading user status: $e');
      userStatus = 'user';
    }

    _safeNotifyListeners();
  }

  /// 🔹 متابعة التغييرات في حالة المستخدم من Firestore لحظيًا
  void startStatusListener() {
    final user = _auth.currentUser;
    if (user == null) return;
    _startStatusListener(user.uid);
  }

  void _startStatusListener(String uid) {
    _statusSubscription?.cancel();
    _statusSubscription = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data();
            final newStatus = data?['status'] ?? 'user';

            if (newStatus != userStatus) {
              userStatus = newStatus;
              debugPrint('🔄 User status updated: $userStatus');
              _safeNotifyListeners();
            }
          }
        });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }
}
