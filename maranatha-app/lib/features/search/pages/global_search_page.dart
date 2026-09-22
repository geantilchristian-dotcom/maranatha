import '../../direct/pages/direct_page.dart';
import '../../library/pages/library_page.dart';
import '../../program/pages/program_page.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/search/maranatha_search_engine.dart';
import '../../../core/search/search_result.dart';
import '../../bible/data/bible_launch_request.dart';
import '../../bible/pages/bible_page.dart';
import '../data/search_bootstrap.dart';

Future<void> openGlobalSearch(
  BuildContext context, {
  String initialQuery = '',
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) {
        return GlobalSearchPage(initialQuery: initialQuery);
      },
    ),
  );
}

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key, this.initialQuery = ''});
  final String initialQuery;
  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  static const Color _blue = Color(0xFF003DF0);
  static const Color _navy = Color(0xFF10284A);
  static const Color _page = Color(0xFFF7F9FC);
  static const Color _border = Color(0xFFE1E7F0);
  static const Color _secondary = Color(0xFF6D7B90);
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  List<MaranathaSearchResult> _results = <MaranathaSearchResult>[];
  bool _searching = false;
  String _query = '';
  @override
  void initState() {
    super.initState();
    SearchBootstrap.ensureInitialized();
    _controller = TextEditingController(text: widget.initialQuery);
    _query = widget.initialQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      if (_query.trim().isNotEmpty) {
        _search(_query);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _query = value;
    });
    if (value.trim().isEmpty) {
      setState(() {
        _results = <MaranathaSearchResult>[];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 180), () {
      _search(value);
    });
  }

  Future<void> _search(String value) async {
    final clean = value.trim();
    if (clean.isEmpty) {
      return;
    }
    setState(() {
      _searching = true;
    });
    final results = await MaranathaSearchEngine.instance.search(clean);
    if (!mounted || clean != _controller.text.trim()) {
      return;
    }
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  Future<void> _openResult(MaranathaSearchResult result) async {
    if (result.destinationType == SearchDestinationType.bibleReference) {
      final bookIndex = result.metadata['bookIndex'];
      final chapter = result.metadata['chapter'];
      final verse = result.metadata['verse'];
      if (bookIndex is int && chapter is int && verse is int) {
        BibleLaunchRequest.instance.set(
          bookIndex: bookIndex,
          chapter: chapter,
          verse: verse,
        );
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) {
            return const BiblePage();
          },
        ),
      );
      return;
    }
    final routeId = result.metadata['routeId'];
    if (routeId == 'bible') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) {
            return const BiblePage();
          },
        ),
      );
      return;
    }
    if (routeId == 'library') {
      final section = result.metadata['section'];
      final focusId = result.metadata['focusId'];
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) {
            return LibraryPage(
              initialSection: section is String ? section : null,
              focusId: focusId is String ? focusId : null,
            );
          },
        ),
      );
      return;
    }
    if (routeId == 'programme') {
      final focusId = result.metadata['focusId'];
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) {
            return ProgramPage(focusId: focusId is String ? focusId : null);
          },
        ),
      );
      return;
    }
    if (routeId == 'direct') {
      final focusId = result.metadata['focusId'];
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) {
            return DirectPage(focusId: focusId is String ? focusId : null);
          },
        ),
      );
      return;
    }
    if (routeId == 'home') {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${result.title} sera connect\u00e9 automatiquement '
          '\u00e0 la recherche d\u00e8s que son module complet '
          'sera ajout\u00e9.',
        ),
      ),
    );
  }

  Map<String, List<MaranathaSearchResult>> _groupResults() {
    final grouped = <String, List<MaranathaSearchResult>>{};
    for (final result in _results) {
      grouped
          .putIfAbsent(result.section, () => <MaranathaSearchResult>[])
          .add(result);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupResults();
    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Recherche MARANATHA',
          style: TextStyle(
            color: _navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 800;
          final maxWidth = desktop ? 980.0 : double.infinity;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.fromLTRB(
                      desktop ? 24 : 14,
                      16,
                      desktop ? 24 : 14,
                      16,
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _onChanged,
                      onSubmitted: _search,
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Chercher dans MARANATHA : Bible, programme, '
                            'biblioth\u00e8que, activit\u00e9s...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF98A3B4),
                          fontSize: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _blue,
                        ),
                        suffixIcon: _controller.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _controller.clear();
                                  _onChanged('');
                                  _focusNode.requestFocus();
                                },
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: _secondary,
                                ),
                              ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFD),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: _blue,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: _border),
                  Expanded(child: _buildContent(grouped, desktop: desktop)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    Map<String, List<MaranathaSearchResult>> grouped, {
    required bool desktop,
  }) {
    if (_query.trim().isEmpty) {
      return _EmptySearch(desktop: desktop);
    }
    if (_searching) {
      return const Center(
        child: CircularProgressIndicator(color: _blue, strokeWidth: 2.5),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Aucun r\u00e9sultat',
                style: TextStyle(
                  color: _navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Aucun contenu local ne correspond encore \u00e0 '
                '\u00ab $_query \u00bb.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _secondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final sections = grouped.entries.toList();
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        desktop ? 24 : 14,
        18,
        desktop ? 24 : 14,
        40,
      ),
      itemCount: sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = sections[sectionIndex];
        return Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.key,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              for (var index = 0; index < section.value.length; index++) ...[
                _SearchResultTile(
                  result: section.value[index],
                  onTap: () {
                    _openResult(section.value[index]);
                  },
                ),
                if (index < section.value.length - 1)
                  const Divider(height: 1, color: _border),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.result, required this.onTap});
  final MaranathaSearchResult result;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 13, 10, 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: const TextStyle(
                        color: _GlobalSearchColors.navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      result.subtitle,
                      style: const TextStyle(
                        color: _GlobalSearchColors.secondary,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                    if (result.snippet != null) ...[
                      const SizedBox(height: 7),
                      Text(
                        result.snippet!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _GlobalSearchColors.navy,
                          fontSize: 12,
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: _GlobalSearchColors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.desktop});
  final bool desktop;
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        desktop ? 24 : 16,
        28,
        desktop ? 24 : 16,
        40,
      ),
      children: const [
        Text(
          'Que cherches-tu ?',
          style: TextStyle(
            color: _GlobalSearchColors.navy,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'La recherche parcourt les contenus disponibles '
          'dans MARANATHA et classe les r\u00e9sultats les plus '
          'pertinents.',
          style: TextStyle(
            color: _GlobalSearchColors.secondary,
            fontSize: 12,
            height: 1.45,
          ),
        ),
        SizedBox(height: 24),
        _ExampleQuery(value: 'Psaume 1:1'),
        _ExampleQuery(value: 'J\u00e9sus revient bient\u00f4t'),
        _ExampleQuery(value: 'Programme'),
        _ExampleQuery(value: 'Pri\u00e8re'),
        _ExampleQuery(value: 'Biblioth\u00e8que'),
      ],
    );
  }
}

class _ExampleQuery extends StatelessWidget {
  const _ExampleQuery({required this.value});
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _GlobalSearchColors.border)),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: _GlobalSearchColors.blue,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

abstract final class _GlobalSearchColors {
  static const Color blue = Color(0xFF003DF0);
  static const Color navy = Color(0xFF10284A);
  static const Color border = Color(0xFFE1E7F0);
  static const Color secondary = Color(0xFF6D7B90);
}
