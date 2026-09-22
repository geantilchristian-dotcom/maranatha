import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/maranatha_live_audio_service.dart';

class MaranathaLiveSetupGate extends StatefulWidget {
  const MaranathaLiveSetupGate({super.key, required this.child});

  final Widget child;

  @override
  State<MaranathaLiveSetupGate> createState() => _MaranathaLiveSetupGateState();
}

class _MaranathaLiveSetupGateState extends State<MaranathaLiveSetupGate>
    with WidgetsBindingObserver {
  Map<String, bool> _status = const <String, bool>{};

  bool _loading = true;
  bool _busy = false;

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _completed => _status['completed'] == true;

  bool get _notifications => _status['notifications'] == true;

  bool get _exactAlarm => _status['exactAlarm'] == true;

  bool get _battery => _status['battery'] == true;

  bool get _allPermissions => _notifications && _exactAlarm && _battery;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    unawaited(_load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  Future<void> _load() async {
    if (!_android) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }

      return;
    }

    final value = await MaranathaLiveAudioService.instance.getSetupStatus();

    if (!mounted) {
      return;
    }

    setState(() {
      _status = value;
      _loading = false;
    });
  }

  Future<void> _nextStep() async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final service = MaranathaLiveAudioService.instance;

      if (!_notifications) {
        await service.requestNotificationPermission();
      } else if (!_exactAlarm) {
        await service.requestExactAlarmPermission();
      } else if (!_battery) {
        await service.requestBatteryPermission();
      } else {
        final completed = await service.completeSetup();

        if (completed && mounted) {
          setState(() {
            _status = <String, bool>{..._status, 'completed': true};
          });

          return;
        }
      }

      await Future<void>.delayed(const Duration(milliseconds: 350));

      await _load();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_android || _completed) {
      return widget.child;
    }

    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE1E7F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuration MARANATHA',
                      style: TextStyle(
                        color: Color(0xFF10284A),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cette configuration se fait une seule fois. Elle permet aux directs programmes de demarrer meme lorsque le telephone est verrouille.',
                      style: TextStyle(
                        color: Color(0xFF68778D),
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _PermissionLine(
                      title: 'Notifications',
                      subtitle: 'Afficher le direct et ses commandes.',
                      granted: _notifications,
                    ),
                    const SizedBox(height: 12),
                    _PermissionLine(
                      title: 'Alarmes exactes',
                      subtitle: 'Demarrer le direct a l heure programmee.',
                      granted: _exactAlarm,
                    ),
                    const SizedBox(height: 12),
                    _PermissionLine(
                      title: 'Batterie sans restriction',
                      subtitle:
                          'Eviter que le telephone bloque le direct en veille.',
                      granted: _battery,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _busy ? null : _nextStep,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF003DF0),
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _allPermissions
                                    ? 'TERMINER LA CONFIGURATION'
                                    : 'CONTINUER',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionLine extends StatelessWidget {
  const _PermissionLine({
    required this.title,
    required this.subtitle,
    required this.granted,
  });

  final String title;
  final String subtitle;
  final bool granted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: granted ? const Color(0xFFE9F8EF) : const Color(0xFFF1F4F9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            granted ? Icons.check_rounded : Icons.lock_outline_rounded,
            color: granted ? const Color(0xFF168454) : const Color(0xFF68778D),
            size: 19,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF10284A),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF68778D),
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
