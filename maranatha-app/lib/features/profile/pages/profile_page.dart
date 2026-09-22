import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/profile_repository.dart';
import '../data/public_config_repository.dart';

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
  bool _notifications = true;
  bool _reducedMotion = false;
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
    final notifications = await ProfileRepository.instance
        .notificationsEnabled();
    final reducedMotion = await ProfileRepository.instance.reducedMotion();
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
      _notifications = notifications;
      _reducedMotion = reducedMotion;
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

  Future<void> _setNotifications(bool value) async {
    await ProfileRepository.instance.setNotificationsEnabled(value);
    if (!mounted) {
      return;
    }
    setState(() {
      _notifications = value;
    });
  }

  Future<void> _setReducedMotion(bool value) async {
    await ProfileRepository.instance.setReducedMotion(value);
    if (!mounted) {
      return;
    }
    setState(() {
      _reducedMotion = value;
    });
  }

  Future<void> _downloadApp() async {
    var url = _config.apkUrl.trim();
    if (url.isEmpty) {
      url = '/downloads/MARANATHA.apk';
    }
    if (url.startsWith('/')) {
      url = '${PublicConfigRepository.baseUrl}$url';
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _message('Lien de telechargement invalide.');
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      _message('Impossible d ouvrir le telechargement.');
    }
  }

  Future<void> _openDocument(
    String title,
    String content, {
    bool support = false,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return _ProfileDocumentPage(
            title: title,
            content: content,
            config: _config,
            support: support,
          );
        },
      ),
    );
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
                          const SizedBox(height: 22),
                          const _SectionTitle(value: 'Parametres'),
                          const SizedBox(height: 8),
                          _generalSettings(),
                          const SizedBox(height: 14),
                          _audioSettings(),
                          const SizedBox(height: 14),
                          _applicationSettings(),
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

  Widget _generalSettings() {
    return _SettingsGroup(
      children: [
        _SwitchRow(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Recevoir les alertes MARANATHA',
          value: _notifications,
          onChanged: _setNotifications,
        ),
        const Divider(height: 1, color: _border),
        _SwitchRow(
          icon: Icons.motion_photos_off_outlined,
          title: 'Reduire les animations',
          subtitle: 'Limiter les mouvements de l interface',
          value: _reducedMotion,
          onChanged: _setReducedMotion,
        ),
      ],
    );
  }

  Widget _audioSettings() {
    return const _SettingsGroup(
      children: [
        _InfoRow(
          icon: Icons.alarm_outlined,
          title: 'Reveil Maranatha',
          value: 'Automatique',
        ),
        Divider(height: 1, color: _border),
        _InfoRow(
          icon: Icons.volume_up_outlined,
          title: 'Audio en arriere-plan',
          value: 'Actif',
        ),
      ],
    );
  }

  Widget _applicationSettings() {
    return _SettingsGroup(
      children: [
        _ActionRow(
          icon: Icons.download_outlined,
          title: 'Telecharger l application',
          onTap: _downloadApp,
        ),
        const Divider(height: 1, color: _border),
        _ActionRow(
          icon: Icons.shield_outlined,
          title: 'Confidentialite et donnees',
          onTap: () {
            _openDocument('Confidentialite et donnees', _config.privacy);
          },
        ),
        const Divider(height: 1, color: _border),
        _ActionRow(
          icon: Icons.description_outlined,
          title: 'Conditions d utilisation',
          onTap: () {
            _openDocument('Conditions d utilisation', _config.terms);
          },
        ),
        const Divider(height: 1, color: _border),
        _ActionRow(
          icon: Icons.support_agent_outlined,
          title: 'Aide et support',
          onTap: () {
            _openDocument('Aide et support', _config.help, support: true);
          },
        ),
        const Divider(height: 1, color: _border),
        _ActionRow(
          icon: Icons.info_outline_rounded,
          title: 'A propos de Maranatha',
          onTap: () {
            final content = _config.about.isNotEmpty
                ? _config.about
                : _config.description;
            _openDocument('A propos de Maranatha', content);
          },
        ),
      ],
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.value});
  final String value;
  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        color: Color(0xFF10284A),
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(children: children),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF44536A)),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF10284A),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFB3BCC9),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF44536A)),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF10284A),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF239B56),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF44536A)),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF10284A),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF8995A7), fontSize: 9),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ProfileDocumentPage extends StatelessWidget {
  const _ProfileDocumentPage({
    required this.title,
    required this.content,
    required this.config,
    required this.support,
  });
  final String title;
  final String content;
  final MaranathaPublicConfig config;
  final bool support;
  Future<void> _openWhatsapp() async {
    final raw = config.supportWhatsapp.isNotEmpty
        ? config.supportWhatsapp
        : config.phone;
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      digits = '243${digits.substring(1)}';
    }
    if (digits.length == 9) {
      digits = '243$digits';
    }
    if (digits.isEmpty) {
      return;
    }
    await launchUrl(
      Uri.parse('https://wa.me/$digits'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayContent = content.trim().isEmpty
        ? 'Ce contenu n a pas encore ete publie par MARANATHA.'
        : content.trim();
    final supportEmail = config.supportEmail.isNotEmpty
        ? config.supportEmail
        : config.email;
    final supportPhone = config.supportWhatsapp.isNotEmpty
        ? config.supportWhatsapp
        : config.phone;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF10284A),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayContent,
                    style: const TextStyle(
                      color: Color(0xFF34445C),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  if (support &&
                      (supportPhone.isNotEmpty || supportEmail.isNotEmpty)) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'Contacter MARANATHA',
                      style: TextStyle(
                        color: Color(0xFF10284A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (supportPhone.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'WhatsApp : $supportPhone',
                        style: const TextStyle(
                          color: Color(0xFF66758A),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _openWhatsapp,
                        child: const Text('Ouvrir WhatsApp'),
                      ),
                    ],
                    if (supportEmail.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'E-mail : $supportEmail',
                        style: const TextStyle(
                          color: Color(0xFF66758A),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
