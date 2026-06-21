import 'package:cloud_firestore/cloud_firestore.dart';

class WalletLedgerModel {
  final String id;
  final String storeId;
  final String userId;
  final String type;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String? referenceId;
  final String? referenceType;
  final String description;
  final DateTime? createdAt;
  final Map<String, dynamic>? metadata;

  const WalletLedgerModel({
    required this.id,
    required this.storeId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.referenceId,
    this.referenceType,
    required this.description,
    this.createdAt,
    this.metadata,
  });

  factory WalletLedgerModel.fromDocument(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return WalletLedgerModel(
      id: doc.id,
      storeId: data['storeId']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      type: data['type']?.toString() ?? 'unknown',
      amount: (data['amount'] ?? 0).toDouble(),
      balanceBefore: (data['balanceBefore'] ?? 0).toDouble(),
      balanceAfter: (data['balanceAfter'] ?? 0).toDouble(),
      referenceId: data['referenceId']?.toString(),
      referenceType: data['referenceType']?.toString(),
      description: data['description']?.toString() ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }
}
