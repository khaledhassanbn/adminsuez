import 'package:suez_admin/core/network/connection_service.dart';
import 'package:suez_admin/core/network/connectivity_wrapper.dart';
import 'package:suez_admin/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';

// 🧩 Firebase
import 'firebase_options.dart';

// 🧠 Auth
import 'authentication/guards/AuthGuard.dart';
import 'authentication/viewModel/AuthViewModel.dart';
import 'support/viewmodels/admin_support_viewmodel.dart';

// 🔔 إشعارات وإعلانات
import 'notifications/viewmodels/announcement_viewmodel.dart';
import 'promotional_popups/viewmodels/promotional_popup_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    print('🚀 Starting Suez Admin app...');
    runApp(const SuezAdminApp());
  } catch (e) {
    print('❌ Error during initialization: $e');
    runApp(const SuezAdminApp());
  }
}

class SuezAdminApp extends StatefulWidget {
  const SuezAdminApp({super.key});

  @override
  State<SuezAdminApp> createState() => _SuezAdminAppState();
}

class _SuezAdminAppState extends State<SuezAdminApp> {
  late final AuthGuard _authGuard;
  late final ConnectionService _connectionService;
  late Future<GoRouter> _routerFuture;

  @override
  void initState() {
    super.initState();
    _authGuard = AuthGuard();
    _connectionService = ConnectionService();
    _connectionService.initialize();
    _routerFuture = createRouter(_authGuard);
  }

  @override
  void dispose() {
    _connectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => _authGuard),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => AdminSupportViewModel()),
        ChangeNotifierProvider(create: (_) => AnnouncementViewModel()),
        ChangeNotifierProvider(create: (_) => PromotionalPopupViewModel()),
        ChangeNotifierProvider<ConnectionService>.value(
          value: _connectionService,
        ),
      ],
      child: FutureBuilder<GoRouter>(
        future: _routerFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4E99B4),
                  ),
                ),
              ),
            );
          }

          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'لوحة إدارة بازار السويس',
            locale: const Locale("ar"),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale("ar"), Locale("en")],
            routerConfig: snapshot.data!,
            builder: (context, child) =>
                ConnectivityWrapper(child: child ?? const SizedBox.shrink()),
            theme: ThemeData(
              fontFamily: "Tajawal",
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF4E99B4),
              ),
              textTheme: const TextTheme(
                bodyMedium: TextStyle(fontSize: 16, fontFamily: "Tajawal"),
                bodyLarge: TextStyle(fontSize: 18, fontFamily: "Tajawal"),
                headlineSmall: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Tajawal",
                ),
                headlineMedium: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Tajawal",
                ),
                titleLarge: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Tajawal",
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
