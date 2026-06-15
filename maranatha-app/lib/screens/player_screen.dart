import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/audio_service.dart';
import 'welcome_screen.dart' show API_URL;

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  List<dynamic> _sermons = [];
  bool _chargement = true;
  bool _erreurReseau = false;
  String? _titreLectureEnCours;

  @override
  void initState() {
    super.initState();
    _chargerSermons();
    AudioService.instance.onTitreChanged = (titre) {
      setState(() => _titreLectureEnCours = titre);
    };
  }

  Future<void> _chargerSermons() async {
    setState(() {
      _chargement = true;
      _erreurReseau = false;
    });
    try {
      final response = await http
          .get(Uri.parse('$API_URL/sermons'))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        setState(() {
          _sermons = jsonDecode(response.body);
          _chargement = false;
        });
      } else {
        setState(() {
          _erreurReseau = true;
          _chargement = false;
        });
      }
    } catch (e) {
      setState(() {
        _erreurReseau = true;
        _chargement = false;
      });
    }
  }

  Future<void> _jouerSermon(Map<String, dynamic> sermon) async {
    final audioUrl = sermon['audioUrl'] as String?;
    final titre = sermon['titre'] as String? ?? 'Prédication';
    if (audioUrl == null || audioUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lien audio non disponible')),
      );
      return;
    }
    setState(() => _titreLectureEnCours = titre);
    await AudioService.instance.jouerAudio(audioUrl, titre: titre);
  }

  String _formaterDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  Color _couleurStatut(String? statut) {
    switch (statut) {
      case 'en_cours':  return Colors.green;
      case 'termine':   return Colors.grey;
      default:          return const Color(0xFFD4AF37);
    }
  }

  String _texteStatut(String? statut) {
    switch (statut) {
      case 'en_cours': return '🔴 EN DIRECT';
      case 'termine':  return '✅ TERMINÉ';
      default:         return '⏰ PLANIFIÉ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF001220),
        title: const Text(
          'Prédications',
          style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37)),
            onPressed: _chargerSermons,
          ),
        ],
      ),
      body: _chargement
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFD4AF37)),
                  SizedBox(height: 20),
                  Text(
                    'Chargement en cours…',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '(Le serveur peut mettre ~30 s à démarrer)',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Barre lecteur en cours
                if (_titreLectureEnCours != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: const Color(0xFF0A2535),
                    child: Row(
                      children: [
                        const Icon(Icons.music_note, color: Color(0xFFD4AF37), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _titreLectureEnCours!,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.stop, color: Colors.red),
                          onPressed: () {
                            AudioService.instance.arreter();
                            setState(() => _titreLectureEnCours = null);
                          },
                        ),
                      ],
                    ),
                  ),

                // Contenu principal
                Expanded(
                  child: _erreurReseau
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.wifi_off, color: Color(0xFFD4AF37), size: 56),
                                const SizedBox(height: 20),
                                const Text(
                                  'Impossible de joindre le serveur',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Vérifiez votre connexion Internet\nou réessayez dans quelques instants.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white54, fontSize: 14),
                                ),
                                const SizedBox(height: 28),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD4AF37),
                                    foregroundColor: const Color(0xFF001220),
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Réessayer', style: TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: _chargerSermons,
                                ),
                              ],
                            ),
                          ),
                        )
                      : _sermons.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.headset_off, color: Colors.white24, size: 56),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Aucune prédication disponible\npour le moment.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white54, fontSize: 16),
                                  ),
                                  const SizedBox(height: 24),
                                  TextButton.icon(
                                    icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37)),
                                    label: const Text(
                                      'Actualiser',
                                      style: TextStyle(color: Color(0xFFD4AF37)),
                                    ),
                                    onPressed: _chargerSermons,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _sermons.length,
                              itemBuilder: (context, index) {
                                final sermon = _sermons[index];
                                final statut = sermon['statut'] as String?;
                                final estEnCours = statut == 'en_cours';
                                final estLuEnCe = _titreLectureEnCours == sermon['titre'];

                                return Card(
                                  color: const Color(0xFF0A2535),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: estEnCours
                                        ? const BorderSide(color: Colors.green, width: 2)
                                        : BorderSide.none,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: _couleurStatut(statut).withOpacity(0.2),
                                          child: Icon(
                                            estLuEnCe ? Icons.volume_up : estEnCours ? Icons.radio : Icons.headset,
                                            color: _couleurStatut(statut),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                sermon['titre'] ?? '',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (sermon['description'] != null &&
                                                  sermon['description'].toString().isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  sermon['description'],
                                                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                                                ),
                                              ],
                                              const SizedBox(height: 6),
                                              Text(
                                                _formaterDate(sermon['dateDiffusion']),
                                                style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                _texteStatut(statut),
                                                style: TextStyle(
                                                  color: _couleurStatut(statut),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            estLuEnCe ? Icons.stop_circle : Icons.play_circle_fill,
                                            color: const Color(0xFFD4AF37),
                                            size: 36,
                                          ),
                                          onPressed: () {
                                            if (estLuEnCe) {
                                              AudioService.instance.arreter();
                                              setState(() => _titreLectureEnCours = null);
                                            } else {
                                              _jouerSermon(Map<String, dynamic>.from(sermon));
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}
