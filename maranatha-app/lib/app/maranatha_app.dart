import 'package:flutter/material.dart';

import '../core/navigation/maranatha_navigation.dart';
import '../core/theme/app_theme.dart';
import '../features/admin/pages/admin_page.dart';
import '../features/live/widgets/maranatha_live_setup_gate.dart';
import '../features/library/pages/library_page.dart';
import '../features/splash/pages/splash_page.dart';

class MaranathaApp extends StatelessWidget {
  const MaranathaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: maranathaNavigatorKey,
      routes: <String, WidgetBuilder>{'/admin': (_) => const AdminPage()},
      onGenerateRoute: (settings) {
        final raw =
            settings.name ?? '';

        final uri =
            Uri.tryParse(raw);

        if (
          uri != null &&
          uri.pathSegments.length >= 2 &&
          uri.pathSegments.first ==
              'livre'
        ) {
          final id =
              Uri.decodeComponent(
            uri.pathSegments[1],
          );

          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) =>
                LibraryPage(
              initialSection: 'book',
              focusId: id,
            ),
          );
        }

        return null;
      },
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
