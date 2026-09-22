import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../content/data/content_repository.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, this.initialSection, this.focusId});
  final String? initialSection;
  final String? focusId;
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  static const Color _blue = Color(0xFF003DF0);
  static const Color _navy = Color(0xFF10284A);
  static const Color _page = Color(0xFFF7F9FC);
  static const Color _border = Color(0xFFE1E7F0);
  static const List<_LibraryTab> _tabs = <_LibraryTab>[
    _LibraryTab(
      keyName: 'recent',
      label: 'R\u00e9cents',
      icon: Icons.history_rounded,
    ),
    _LibraryTab(
      keyName: 'live',
      label: 'Pr\u00e9dications',
      icon: Icons.podcasts_rounded,
    ),
    _LibraryTab(
      keyName: 'audio',
      label: 'Audios',
      icon: Icons.headphones_rounded,
    ),
    _LibraryTab(
      keyName: 'video',
      label: 'Vid\u00e9os',
      icon: Icons.play_circle_outline_rounded,
    ),
    _LibraryTab(
      keyName: 'book',
      label: 'Livres',
      icon: Icons.menu_book_rounded,
    ),
  ];
  MaranathaContentSnapshot? _snapshot;
  late String _selected;
  bool _loading = true;
  bool _refreshing = false;
  @override
  void initState() {
    super.initState();
    final wanted = widget.initialSection;
    _selected = _tabs.any((tab) => tab.keyName == wanted) ? wanted! : 'recent';
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
    final snapshot = _snapshot;
    if (snapshot == null) {
      return <Map<String, dynamic>>[];
    }
    final source = List<Map<String, dynamic>>.from(
      snapshot.library[_selected] ?? const <Map<String, dynamic>>[],
    );
    final focus = widget.focusId;
    if (focus != null && focus.isNotEmpty) {
      source.sort((a, b) {
        final aFocus = ContentFields.id(a) == focus;
        final bFocus = ContentFields.id(b) == focus;
        if (aFocus == bFocus) {
          return 0;
        }
        return aFocus ? -1 : 1;
      });
    }
    return source;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        title: const Text(
          'Biblioth\u00e8que',
          style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Actualiser',
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
                      maxWidth: desktop ? 1280 : double.infinity,
                    ),
                    child: Column(
                      children: [
                        _categoryBar(desktop: desktop),
                        const Divider(height: 1, color: _border),
                        Expanded(child: _contentGrid(constraints.maxWidth)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _categoryBar({required bool desktop}) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        desktop ? 20 : 12,
        14,
        desktop ? 20 : 12,
        14,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 8.0;
          final useSingleRow = constraints.maxWidth >= 700;
          final columnCount = useSingleRow ? 5 : 3;
          final totalSpacing = spacing * (columnCount - 1);
          final buttonWidth =
              (constraints.maxWidth - totalSpacing) / columnCount;
          return Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: spacing,
            runSpacing: 9,
            children: [
              for (final tab in _tabs)
                SizedBox(
                  width: buttonWidth,
                  height: 42,
                  child: _CategoryButton(
                    label: tab.label,
                    icon: tab.icon,
                    selected: _selected == tab.keyName,
                    onTap: () {
                      setState(() {
                        _selected = tab.keyName;
                      });
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _contentGrid(double width) {
    final items = _items;
    if (items.isEmpty) {
      return const _EmptyState(
        title: 'Aucun contenu disponible',
        message: 'Cette section sera automatiquement aliment\u00e9e par les publications de MARANATHA.',
      );
    }
    final mobile = width < 620;
    // ========================================================
    // TELEPHONE :
    // 1 ELEMENT PAR LIGNE
    // PRESENTATION HORIZONTALE
    // ========================================================
    if (mobile) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        itemCount: items.length,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 10);
        },
        itemBuilder: (context, index) {
          final item = items[index];
          final focused =
              widget.focusId != null &&
              ContentFields.id(item) == widget.focusId;
          return _LibraryCard(
            item: item,
            highlighted: focused,
            horizontal: true,
          );
        },
      );
    }
    // ========================================================
    // TABLETTE / PC :
    // VRAIE GALERIE DE POCHETTES
    // ========================================================
    final columns = width >= 1250
        ? 4
        : width >= 900
        ? 3
        : 2;
    return GridView.builder(
      padding: EdgeInsets.all(width >= 900 ? 20 : 14),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: width >= 1200 ? 0.72 : 0.76,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final focused =
            widget.focusId != null && ContentFields.id(item) == widget.focusId;
        return _LibraryCard(
          item: item,
          highlighted: focused,
          horizontal: false,
        );
      },
    );
  }
}

class _LibraryTab {
  const _LibraryTab({
    required this.keyName,
    required this.label,
    required this.icon,
  });
  final String keyName;
  final String label;
  final IconData icon;
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF003DF0) : const Color(0xFFF4F7FC),
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? Colors.white : const Color(0xFF003DF0),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF10284A),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({
    required this.item,
    required this.highlighted,
    required this.horizontal,
  });
  static const String _server = 'https://maranatha-1-k6ro.onrender.com';
  final Map<String, dynamic> item;
  final bool highlighted;
  final bool horizontal;
  @override
  Widget build(BuildContext context) {
    final title = ContentFields.title(item).trim();
    final author = ContentFields.author(item).trim();
    final description = ContentFields.description(item).trim();
    final image = ContentFields.image(item).trim();
    final url = ContentFields.mediaUrl(item).trim();
    final displayTitle = title.isEmpty ? 'Publication MARANATHA' : title;
    if (horizontal) {
      return _mobileCard(
        context,
        title: displayTitle,
        author: author,
        description: description,
        image: image,
        url: url,
      );
    }
    return _desktopCard(
      context,
      title: displayTitle,
      author: author,
      description: description,
      image: image,
      url: url,
    );
  }

  // ==========================================================
  // MOBILE
  // ==========================================================
  Widget _mobileCard(
    BuildContext context, {
    required String title,
    required String author,
    required String description,
    required String image,
    required String url,
  }) {
    return Material(
      color: Colors.white,
      child: Container(
        constraints: const BoxConstraints(minHeight: 150),
        decoration: BoxDecoration(
          border: Border.all(
            color: highlighted
                ? const Color(0xFF003DF0)
                : const Color(0xFFE1E7F0),
            width: highlighted ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // POCHETTE
              // =================================================
              SizedBox(
                width: 92,
                height: 132,
                child: _MaranathaLibraryCover(
                  imageUrl: _resolveUrl(image),
                  onTap: () {
                    _openFile(context, url);
                  },
                ),
              ),
              const SizedBox(width: 12),
              // =================================================
              // INFORMATIONS + ACTIONS
              // =================================================
              Expanded(
                child: SizedBox(
                  height: 132,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF10284A),
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (author.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF748094),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Expanded(
                          child: Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF7B8798),
                              fontSize: 9,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ] else
                        const Spacer(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _LibraryActionButton(
                              icon: Icons.menu_book_outlined,
                              label: 'Lire',
                              primary: true,
                              onTap: url.isEmpty
                                  ? null
                                  : () {
                                      _openFile(context, url);
                                    },
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: _LibraryActionButton(
                              icon: Icons.download_outlined,
                              label: 'T\u00e9l\u00e9charger',
                              onTap: url.isEmpty
                                  ? null
                                  : () {
                                      _downloadFile(context, url);
                                    },
                            ),
                          ),
                          const SizedBox(width: 5),
                          SizedBox(
                            width: 42,
                            child: _LibraryActionButton(
                              icon: Icons.share_outlined,
                              label: '',
                              onTap: url.isEmpty
                                  ? null
                                  : () {
                                      _shareFile(context, title, url);
                                    },
                            ),
                          ),
                        ],
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

  // ==========================================================
  // TABLETTE / ORDINATEUR
  // ==========================================================
  Widget _desktopCard(
    BuildContext context, {
    required String title,
    required String author,
    required String description,
    required String image,
    required String url,
  }) {
    return Material(
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: highlighted
                ? const Color(0xFF003DF0)
                : const Color(0xFFE1E7F0),
            width: highlighted ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =================================================
            // GRANDE POCHETTE
            // =================================================
            Expanded(
              flex: 7,
              child: _MaranathaLibraryCover(
                imageUrl: _resolveUrl(image),
                onTap: () {
                  _openFile(context, url);
                },
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF10284A),
                        fontSize: 13,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (author.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7B8798),
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: _LibraryActionButton(
                            icon: Icons.menu_book_outlined,
                            label: 'Lire',
                            primary: true,
                            onTap: url.isEmpty
                                ? null
                                : () {
                                    _openFile(context, url);
                                  },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _LibraryActionButton(
                            icon: Icons.download_outlined,
                            label: 'T\u00e9l\u00e9charger',
                            onTap: url.isEmpty
                                ? null
                                : () {
                                    _downloadFile(context, url);
                                  },
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 42,
                          child: _LibraryActionButton(
                            icon: Icons.share_outlined,
                            label: '',
                            onTap: url.isEmpty
                                ? null
                                : () {
                                    _shareFile(context, title, url);
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // OUVRIR LE PDF / MEDIA
  // ==========================================================
  static Future<void> _openFile(BuildContext context, String rawUrl) async {
    final url = _resolveUrl(rawUrl);
    if (url.isEmpty) {
      _showMessage(context, 'Fichier indisponible.');
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showMessage(context, 'Lien invalide.');
      return;
    }
    final success = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );
    if (!success && context.mounted) {
      _showMessage(context, 'Impossible d ouvrir le fichier.');
    }
  }

  // ==========================================================
  // TELECHARGER
  // ==========================================================
  static Future<void> _downloadFile(BuildContext context, String rawUrl) async {
    final url = _resolveUrl(rawUrl);
    if (url.isEmpty) {
      _showMessage(context, 'Fichier indisponible.');
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showMessage(context, 'Lien invalide.');
      return;
    }
    final success = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );
    if (!success && context.mounted) {
      _showMessage(context, 'Impossible d ouvrir le fichier.');
    }
  }

  // ==========================================================
  // PARTAGER
  // ==========================================================
  static Future<void> _shareFile(
    BuildContext context,
    String title,
    String rawUrl,
  ) async {
    final url = _resolveUrl(rawUrl);
    if (url.isEmpty) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.content_copy_outlined),
                  title: const Text('Copier le lien'),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                    if (context.mounted) {
                      _showMessage(context, 'Lien copi\u00e9.');
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.chat_outlined),
                  title: const Text('Partager sur WhatsApp'),
                  onTap: () async {
                    final message = '$title\n$url';
                    final whatsapp = Uri.parse(
                      'https://wa.me/?text=${Uri.encodeComponent(message)}',
                    );
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                    await launchUrl(
                      whatsapp,
                      mode: LaunchMode.platformDefault,
                      webOnlyWindowName: '_blank',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // URL ABSOLUE
  // ==========================================================
  static String _resolveUrl(String value) {
    final raw = value.trim();
    if (raw.isEmpty) {
      return '';
    }
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    if (raw.startsWith('//')) {
      return 'https:$raw';
    }
    if (raw.startsWith('/')) {
      return '$_server$raw';
    }
    return '$_server/$raw';
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MaranathaLibraryCover extends StatelessWidget {
  const _MaranathaLibraryCover({required this.imageUrl, required this.onTap});
  final String imageUrl;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F4F9),
      child: InkWell(
        onTap: onTap,
        child: imageUrl.isEmpty
            ? _placeholder()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return _placeholder();
                },
              ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Color(0xFFF0F3F8)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_stories_outlined,
            color: Color(0xFF003DF0),
            size: 28,
          ),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            color: const Color(0xFF003DF0),
            child: const Text(
              'PDF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryActionButton extends StatelessWidget {
  const _LibraryActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: primary && enabled
          ? const Color(0xFF003DF0)
          : const Color(0xFFF3F6FA),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 34,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: label.isEmpty ? 0 : 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: !enabled
                      ? const Color(0xFFB6BFCC)
                      : primary
                      ? Colors.white
                      : const Color(0xFF24405F),
                ),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: !enabled
                            ? const Color(0xFFB6BFCC)
                            : primary
                            ? Colors.white
                            : const Color(0xFF24405F),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF10284A),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF68778D),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
