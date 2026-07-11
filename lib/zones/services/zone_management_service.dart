import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class ZoneValidationResult {
  final bool isValid;
  final List<String> errors;
  final int? version;
  final int zoneCount;
  final List<String> zoneNames;
  final int fileSizeBytes;

  const ZoneValidationResult({
    required this.isValid,
    required this.errors,
    this.version,
    this.zoneCount = 0,
    this.zoneNames = const [],
    this.fileSizeBytes = 0,
  });
}

class ZoneConfig {
  final int currentZonesVersion;
  final String fileName;
  final String zonesStoragePath;
  final DateTime? updatedAt;

  const ZoneConfig({
    required this.currentZonesVersion,
    required this.fileName,
    required this.zonesStoragePath,
    this.updatedAt,
  });

  factory ZoneConfig.fromMap(Map<String, dynamic> data) {
    return ZoneConfig(
      currentZonesVersion: (data['currentZonesVersion'] as num?)?.toInt() ?? 0,
      fileName: data['zonesFileName'] as String? ?? '',
      zonesStoragePath: data['zonesStoragePath'] as String? ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class ZoneManagementService {
  static const _configDocPath = 'system/config';
  static const _storageFolder = 'system/zones';

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ZoneManagementService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  Future<ZoneConfig?> getCurrentConfig() async {
    final doc = await _firestore.doc(_configDocPath).get();
    if (!doc.exists || doc.data() == null) return null;
    return ZoneConfig.fromMap(doc.data()!);
  }

  ZoneValidationResult validateZoneFile({
    required String fileName,
    required List<int> bytes,
    int? currentVersion,
  }) {
    final errors = <String>[];
    final fileSizeBytes = bytes.length;

    final versionMatch = RegExp(
      r'^zones_v(\d+)\.json$',
      caseSensitive: false,
    ).firstMatch(fileName);
    if (versionMatch == null) {
      errors.add('اسم الملف يجب أن يكون بصيغة zones_vX.json');
    }

    final fileVersion = versionMatch != null
        ? int.tryParse(versionMatch.group(1)!)
        : null;

    Map<String, dynamic>? data;
    try {
      data = json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (_) {
      errors.add('الملف ليس JSON صالحاً');
      return ZoneValidationResult(
        isValid: false,
        errors: errors,
        fileSizeBytes: fileSizeBytes,
      );
    }

    final jsonVersion = (data['version'] as num?)?.toInt();
    if (jsonVersion == null) {
      errors.add('الحقل version مفقود داخل الملف');
    } else if (fileVersion != null && jsonVersion != fileVersion) {
      errors.add(
        'رقم الإصدار داخل الملف ($jsonVersion) لا يطابق اسم الملف ($fileVersion)',
      );
    }

    if (currentVersion != null &&
        fileVersion != null &&
        fileVersion <= currentVersion) {
      errors.add(
        'النسخة الجديدة ($fileVersion) يجب أن تكون أكبر من الحالية ($currentVersion)',
      );
    }

    final zones = data['zones'];
    if (zones is! List || zones.isEmpty) {
      errors.add('قائمة zones مفقودة أو فارغة');
      return ZoneValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        version: jsonVersion,
        fileSizeBytes: fileSizeBytes,
      );
    }

    final ids = <String>{};
    final names = <String>{};
    final zoneNames = <String>[];

    for (var i = 0; i < zones.length; i++) {
      final zone = zones[i];
      if (zone is! Map) {
        errors.add('المنطقة رقم ${i + 1} غير صالحة');
        continue;
      }

      final map = Map<String, dynamic>.from(zone);
      final id = map['id'] as String?;
      final name = map['name'] as String?;
      final center = map['center'];
      final radius = map['radius'];

      if (id == null || id.isEmpty) {
        errors.add('المنطقة رقم ${i + 1}: id مفقود');
      } else if (!ids.add(id)) {
        errors.add('معرّف مكرر: $id');
      }

      if (name == null || name.isEmpty) {
        errors.add('المنطقة رقم ${i + 1}: name مفقود');
      } else {
        zoneNames.add(name);
        if (!names.add(name)) {
          errors.add('اسم منطقة مكرر: $name');
        }
      }

      if (center is! Map || center['lat'] == null || center['lng'] == null) {
        errors.add('المنطقة "${name ?? i + 1}": center.lat/lng مفقود');
      }

      if (radius == null || (radius as num) <= 0) {
        errors.add('المنطقة "${name ?? i + 1}": radius غير صالح');
      }
    }

    return ZoneValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      version: jsonVersion ?? fileVersion,
      zoneCount: zones.length,
      zoneNames: zoneNames,
      fileSizeBytes: fileSizeBytes,
    );
  }

  Future<void> uploadZoneFile({
    required String fileName,
    required List<int> bytes,
    required int version,
  }) async {
    final storagePath = '$_storageFolder/$fileName';
    final ref = _storage.ref(storagePath);

    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: 'application/json'),
    );

    await _firestore.doc(_configDocPath).set({
      'currentZonesVersion': version,
      'zonesFileName': fileName,
      'zonesStoragePath': storagePath,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<({String fileName, List<int> bytes})?> pickZoneFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    if (file.bytes == null || file.name.isEmpty) return null;

    return (fileName: file.name, bytes: file.bytes!);
  }
}
