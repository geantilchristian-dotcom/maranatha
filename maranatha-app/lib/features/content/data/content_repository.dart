import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MaranathaContentSnapshot {
  const MaranathaContentSnapshot({
    required this.library,
    required this.programmes,
    required this.sermons,
    required this.studies,
    required this.prayers,
  });
  final Map<String, List<Map<String, dynamic>>> library;
  final List<Map<String, dynamic>> programmes;
  final List<Map<String, dynamic>> sermons;
  final List<Map<String, dynamic>> studies;
  final List<Map<String, dynamic>> prayers;
  MaranathaContentSnapshot copyWith({
    Map<String, List<Map<String, dynamic>>>? library,
    List<Map<String, dynamic>>? programmes,
    List<Map<String, dynamic>>? sermons,
    List<Map<String, dynamic>>? studies,
    List<Map<String, dynamic>>? prayers,
  }) {
    return MaranathaContentSnapshot(
      library: library ?? this.library,
      programmes: programmes ?? this.programmes,
      sermons: sermons ?? this.sermons,
      studies: studies ?? this.studies,
      prayers: prayers ?? this.prayers,
    );
  }
}

abstract final class ContentFields {
  static String text(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value == null) {
        continue;
      }
      final result = value.toString().trim();
      if (result.isNotEmpty) {
        return result;
      }
    }
    return '';
  }

  static String id(Map<String, dynamic> item) {
    return text(item, const <String>['_id', 'id']);
  }

  static String title(Map<String, dynamic> item) {
    return text(item, const <String>['title', 'titre', 'name', 'badge']);
  }

  static String description(Map<String, dynamic> item) {
    return text(item, const <String>[
      'description',
      'details',
      'texte',
      'theme',
    ]);
  }

  static String author(Map<String, dynamic> item) {
    return text(item, const <String>['auteur', 'author', 'pasteur', 'speaker']);
  }

  static String image(Map<String, dynamic> item) {
    return text(item, const <String>[
      'couvertureUrl',
      'imageUrl',
      'image',
      'cover',
      'thumbnail',
    ]);
  }

  static String mediaUrl(Map<String, dynamic> item) {
    return text(item, const <String>[
      'fichierUrl',
      'audioUrl',
      'youtubeUrl',
      'lienExterne',
      'pdfUrl',
      'url',
    ]);
  }

  static String date(Map<String, dynamic> item) {
    return text(item, const <String>[
      'date',
      'dateStr',
      'dateDiffusion',
      'datePublication',
      'createdAt',
    ]);
  }

  static String time(Map<String, dynamic> item) {
    return text(item, const <String>['time', 'heure', 'heureStr']);
  }

  static String place(Map<String, dynamic> item) {
    return text(item, const <String>['place', 'location', 'lieu']);
  }

  static String theme(Map<String, dynamic> item) {
    return text(item, const <String>['theme', 'badge']);
  }

  static String status(Map<String, dynamic> item) {
    return text(item, const <String>['statut', 'status']);
  }
}

class MaranathaContentRepository {
  MaranathaContentRepository._();
  static final MaranathaContentRepository instance =
      MaranathaContentRepository._();
  static const String _baseApi = 'https://maranatha-1-k6ro.onrender.com/api';
  static const String _cacheLibrary = 'maranatha_cache_library_v3';
  static const String _cacheProgramme = 'maranatha_cache_programme_v3';
  static const String _cacheSermons = 'maranatha_cache_sermons_v3';
  static const String _cacheStudies = 'maranatha_cache_studies_v3';
  static const String _cachePrayers = 'maranatha_cache_prayers_v3';
  MaranathaContentSnapshot? _snapshot;
  Future<MaranathaContentSnapshot> load() async {
    final existing = _snapshot;
    if (existing != null) {
      return existing;
    }
    final preferences = await SharedPreferences.getInstance();
    final library = await _readLibrary(
      cache: preferences.getString(_cacheLibrary),
      asset: 'assets/content/library.json',
    );
    final programmes = await _readList(
      cache: preferences.getString(_cacheProgramme),
      asset: 'assets/content/programme.json',
    );
    final sermons = await _readList(
      cache: preferences.getString(_cacheSermons),
      asset: 'assets/content/sermons.json',
    );
    final studies = await _readList(
      cache: preferences.getString(_cacheStudies),
      asset: 'assets/content/studies.json',
    );
    final prayers = await _readList(
      cache: preferences.getString(_cachePrayers),
      asset: 'assets/content/prayers.json',
    );
    final snapshot = MaranathaContentSnapshot(
      library: library,
      programmes: programmes,
      sermons: sermons,
      studies: studies,
      prayers: prayers,
    );
    _snapshot = snapshot;
    return snapshot;
  }

