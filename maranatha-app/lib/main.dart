import 'package:flutter/material.dart';
import 'welcome_screen.dart'; // Importation de notre écran

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maranatha Ministry',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // On définit l'écran de bienvenue comme écran de démarrage
      home: const WelcomeScreen(), 
    );
  }
}