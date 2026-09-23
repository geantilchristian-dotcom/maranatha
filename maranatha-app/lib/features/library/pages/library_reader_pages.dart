import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const String _libraryServer = 'https://maranatha-1-k6ro.onrender.com';
const String _libraryApi = '$_libraryServer/api';

String _youtubeId(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';

  final uri = Uri.tryParse(value);
  if (uri == null) return '';

  final host = uri.host.toLowerCase();

  if (host == 'youtu.be' || host.endsWith('.youtu.be')) {
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
  }

  if (host.contains('youtube.com')) {
    final v = uri.queryParameters['v'];
    if (v != null && v.trim().isNotEmpty) {
      return v.trim();
    }

    final segments = uri.pathSegments;
    if (segments.length >= 2 &&
        (segments.first == 'embed' ||
            segments.first == 'shorts' ||
            segments.first == 'live')) {
      return segments[1];
    }
  }

  return '';
}

String youtubeThumbnailFromUrl(String raw) {
  final id = _youtubeId(raw);
  return id.isEmpty ? '' : 'https://img.youtube.com/vi/$id/hqdefault.jpg';
}

Uri libraryPdfProxyUri(String source) {
  return Uri.parse(
    '$_libraryApi/library/read-pdf?url=${Uri.encodeQueryComponent(source)}',
  );
}

String libraryAudioCoverUrl(String source) {
  if (source.trim().isEmpty) return '';
  return '$_libraryApi/library/audio-cover?url=${Uri.encodeQueryComponent(source)}';
}

class LibraryMediaCover extends StatelessWidget {
  const LibraryMediaCover({
    super.key,
    required this.kind,
    required this.mediaUrl,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.iconSize = 38,
  });

  final String kind;
  final String mediaUrl;
  final String imageUrl;
  final BoxFit fit;
  final double iconSize;

