import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/independent_courier_settings.dart';

class IndependentCourierSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  IndependentCourierSettings? _cachedSettings;
  DateTime? _cacheTime;
  static const _cacheValidityMinutes = 5;

  static const String _settingsPath = 'settings';
  static const String _settingsDoc = 'independent_courier';

  Future<IndependentCourierSettings> getSettings({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedSettings != null && _cacheTime != null) {
      final cacheAge = DateTime.now().difference(_cacheTime!);
      if (cacheAge.inMinutes < _cacheValidityMinutes) {
        return _cachedSettings!;
      }
    }

    try {
      final doc = await _firestore
          .collection(_settingsPath)
          .doc(_settingsDoc)
          .get();

      if (doc.exists && doc.data() != null) {
        _cachedSettings = IndependentCourierSettings.fromMap(doc.data()!);
      } else {
        _cachedSettings = IndependentCourierSettings.defaults();
      }
      _cacheTime = DateTime.now();
      return _cachedSettings!;
    } catch (e) {
      return IndependentCourierSettings.defaults();
    }
  }

  Future<bool> updateSettings(IndependentCourierSettings settings) async {
    try {
      await _firestore.collection(_settingsPath).doc(_settingsDoc).set(
            settings.toMap(updatedBy: _auth.currentUser?.uid),
          );
      _cachedSettings = settings;
      _cacheTime = DateTime.now();
      return true;
    } catch (e) {
      return false;
    }
  }
}
