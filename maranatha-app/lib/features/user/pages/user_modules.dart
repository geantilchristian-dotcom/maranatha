import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../profile/pages/profile_page.dart';

const String _apiRoot = 'https://maranatha-1-k6ro.onrender.com/api';

// ============================================================
// BLOC-NOTE
// ============================================================
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});
  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  static const String _storageKey = 'maranatha_bloc_note';
  final TextEditingController _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _controller.text = prefs.getString(_storageKey) ?? '';
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _controller.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Note enregistrée')));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          'Bloc-note',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: <Widget>[
          IconButton(
            tooltip: 'Enregistrer',
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                autofocus: false,
                expands: true,
                minLines: null,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText: 'Écrivez vos notes ici...',
                  filled: true,
                  fillColor: Colors.white,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
    );
  }
}

// ============================================================
// DON
// ============================================================
class DonationPage extends StatefulWidget {
  const DonationPage({super.key});
  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  bool _loading = true;
  String _error = '';
  Map<String, dynamic> _data = <String, dynamic>{};
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final response = await http
          .get(Uri.parse('$_apiRoot/settings/don'))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        _data = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      _error = 'Impossible de récupérer les informations de don.';
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  String _read(String key) {
    return (_data[key] ?? '').toString().trim();
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copié')));
  }