  Widget _fallback() {
    IconData icon = Icons.auto_awesome_rounded;

    switch (kind) {
      case 'LIVRE':
        icon = Icons.menu_book_rounded;
        break;
      case 'AUDIO':
        icon = Icons.headphones_rounded;
        break;
      case 'PRÃ‰DICATION':
        icon = Icons.podcasts_rounded;
        break;
      case 'VIDÃ‰O':
        icon = Icons.play_circle_outline_rounded;
        break;
    }

    return Container(
      color: const Color(0xFFF0F4FA),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: iconSize,
        color: const Color(0xFF102A56),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var image = imageUrl.trim();

    final imageYoutube = youtubeThumbnailFromUrl(image);
    if (imageYoutube.isNotEmpty) {
      image = imageYoutube;
    }

    if (image.isNotEmpty &&
        (image.startsWith('http://') || image.startsWith('https://'))) {
      return Image.network(
        image,
        fit: fit,
        alignment: Alignment.topCenter,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    final mediaYoutube = youtubeThumbnailFromUrl(mediaUrl);
    if (mediaYoutube.isNotEmpty) {
      return Image.network(
        mediaYoutube,
        fit: fit,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    if (kind == 'LIVRE' && mediaUrl.trim().isNotEmpty) {
      return PdfDocumentViewBuilder.uri(
        libraryPdfProxyUri(mediaUrl),
        loadingBuilder: (_) => const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorBuilder: (_, __, ___) => _fallback(),
        builder: (context, document) {
          if (document == null || document.pages.isEmpty) {
            return _fallback();
          }

          return Container(
            color: Colors.white,
            alignment: Alignment.topCenter,
            child: PdfPageView(
              document: document,
              pageNumber: 1,
              maximumDpi: 110,
              alignment: Alignment.topCenter,
            ),
          );
        },
      );
    }

    if ((kind == 'AUDIO' || kind == 'PRÃ‰DICATION') &&
        mediaUrl.trim().isNotEmpty) {
      return Image.network(
        libraryAudioCoverUrl(mediaUrl),
        fit: fit,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return _fallback();
  }
}

Future<void> shareLibraryItem({
  required String title,
  required String url,
}) async {
  final text = title.trim().isEmpty ? url : '${title.trim()}\n$url';

  await SharePlus.instance.share(
    ShareParams(
      title: title.trim().isEmpty ? 'MARANATHA' : title.trim(),
      text: text,
    ),
  );
}

class LibraryPdfPage extends StatelessWidget {
  const LibraryPdfPage({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  Future<void> _download(BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TÃ©lÃ©chargement impossible.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF102A56),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          title.trim().isEmpty ? 'Livre' : title.trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Partager',
            onPressed: () => shareLibraryItem(title: title, url: url),
            icon: const Icon(Icons.ios_share_rounded),
          ),
          IconButton(
            tooltip: 'TÃ©lÃ©charger',
            onPressed: () => _download(context),
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: PdfViewer.uri(
        libraryPdfProxyUri(url),
      ),
    );
  }
}

class LibraryAudioPage extends StatefulWidget {
  const LibraryAudioPage({
    super.key,
    required this.title,
    required this.author,
    required this.url,
    required this.imageUrl,
    required this.kind,
  });

  final String title;
  final String author;
  final String url;
  final String imageUrl;
  final String kind;

  @override
  State<LibraryAudioPage> createState() => _LibraryAudioPageState();
}

class _LibraryAudioPageState extends State<LibraryAudioPage> {
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  PlayerState _state = PlayerState.stopped;
  bool _loading = true;
  String _error = '';

  bool get _playing => _state == PlayerState.playing;

  @override
  void initState() {
    super.initState();

    _positionSub = _player.onPositionChanged.listen((value) {
      if (!mounted) return;
      setState(() => _position = value);
    });

    _durationSub = _player.onDurationChanged.listen((value) {
      if (!mounted) return;
      setState(() => _duration = value);
    });

    _stateSub = _player.onPlayerStateChanged.listen((value) {
      if (!mounted) return;
      setState(() {
        _state = value;
        _loading = false;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _start();
    });
  }

  Future<void> _start() async {
    try {
      await _player.play(UrlSource(widget.url));
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Lecture audio impossible.';
      });
    }
  }

  Future<void> _toggle() async {
    try {
      if (_playing) {
        await _player.pause();
      } else if (_state == PlayerState.paused) {
        await _player.resume();
      } else {
        await _player.play(UrlSource(widget.url));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Lecture audio impossible.');
    }
  }

  String _time(Duration value) {
    final total = value.inSeconds;
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxSeconds = _duration.inMilliseconds <= 0
        ? 1.0
        : _duration.inMilliseconds.toDouble();

    final currentSeconds = _position.inMilliseconds
        .clamp(0, maxSeconds.toInt())
        .toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF102A56),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Lecteur MARANATHA',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Partager',
            onPressed: () => shareLibraryItem(
              title: widget.title,
              url: widget.url,
            ),
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: LibraryMediaCover(
                        kind: widget.kind,
                        mediaUrl: widget.url,
                        imageUrl: widget.imageUrl,
                        fit: BoxFit.cover,
                        iconSize: 72,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.title.trim().isEmpty
                        ? 'Audio MARANATHA'
                        : widget.title.trim(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF102A56),
                    ),
                  ),
                  if (widget.author.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 7),
                    Text(
                      widget.author.trim(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF71809A),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Slider(
                    value: currentSeconds,
                    max: maxSeconds,
                    onChanged: (value) {
                      _player.seek(
                        Duration(milliseconds: value.round()),
                      );
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        _time(_position),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          color: Color(0xFF71809A),
                        ),
                      ),
                      Text(
                        _time(_duration),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          color: Color(0xFF71809A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 74,
                    height: 74,
                    child: FilledButton(
                      onPressed: _loading ? null : _toggle,
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                        backgroundColor: const Color(0xFFD3132A),
                        foregroundColor: Colors.white,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 25,
                              height: 25,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 40,
                            ),
                    ),
                  ),
                  if (_error.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 18),
                    Text(
                      _error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
