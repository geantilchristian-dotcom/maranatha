import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/navigation/maranatha_navigation.dart';
import '../data/maranatha_live_audio_service.dart';

class MaranathaLiveBootstrap extends StatefulWidget {
  const MaranathaLiveBootstrap({super.key, required this.child});

  final Widget child;

  @override
  State<MaranathaLiveBootstrap> createState() => _MaranathaLiveBootstrapState();
}

class _MaranathaLiveBootstrapState extends State<MaranathaLiveBootstrap>
    with WidgetsBindingObserver {
  StreamSubscription<MaranathaLiveState>? _subscription;

  StreamSubscription<String>? _navigationSubscription;

  MaranathaLiveState _state = MaranathaLiveAudioService.instance.state;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _subscription = MaranathaLiveAudioService.instance.changes.listen((state) {
      if (!mounted) {
        return;
      }

      setState(() {
        _state = state;
      });
    });

    _navigationSubscription = MaranathaLiveAudioService
        .instance
        .openDirectRequests
        .listen((id) {
          openMaranathaDirect(id);
        });

    unawaited(MaranathaLiveAudioService.instance.initialize());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(MaranathaLiveAudioService.instance.onResume());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _subscription?.cancel();
    _navigationSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      fit: StackFit.expand,
      children: [
        widget.child,
        if (kIsWeb && _state.hasLive && _state.webAutoplayBlocked)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Material(
                color: const Color(0xFF10284A),
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.graphic_eq_rounded, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _state.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          unawaited(
                            MaranathaLiveAudioService.instance.unlockWebAudio(),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFB10C16),
                        ),
                        child: const Text(
                          'ACTIVER LE SON',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
