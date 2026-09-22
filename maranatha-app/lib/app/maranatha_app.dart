import 'package:flutter/material.dart';

import '../core/navigation/maranatha_navigation.dart';
import '../core/theme/app_theme.dart';
import '../features/admin/pages/admin_page.dart';
import '../features/live/widgets/maranatha_live_setup_gate.dart';
import '../features/splash/pages/splash_page.dart';

class MaranathaApp extends StatelessWidget {
  const MaranathaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: maranathaNavigatorKey,
      routes: <String, WidgetBuilder>{'/admin': (_) => const AdminPage()},
      title: 'MARANATHA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashPage(),
      builder: (context, child) {
        return MaranathaLiveSetupGate(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
