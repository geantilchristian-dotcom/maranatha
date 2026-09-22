import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const Color _blue = Color(0xFF0B5CFF);
  static const Color _navy = Color(0xFF102A56);
  static const Color _muted = Color(0xFF71809A);
  static const Color _line = Color(0xFFE2E9F3);
  static const String _downloadUrl =
      'https://cemm-eglisemaranatha.site/downloads/MARANATHA.apk';

  bool _reduceAnimations = false;
  bool _backgroundAudio = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _reduceAnimations = prefs.getBool('maranatha_reduce_animations') ?? false;
      _backgroundAudio = prefs.getBool('maranatha_background_audio') ?? true;
      _loading = false;
    });
  }

  Future<void> _setReduceAnimations(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('maranatha_reduce_animations', value);

    if (!mounted) return;

    setState(() {
      _reduceAnimations = value;
    });
  }

  Future<void> _setBackgroundAudio(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('maranatha_background_audio', value);

    if (!mounted) return;

    setState(() {
      _backgroundAudio = value;
    });
  }

  Future<void> _downloadApplication() async {
    final uri = Uri.parse(_downloadUrl);

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir le téléchargement.')),
      );
    }
  }

  void _showInfo({required String title, required String message}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: _navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: _muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          'Paramètres',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _line),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _blue, strokeWidth: 2.3),
            )
          : SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
                    children: <Widget>[
                      const Text(
                        'Personnalisez votre expérience',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          color: _muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _line),
                        ),
                        child: Column(
                          children: <Widget>[
                            _SettingSwitchTile(
                              icon: Icons.motion_photos_off_rounded,
                              title: 'Réduire les animations',
                              subtitle: 'Limiter les mouvements de l’interface',
                              value: _reduceAnimations,
                              onChanged: _setReduceAnimations,
                            ),
                            const Divider(height: 1, indent: 62, color: _line),
                            _SettingInfoTile(
                              icon: Icons.alarm_rounded,
                              title: 'Réveil Maranatha',
                              subtitle:
                                  'Recevez un rappel pour vos temps spirituels',
                              trailingText: 'Automatique',
                              onTap: () {
                                _showInfo(
                                  title: 'Réveil Maranatha',
                                  message: 'Le réveil automatique continue de fonctionner avec les réglages de MARANATHA.',
                                );
                              },
                            ),
                            const Divider(height: 1, indent: 62, color: _line),
                            _SettingSwitchTile(
                              icon: Icons.volume_up_rounded,
                              title: 'Audio en arrière-plan',
                              subtitle: 'Continuez à écouter pendant l’utilisation d’autres applications',
                              value: _backgroundAudio,
                              onChanged: _setBackgroundAudio,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: _downloadApplication,
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: <Color>[
                                  Color(0xFF0A49C9),
                                  Color(0xFF0B68FF),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.fromLTRB(16, 14, 12, 14),
                              child: Row(
                                children: <Widget>[
                                  _BlueDownloadIcon(),
                                  SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          'Télécharger l’application',
                                          style: TextStyle(
                                            fontFamily: 'Manrope',
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.15,
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          'Obtenez la dernière version de CEMM Maranatha',
                                          style: TextStyle(
                                            fontFamily: 'Manrope',
                                            color: Color(0xFFE7F0FF),
                                            fontSize: 10.2,
                                            height: 1.25,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _line),
                        ),
                        child: Column(
                          children: <Widget>[
                            _SettingInfoTile(
                              icon: Icons.shield_outlined,
                              title: 'Confidentialité et données',
                              subtitle: 'Découvrez comment nous protégeons vos informations',
                              onTap: () {
                                _showInfo(
                                  title: 'Confidentialité et données',
                                  message: 'Vos informations sont utilisées pour les services de MARANATHA et la gestion de votre compte.',
                                );
                              },
                            ),
                            const Divider(height: 1, indent: 62, color: _line),
                            _SettingInfoTile(
                              icon: Icons.description_outlined,
                              title: 'Conditions d’utilisation',
                              subtitle:
                                  'Consultez nos conditions d’utilisation',
                              onTap: () {
                                _showInfo(
                                  title: 'Conditions d’utilisation',
                                  message: 'Les conditions complètes pourront être publiées ici depuis l’administration.',
                                );
                              },
                            ),
                            const Divider(height: 1, indent: 62, color: _line),
                            _SettingInfoTile(
                              icon: Icons.support_agent_rounded,
                              title: 'Aide et support',
                              subtitle:
                                  'Obtenez de l’aide ou contactez notre équipe',
                              onTap: () {
                                _showInfo(
                                  title: 'Aide et support',
                                  message: 'Pour l’assistance, utilisez les moyens de contact officiels de CEMM Maranatha.',
                                );
                              },
                            ),
                            const Divider(height: 1, indent: 62, color: _line),
                            _SettingInfoTile(
                              icon: Icons.info_outline_rounded,
                              title: 'À propos de Maranatha',
                              subtitle:
                                  'Version, crédits et plus d’informations',
                              onTap: () {
                                _showInfo(
                                  title: 'À propos de Maranatha',
                                  message: 'MARANATHA — application officielle de CEMM Maranatha.',
                                );
                              },
                            ),
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
}

class _SettingSwitchTile extends StatelessWidget {
  const _SettingSwitchTile({
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
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: Row(
        children: <Widget>[
          _SettingIcon(icon: icon),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: _SettingsColors.navy,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: _SettingsColors.muted,
                    fontSize: 9.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.82,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: _SettingsColors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingInfoTile extends StatelessWidget {
  const _SettingInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: <Widget>[
              _SettingIcon(icon: icon),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: _SettingsColors.navy,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: _SettingsColors.muted,
                        fontSize: 9.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingText != null) ...<Widget>[
                const SizedBox(width: 8),
                Text(
                  trailingText!,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: Color(0xFF159447),
                    fontSize: 9.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8C9BB0),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FD),
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: _SettingsColors.navy, size: 20),
    );
  }
}

class _BlueDownloadIcon extends StatelessWidget {
  const _BlueDownloadIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0x2EFFFFFF),
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.download_rounded, color: Colors.white, size: 25),
    );
  }
}

class _SettingsColors {
  static const Color blue = Color(0xFF0B5CFF);
  static const Color navy = Color(0xFF102A56);
  static const Color muted = Color(0xFF71809A);
}
