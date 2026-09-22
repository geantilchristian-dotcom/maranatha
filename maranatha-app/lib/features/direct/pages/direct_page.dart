import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../content/data/content_repository.dart';
import '../../live/data/maranatha_live_audio_service.dart';
import '../../../core/constants/app_assets.dart';

class DirectPage extends StatefulWidget {
  const DirectPage({super.key, this.focusId});
  final String? focusId;
  @override
  State<DirectPage> createState() => _DirectPageState();
}

class _DirectPageState extends State<DirectPage> {
  static const Color _blue = Color(0xFF003DF0);
  static const Color _navy = Color(0xFF10284A);
  static const Color _page = Color(0xFFF7F9FC);
  static const Color _border = Color(0xFFE1E7F0);
  static const String _server = 'https://maranatha-1-k6ro.onrender.com';
  MaranathaContentSnapshot? _snapshot;
  String _filter = 'en_cours';
  bool _loading = true;
  bool _refreshing = false;
  // Lecteur manuel pour archives / contenus audio.
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _completeSubscription;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  PlayerState _playerState = PlayerState.stopped;
  Map<String, dynamic>? _selectedItem;
  // Etat du vrai moteur Direct / autoplay.
  StreamSubscription<MaranathaLiveState>? _liveSubscription;
  MaranathaLiveState _liveState = MaranathaLiveAudioService.instance.state;
  static const MethodChannel _liveChannel = MethodChannel(
    'maranatha/live_audio',
  );
  bool _livePaused = false;
  double _liveVolume = 0.75;
  @override
  void initState() {
    super.initState();
    _durationSubscription = _player.onDurationChanged.listen((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        _duration = value;
      });
    });
    _positionSubscription = _player.onPositionChanged.listen((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        _position = value;
      });
    });
    _playerStateSubscription = _player.onPlayerStateChanged.listen((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        _playerState = value;
      });
    });
    _completeSubscription = _player.onPlayerComplete.listen((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _position = Duration.zero;
        _playerState = PlayerState.stopped;
      });
    });
    _liveSubscription = MaranathaLiveAudioService.instance.changes.listen((
      state,
    ) {
      if (!mounted) {
        return;
      }
      // Le Direct a toujours priorité sur une archive.
      if (state.hasLive && _playerState == PlayerState.playing) {
        unawaited(_player.stop());
      }
      setState(() {
        _liveState = state;
        if (!state.hasLive) {
          _livePaused = false;
        }
      });
    });
    unawaited(_load());
    // Force une synchronisation immediate avec le programme
    // actuellement marque "en_cours".
    unawaited(MaranathaLiveAudioService.instance.refresh());
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _completeSubscription?.cancel();
    _liveSubscription?.cancel();
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _load() async {
    final snapshot = await MaranathaContentRepository.instance.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (_refreshing) {
      return;
    }
    setState(() {
      _refreshing = true;
    });
    final snapshot = await MaranathaContentRepository.instance.refresh();
    if (!mounted) {
      return;
    }
    setState(() {
      _snapshot = snapshot;
      _refreshing = false;
    });
  }

  List<Map<String, dynamic>> get _items {
    final source = List<Map<String, dynamic>>.from(
      _snapshot?.sermons ?? const <Map<String, dynamic>>[],
    );
    final list = source.where((item) {
      final status = ContentFields.status(item);
      if (_filter == 'all') {
        return true;
      }
      return status == _filter;
    }).toList();
    final focus = widget.focusId;
    if (focus != null && focus.isNotEmpty) {
      list.sort((a, b) {
        final aa = ContentFields.id(a) == focus;
        final bb = ContentFields.id(b) == focus;
        if (aa == bb) {
          return 0;
        }
        return aa ? -1 : 1;
      });
    }
    return list;
  }

  String _absoluteUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return '';
    }
    if (value.startsWith('https://') || value.startsWith('http://')) {
      return value;
    }
    if (value.startsWith('/')) {
      return '$_server$value';
    }
    return '$_server/$value';
  }

  Future<void> _listenTo(Map<String, dynamic> item) async {
    final id = ContentFields.id(item);
    final title = ContentFields.title(item);
    final status = ContentFields.status(item);
    final audio = _absoluteUrl(ContentFields.mediaUrl(item));
    if (audio.isEmpty) {
      return;
    }
    // Un vrai direct utilise le moteur natif/autoplay.
    if (status == 'en_cours') {
      await _player.stop();
      await MaranathaLiveAudioService.instance.start(
        id: id.isEmpty ? 'direct-maranatha' : id,
        title: title.isEmpty ? 'Direct MARANATHA' : title,
        audioUrl: audio,
      );
      return;
    }
    // On ne lance pas une archive par-dessus un vrai direct.
    if (_liveState.hasLive) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une diffusion en direct est actuellement en cours.'),
        ),
      );
      return;
    }
    final currentId = _selectedItem == null
        ? ''
        : ContentFields.id(_selectedItem!);
    if (currentId == id && _playerState == PlayerState.playing) {
      await _player.pause();
      return;
    }
    if (currentId == id && _playerState == PlayerState.paused) {
      await _player.resume();
      return;
    }
    await _player.stop();
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedItem = item;
      _duration = Duration.zero;
      _position = Duration.zero;
    });
    await _player.play(UrlSource(audio));
  }

  Future<void> _toggleArchive() async {
    if (_selectedItem == null) {
      return;
    }
    if (_playerState == PlayerState.playing) {
      await _player.pause();
      return;
    }
    if (_playerState == PlayerState.paused) {
      await _player.resume();
      return;
    }
    await _listenTo(_selectedItem!);
  }

  Future<void> _stopArchive() async {
    await _player.stop();
    if (!mounted) {
      return;
    }
    setState(() {
      _position = Duration.zero;
    });
  }

  Future<void> _seek(double value) async {
    final durationMs = _duration.inMilliseconds;
    if (durationMs <= 0) {
      return;
    }
    final target = Duration(milliseconds: value.round());
    await _player.seek(target);
  }

  Future<void> _toggleLivePlayback() async {
    if (!_liveState.hasLive) {
      return;
    }
    try {
      if (_livePaused) {
        await _liveChannel.invokeMethod<void>('resume');
      } else {
        await _liveChannel.invokeMethod<void>('pause');
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _livePaused = !_livePaused;
      });
    } catch (_) {}
  }

  Future<void> _stopLivePlayback() async {
    try {
      await MaranathaLiveAudioService.instance.stop();
    } catch (_) {}
    if (!mounted) {
      return;
    }
    setState(() {
      _livePaused = false;
    });
  }

  Future<void> _setLiveVolume(double value) async {
    final safe = value.clamp(0.0, 1.0).toDouble();
    if (mounted) {
      setState(() {
        _liveVolume = safe;
      });
    }
    try {
      await _liveChannel.invokeMethod<void>('volume', <String, Object?>{
        'value': safe,
      });
    } catch (_) {}
  }

  String _time(Duration duration) {
    final total = duration.inSeconds;
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        title: const Text(
          'Direct',
          style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _refreshing ? null : _refresh,
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _blue,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 900;
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: desktop ? 1050 : double.infinity,
                    ),
                    child: Column(
                      children: [
                        _statusBar(),
                        _audioPlayer(),
                        Expanded(child: _sermonList()),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _statusBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _DirectFilter(
            label: 'En direct',
            selected: _filter == 'en_cours',
            onTap: () {
              setState(() {
                _filter = 'en_cours';
              });
            },
          ),
          _DirectFilter(
            label: '\u00C0 venir',
            selected: _filter == 'planifie',
            onTap: () {
              setState(() {
                _filter = 'planifie';
              });
            },
          ),
          _DirectFilter(
            label: 'Archives',
            selected: _filter == 'termine',
            onTap: () {
              setState(() {
                _filter = 'termine';
              });
            },
          ),
          _DirectFilter(
            label: 'Tous',
            selected: _filter == 'all',
            onTap: () {
              setState(() {
                _filter = 'all';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _audioPlayer() {
    if (_liveState.hasLive) {
      return _livePlayer();
    }
    if (_selectedItem != null) {
      return _archivePlayer();
    }
    return _emptyPlayer();
  }

  Widget _emptyPlayer() {
    Map<String, dynamic>? active;
    final sermons = _snapshot?.sermons ?? const <Map<String, dynamic>>[];
    for (final item in sermons) {
      if (ContentFields.status(item) == 'en_cours' &&
          ContentFields.mediaUrl(item).trim().isNotEmpty) {
        active = item;
        break;
      }
    }
    final hasLive = active != null;
    final title = hasLive
        ? ContentFields.title(active)
        : 'Aucune diffusion en cours';
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF850014),
            Color(0xFFB20B27),
            Color(0xFFE9314E),
          ],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(AppAssets.appIcon, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title.isEmpty ? 'Direct MARANATHA' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasLive ? 'EN DIRECT' : 'Aucune diffusion en cours',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .80),
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .25),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                tooltip: 'Lecture',
                onPressed: hasLive
                    ? () {
                        unawaited(_listenTo(active!));
                      }
                    : null,
                iconSize: 34,
                icon: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white.withValues(alpha: hasLive ? 1 : .40),
                ),
              ),
              const SizedBox(width: 20),
              Icon(
                Icons.stop_rounded,
                color: Colors.white.withValues(alpha: .42),
                size: 27,
              ),
              const SizedBox(width: 24),
              Icon(
                Icons.volume_up_rounded,
                color: Colors.white.withValues(alpha: .80),
                size: 27,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _livePlayer() {
    final playing = _liveState.isPlaying && !_livePaused;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF57000B),
            Color(0xFFA90819),
            Color(0xFFE83E50),
          ],
          stops: <double>[0, 0.55, 1],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(AppAssets.appIcon, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _liveState.title.isEmpty
                          ? 'Direct MARANATHA'
                          : _liveState.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: <Widget>[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          playing ? 'EN DIRECT' : 'EN PAUSE',
                          style: const TextStyle(
                            color: Color(0xEFFFFFFF),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: LinearProgressIndicator(
              minHeight: 4,
              backgroundColor: const Color(0x3DFFFFFF),
              color: Colors.white,
              value: playing ? null : 0.35,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: <Widget>[
              Text(
                playing ? 'Lecture en cours' : 'Lecture en pause',
                style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 9),
              ),
              const Spacer(),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              InkWell(
                onTap: () {
                  unawaited(_toggleLivePlayback());
                },
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: const Color(0xFFAA0718),
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              InkWell(
                onTap: () {
                  unawaited(_stopLivePlayback());
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x55FFFFFF)),
                  ),
                  child: const Icon(
                    Icons.stop_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: <Widget>[
              Icon(
                _liveVolume <= 0.01
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                  ),
                  child: Slider(
                    min: 0,
                    max: 1,
                    value: _liveVolume,
                    activeColor: Colors.white,
                    inactiveColor: const Color(0x55FFFFFF),
                    onChanged: (value) {
                      unawaited(_setLiveVolume(value));
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 37,
                child: Text(
                  '${(_liveVolume * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _archivePlayer() {
    final item = _selectedItem!;
    final title = ContentFields.title(item);
    final maxMs = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds.toDouble()
        : 1.0;
    final positionMs = _position.inMilliseconds
        .clamp(0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 0)
        .toDouble();
    final playing = _playerState == PlayerState.playing;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: _toggleArchive,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: _blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LECTEUR AUDIO',
                      style: TextStyle(
                        color: _blue,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title.isEmpty ? 'MARANATHA' : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _stopArchive,
                icon: const Icon(Icons.stop_rounded, color: Color(0xFF68778D)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            ),
            child: Slider(
              value: positionMs,
              max: maxMs,
              onChanged: _duration.inMilliseconds > 0 ? _seek : null,
              activeColor: _blue,
              inactiveColor: const Color(0xFFE5EAF2),
            ),
          ),
          Row(
            children: [
              Text(
                _time(_position),
                style: const TextStyle(color: Color(0xFF7B8798), fontSize: 9),
              ),
              const Spacer(),
              Text(
                _time(_duration),
                style: const TextStyle(color: Color(0xFF7B8798), fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sermonList() {
    final items = _items;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Text(
            _filter == 'en_cours'
                ? 'Aucune diffusion en direct actuellement.'
                : 'Aucun contenu disponible dans cette section.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF68778D), fontSize: 12),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: items.length,
      separatorBuilder: (context, index) {
        return const SizedBox(height: 10);
      },
      itemBuilder: (context, index) {
        final item = items[index];
        final selectedId = _selectedItem == null
            ? ''
            : ContentFields.id(_selectedItem!);
        return _DirectCard(
          item: item,
          highlighted:
              widget.focusId != null &&
              ContentFields.id(item) == widget.focusId,
          playing:
              selectedId == ContentFields.id(item) &&
              _playerState == PlayerState.playing,
          onListen: () {
            unawaited(_listenTo(item));
          },
        );
      },
    );
  }
}

class _DirectFilter extends StatelessWidget {
  const _DirectFilter({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF003DF0) : const Color(0xFFF3F6FB),
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF10284A),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectCard extends StatelessWidget {
  const _DirectCard({
    required this.item,
    required this.highlighted,
    required this.playing,
    required this.onListen,
  });
  final Map<String, dynamic> item;
  final bool highlighted;
  final bool playing;
  final VoidCallback onListen;
  @override
  Widget build(BuildContext context) {
    final title = ContentFields.title(item);
    final description = ContentFields.description(item);
    final status = ContentFields.status(item);
    final date = ContentFields.date(item);
    final audio = ContentFields.mediaUrl(item);
    final live = status == 'en_cours';
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted || playing
              ? const Color(0xFF003DF0)
              : const Color(0xFFE1E7F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 57,
            height: 57,
            decoration: BoxDecoration(
              color: live ? const Color(0xFFFFEDEF) : const Color(0xFFEEF3FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              live ? Icons.podcasts_rounded : Icons.graphic_eq_rounded,
              color: live ? const Color(0xFFC71F37) : const Color(0xFF003DF0),
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (live) ...[
                      const Text(
                        'EN DIRECT',
                        style: TextStyle(
                          color: Color(0xFFC71F37),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        title.isEmpty ? 'Diffusion MARANATHA' : title,
                        style: const TextStyle(
                          color: Color(0xFF10284A),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF68778D),
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ],
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    date,
                    style: const TextStyle(
                      color: Color(0xFF8A96A7),
                      fontSize: 9,
                    ),
                  ),
                ],
                if (audio.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: onListen,
                    style: TextButton.styleFrom(
                      foregroundColor: live
                          ? const Color(0xFFC71F37)
                          : const Color(0xFF003DF0),
                      padding: EdgeInsets.zero,
                    ),
                    icon: Icon(
                      playing
                          ? Icons.pause_rounded
                          : live
                          ? Icons.podcasts_rounded
                          : Icons.play_arrow_rounded,
                      size: 18,
                    ),
                    label: Text(
                      playing
                          ? 'Pause'
                          : live
                          ? 'Ecouter le direct'
                          : 'Ecouter',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
