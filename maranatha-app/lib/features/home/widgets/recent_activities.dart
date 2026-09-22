import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../program/pages/program_page.dart';
import '../../../core/theme/app_colors.dart';

class RecentActivities extends StatefulWidget {
  const RecentActivities({super.key});

  @override
  State<RecentActivities> createState() => _RecentActivitiesState();
}

class _RecentActivitiesState extends State<RecentActivities> {
  static const String _server = 'https://maranatha-1-k6ro.onrender.com';
  static const String _endpoint = '$_server/api/settings/programme';

  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _text(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];

      if (value == null) continue;

      final text = value.toString().trim();

      if (text.isNotEmpty) return text;
    }

    return '';
  }

  String _absoluteUrl(String raw) {
    final value = raw.trim();

    if (value.isEmpty) return '';

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('//')) return 'https:$value';
    if (value.startsWith('/')) return '$_server$value';

    return '$_server/$value';
  }

  Future<void> _load() async {
    try {
      final response = await http
          .get(
            Uri.parse(_endpoint),
            headers: const <String, String>{'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 18));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      final items = <Map<String, dynamic>>[];

      if (decoded is Map && decoded['items'] is List) {
        for (final raw in decoded['items'] as List) {
          if (raw is! Map) continue;

          final item = Map<String, dynamic>.from(raw);

          if (item['active'] == false) continue;

          items.add(item);
        }
      }

      items.sort((a, b) {
        final da = DateTime.tryParse(
          _text(a, const <String>['date', 'dateStr']),
        );

        final db = DateTime.tryParse(
          _text(b, const <String>['date', 'dateStr']),
        );

        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;

        return da.compareTo(db);
      });

      if (!mounted) return;

      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _items = <Map<String, dynamic>>[];
        _loading = false;
      });
    }
  }

  void _openProgram(Map<String, dynamic> item) {
    final id = _text(item, const <String>['_id', 'id']);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProgramPage(focusId: id.isEmpty ? null : id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 110,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    // Aucun faux programme local.
    if (_items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Programme à venir',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: AppColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ProgramPage()),
                );
              },
              child: const Text(
                'Voir tout',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 760;

            if (!desktop) {
              return SizedBox(
                height: 184,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _items.length.clamp(0, 8),
                  separatorBuilder: (_, __) => const SizedBox(width: 9),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 145,
                      child: _ProgramCard(
                        item: _items[index],
                        resolveUrl: _absoluteUrl,
                        onTap: () {
                          _openProgram(_items[index]);
                        },
                      ),
                    );
                  },
                ),
              );
            }

            final count = _items.length.clamp(0, 4);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List<Widget>.generate(count, (index) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index < count - 1 ? 12 : 0),
                    child: SizedBox(
                      height: 190,
                      child: _ProgramCard(
                        item: _items[index],
                        resolveUrl: _absoluteUrl,
                        onTap: () {
                          _openProgram(_items[index]);
                        },
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.item,
    required this.resolveUrl,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final String Function(String) resolveUrl;
  final VoidCallback onTap;

  String _text(List<String> keys) {
    for (final key in keys) {
      final value = item[key];

      if (value == null) continue;

      final text = value.toString().trim();

      if (text.isNotEmpty) return text;
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final title = _text(const <String>['name', 'title', 'titre', 'badge']);

    final subtitle = _text(const <String>['details', 'description', 'theme']);

    final date = _text(const <String>['date', 'dateStr']);

    final image = resolveUrl(_text(const <String>['image', 'imageUrl']));

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 100,
                width: double.infinity,
                child: image.isEmpty
                    ? Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              Color(0xFF0B5CFF),
                              Color(0xFF102A56),
                            ],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      )
                    : Image.network(
                        image,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            color: const Color(0xFFEAF1FF),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: AppColors.primary,
                              size: 30,
                            ),
                          );
                        },
                      ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title.isEmpty ? 'Programme' : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          color: AppColors.navy,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      if (subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              color: AppColors.textSecondary,
                              fontSize: 8,
                            ),
                          ),
                        ),

                      const Spacer(),

                      if (date.isNotEmpty)
                        Text(
                          date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            color: AppColors.textMuted,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
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
