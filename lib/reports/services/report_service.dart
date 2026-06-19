import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_report.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Watch pending reports in real-time
  Stream<List<UserReport>> watchPendingReports() {
    try {
      return _firestore
          .collection('user_reports')
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snapshot) {
        final reports = snapshot.docs
            .map((doc) {
              try {
                return UserReport.fromFirestore(doc);
              } catch (e) {
                print('Error parsing report ${doc.id}: $e');
                return null;
              }
            })
            .where((report) => report != null)
            .cast<UserReport>()
            .toList();
        
        // Sort locally instead of using orderBy (to avoid composite index)
        reports.sort((a, b) {
          final aTime = a.createdAt;
          final bTime = b.createdAt;
          return bTime.compareTo(aTime);
        });
        return reports;
      });
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لعرض البلاغات');
      }
      print('Error in watchPendingReports: $e');
      rethrow;
    }
  }

  /// Get all reports for a specific target
  Future<List<UserReport>> getReportsByTarget(String targetId) async {
    try {
      final snapshot = await _firestore
          .collection('user_reports')
          .where('targetId', isEqualTo: targetId)
          .get()
          .timeout(const Duration(seconds: 30));

      final reports = snapshot.docs
          .map((doc) => UserReport.fromFirestore(doc))
          .toList();
      
      // Sort locally instead of using orderBy (to avoid composite index)
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return reports;
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لعرض البلاغات');
      } else if (e.toString().contains('timeout')) {
        throw Exception('انتهت مهلة الاتصال، حاول مرة أخرى');
      }
      rethrow;
    }
  }

  /// Resolve a report
  Future<void> resolveReport({
    required String reportId,
    required String adminId,
    required String resolution,
  }) async {
    try {
      // Validate resolution text
      if (resolution.trim().length < 10) {
        throw Exception('يجب أن يكون نص الحل 10 أحرف على الأقل');
      }

      await _firestore
          .collection('user_reports')
          .doc(reportId)
          .update({
            'status': 'resolved',
            'resolvedAt': FieldValue.serverTimestamp(),
            'resolvedBy': adminId,
            'resolution': resolution.trim(),
          })
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لحل البلاغ');
      } else if (e.toString().contains('not-found')) {
        throw Exception('البلاغ غير موجود');
      } else if (e.toString().contains('timeout')) {
        throw Exception('انتهت مهلة الاتصال، حاول مرة أخرى');
      }
      rethrow;
    }
  }

  /// Dismiss a report
  Future<void> dismissReport({
    required String reportId,
    required String adminId,
    required String reason,
  }) async {
    try {
      await _firestore
          .collection('user_reports')
          .doc(reportId)
          .update({
            'status': 'dismissed',
            'resolvedAt': FieldValue.serverTimestamp(),
            'resolvedBy': adminId,
            'resolution': reason.trim(),
          })
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لرفض البلاغ');
      } else if (e.toString().contains('not-found')) {
        throw Exception('البلاغ غير موجود');
      } else if (e.toString().contains('timeout')) {
        throw Exception('انتهت مهلة الاتصال، حاول مرة أخرى');
      }
      rethrow;
    }
  }

  /// Get report count for a specific target
  Future<int> getReportCountForTarget(String targetId) async {
    try {
      final snapshot = await _firestore
          .collection('user_reports')
          .where('targetId', isEqualTo: targetId)
          .count()
          .get()
          .timeout(const Duration(seconds: 30));

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting report count: $e');
      return 0;
    }
  }

  /// Watch all reports (for admin dashboard)
  Stream<List<UserReport>> watchAllReports() {
    try {
      return _firestore
          .collection('user_reports')
          .limit(100)
          .snapshots()
          .map((snapshot) {
        final reports = snapshot.docs
            .map((doc) {
              try {
                return UserReport.fromFirestore(doc);
              } catch (e) {
                print('Error parsing report ${doc.id}: $e');
                return null;
              }
            })
            .where((report) => report != null)
            .cast<UserReport>()
            .toList();
        
        // Sort locally instead of using orderBy (to avoid index requirement)
        reports.sort((a, b) {
          final aTime = a.createdAt;
          final bTime = b.createdAt;
          return bTime.compareTo(aTime);
        });
        return reports;
      });
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لعرض البلاغات');
      }
      print('Error in watchAllReports: $e');
      rethrow;
    }
  }

  /// Watch reports for a specific target in real-time
  Stream<List<UserReport>> watchReportsForTarget(String targetId) {
    try {
      return _firestore
          .collection('user_reports')
          .where('targetId', isEqualTo: targetId)
          .snapshots()
          .map((snapshot) {
        final reports = snapshot.docs
            .map((doc) => UserReport.fromFirestore(doc))
            .toList();
        // Sort locally instead of using orderBy (to avoid composite index)
        reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return reports;
      });
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لعرض البلاغات');
      }
      rethrow;
    }
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
