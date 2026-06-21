import 'package:cloud_firestore/cloud_firestore.dart';

class WalletTransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String status;
  final String? imageUrl;
  final String? adminId;
  final String? rejectReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WalletTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    this.imageUrl,
    this.adminId,
    this.rejectReason,
    this.createdAt,
    this.updatedAt,
  });

  factory WalletTransactionModel.fromDocument(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return WalletTransactionModel(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      status: data['status']?.toString() ?? 'pending',
      imageUrl: data['imageUrl']?.toString(),
      adminId: data['adminId']?.toString(),
      rejectReason: data['rejectReason']?.toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
