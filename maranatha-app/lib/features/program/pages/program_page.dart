import 'dart:async';

import 'package:flutter/material.dart';

import '../../content/data/content_repository.dart';

class ProgramPage extends StatefulWidget {
  const ProgramPage({super.key, this.focusId});
  final String? focusId;
  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {
  static const Color _blue = Color(0xFF003DF0);
  static const Color _navy = Color(0xFF10284A);
  static const Color _page = Color(0xFFF7F9FC);
  static const Color _border = Color(0xFFE1E7F0);
  MaranathaContentSnapshot? _snapshot;
  String _filter = 'upcoming';
  bool _loading = true;
  bool _refreshing = false;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
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
      _snapshot?.programmes ?? const <Map<String, dynamic>>[],
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final filtered = source.where((item) {
      if (_filter == 'all') {
        return true;
      }
      final date = _parseDate(ContentFields.date(item));
      if (date == null) {
        return _filter == 'upcoming';
      }
      final day = DateTime(date.year, date.month, date.day);
      if (_filter == 'today') {
        return day == today;
      }
      if (_filter == 'past') {
        return day.isBefore(today);
      }
      return !day.isBefore(today);
    }).toList();
    filtered.sort((a, b) {
      final da = _parseDate(ContentFields.date(a)) ?? DateTime(9999);
      final db = _parseDate(ContentFields.date(b)) ?? DateTime(9999);
      return da.compareTo(db);
    });
    final focus = widget.focusId;
    if (focus != null && focus.isNotEmpty) {
      filtered.sort((a, b) {
        final aa = ContentFields.id(a) == focus;
        final bb = ContentFields.id(b) == focus;
        if (aa == bb) {
          return 0;
        }
        return aa ? -1 : 1;
      });
    }
    return filtered;
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        title: const Text(
          'Programme',
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
                        _filters(),
                        Expanded(child: _programList()),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _filters() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _ProgramFilter(
            label: 'A venir',
            selected: _filter == 'upcoming',
            onTap: () {
              setState(() {
                _filter = 'upcoming';
              });
            },
          ),
          _ProgramFilter(
            label: 'Aujourd hui',
            selected: _filter == 'today',
            onTap: () {
              setState(() {
                _filter = 'today';
              });
            },
          ),
          _ProgramFilter(
            label: 'Passes',
            selected: _filter == 'past',
            onTap: () {
              setState(() {
                _filter = 'past';
              });
            },
          ),
          _ProgramFilter(
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

  Widget _programList() {
    final items = _items;
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text(
            'Aucun programme disponible dans cette section.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF68778D), fontSize: 12),
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
        return _ProgramCard(
          item: item,
          highlighted:
              widget.focusId != null &&
              ContentFields.id(item) == widget.focusId,
        );
      },
    );
  }
}

class _ProgramFilter extends StatelessWidget {
  const _ProgramFilter({
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

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.item, required this.highlighted});
  final Map<String, dynamic> item;
  final bool highlighted;
  @override
  Widget build(BuildContext context) {
    final title = ContentFields.title(item);
    final date = ContentFields.date(item);
    final time = ContentFields.time(item);
    final place = ContentFields.place(item);
    final theme = ContentFields.theme(item);
    final details = ContentFields.description(item);
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            builder: (context) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty ? 'Programme' : title,
                        style: const TextStyle(
                          color: Color(0xFF10284A),
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (theme.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          theme,
                          style: const TextStyle(
                            color: Color(0xFF003DF0),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 17),
                      _DetailLine(label: 'Date', value: date),
                      _DetailLine(label: 'Heure', value: time),
                      _DetailLine(label: 'Lieu', value: place),
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          details,
                          style: const TextStyle(
                            color: Color(0xFF44536A),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(
              color: highlighted
                  ? const Color(0xFF003DF0)
                  : const Color(0xFFE1E7F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                color: const Color(0xFFEEF3FF),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF003DF0),
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? 'Programme' : title,
                      style: const TextStyle(
                        color: Color(0xFF10284A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (theme.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        theme,
                        style: const TextStyle(
                          color: Color(0xFF53647B),
                          fontSize: 10,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      [
                        date,
                        time,
                        place,
                      ].where((value) => value.isNotEmpty).join('  |  '),
                      style: const TextStyle(
                        color: Color(0xFF7A879A),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF003DF0)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF718097), fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF10284A),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
