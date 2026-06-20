import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ConversationStatus {
  open,        // مفتوحة
  inProgress,  // جارى المتابعة
  resolved,    // تم الحل
  closed,      // مغلقة
}

enum ConversationPriority {
  low,
  medium,
  high,
}

class SupportConversation {
  final String id;
  final String userId;
  final String userName;
  final String userType; // customer | merchant | craftsman | driver
  final String issueType; // store_issue | craftsman_issue | driver_issue | customer_issue | app_issue | general_inquiry
  final String? relatedMerchantId;
  final String? relatedMerchantName;
  final String? relatedCraftsmanId;
  final String? relatedCraftsmanName;
  final String? relatedDriverId;
  final String? relatedDriverName;
  final String? relatedCustomerId;
  final String? relatedCustomerName;
  final String? relatedOrderId;
  final ConversationStatus status;
  final ConversationPriority priority;
  final String? source; // customer_app | merchant_app | craftsman_app | driver_app
  final String lastMessage;
  final int unreadAdminCount;
  final int unreadUserCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportConversation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userType,
    required this.issueType,
    this.relatedMerchantId,
    this.relatedMerchantName,
    this.relatedCraftsmanId,
    this.relatedCraftsmanName,
    this.relatedDriverId,
    this.relatedDriverName,
    this.relatedCustomerId,
    this.relatedCustomerName,
    this.relatedOrderId,
    required this.status,
    required this.priority,
    this.source,
    required this.lastMessage,
    required this.unreadAdminCount,
    required this.unreadUserCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// نوع المستخدم بالعربية
  String get userTypeDisplayName {
    switch (userType.toLowerCase()) {
      case 'customer':
        return 'عميل';
      case 'merchant':
        return 'تاجر';
      case 'craftsman':
        return 'صنايعي';
      case 'driver':
        return 'مندوب';
      default:
        return userType;
    }
  }

  /// مصدر المحادثة بالعربية
  String get sourceDisplayName {
    if (source == null) return 'غير محدد';
    switch (source) {
      case 'customer_app':
        return 'تطبيق العملاء';
      case 'merchant_app':
        return 'تطبيق التجار';
      case 'craftsman_app':
        return 'تطبيق الصنايعية';
      case 'driver_app':
        return 'تطبيق المناديب';
      default:
        return source!;
    }
  }

