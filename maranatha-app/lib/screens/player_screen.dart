import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../services/audio_service.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  static const Color _background = Color(0xFF001522);
  static const Color _surface = Color(0xFF0B293A);
  static const Color _gold = Color(0xFFD5AE32);

  List<Map<String, dynamic>> _sermons = const [];
  bool _loading = true;
  bool _networkError = false;
  String? _currentTitle;

  @override
  void initState() {
    super.initState();
    _loadSermons();
    AudioService.instance.onTitreChanged = (title) {
      if (!mounted) return;
      setState(() => _currentTitle = title);
    };
  }

  @override
  void dispose() {
    AudioService.instance.onTitreChanged = null;
    super.dispose();
  }

  Future<void> _loadSermons() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _networkError = false;
      });
    }

    try {
      final response = await http
          .get(Uri.parse('$API_URL/sermons'))
          .timeout(const Duration(seconds: 75));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw http.ClientException('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) throw const FormatException('Réponse invalide');

      final sermons = decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _sermons = sermons;
        _loading = false;
      });
    } catch (error) {
      debugPrint('Chargement des prédications impossible : $error');
      if (!mounted) return;
      setState(() {
        _networkError = true;
        _loading = false;
      });
    }
  }

  Future<void> _play(Map<String, dynamic> sermon) async {
    final url = sermon['audioUrl']?.toString().trim() ?? '';
    final title = sermon['titre']?.toString().trim();

    if (url.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lien audio non disponible.')),
      );
      return;
    }

    try {
      await AudioService.instance.jouerAudio(
        url,
        titre: title == null || title.isEmpty ? 'Prédication' : title,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lecture audio impossible.')),
      );
    }
  }

  String _formatDate(Object? value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return '';
    try {
      final date = DateTime.parse(raw).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/${date.year} à ${hour}h$minute';
    } catch (_) {
      return raw;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'en_cours':
        return const Color(0xFF4CD58A);
      case 'termine':
        return Colors.white38;
      default:
        return _gold;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'en_cours':
        return 'EN DIRECT';
      case 'termine':
        return 'TERMINÉ';
      default:
        return 'PLANIFIÉ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _gold,
        title: const Text(
          'Prédications',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loadSermons,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_currentTitle != null)
            Container(
              width: double.infinity,
              color: _surface,
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                children: [
                  const Icon(Icons.graphic_eq_rounded, color: _gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _currentTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Arrêter',
                    onPressed: AudioService.instance.arreter,
                    icon: const Icon(Icons.stop_circle_rounded),
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _gold),
      );
    }

    if (_networkError) {
      return _EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Impossible de joindre le serveur',
        subtitle: 'Vérifiez votre connexion Internet, puis réessayez.',
        actionLabel: 'Réessayer',
        onAction: _loadSermons,
      );
    }

    if (_sermons.isEmpty) {
      return _EmptyState(
        icon: Icons.library_music_outlined,
        title: 'Aucune prédication disponible',
        subtitle: 'Les prochaines prédications apparaîtront ici.',
        actionLabel: 'Actualiser',
        onAction: _loadSermons,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSermons,
      color: _gold,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _sermons.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final sermon = _sermons[index];
          final title = sermon['titre']?.toString() ?? 'Prédication';
          final description = sermon['description']?.toString().trim() ?? '';
          final status = sermon['statut']?.toString() ?? 'planifie';
          final isPlaying = _currentTitle == title;
          final color = _statusColor(status);

          return Material(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _play(sermon),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.graphic_eq_rounded
                            : Icons.headphones_rounded,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Text(
                                _formatDate(sermon['dateDiffusion']),
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                _statusLabel(status),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        if (isPlaying) {
                          await AudioService.instance.arreter();
                        } else {
                          await _play(sermon);
                        }
                      },
                      icon: Icon(
                        isPlaying
                            ? Icons.stop_circle_rounded
                            : Icons.play_circle_fill_rounded,
                        color: _gold,
                        size: 38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFD5AE32), size: 58),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD5AE32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
