import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/profile_repository.dart';
import '../data/public_config_repository.dart';
import '../../settings/pages/settings_page.dart' as modern_settings;

Future<void> openProfilePage(BuildContext context) {
  return Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const ProfilePage()));
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color _blue = Color(0xFF003DF0);
  static const Color _navy = Color(0xFF10284A);
  static const Color _page = Color(0xFFF5F7FB);
  static const Color _border = Color(0xFFE1E7F0);
  final _nom = TextEditingController();
  final _postNom = TextEditingController();
  final _prenom = TextEditingController();
  final _telephone = TextEditingController();
  final _email = TextEditingController();
  final _adresse = TextEditingController();
  final _eglise = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  MaranathaProfileData _profile = const MaranathaProfileData();
  MaranathaPublicConfig _config = const MaranathaPublicConfig();
  bool _loading = true;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nom.dispose();
    _postNom.dispose();
    _prenom.dispose();
    _telephone.dispose();
    _email.dispose();
    _adresse.dispose();
    _eglise.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profile = await ProfileRepository.instance.load();
    final config = await PublicConfigRepository.instance.load();
    if (!mounted) {
      return;
    }
    _nom.text = profile.nom;
    _postNom.text = profile.postNom;
    _prenom.text = profile.prenom;
    _telephone.text = profile.telephone;
    _email.text = profile.email;
    _adresse.text = profile.adresse;
    _eglise.text = profile.eglise;
    setState(() {
      _profile = profile;
      _config = config;
      _loading = false;
    });
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 82,
      );
      if (file == null) {
        return;
      }
      final bytes = await file.readAsBytes();
      final base64 = base64Encode(bytes);
      final next = _profile.copyWith(photoBase64: base64);
      await ProfileRepository.instance.save(next);
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = next;
      });
    } catch (_) {
      _message('Impossible de charger cette photo.');
    }
  }

  Future<void> _saveProfile() async {
    if (_nom.text.trim().isEmpty) {
      _message('Le nom est obligatoire.');
      return;
    }
    if (_prenom.text.trim().isEmpty) {
      _message('Le prenom est obligatoire.');
      return;
    }
    if (_telephone.text.trim().isEmpty) {
      _message('Le telephone est obligatoire.');
      return;
    }
    setState(() {
      _saving = true;
    });
    final next = _profile.copyWith(
      nom: _nom.text.trim(),
      postNom: _postNom.text.trim(),
      prenom: _prenom.text.trim(),
      telephone: _telephone.text.trim(),
      email: _email.text.trim(),
      adresse: _adresse.text.trim(),
      eglise: _eglise.text.trim(),
    );
    await ProfileRepository.instance.save(next);
    if (!mounted) {
      return;
    }
    setState(() {
      _profile = next;
      _saving = false;
    });
    _message('Profil enregistre.');
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Deconnexion'),
          content: const Text('Voulez-vous vraiment vous deconnecter ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Se deconnecter'),
            ),
          ],
        );
      },
    );
    if (confirm != true) {
      return;
    }
    await ProfileRepository.instance.clearAccount();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _message(String value) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        title: const Text(
          'Mon profil',
          style: TextStyle(
            color: _navy,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        desktop ? 28 : 14,
                        20,
                        desktop ? 28 : 14,
                        50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _profileHeader(),
                          const SizedBox(height: 16),
                          _profileForm(desktop: desktop),
                          const SizedBox(height: 18),
                          _profileSettingsButton(),
                          const SizedBox(height: 18),
                          OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Se deconnecter'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFB4233C),
                              side: const BorderSide(color: Color(0xFFE8BCC4)),
                              minimumSize: const Size(double.infinity, 48),
                              shape: const RoundedRectangleBorder(),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _config.version.isEmpty
                                ? 'MARANATHA'
                                : 'MARANATHA - version ${_config.version}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF9AA5B4),
                              fontSize: 9,
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

  Widget _profileSettingsButton() {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const modern_settings.SettingsPage(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _border),
          ),
          child: const Row(
            children: <Widget>[
              CircleAvatar(
                radius: 21,
                backgroundColor: Color(0xFFEEF3FF),
                child: Icon(Icons.settings_outlined, color: _blue, size: 21),
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Paramètres de l’application',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        color: _navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Notifications, audio, téléchargement, confidentialité et plus',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        color: Color(0xFF71809A),
                        fontSize: 9.8,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Color(0xFF8A98AB)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickPhoto,
            child: _Avatar(profile: _profile),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile.fullName.isEmpty
                      ? 'Votre profil'
                      : _profile.fullName,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _profile.statut,
                  style: const TextStyle(
                    color: _blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: _pickPhoto,
                  child: const Text(
                    'Modifier la photo',
                    style: TextStyle(
                      color: _blue,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileForm({required bool desktop}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Informations personnelles',
            style: TextStyle(
              color: _navy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 17),
          if (desktop)
            Row(
              children: [
                Expanded(
                  child: _ProfileField(label: 'Nom', controller: _nom),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileField(label: 'Post-nom', controller: _postNom),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileField(label: 'Prenom', controller: _prenom),
                ),
              ],
            )
          else ...[
            _ProfileField(label: 'Nom', controller: _nom),
            const SizedBox(height: 12),
            _ProfileField(label: 'Post-nom', controller: _postNom),
            const SizedBox(height: 12),
            _ProfileField(label: 'Prenom', controller: _prenom),
          ],
          const SizedBox(height: 12),
          _ProfileField(
            label: 'Telephone',
            controller: _telephone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _ProfileField(
            label: 'E-mail (facultatif)',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _ProfileField(label: 'Adresse (facultatif)', controller: _adresse),
          const SizedBox(height: 12),
          _ProfileField(
            label: 'Eglise / Assemblee (facultatif)',
            controller: _eglise,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _saving ? null : _saveProfile,
            style: FilledButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: const RoundedRectangleBorder(),
            ),
            child: _saving
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Enregistrer les modifications',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF66758A), fontSize: 10),
        filled: true,
        fillColor: const Color(0xFFF9FAFC),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFFE1E7F0)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFF003DF0)),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile});
  final MaranathaProfileData profile;
  @override
  Widget build(BuildContext context) {
    final bytes = _decode(profile.photoBase64);
    if (bytes != null) {
      return ClipOval(
        child: Image.memory(bytes, width: 72, height: 72, fit: BoxFit.cover),
      );
    }
    final letters =
        '${profile.prenom.isEmpty ? '' : profile.prenom[0]}'
                '${profile.nom.isEmpty ? '' : profile.nom[0]}'
            .toUpperCase();
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEEF3FF),
      ),
      child: letters.isEmpty
          ? const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFF003DF0),
              size: 31,
            )
          : Text(
              letters,
              style: const TextStyle(
                color: Color(0xFF003DF0),
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }

  Uint8List? _decode(String value) {
    if (value.isEmpty) {
      return null;
    }
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }
}