  Future<MaranathaContentSnapshot> refresh() async {
    final current = await load();
    final responses = await Future.wait<Object?>([
      _getJson('$_baseApi/library/state'),
      _getJson('$_baseApi/settings/programme'),
      _getJson('$_baseApi/sermons'),
      _getJson('$_baseApi/etudes'),
      _getJson('$_baseApi/prieres'),
    ]);
    final remoteLibrary = _libraryFromRemote(responses[0]);
    final remoteProgramme = _listFromRemote(
      responses[1],
      preferredKey: 'items',
    );
    final remoteSermons = _listFromRemote(responses[2]);
    final remoteStudies = _listFromRemote(responses[3]);
    final remotePrayers = _listFromRemote(responses[4]);
    final next = current.copyWith(
      library: remoteLibrary ?? current.library,
      programmes: remoteProgramme ?? current.programmes,
      sermons: remoteSermons ?? current.sermons,
      studies: remoteStudies ?? current.studies,
      prayers: remotePrayers ?? current.prayers,
    );
    _snapshot = next;
    final preferences = await SharedPreferences.getInstance();
    if (remoteLibrary != null) {
      await preferences.setString(_cacheLibrary, jsonEncode(remoteLibrary));
    }
    if (remoteProgramme != null) {
      await preferences.setString(_cacheProgramme, jsonEncode(remoteProgramme));
    }
    if (remoteSermons != null) {
      await preferences.setString(_cacheSermons, jsonEncode(remoteSermons));
    }
    if (remoteStudies != null) {
      await preferences.setString(_cacheStudies, jsonEncode(remoteStudies));
    }
    if (remotePrayers != null) {
      await preferences.setString(_cachePrayers, jsonEncode(remotePrayers));
    }
    return next;
  }

  Future<Object?> _getJson(String url) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: const <String, String>{'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _readLibrary({
    required String? cache,
    required String asset,
  }) async {
    if (cache != null && cache.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(cache);
        final normalized = _normalizeLibrary(decoded);
        if (normalized != null) {
          return normalized;
        }
      } catch (_) {}
    }
    try {
      final source = await rootBundle.loadString(asset);
      final decoded = jsonDecode(source);
      return _normalizeLibrary(decoded) ?? _emptyLibrary();
    } catch (_) {
      return _emptyLibrary();
    }
  }

  Future<List<Map<String, dynamic>>> _readList({
    required String? cache,
    required String asset,
  }) async {
    if (cache != null && cache.trim().isNotEmpty) {
      try {
        return _normalizeList(jsonDecode(cache));
      } catch (_) {}
    }
    try {
      final source = await rootBundle.loadString(asset);
      return _normalizeList(jsonDecode(source));
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Map<String, List<Map<String, dynamic>>>? _libraryFromRemote(Object? value) {
    if (value is Map && value.containsKey('value')) {
      return _normalizeLibrary(value['value']);
    }
    return _normalizeLibrary(value);
  }

  List<Map<String, dynamic>>? _listFromRemote(
    Object? value, {
    String? preferredKey,
  }) {
    if (value == null) {
      return null;
    }
    if (value is List) {
      return _normalizeList(value);
    }
    if (value is Map) {
      if (preferredKey != null && value[preferredKey] is List) {
        return _normalizeList(value[preferredKey]);
      }
      for (final key in const <String>['items', 'data', 'results']) {
        if (value[key] is List) {
          return _normalizeList(value[key]);
        }
      }
    }
    return null;
  }

  Map<String, List<Map<String, dynamic>>>? _normalizeLibrary(Object? value) {
    if (value is! Map) {
      return null;
    }
    final result = _emptyLibrary();
    for (final key in result.keys) {
      result[key] = _normalizeList(value[key]);
    }
    return result;
  }

  List<Map<String, dynamic>> _normalizeList(Object? value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Map<String, List<Map<String, dynamic>>> _emptyLibrary() {
    return <String, List<Map<String, dynamic>>>{
      'recent': <Map<String, dynamic>>[],
      'live': <Map<String, dynamic>>[],
      'audio': <Map<String, dynamic>>[],
      'video': <Map<String, dynamic>>[],
      'book': <Map<String, dynamic>>[],
    };
  }
}
