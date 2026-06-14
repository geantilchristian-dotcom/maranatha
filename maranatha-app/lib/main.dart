import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'services/audio_service.dart';
import 'screens/welcome_screen.dart';
// Ce fichier est généré automatiquement par : flutterfire configure
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Initialiser le service de notifications (FCM)
  await NotificationService.instance.initialiser();

  // 3. Initialiser le lecteur audio
  await AudioService.instance.initialiser();

  runApp(const MaranathaApp());
}

class MaranathaApp extends StatelessWidget {
  const MaranathaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maranatha Ministry',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF001220),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}
