import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/intro_screen.dart';
import 'services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaranathaApp());
  unawaited(NotificationService.instance.initialiser());
}

class MaranathaApp extends StatelessWidget {
  const MaranathaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maranatha',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC0001A),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F3F8),
        useMaterial3: true,
      ),
      home: const IntroScreen(),
    );
  }
}
