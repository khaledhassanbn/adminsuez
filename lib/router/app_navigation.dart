import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// مفتاح [Navigator] الجذر — يُمرَّر لـ [GoRouter]
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter? _appRouter;

/// تسجيل الـ [GoRouter] بعد إنشائه (يُستدعى مرة من [createRouter]).
void registerAppRouter(GoRouter router) {
  _appRouter = router;
}

/// الحصول على الـ router الحالي
GoRouter? get appRouter => _appRouter;
