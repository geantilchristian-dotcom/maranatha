import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/notification_service.dart';
import 'player_screen.dart';

// Remplacez par l'URL de votre serveur une fois déployé
// En développement local : utilisez l'IP de votre ordinateur (ex: http://192.168.1.10:5000/api)
const String API_URL = 'https://maranatha-2vgy.onrender.com/api';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isMaranathaEnabled = true;
  bool _chargement = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initialiserUtilisateur();
  }

  Future<void> _initialiserUtilisateur() async {
    final prefs = await SharedPreferences.getInstance();
    final idSauvegarde = prefs.getString('user_id');

    if (idSauvegarde != null) {
      // Utilisateur déjà enregistré — mettre à jour le token FCM
      setState(() {
        _userId = idSauvegarde;
        _isMaranathaEnabled = prefs.getBool('maranatha_actif') ?? true;
        _chargement = false;
      });
      _mettreAJourToken(idSauvegarde);
    } else {
      // Première installation — enregistrer l'utilisateur
      await _inscrireNouvelUtilisateur(prefs);
    }
  }

  Future<void> _inscrireNouvelUtilisateur(SharedPreferences prefs) async {
    try {
      final fcmToken = await NotificationService.instance.obtenirTokenFCM();
      if (fcmToken == null) {
        setState(() => _chargement = false);
        return;
      }

      final response = await http.post(
        Uri.parse('$API_URL/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom': 'Fidèle Maranatha',
          'telephone': fcmToken.substring(0, 15),
          'fcmToken': fcmToken,
          'role': 'fidele',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final userId = data['user']['_id'] as String;
        await prefs.setString('user_id', userId);
        await prefs.setBool('maranatha_actif', true);
        setState(() {
          _userId = userId;
          _chargement = false;
        });
      }
    } catch (e) {
      print('❌ Erreur inscription : $e');
    } finally {
      setState(() => _chargement = false);
    }
  }

  Future<void> _mettreAJourToken(String userId) async {
    try {
      final fcmToken = await NotificationService.instance.obtenirTokenFCM();
      if (fcmToken == null) return;
      await http.post(
        Uri.parse('$API_URL/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom': 'Fidèle Maranatha',
          'telephone': fcmToken.substring(0, 15),
          'fcmToken': fcmToken,
          'role': 'fidele',
        }),
      );
    } catch (e) {
      print('❌ Erreur mise à jour token : $e');
    }
  }

  Future<void> _basculerModeMaranatha(bool valeur) async {
    setState(() => _isMaranathaEnabled = valeur);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('maranatha_actif', valeur);

    if (_userId != null) {
      try {
        await http.patch(
          Uri.parse('$API_URL/users/$_userId/toggle-maranatha'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'modeMaranathaActif': valeur}),
        );
      } catch (e) {
        print('❌ Erreur mise à jour préférence : $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001220),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. LOGO ET TITRE
              Column(
                children: [
                  const SizedBox(height: 20),
                  const Icon(
                    Icons.local_fire_department,
                    size: 70,
                    color: Color(0xFFD4AF37),
                  ),
                  const Text(
                    'MARANATHA',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Bienvenue dans votre\nMinistère Maranatha',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Une connexion directe avec la parole de Dieu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              // 2. ENCADRÉ MODE MARANATHA
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0DF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.alarm, size: 50, color: Color(0xFF001220)),
                    const SizedBox(height: 10),
                    const Text(
                      'Activer le mode Maranatha (Alarme)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF001220),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Recevez les prédications du Pasteur en direct, même en veille. Votre téléphone se réveillera pour vous à l\'heure du prêche.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF001220).withOpacity(0.8),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Désactivé',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Transform.scale(
                          scale: 1.2,
                          child: Switch(
                            value: _isMaranathaEnabled,
                            activeColor: const Color(0xFFD4AF37),
                            activeTrackColor:
                                const Color(0xFF001220).withOpacity(0.3),
                            inactiveThumbColor: Colors.grey,
                            onChanged: _basculerModeMaranatha,
                          ),
                        ),
                        const Text(
                          'Activé',
                          style: TextStyle(
                            color: Color(0xFF001220),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. BOUTON ENTRER DANS L'APPLICATION
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _chargement
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PlayerScreen(),
                                ),
                              );
                            },
                      child: _chargement
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Color(0xFF001220),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'ENTRER DANS L\'APPLICATION',
                              style: TextStyle(
                                color: Color(0xFF001220),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
