import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'screens/web_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Lancer les permissions système en arrière-plan (ne bloque PAS runApp).
  // requestExactAlarmsPermission / requestFullScreenIntentPermission ouvrent
  // des écrans système Android et n'ont pas besoin d'être awaités au démarrage.
  NotificationService.instance.initialiser().catchError((_) {});
  runApp(const MaranathaApp());
}

class MaranathaApp extends StatelessWidget {
  const MaranathaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maranatha',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5C5CFF)),
        useMaterial3: true,
      ),
      home: const WebScreen(),
    );
  }
}
