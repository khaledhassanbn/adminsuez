import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../model/userModel.dart';

class AuthService {
  static const String _iosGoogleClientId =
      '681758766010-8hguil2cbb7an3mr70q161f56vr6v4kn.apps.googleusercontent.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ====== تسجيل الدخول بجوجل ======
  Future<UserModel?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final GoogleAuthProvider provider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        final googleSignIn = GoogleSignIn(
          clientId: defaultTargetPlatform == TargetPlatform.iOS
              ? _iosGoogleClientId
              : null,
        );

        // تأكد من فصل أي جلسة سابقة حتى يَطلب التطبيق اختيار البريد في كل مرة
        try {
          await googleSignIn.signOut();
          await googleSignIn.disconnect();
        } catch (_) {
          // تجاهل الأخطاء في حالة عدم وجود جلسة سابقة
        }

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          throw Exception("تم إلغاء تسجيل الدخول");
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user == null) return null;

      final doc = await _firestore.collection("users").doc(user.uid).get();

      if (!doc.exists) {
        final displayName = user.displayName ?? "";
        final parts = displayName.split(" ");
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? "",
          firstName: parts.isNotEmpty ? parts.first : "",
          lastName: parts.length > 1 ? parts.last : "",
        );

        await _firestore
            .collection("users")
            .doc(user.uid)
            .set(userModel.toJson());

        return userModel;
      }

      return UserModel.fromJson(doc.data()!);
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Google sign-in failed: code=${e.code}, message=${e.message ?? ''}',
      );
      if (e.code == 'sign_in_canceled') {
        throw Exception("تم إلغاء تسجيل الدخول");
      }
      throw Exception("فشل تسجيل الدخول بجوجل: ${e.code}");
    } catch (e) {
      if (e.toString().contains("تم إلغاء تسجيل الدخول")) {
        rethrow;
      }
      throw Exception("فشل تسجيل الدخول بجوجل: $e");
    }
  }

  /// التحقق من أن المستخدم admin
  Future<bool> isUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data()?['status'] == 'admin';
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ Error checking admin status: $e');
      return false;
    }
  }

  // ====== تسجيل الخروج ======
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb) {
        final googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      }
    } catch (e) {
      throw Exception("فشل تسجيل الخروج: $e");
    }
  }

  // ====== المستخدم الحالي ======
  User? get currentUser => _auth.currentUser;
}
