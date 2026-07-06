import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String id;
  final String name;
  final String? phone;
  final bool isActive;
  final DateTime? licenseStartAt;
  final DateTime? licenseEndAt;
  final int? totalProducts;
  final Map<String, dynamic>? userData;
  final double commissionRate;
  final String commissionType;
  final double creditLimit;
  final double totalCommissionsPaid;
  final DateTime? lastCommissionAt;
  final double? walletBalance;
  final bool? independentCourierEnabled;

  StoreModel({
    required this.id,
    required this.name,
    this.phone,
    required this.isActive,
    this.licenseStartAt,
    this.licenseEndAt,
    this.totalProducts,
    this.userData,
    this.commissionRate = 5.0,
    this.commissionType = 'fixed',
    this.creditLimit = -50.0,
    this.totalCommissionsPaid = 0.0,
    this.lastCommissionAt,
    this.walletBalance,
    this.independentCourierEnabled,
  });

  factory StoreModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    DateTime? readDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    return StoreModel(
      id: doc.id,
      name: data['name']?.toString() ?? 'بدون اسم',
      phone: data['phone']?.toString(),
      isActive: data['isActive'] == true,
      licenseStartAt: readDate(data['licenseStartAt']),
      licenseEndAt: readDate(data['licenseEndAt']),
      totalProducts: data['totalProducts'] as int?,
      commissionRate: (data['commissionRate'] ?? 5.0).toDouble(),
      commissionType: data['commissionType']?.toString() ?? 'fixed',
      creditLimit: (data['creditLimit'] ?? -50.0).toDouble(),
      totalCommissionsPaid: (data['totalCommissionsPaid'] ?? 0.0).toDouble(),
      lastCommissionAt: readDate(data['lastCommissionAt']),
      independentCourierEnabled: data.containsKey('independentCourierEnabled')
          ? data['independentCourierEnabled'] == true
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'isActive': isActive,
      'licenseStartAt': licenseStartAt != null ? Timestamp.fromDate(licenseStartAt!) : null,
      'licenseEndAt': licenseEndAt != null ? Timestamp.fromDate(licenseEndAt!) : null,
      'totalProducts': totalProducts,
      'commissionRate': commissionRate,
      'commissionType': commissionType,
      'creditLimit': creditLimit,
      'totalCommissionsPaid': totalCommissionsPaid,
      'lastCommissionAt': lastCommissionAt != null
          ? Timestamp.fromDate(lastCommissionAt!)
          : null,
    };
  }

  StoreModel copyWith({
    String? id,
    String? name,
    String? phone,
    bool? isActive,
    DateTime? licenseStartAt,
    DateTime? licenseEndAt,
    int? totalProducts,
    Map<String, dynamic>? userData,
    double? commissionRate,
    String? commissionType,
    double? creditLimit,
    double? totalCommissionsPaid,
    DateTime? lastCommissionAt,
    double? walletBalance,
    bool? independentCourierEnabled,
    bool clearIndependentCourierEnabled = false,
  }) {
    return StoreModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      licenseStartAt: licenseStartAt ?? this.licenseStartAt,
      licenseEndAt: licenseEndAt ?? this.licenseEndAt,
      totalProducts: totalProducts ?? this.totalProducts,
      userData: userData ?? this.userData,
      commissionRate: commissionRate ?? this.commissionRate,
      commissionType: commissionType ?? this.commissionType,
      creditLimit: creditLimit ?? this.creditLimit,
      totalCommissionsPaid: totalCommissionsPaid ?? this.totalCommissionsPaid,
      lastCommissionAt: lastCommissionAt ?? this.lastCommissionAt,
      walletBalance: walletBalance ?? this.walletBalance,
      independentCourierEnabled: clearIndependentCourierEnabled
          ? null
          : (independentCourierEnabled ?? this.independentCourierEnabled),
    );
  }

  // حساب الأيام المتبقية
  int get daysRemaining {
    if (licenseEndAt == null) return 0;
    final now = DateTime.now();
    if (licenseEndAt!.isAfter(now)) {
      return licenseEndAt!.difference(now).inDays;
    }
    return 0;
  }

  // الحصول على اسم المستخدم
  String get userName {
    if (userData == null) return 'غير محدد';
    if (userData!['firstName'] != null && userData!['lastName'] != null) {
      return '${userData!['firstName']} ${userData!['lastName']}';
    }
    return userData!['email']?.toString() ?? 'غير محدد';
  }
}
