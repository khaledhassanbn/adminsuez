import 'package:cloud_firestore/cloud_firestore.dart';

class CommissionConfigModel {
  final double defaultCommissionRate;
  final String defaultCommissionType;
  final double defaultCreditLimit;
  final List<double> balanceWarningThresholds;
  final bool blockOrdersOnCreditExceeded;
  final DateTime? updatedAt;
  final String? updatedBy;

  const CommissionConfigModel({
    this.defaultCommissionRate = 5.0,
    this.defaultCommissionType = 'fixed',
    this.defaultCreditLimit = -50.0,
    this.balanceWarningThresholds = const [50, 20, 10, 0],
    this.blockOrdersOnCreditExceeded = true,
    this.updatedAt,
    this.updatedBy,
  });

  factory CommissionConfigModel.fromMap(Map<String, dynamic> map) {
    DateTime? readDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    final thresholdsRaw = map['balanceWarningThresholds'];
    final thresholds = thresholdsRaw is List
        ? thresholdsRaw.map((e) => (e as num).toDouble()).toList()
        : <double>[50, 20, 10, 0];

    return CommissionConfigModel(
      defaultCommissionRate: (map['defaultCommissionRate'] ?? 5.0).toDouble(),
      defaultCommissionType: map['defaultCommissionType'] ?? 'fixed',
      defaultCreditLimit: (map['defaultCreditLimit'] ?? -50.0).toDouble(),
      balanceWarningThresholds: thresholds,
      blockOrdersOnCreditExceeded: map['blockOrdersOnCreditExceeded'] != false,
      updatedAt: readDate(map['updatedAt']),
      updatedBy: map['updatedBy']?.toString(),
    );
  }

  factory CommissionConfigModel.fromDocument(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return CommissionConfigModel.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'defaultCommissionRate': defaultCommissionRate,
      'defaultCommissionType': defaultCommissionType,
      'defaultCreditLimit': defaultCreditLimit,
      'balanceWarningThresholds': balanceWarningThresholds,
      'blockOrdersOnCreditExceeded': blockOrdersOnCreditExceeded,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'updatedBy': updatedBy,
    };
  }
}
