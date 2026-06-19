import 'package:flutter/material.dart';
import '../model/userModel.dart';
import '../service/service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? currentUser;
  bool isLoading = false;
  String? errorMessage;

  // ====== Sign In بجوجل ======
  Future<UserModel?> signInWithGoogle() async {
    _setLoading(true);
    errorMessage = null;
    try {
      currentUser = await _authService.signInWithGoogle();

      // التحقق من أن المستخدم admin
      if (currentUser != null) {
        final isAdmin = await _authService.isUserAdmin();
        if (!isAdmin) {
          // إذا لم يكن admin، نسجل خروجه ونعرض رسالة
          await _authService.signOut();
          currentUser = null;
          errorMessage = 'غير مصرح لك بالدخول. هذا التطبيق مخصص للمسؤولين فقط.';
          return null;
        }
      }

      return currentUser;
    } catch (e) {
      errorMessage = _handleError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ====== Sign Out ======
  Future<void> signOut() async {
    await _authService.signOut();
    currentUser = null;
    notifyListeners();
  }

  // ====== Helpers ======
  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  String _handleError(String error) {
    if (error.contains("تم إلغاء تسجيل الدخول")) {
      return "تم إلغاء تسجيل الدخول";
    } else if (error.contains("غير مصرح")) {
      return "غير مصرح لك بالدخول. هذا التطبيق مخصص للمسؤولين فقط.";
    } else {
      return "حدث خطأ غير متوقع";
    }
  }
}
