import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  final AudioPlayer _audioPlayer = AudioPlayer();

  StreamSubscription<void>? _finLectureSubscription;

  bool _estInitialise = false;
  String? _titreEnCours;

  void Function(String? titre)? onTitreChanged;

  String? get titreEnCours => _titreEnCours;

  Future<void> initialiser() async {
    if (_estInitialise) {
      return;
    }

    _finLectureSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      _modifierTitre(null);
    });

    _estInitialise = true;
  }

  Future<void> jouerAudio(
    String audioUrl, {
    String? titre,
  }) async {
    final url = audioUrl.trim();

    if (url.isEmpty) {
      throw ArgumentError('Le lien audio est vide.');
    }

    await initialiser();

    try {
      await _audioPlayer.stop();

      _modifierTitre(
        titre == null || titre.trim().isEmpty ? 'Prédication' : titre.trim(),
      );

      await _audioPlayer.play(
        UrlSource(url),
      );
    } catch (e) {
      _modifierTitre(null);
      rethrow;
    }
  }

  Future<void> arreter() async {
    await initialiser();

    try {
      await _audioPlayer.stop();
    } finally {
      _modifierTitre(null);
    }
  }

  Future<void> mettreEnPause() async {
    await initialiser();
    await _audioPlayer.pause();
  }

  Future<void> reprendre() async {
    await initialiser();
    await _audioPlayer.resume();
  }

  void _modifierTitre(String? titre) {
    _titreEnCours = titre;
    onTitreChanged?.call(titre);
  }

  Future<void> disposer() async {
    await _finLectureSubscription?.cancel();
    await _audioPlayer.dispose();

    _finLectureSubscription = null;
    _estInitialise = false;
    _modifierTitre(null);
  }
}