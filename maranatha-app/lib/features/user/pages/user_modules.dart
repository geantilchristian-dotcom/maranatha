import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../profile/pages/profile_page.dart';

const String _server = 'https://maranatha-1-k6ro.onrender.com';
const String _apiRoot = '$_server/api';

// ============================================================
// BLOC-NOTE AVEC HISTORIQUE
// ============================================================

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  static const String _storageKey = 'maranatha_notes_v2';

  static const Color _blue = Color(0xFF0B5CFF);
  static const Color _navy = Color(0xFF102A56);
  static const Color _muted = Color(0xFF71809A);
  static const Color _line = Color(0xFFE2E9F3);
  static const Color _soft = Color(0xFFF5F7FB);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  List<Map<String, dynamic>> _notes = <Map<String, dynamic>>[];

  bool _loading = true;
  bool _saving = false;
  bool _editorVisible = false;

  String? _editingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    final list = <Map<String, dynamic>>[];

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);

        if (decoded is List) {
          for (final item in decoded) {
            if (item is! Map) continue;

            final note = Map<String, dynamic>.from(item);

            final title = (note['title'] ?? '').toString().trim();
            final text = (note['text'] ?? '').toString();

            // Compatibilité avec les anciennes notes.
            if (title.isEmpty && text.trim().isNotEmpty) {
              final firstLine = text.trim().split('\n').first.trim();

              note['title'] = firstLine.length > 50
                  ? '${firstLine.substring(0, 50)}…'
                  : firstLine;
            }

            list.add(note);
          }
        }
      } catch (_) {}
    }

    list.sort((a, b) => _sortDate(b).compareTo(_sortDate(a)));

    if (!mounted) return;

    setState(() {
      _notes = list;
      _loading = false;
    });
  }

  DateTime _sortDate(Map<String, dynamic> note) {
    return DateTime.tryParse(
          (note['updatedAt'] ?? note['createdAt'] ?? '').toString(),
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_storageKey, jsonEncode(_notes));
  }

  void _newNote() {
    FocusScope.of(context).unfocus();

    setState(() {
      _editingId = null;
      _titleController.clear();
      _bodyController.clear();
      _editorVisible = true;
    });
  }

  void _editNote(Map<String, dynamic> note) {
    FocusScope.of(context).unfocus();

    setState(() {
      _editingId = (note['id'] ?? '').toString();
      _titleController.text = (note['title'] ?? '').toString();
      _bodyController.text = (note['text'] ?? '').toString();
      _editorVisible = true;
    });
  }

  void _closeEditor() {
    FocusScope.of(context).unfocus();

    setState(() {
      _editingId = null;
      _titleController.clear();
      _bodyController.clear();
      _editorVisible = false;
    });
  }

  Future<void> _save() async {
    if (_saving) return;

    var title = _titleController.text.trim();
    final text = _bodyController.text.trim();

    if (title.isEmpty && text.isNotEmpty) {
      final firstLine = text.split('\n').first.trim();

      title = firstLine.length > 50
          ? '${firstLine.substring(0, 50)}…'
          : firstLine;
    }

    if (title.isEmpty) {
      _message('Ajoutez un sujet à votre note.');
      return;
    }

    if (text.isEmpty) {
      _message('Écrivez le contenu de votre note.');
      return;
    }

    setState(() {
      _saving = true;
    });

    final now = DateTime.now().toIso8601String();

    if (_editingId == null) {
      _notes.insert(0, <String, dynamic>{
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'title': title,
        'text': text,
        'createdAt': now,
        'updatedAt': now,
      });
    } else {
      final index = _notes.indexWhere(
        (note) => (note['id'] ?? '').toString() == _editingId,
      );

      if (index >= 0) {
        final old = _notes[index];

        _notes[index] = <String, dynamic>{
          ...old,
          'title': title,
          'text': text,
          'updatedAt': now,
        };
      }
    }

    _notes.sort((a, b) => _sortDate(b).compareTo(_sortDate(a)));

    await _persist();

    if (!mounted) return;

    setState(() {
      _saving = false;
      _editingId = null;
      _titleController.clear();
      _bodyController.clear();

      // IMPORTANT :
      // après Enregistrer, la page de saisie disparaît.
      _editorVisible = false;
    });

    _message('Note enregistrée • ${_formatDateTime(DateTime.now())}');
  }

  Future<void> _deleteNote(Map<String, dynamic> note) async {
    final title = (note['title'] ?? 'Cette note').toString();

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Supprimer la note ?',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: _navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Text(
                '« $title » sera supprimée définitivement.',
                style: const TextStyle(fontFamily: 'Manrope', color: _muted),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB42318),
                  ),
                  child: const Text('Supprimer'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    final id = (note['id'] ?? '').toString();

    setState(() {
      _notes.removeWhere((item) => (item['id'] ?? '').toString() == id);
    });

    await _persist();

    if (mounted) {
      _message('Note supprimée.');
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} • $hour:$minute';
  }

  String _noteDate(Map<String, dynamic> note) {
    final parsed = DateTime.tryParse(
      (note['updatedAt'] ?? note['createdAt'] ?? '').toString(),
    );

    if (parsed == null) return '';

    return _formatDateTime(parsed.toLocal());
  }

  String _preview(String text) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (clean.length <= 95) return clean;

    return '${clean.substring(0, 95)}…';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _soft,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leading: _editorVisible
            ? IconButton(
                tooltip: 'Retour aux notes',
                onPressed: _closeEditor,
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        title: Text(
          _editorVisible
              ? (_editingId == null ? 'Nouvelle note' : 'Modifier la note')
              : 'Bloc-note',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: _editorVisible
            ? null
            : <Widget>[
                IconButton(
                  tooltip: 'Nouvelle note',
                  onPressed: _newNote,
                  icon: const Icon(Icons.add_rounded, color: _blue, size: 27),
                ),
              ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _line),
        ),
      ),
      floatingActionButton: !_loading && !_editorVisible
          ? FloatingActionButton(
              onPressed: _newNote,
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              tooltip: 'Nouvelle note',
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _blue, strokeWidth: 2.2),
            )
          : SafeArea(
              top: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _editorVisible ? _editor() : _history(),
              ),
            ),
    );
  }

  Widget _history() {
    if (_notes.isEmpty) {
      return Center(
        key: const ValueKey<String>('notes-empty'),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF1FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.note_alt_outlined,
                  color: _blue,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucune note pour le moment',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: _navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Appuyez sur + pour écrire votre première note.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: _muted,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _newNote,
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Nouvelle note',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      key: const ValueKey<String>('notes-history'),
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Mes notes',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      color: _navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Text(
                  '${_notes.length} ${_notes.length == 1 ? 'note' : 'notes'}',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: _muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._notes.map((note) => _noteCard(note)),
          ],
        ),
      ),
    );
  }

  Widget _noteCard(Map<String, dynamic> note) {
    final title = (note['title'] ?? 'Sans sujet').toString();
    final text = (note['text'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _line),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x080D2340),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          // Cliquer sur le sujet/la carte ouvre directement la modification.
          onTap: () {
            _editNote(note);
          },
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 7, 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FF),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.description_outlined,
                    color: _blue,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          color: _navy,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _preview(text),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          color: _muted,
                          fontSize: 10.5,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: _muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _noteDate(note),
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              color: _muted,
                              fontSize: 9.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Options',
                  color: Colors.white,
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editNote(note);
                    }

                    if (value == 'delete') {
                      _deleteNote(note);
                    }
                  },
                  itemBuilder: (context) {
                    return const <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Color(0xFFB42318),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Supprimer',
                              style: TextStyle(color: Color(0xFFB42318)),
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _editor() {
    final editing = _editingId != null;

    return Align(
      key: ValueKey<String>(editing ? 'notes-editor-edit' : 'notes-editor-new'),
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 32),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    editing ? 'Modifier votre note' : 'Écrire une note',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      color: _navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    editing
                        ? 'Modifiez le sujet ou le contenu puis enregistrez.'
                        : 'Ajoutez un sujet pour retrouver facilement cette note.',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      color: _muted,
                      fontSize: 10.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      color: _navy,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Sujet',
                      hintText: 'Ex. Notes du culte de dimanche',
                      prefixIcon: const Icon(Icons.title_rounded, color: _navy),
                      filled: true,
                      fillColor: _soft,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _blue, width: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    child: TextField(
                      controller: _bodyController,
                      expands: true,
                      minLines: null,
                      maxLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: _navy,
                        fontSize: 13,
                        height: 1.55,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Écrivez votre note ici…',
                        filled: true,
                        fillColor: _soft,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _line),
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
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : _closeEditor,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _navy,
                            side: const BorderSide(color: _line),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Annuler',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: _blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: _saving
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded, size: 18),
                          label: Text(
                            editing
                                ? 'Enregistrer les modifications'
                                : 'Enregistrer',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 10.8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (editing) ...<Widget>[
                    const SizedBox(height: 11),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Dernière modification : ${_noteDate(_notes.firstWhere((note) => (note['id'] ?? '').toString() == _editingId, orElse: () => <String, dynamic>{}))}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          color: _muted,
                          fontSize: 9.2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DON K-PAY
// ============================================================

class DonationPage extends StatefulWidget {
  const DonationPage({super.key});

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  static const String _historyKey = 'maranatha_don_history_v2';

  final TextEditingController _amount = TextEditingController();

  String _category = 'offrande';
  bool _busy = false;
  bool _checking = false;
  String _reference = '';
  String _status = '';
  List<Map<String, dynamic>> _history = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);

    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List && mounted) {
        setState(() {
          _history = decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(_history));
  }

  String _labelCategory(String value) {
    switch (value) {
      case 'dime':
        return 'Dîme';
      case 'don_mensuel':
        return 'Don mensuel';
      case 'don_volontaire':
        return 'Don volontaire';
      default:
        return 'Offrande';
    }
  }

  Future<void> _startPayment() async {
    final amount = int.tryParse(_amount.text.replaceAll(RegExp(r'[^0-9]'), ''));

    if (amount == null || amount < 500) {
      _message('Le montant minimum est de 500 CDF.');
      return;
    }

    setState(() {
      _busy = true;
      _status = '';
      _reference = '';
    });

    try {
      final response = await http
          .post(
            Uri.parse('$_apiRoot/dons/kpay/init'),
            headers: const <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(<String, dynamic>{
              'amount': amount,
              'category': _category,
            }),
          )
          .timeout(const Duration(seconds: 25));

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! Map || decoded['success'] != true) {
        throw Exception(
          decoded is Map
              ? (decoded['message'] ?? 'Paiement impossible').toString()
              : 'Paiement impossible',
        );
      }

      final reference = (decoded['reference'] ?? '').toString();
      final gateway = (decoded['gatewayUrl'] ?? '').toString();
      final uri = Uri.tryParse(gateway);

      if (reference.isEmpty || uri == null) {
        throw Exception('K-PAY n’a pas retourné une page de paiement.');
      }

      _history.insert(0, <String, dynamic>{
        'reference': reference,
        'amount': amount,
        'category': _category,
        'status': 'PENDING',
        'createdAt': DateTime.now().toIso8601String(),
      });

      await _saveHistory();

      if (!mounted) return;

      setState(() {
        _reference = reference;
        _status = 'PENDING';
      });

      await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
    } catch (error) {
      if (mounted) {
        _message(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _checkStatus([String? reference]) async {
    final ref = (reference ?? _reference).trim();
    if (ref.isEmpty) return;

    setState(() => _checking = true);

    try {
      final response = await http
          .get(
            Uri.parse('$_apiRoot/dons/kpay/status/${Uri.encodeComponent(ref)}'),
            headers: const <String, String>{'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! Map ||
          decoded['success'] != true ||
          decoded['donation'] is! Map) {
        throw Exception();
      }

      final donation = Map<String, dynamic>.from(decoded['donation'] as Map);
      final status = (donation['status'] ?? 'PENDING').toString().toUpperCase();

      for (var i = 0; i < _history.length; i++) {
        if (_history[i]['reference']?.toString() == ref) {
          _history[i] = <String, dynamic>{..._history[i], 'status': status};
        }
      }

      await _saveHistory();

      if (!mounted) return;

      setState(() => _status = status);

      _message(
        status == 'COMPLETED'
            ? 'Paiement confirmé. Merci pour votre don.'
            : 'Statut : $status',
      );
    } catch (_) {
      if (mounted) _message('Impossible de vérifier le paiement.');
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return const Color(0xFF16803D);
      case 'FAILED':
      case 'CANCELLED':
        return const Color(0xFFB42318);
      default:
        return const Color(0xFFB26A00);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text(
          'Faire un don',
          style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                color: const Color(0xFF10284A),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.volunteer_activism_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Soutenir l’Église Maranatha',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Paiement sécurisé via K-PAY.',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        color: Color(0xFFDCE6F8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Type de contribution',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          <String>[
                            'offrande',
                            'dime',
                            'don_mensuel',
                            'don_volontaire',
                          ].map((value) {
                            return ChoiceChip(
                              label: Text(_labelCategory(value)),
                              selected: _category == value,
                              onSelected: (_) {
                                setState(() => _category = value);
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Montant',
                        suffixText: 'CDF',
                        helperText: 'Minimum : 500 CDF',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _startPayment,
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.lock_rounded),
                        label: const Text(
                          'Continuer avec K-PAY',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    if (_reference.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        color: const Color(0xFFF6F8FC),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Référence : $_reference',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Statut : ${_status.isEmpty ? 'PENDING' : _status}',
                              style: TextStyle(
                                color: _statusColor(_status),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _checking
                                  ? null
                                  : () => _checkStatus(),
                              icon: _checking
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.refresh_rounded),
                              label: const Text('Vérifier le paiement'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_history.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Historique des dons',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10284A),
                  ),
                ),
                const SizedBox(height: 10),
                ..._history.take(10).map((item) {
                  final status = (item['status'] ?? 'PENDING').toString();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.white,
                    child: ListTile(
                      title: Text(
                        '${_labelCategory((item['category'] ?? '').toString())} • ${item['amount']} CDF',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text((item['reference'] ?? '').toString()),
                      trailing: TextButton(
                        onPressed: _checking
                            ? null
                            : () => _checkStatus(
                                (item['reference'] ?? '').toString(),
                              ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: _statusColor(status),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// COMMENTAIRE
// ============================================================

class CommentsPage extends StatefulWidget {
  const CommentsPage({super.key});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _message = TextEditingController();

  bool _sending = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _message.text.trim();
    if (message.isEmpty) return;

    setState(() => _sending = true);

    try {
      final response = await http
          .post(
            Uri.parse('$_apiRoot/comments'),
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(<String, dynamic>{
              'section': 'communaute',
              'type': 'commentaire',
              'nom': _name.text.trim().isEmpty
                  ? 'Utilisateur MARANATHA'
                  : _name.text.trim(),
              'telephone': _phone.text.trim(),
              'message': message,
              'texte': message,
              'commentaire': message,
              'source': 'application_flutter',
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception();
      }

      if (!mounted) return;

      _message.clear();

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Commentaire envoyé.')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Envoi impossible pour le moment.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text(
          'Commentaire',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _message,
                minLines: 6,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Votre commentaire',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: const Text('Envoyer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PARAMETRES
// ============================================================

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text(
          'Paramètres',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                tileColor: Colors.white,
                leading: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF003DF0),
                ),
                title: const Text(
                  'Mon profil',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfilePage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DEVENIR MEMBRE MODERNE
// ============================================================

void openMemberRegistration(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const MemberRegistrationPage()),
  );
}

class MemberRegistrationPage extends StatefulWidget {
  const MemberRegistrationPage({super.key});
  @override
  State<MemberRegistrationPage> createState() => _MemberRegistrationPageState();
}

class _MemberRegistrationPageState extends State<MemberRegistrationPage> {
  static const Color _blue = Color(0xFF0B5CFF);
  static const Color _navy = Color(0xFF102A56);
  static const Color _muted = Color(0xFF71809A);
  static const Color _line = Color(0xFFE2E9F3);
  static const Color _soft = Color(0xFFF6F8FC);
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _church = TextEditingController();
  final TextEditingController _residence = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _otherFunction = TextEditingController();
  int _step = 0;
  String _function = 'Fidèle';
  String _service = 'Oui';
  bool _sending = false;
  static const int _questionCount = 6;
  @override
  void dispose() {
    _fullName.dispose();
    _church.dispose();
    _residence.dispose();
    _phone.dispose();
    _otherFunction.dispose();
    super.dispose();
  }

  String get _name {
    return _fullName.text.trim();
  }

  String get _functionValue {
    if (_function == 'Autres') {
      return _otherFunction.text.trim();
    }
    return _function;
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  bool _validateStep() {
    switch (_step) {
      case 0:
        if (_fullName.text.trim().length < 2) {
          _message('Indiquez votre nom complet.');
          return false;
        }
        return true;
      case 1:
        if (_church.text.trim().isEmpty) {
          _message('Indiquez votre église de provenance.');
          return false;
        }
        return true;
      case 2:
        if (_residence.text.trim().isEmpty) {
          _message('Indiquez votre lieu de résidence.');
          return false;
        }
        return true;
      case 3:
        if (_function == 'Autres' && _otherFunction.text.trim().isEmpty) {
          _message('Précisez votre fonction.');
          return false;
        }
        return true;
      case 4:
        final phone = _phone.text.replaceAll(RegExp(r'[^0-9+]'), '');
        if (phone.length < 8) {
          _message('Indiquez un numéro de téléphone valide.');
          return false;
        }
        return true;
      case 5:
        if (_service.isEmpty) {
          _message('Choisissez une réponse.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (!_validateStep()) {
      return;
    }
    if (_step < _questionCount) {
      setState(() {
        _step += 1;
      });
    }
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step <= 0) {
      return;
    }
    setState(() {
      _step -= 1;
    });
  }

  Map<String, String> _splitName() {
    final parts = _name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return <String, String>{'nom': '', 'postNom': '', 'prenom': ''};
    }
    if (parts.length == 1) {
      return <String, String>{
        'nom': parts.first,
        'postNom': '',
        'prenom': parts.first,
      };
    }
    if (parts.length == 2) {
      return <String, String>{
        'nom': parts.first,
        'postNom': '',
        'prenom': parts.last,
      };
    }
    return <String, String>{
      'nom': parts.first,
      'postNom': parts.sublist(1, parts.length - 1).join(' '),
      'prenom': parts.last,
    };
  }

  Future<void> _submit() async {
    if (_sending) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
    });
    try {
      final names = _splitName();
      final response = await http
          .post(
            Uri.parse('$_apiRoot/membres'),
            headers: const <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(<String, dynamic>{
              'nom': names['nom'],
              'postNom': names['postNom'],
              'prenom': names['prenom'],
              'telephone': _phone.text.trim(),
              'adresse': _residence.text.trim(),
              'pays': 'RDC',
              'bio': [
                'Nom complet : $_name',
                'Église de provenance : ${_church.text.trim()}',
                'Fonction : $_functionValue',
                'Prêt à servir : $_service',
              ].join('\n'),
              'nomComplet': _name,
              'eglise': _church.text.trim(),
              'egliseProvenance': _church.text.trim(),
              'residence': _residence.text.trim(),
              'lieuResidence': _residence.text.trim(),
              'fonction': _functionValue,
              'pretAServir': _service == 'Oui',
              'source': 'application_flutter',
            }),
          )
          .timeout(const Duration(seconds: 20));
      Map<String, dynamic>? decoded;
      try {
        final raw = jsonDecode(utf8.decode(response.bodyBytes));
        if (raw is Map) {
          decoded = Map<String, dynamic>.from(raw);
        }
      } catch (_) {}
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error =
            decoded?['error']?.toString() ??
            decoded?['message']?.toString() ??
            'Impossible de terminer l’inscription.';
        throw Exception(error);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'maranatha_last_membership',
        jsonEncode(<String, dynamic>{
          'name': _name,
          'phone': _phone.text.trim(),
          'date': DateTime.now().toIso8601String(),
        }),
      );
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            icon: Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: Color(0xFFE9F1FF),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.check_circle_rounded,
                color: _blue,
                size: 38,
              ),
            ),
            title: Text(
              'Bienvenue, $_name !',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: _navy,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: const Text(
              'Votre inscription a bien été envoyée à CEMM Maranatha.\n\n'
              'L’administration pourra maintenant traiter votre demande.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Manrope',
                color: _muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: <Widget>[
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Terminer',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          );
        },
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      final value = error.toString().replaceFirst('Exception: ', '');
      _message(value);
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  String _stepTitle() {
    switch (_step) {
      case 0:
        return 'Quel est votre nom complet ?';
      case 1:
        return 'Quelle est votre église de provenance ?';
      case 2:
        return 'Quel est votre lieu de résidence ?';
      case 3:
        return 'Quelle est votre fonction dans l’église ?';
      case 4:
        return 'Quel est votre numéro de téléphone / WhatsApp ?';
      case 5:
        return 'Êtes-vous prêt(e) à servir Dieu dans la communauté ?';
      default:
        return 'Vérifiez vos informations';
    }
  }

  String _stepHelp() {
    switch (_step) {
      case 0:
        return 'Écrivez votre nom tel qu’il doit apparaître dans votre inscription.';
      case 1:
        return 'Indiquez l’église que vous fréquentez ou votre église de provenance.';
      case 2:
        return 'Indiquez votre commune, quartier ou avenue.';
      case 3:
        return 'Choisissez la fonction qui vous correspond.';
      case 4:
        return 'Utilisez de préférence un numéro WhatsApp actif.';
      case 5:
        return 'Votre réponse nous aidera à mieux vous accueillir.';
      default:
        return 'Relisez vos réponses avant de confirmer votre inscription.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _step >= _questionCount
        ? 1.0
        : (_step + 1) / _questionCount;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          'Devenir membre',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _line),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 34),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      _step >= _questionCount
                          ? 'Confirmation'
                          : 'Étape ${_step + 1} sur $_questionCount',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: _blue,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: _muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFE1E7F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(_blue),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _line),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x090D2340),
                        blurRadius: 14,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F1FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(_stepIcon(), color: _blue, size: 22),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _stepTitle(),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          color: _navy,
                          fontSize: 20,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _stepHelp(),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          color: _muted,
                          fontSize: 11.5,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _stepContent(),
                      const SizedBox(height: 24),
                      _actions(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _stepIcon() {
    switch (_step) {
      case 0:
        return Icons.person_outline_rounded;
      case 1:
        return Icons.church_outlined;
      case 2:
        return Icons.location_on_outlined;
      case 3:
        return Icons.work_outline_rounded;
      case 4:
        return Icons.phone_outlined;
      case 5:
        return Icons.volunteer_activism_outlined;
      default:
        return Icons.fact_check_outlined;
    }
  }

  Widget _stepContent() {
    switch (_step) {
      case 0:
        return _answerField(
          controller: _fullName,
          hint: 'Votre nom complet',
          icon: Icons.person_outline_rounded,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
        );
      case 1:
        return _answerField(
          controller: _church,
          hint: 'Nom de votre église',
          icon: Icons.church_outlined,
          textCapitalization: TextCapitalization.words,
        );
      case 2:
        return _answerField(
          controller: _residence,
          hint: 'Ex. Ibanda, Bukavu',
          icon: Icons.location_on_outlined,
          textCapitalization: TextCapitalization.words,
        );
      case 3:
        return _functionChoices();
      case 4:
        return _answerField(
          controller: _phone,
          hint: '+243 ...',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        );
      case 5:
        return _serviceChoices();
      default:
        return _summary();
    }
  }

  Widget _answerField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        fontFamily: 'Manrope',
        color: _navy,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      onSubmitted: (_) {
        _next();
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Manrope',
          color: Color(0xFF9AA7B9),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: _navy, size: 21),
        filled: true,
        fillColor: _soft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _blue, width: 1.4),
        ),
      ),
    );
  }

  Widget _functionChoices() {
    const roles = <String>[
      'Pasteur',
      'Évangéliste',
      'Musicien',
      'Diacre',
      'Fidèle',
      'Autres',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: roles.map((role) {
            final selected = role == _function;
            return ChoiceChip(
              label: Text(role),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _function = role;
                });
              },
              showCheckmark: true,
              selectedColor: const Color(0xFF0B5CFF),
              backgroundColor: Colors.white,
              side: BorderSide(color: selected ? _blue : _line),
              labelStyle: TextStyle(
                fontFamily: 'Manrope',
                color: selected ? Colors.white : _navy,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            );
          }).toList(),
        ),
        if (_function == 'Autres') ...<Widget>[
          const SizedBox(height: 12),
          _answerField(
            controller: _otherFunction,
            hint: 'Précisez votre fonction',
            icon: Icons.edit_outlined,
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ],
    );
  }

  Widget _serviceChoices() {
    return Column(
      children: <Widget>[
        _serviceOption(
          value: 'Oui',
          title: 'Oui, je suis prêt(e)',
          subtitle: 'Je souhaite participer et servir dans la communauté.',
          icon: Icons.favorite_outline_rounded,
        ),
        const SizedBox(height: 10),
        _serviceOption(
          value: 'Non',
          title: 'Pas pour le moment',
          subtitle: 'Je souhaite d’abord découvrir davantage la communauté.',
          icon: Icons.schedule_rounded,
        ),
      ],
    );
  }

  Widget _serviceOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _service == value;
    return Material(
      color: selected ? const Color(0xFFEAF1FF) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          setState(() {
            _service = value;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _blue : _line,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? _blue : const Color(0xFFF0F4FA),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: selected ? Colors.white : _navy,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: _navy,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: _muted,
                        fontSize: 9.8,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: _blue, size: 21),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summary() {
    return Container(
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: <Widget>[
          _summaryLine('Nom complet', _name, Icons.person_outline_rounded),
          _divider(),
          _summaryLine('Église', _church.text.trim(), Icons.church_outlined),
          _divider(),
          _summaryLine(
            'Résidence',
            _residence.text.trim(),
            Icons.location_on_outlined,
          ),
          _divider(),
          _summaryLine('Fonction', _functionValue, Icons.work_outline_rounded),
          _divider(),
          _summaryLine('Téléphone', _phone.text.trim(), Icons.phone_outlined),
          _divider(),
          _summaryLine(
            'Prêt à servir',
            _service,
            Icons.volunteer_activism_outlined,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, indent: 48, color: _line);
  }

  Widget _summaryLine(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: _blue, size: 19),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: _muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: _navy,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Row(
      children: <Widget>[
        if (_step > 0) ...<Widget>[
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _sending ? null : _back,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _navy,
                  side: const BorderSide(color: _line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Text(
                  'Retour',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: _step == 0 ? 1 : 2,
          child: SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _sending
                  ? null
                  : _step >= _questionCount
                  ? _submit
                  : _next,
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          _step >= _questionCount
                              ? 'Confirmer mon inscription'
                              : _step == 5
                              ? 'Voir le récapitulatif'
                              : 'Suivant',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_step < _questionCount) ...<Widget>[
                          const SizedBox(width: 7),
                          const Icon(Icons.arrow_forward_rounded, size: 17),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
