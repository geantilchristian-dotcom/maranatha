import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final _player = AudioPlayer();
  bool _estEnCoursLecture = false;
  String? _titreCourant;

  // Callback pour notifier l'interface du titre en cours
  Function(String?)? onTitreChanged;

  bool get estEnCoursLecture => _estEnCoursLecture;
  String? get titreCourant => _titreCourant;

  Future<void> initialiser() async {
    await _player.setReleaseMode(ReleaseMode.stop);

    _player.onPlayerStateChanged.listen((state) {
      _estEnCoursLecture = state == PlayerState.playing;
    });

    _player.onPlayerComplete.listen((_) {
      _estEnCoursLecture = false;
      _titreCourant = null;
      onTitreChanged?.call(null);
      print('✅ Lecture terminée');
    });

    print('✅ AudioService initialisé');
  }

  /// Lance la lecture d'un fichier MP3 depuis une URL
  Future<void> jouerAudio(String url, {String? titre}) async {
    try {
      if (_estEnCoursLecture) {
        await arreter();
      }

      _titreCourant = titre;
      await _player.play(UrlSource(url));
      _estEnCoursLecture = true;
      onTitreChanged?.call(titre);

      print('▶️ Lecture lancée : ${titre ?? url}');
    } catch (e) {
      print('❌ Erreur lecture audio : $e');
      rethrow;
    }
  }

  Future<void> mettreEnPause() async {
    if (_estEnCoursLecture) await _player.pause();
  }

  Future<void> reprendre() async {
    if (!_estEnCoursLecture) await _player.resume();
  }

  Future<void> arreter() async {
    await _player.stop();
    _estEnCoursLecture = false;
    _titreCourant = null;
    onTitreChanged?.call(null);
  }

  Future<void> disposer() async {
    await _player.dispose();
  }
}