  /// نوع المشكلة بالعربية
  String get issueTypeDisplayName {
    final sanitized = issueType.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), '_').toLowerCase();
    switch (sanitized) {
      case 'store_issue':
      case 'storeissue':
        return 'مشكلة بمتجر';
      case 'craftsman_issue':
      case 'craftsmanissue':
        return 'مشكلة بصنايعي';
      case 'driver_issue':
      case 'driverissue':
        return 'مشكلة بمندوب';
      case 'customer_issue':
      case 'customerissue':
        return 'مشكلة بعميل';
      case 'app_issue':
      case 'appissue':
        return 'مشكلة بالتطبيق';
      case 'general_inquiry':
      case 'generalinquiry':
        return 'استفسار عام';
      default:
        return issueType;
    }
  }

  /// حالة المحادثة بالعربية
  String get statusDisplayName {
    switch (status) {
      case ConversationStatus.open:
        return 'مفتوحة';
      case ConversationStatus.inProgress:
        return 'جارى المتابعة';
      case ConversationStatus.resolved:
        return 'تم الحل';
      case ConversationStatus.closed:
        return 'مغلقة';
    }
  }

  /// لون حالة المحادثة
  Color get statusColor {
    switch (status) {
      case ConversationStatus.open:
        return Colors.blue;
      case ConversationStatus.inProgress:
        return Colors.orange;
      case ConversationStatus.resolved:
        return Colors.green;
      case ConversationStatus.closed:
        return Colors.grey;
    }
  }

  /// الأولوية بالعربية
  String get priorityDisplayName {
    switch (priority) {
      case ConversationPriority.low:
        return 'منخفضة';
      case ConversationPriority.medium:
        return 'متوسطة';
      case ConversationPriority.high:
        return 'عالية';
    }
  }

  /// لون الأولوية
  Color get priorityColor {
    switch (priority) {
      case ConversationPriority.low:
        return Colors.green;
      case ConversationPriority.medium:
        return Colors.orange;
      case ConversationPriority.high:
        return Colors.red;
    }
  }

  /// هل يوجد كيان مرتبط
  bool get hasRelatedEntity =>
      (relatedMerchantId != null && relatedMerchantId!.isNotEmpty) ||
      (relatedCraftsmanId != null && relatedCraftsmanId!.isNotEmpty) ||
      (relatedDriverId != null && relatedDriverId!.isNotEmpty) ||
      (relatedCustomerId != null && relatedCustomerId!.isNotEmpty) ||
      (relatedOrderId != null && relatedOrderId!.isNotEmpty);

  /// اسم الكيان المرتبط
  String get relatedEntityName {
    if (relatedMerchantName != null && relatedMerchantName!.isNotEmpty) {
      return 'متجر: $relatedMerchantName';
    }
    if (relatedCraftsmanName != null && relatedCraftsmanName!.isNotEmpty) {
      return 'صنايعي: $relatedCraftsmanName';
    }
    if (relatedDriverName != null && relatedDriverName!.isNotEmpty) {
      return 'مندوب: $relatedDriverName';
    }
    if (relatedCustomerName != null && relatedCustomerName!.isNotEmpty) {
      return 'عميل: $relatedCustomerName';
    }
    if (relatedOrderId != null && relatedOrderId!.isNotEmpty) {
      return 'طلب رقم: $relatedOrderId';
    }
    return '';
  }

  factory SupportConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Parse status safely from snake_case
    final statusStr = (data['status'] ?? 'open').toString().toLowerCase();
    ConversationStatus parsedStatus;
    if (statusStr == 'in_progress' || statusStr == 'inprogress') {
      parsedStatus = ConversationStatus.inProgress;
    } else if (statusStr == 'resolved') {
      parsedStatus = ConversationStatus.resolved;
    } else if (statusStr == 'closed') {
      parsedStatus = ConversationStatus.closed;
    } else {
      parsedStatus = ConversationStatus.open;
    }

    // Parse priority safely
    final priorityStr = (data['priority'] ?? 'medium').toString().toLowerCase();
    ConversationPriority parsedPriority;
    if (priorityStr == 'low') {
      parsedPriority = ConversationPriority.low;
    } else if (priorityStr == 'high') {
      parsedPriority = ConversationPriority.high;
    } else {
      parsedPriority = ConversationPriority.medium;
    }

    final createdAtTimestamp = data['createdAt'] as Timestamp?;
    final updatedAtTimestamp = data['updatedAt'] as Timestamp?;

    return SupportConversation(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? '',
      userType: data['userType']?.toString() ?? 'customer',
      issueType: data['issueType']?.toString() ?? 'general_inquiry',
      relatedMerchantId: data['relatedMerchantId']?.toString(),
      relatedMerchantName: data['relatedMerchantName']?.toString(),
      relatedCraftsmanId: data['relatedCraftsmanId']?.toString(),
      relatedCraftsmanName: data['relatedCraftsmanName']?.toString(),
      relatedDriverId: data['relatedDriverId']?.toString(),
      relatedDriverName: data['relatedDriverName']?.toString(),
      relatedCustomerId: data['relatedCustomerId']?.toString(),
      relatedCustomerName: data['relatedCustomerName']?.toString(),
      relatedOrderId: data['relatedOrderId']?.toString(),
      status: parsedStatus,
      priority: parsedPriority,
      source: data['source']?.toString(),
      lastMessage: data['lastMessage']?.toString() ?? '',
      unreadAdminCount: (data['unreadAdminCount'] as num?)?.toInt() ?? 0,
      unreadUserCount: (data['unreadUserCount'] as num?)?.toInt() ?? 0,
      createdAt: createdAtTimestamp != null ? createdAtTimestamp.toDate() : DateTime.now(),
      updatedAt: updatedAtTimestamp != null ? updatedAtTimestamp.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    String statusStr;
    switch (status) {
      case ConversationStatus.open:
        statusStr = 'open';
        break;
      case ConversationStatus.inProgress:
        statusStr = 'in_progress';
        break;
      case ConversationStatus.resolved:
        statusStr = 'resolved';
        break;
      case ConversationStatus.closed:
        statusStr = 'closed';
        break;
    }

    String priorityStr;
    switch (priority) {
      case ConversationPriority.low:
        priorityStr = 'low';
        break;
      case ConversationPriority.medium:
        priorityStr = 'medium';
        break;
      case ConversationPriority.high:
        priorityStr = 'high';
        break;
    }

    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userType': userType,
      'issueType': issueType,
      'relatedMerchantId': relatedMerchantId ?? '',
      'relatedMerchantName': relatedMerchantName ?? '',
      'relatedCraftsmanId': relatedCraftsmanId ?? '',
      'relatedCraftsmanName': relatedCraftsmanName ?? '',
      'relatedDriverId': relatedDriverId ?? '',
      'relatedDriverName': relatedDriverName ?? '',
      'relatedCustomerId': relatedCustomerId ?? '',
      'relatedCustomerName': relatedCustomerName ?? '',
      'relatedOrderId': relatedOrderId ?? '',
      'status': statusStr,
      'priority': priorityStr,
      'source': source,
      'lastMessage': lastMessage,
      'unreadAdminCount': unreadAdminCount,
      'unreadUserCount': unreadUserCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SupportConversation copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userType,
    String? issueType,
    String? relatedMerchantId,
    String? relatedMerchantName,
    String? relatedCraftsmanId,
    String? relatedCraftsmanName,
    String? relatedDriverId,
    String? relatedDriverName,
    String? relatedCustomerId,
    String? relatedCustomerName,
    String? relatedOrderId,
    ConversationStatus? status,
    ConversationPriority? priority,
    String? source,
    String? lastMessage,
    int? unreadAdminCount,
    int? unreadUserCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupportConversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userType: userType ?? this.userType,
      issueType: issueType ?? this.issueType,
      relatedMerchantId: relatedMerchantId ?? this.relatedMerchantId,
      relatedMerchantName: relatedMerchantName ?? this.relatedMerchantName,
      relatedCraftsmanId: relatedCraftsmanId ?? this.relatedCraftsmanId,
      relatedCraftsmanName: relatedCraftsmanName ?? this.relatedCraftsmanName,
      relatedDriverId: relatedDriverId ?? this.relatedDriverId,
      relatedDriverName: relatedDriverName ?? this.relatedDriverName,
      relatedCustomerId: relatedCustomerId ?? this.relatedCustomerId,
      relatedCustomerName: relatedCustomerName ?? this.relatedCustomerName,
      relatedOrderId: relatedOrderId ?? this.relatedOrderId,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      source: source ?? this.source,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadAdminCount: unreadAdminCount ?? this.unreadAdminCount,
      unreadUserCount: unreadUserCount ?? this.unreadUserCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
