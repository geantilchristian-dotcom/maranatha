// AudioService conservé pour compatibilité mais non utilisé.
// L'audio est géré directement par la WebView (interface web).
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();
  Future<void> initialiser() async {}
}