  Widget _method(String title, String value, IconData icon) {
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE4E7EC)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFEFF2),
          child: Icon(icon, color: const Color(0xFFA20722)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: SelectableText(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        trailing: IconButton(
          tooltip: 'Copier',
          onPressed: () => _copy(value),
          icon: const Icon(Icons.copy_rounded),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bank = <String>[
      _read('nomBanque'),
      _read('nomTitulaire'),
      _read('numeroCompte'),
      _read('iban'),
      _read('bic'),
    ].where((item) => item.isNotEmpty).join('\n');
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Don', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: <Widget>[
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
              child: FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                _method('Airtel Money', _read('airtel'), Icons.phone_android),
                _method('Orange Money', _read('orange'), Icons.phone_android),
                _method(
                  'Vodacom / M-Pesa',
                  _read('vodacom'),
                  Icons.phone_android,
                ),
                _method('Banque', bank, Icons.account_balance_rounded),
                if (_read('instructions').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _read('instructions'),
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
              ],
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
    final text = _message.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Écrivez votre commentaire.')),
      );
      return;
    }
    setState(() {
      _sending = true;
    });
    bool success = false;
    final body = <String, dynamic>{
      'section': 'communaute',
      'type': 'commentaire',
      'nom': _name.text.trim().isEmpty
          ? 'Utilisateur MARANATHA'
          : _name.text.trim(),
      'telephone': _phone.text.trim(),
      'message': text,
      'texte': text,
      'commentaire': text,
      'source': 'application_flutter',
    };
    try {
      final response = await http
          .post(
            Uri.parse('$_apiRoot/comments'),
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));
      success = response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {}
    if (!success) {
      try {
        final response = await http
            .post(
              Uri.parse('$_apiRoot/admin-inbox/public'),
              headers: const <String, String>{
                'Content-Type': 'application/json',
              },
              body: jsonEncode(<String, dynamic>{
                'nom': body['nom'],
                'telephone': body['telephone'],
                'message': '[COMMENTAIRE] $text',
              }),
            )
            .timeout(const Duration(seconds: 12));
        success = response.statusCode >= 200 && response.statusCode < 300;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
    });
    if (success) {
      _message.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Commentaire envoyé.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Envoi impossible pour le moment.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          'Commentaire',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: <Widget>[
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
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
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
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          'Paramètres',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            elevation: 0,
            color: Colors.white,
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
              title: const Text(
                'Compte et identité',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Modifier vos informations personnelles'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Card(
            elevation: 0,
            color: Colors.white,
            child: ListTile(
              leading: CircleAvatar(child: Icon(Icons.info_outline_rounded)),
              title: Text(
                'MARANATHA',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('Application CEMM MARANATHA'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DEVENIR MEMBRE
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
  int _step = 0;
  bool _sending = false;
  final _prenom = TextEditingController();
  final _postNom = TextEditingController();
  final _nom = TextEditingController();
  final _eglise = TextEditingController();
  final _residence = TextEditingController();
  final _fonction = TextEditingController();
  final _fonctionAutre = TextEditingController();
  final _telephone = TextEditingController();
  bool _pretAServir = true;
  @override
  void dispose() {
    _prenom.dispose();
    _postNom.dispose();
    _nom.dispose();
    _eglise.dispose();
    _residence.dispose();
    _fonction.dispose();
    _fonctionAutre.dispose();
    _telephone.dispose();
    super.dispose();
  }

  void _error(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  bool _validateStep() {
    switch (_step) {
      case 0:
        if (_prenom.text.trim().isEmpty || _nom.text.trim().isEmpty) {
          _error('Complétez votre prénom et votre nom.');
          return false;
        }
        return true;
      case 1:
        if (_eglise.text.trim().isEmpty) {
          _error('Indiquez votre église de provenance.');
          return false;
        }
        return true;
      case 2:
        if (_residence.text.trim().isEmpty) {
          _error('Indiquez votre lieu de résidence.');
          return false;
        }
        return true;
      case 3:
        if (_fonction.text.trim().isEmpty) {
          _error('Indiquez votre fonction ou service.');
          return false;
        }
        return true;
      case 4:
        if (_telephone.text.trim().isEmpty) {
          _error('Indiquez votre numéro de téléphone.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _next() async {
    if (_step < 5) {
      if (!_validateStep()) return;
      setState(() {
        _step++;
      });
      return;
    }
    await _submit();
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _step--;
    });
  }

  Future<void> _submit() async {
    if (_sending) return;
    setState(() {
      _sending = true;
    });
    final record = <String, dynamic>{
      'prenom': _prenom.text.trim(),
      'postNom': _postNom.text.trim(),
      'nom': _nom.text.trim(),
      'egliseProvenance': _eglise.text.trim(),
      'eglise': _eglise.text.trim(),
      'lieuResidence': _residence.text.trim(),
      'residence': _residence.text.trim(),
      'fonction': _fonction.text.trim(),
      'fonctionAutre': _fonctionAutre.text.trim(),
      'telephone': _telephone.text.trim(),
      'pretAServir': _pretAServir,
      'statut': 'en_attente',
      'source': 'application_flutter',
    };
    bool success = false;
    try {
      final response = await http
          .post(
            Uri.parse('$_apiRoot/membres'),
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(record),
          )
          .timeout(const Duration(seconds: 15));
      success = response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _sending = false;
    });
    if (!success) {
      _error('Impossible d’envoyer la demande pour le moment.');
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A36A),
            size: 48,
          ),
          title: const Text('Demande envoyée'),
          content: const Text(
            'Votre demande a été transmise à l’église.',
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? type,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: _input(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          'Devenir membre',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _step,
            onStepTapped: (index) {
              if (index <= _step) {
                setState(() {
                  _step = index;
                });
              }
            },
            onStepContinue: _sending ? null : _next,
            onStepCancel: _sending ? null : _back,
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Row(
                  children: <Widget>[
                    FilledButton(
                      onPressed: _sending ? null : details.onStepContinue,
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_step == 5 ? 'ENVOYER' : 'CONTINUER'),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: _sending ? null : details.onStepCancel,
                      child: Text(_step == 0 ? 'ANNULER' : 'RETOUR'),
                    ),
                  ],
                ),
              );
            },
            steps: <Step>[
              Step(
                title: const Text('Identité'),
                isActive: _step >= 0,
                state: _step > 0 ? StepState.complete : StepState.indexed,
                content: Column(
                  children: <Widget>[
                    _field(_prenom, 'Prénom'),
                    _field(_postNom, 'Post-nom'),
                    _field(_nom, 'Nom'),
                  ],
                ),
              ),
              Step(
                title: const Text('Église'),
                isActive: _step >= 1,
                state: _step > 1 ? StepState.complete : StepState.indexed,
                content: _field(_eglise, 'Église de provenance'),
              ),
              Step(
                title: const Text('Résidence'),
                isActive: _step >= 2,
                state: _step > 2 ? StepState.complete : StepState.indexed,
                content: _field(_residence, 'Lieu de résidence'),
              ),
              Step(
                title: const Text('Fonction'),
                isActive: _step >= 3,
                state: _step > 3 ? StepState.complete : StepState.indexed,
                content: Column(
                  children: <Widget>[
                    _field(_fonction, 'Fonction ou service'),
                    _field(_fonctionAutre, 'Précision (facultatif)'),
                  ],
                ),
              ),
              Step(
                title: const Text('Contact'),
                isActive: _step >= 4,
                state: _step > 4 ? StepState.complete : StepState.indexed,
                content: Column(
                  children: <Widget>[
                    _field(
                      _telephone,
                      'Téléphone / WhatsApp',
                      type: TextInputType.phone,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Je suis prêt(e) à servir'),
                      value: _pretAServir,
                      onChanged: (value) {
                        setState(() {
                          _pretAServir = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Step(
                title: const Text('Confirmation'),
                isActive: _step >= 5,
                content: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${_prenom.text.trim()} '
                        '${_postNom.text.trim()} '
                        '${_nom.text.trim()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Église : ${_eglise.text.trim()}'),
                      Text('Résidence : ${_residence.text.trim()}'),
                      Text('Fonction : ${_fonction.text.trim()}'),
                      Text('Téléphone : ${_telephone.text.trim()}'),
                      Text('Prêt à servir : ${_pretAServir ? "Oui" : "Non"}'),
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
