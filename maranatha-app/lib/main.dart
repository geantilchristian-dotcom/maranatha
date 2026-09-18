import 'dart:async';

import 'package:flutter/material.dart';

import 'services/notification_service.dart';

import 'screens/offline_shell_screen.dart';
import 'screens/web_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService.instance.installerCallback();
  runApp(const MaranathaApp());
  unawaited(NotificationService.instance.initialiser());
}

class MaranathaApp extends StatefulWidget {
  const MaranathaApp({super.key});

  @override
  State<MaranathaApp> createState() => _MaranathaAppState();
}

class _MaranathaAppState extends State<MaranathaApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<String>? _publicationSubscription;

  @override
  void initState() {
    super.initState();
    _publicationSubscription =
        NotificationService.instance.publicationChanges.listen((path) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _navigatorKey.currentState?.push(
          MaterialPageRoute<void>(
            builder: (_) => WebScreen(initialPath: path),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _publicationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Maranatha',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC0001A),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F3F8),
        useMaterial3: true,
      ),
      home: const OfflineShellScreen(),
    );
  }
}
