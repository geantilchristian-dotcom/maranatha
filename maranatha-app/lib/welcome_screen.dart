import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // Cette variable retient si le fidèle active ou non le mode Alarme
  bool _isMaranathaEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fond bleu marine profond
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
                  // Icône symbolisant le ministère (Lumière/Bible)
                  const Icon(
                    Icons.local_fire_department,
                    size: 70,
                    color: Color(0xFFD4AF37), // Couleur Or
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

              // 2. LE ENCADRÉ CENTRAL (ACTIVATION MODE MARANATHA)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0DF), // Fond crème doux
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.alarm,
                      size: 50,
                      color: Color(0xFF001220),
                    ),
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
                      'Recevez les prédications du Pasteur en direct, même en veille. Votre téléphone se réveillera pour vous à l’heure du prêche.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF001220).withOpacity(0.8),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Le bouton poussoir (Toggle Switch)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Désactivé',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        Transform.scale(
                          scale: 1.2,
                          child: Switch(
                            value: _isMaranathaEnabled,
                            activeColor: const Color(0xFFD4AF37),
                            activeTrackColor: const Color(0xFF001220).withOpacity(0.3),
                            inactiveThumbColor: Colors.grey,
                            onChanged: (bool value) {
                              setState(() {
                                _isMaranathaEnabled = value;
                              });
                            },
                          ),
                        ),
                        const Text(
                          'Activé',
                          style: TextStyle(
                            color: Color(0xFF001220), 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. LE BOUTON D'ENTRÉE EN BAS
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37), // Couleur Or
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    // C'est ici qu'on gérera le passage à l'écran suivant
                    print('Mode Maranatha activé : $_isMaranathaEnabled');
                  },
                  child: const Text(
                    'ENTRER DANS L\'APPLICATION',
                    style: TextStyle(
                      color: Color(0xFF001220), // Texte marine sur bouton or
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}