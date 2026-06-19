import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'connection_service.dart';
import 'no_internet_page.dart';

/// Widget يلف التطبيق ويعرض صفحة no_internet عند انقطاع الاتصال
class ConnectivityWrapper extends StatelessWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionService>(
      builder: (context, connectionService, _) {
        if (!connectionService.isConnected) {
          return NoInternetPage(
            onRetry: () async {
              await connectionService.initialize();
            },
          );
        }
        return child;
      },
    );
  }
}
