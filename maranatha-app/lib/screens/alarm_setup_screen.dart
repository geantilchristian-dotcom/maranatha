import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import 'web_screen.dart';

class AlarmSetupScreen extends StatefulWidget {
  const AlarmSetupScreen({super.key});

  @override
  State<AlarmSetupScreen> createState() => _AlarmSetupScreenState();
}

class _AlarmSetupScreenState extends State<AlarmSetupScreen>
    with WidgetsBindingObserver {
  static const String _consentKey = 'maranatha_reveil_consentement';

  Map<String, bool> _permissions = const <String, bool>{};
  bool _accepted = false;
  bool _loading = true;
  bool _processing = false;
  bool _automaticNavigationDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshPermissions());
    }
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final accepted = preferences.getBool(_consentKey) ?? false;
    final permissions =
        await NotificationService.instance.obtenirEtatAutorisations();

    if (!mounted) return;

    setState(() {
      _accepted = accepted;
      _permissions = permissions;
      _loading = false;
    });

    if (accepted &&
        permissions['modeEnabled'] == true &&
        permissions['notifications'] == true &&
        permissions['exactAlarms'] == true) {
      _openDashboardAutomatically();
    }
  }

  Future<void> _refreshPermissions() async {
    final permissions =
        await NotificationService.instance.obtenirEtatAutorisations();
    if (!mounted) return;
    setState(() => _permissions = permissions);
  }

  void _openDashboardAutomatically() {
    if (_automaticNavigationDone || !mounted) return;
    _automaticNavigationDone = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const WebScreen()),
      );
    });
  }

  bool get _notifications => _permissions['notifications'] == true;
  bool get _exactAlarms => _permissions['exactAlarms'] == true;
  bool get _fullScreen => _permissions['fullScreen'] == true;
  bool get _battery => _permissions['battery'] == true;

  bool get _corePermissionsReady => _notifications && _exactAlarms;
  bool get _recommendedPermissionsMissing => !_fullScreen || !_battery;

  String get _buttonLabel {
    if (!_accepted) return 'Acceptez d’abord les conditions';
    if (!_notifications) return 'Autoriser les notifications';
    if (!_exactAlarms) return 'Autoriser les alarmes exactes';
    if (!_fullScreen) return 'Autoriser l’écran de réveil';
    if (!_battery) return 'Autoriser en arrière-plan';
    return 'Activer le réveil Maranatha';
  }

  Future<void> _activateAndOpen() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_consentKey, true);
    await NotificationService.instance.activerModeMaranatha();

    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const WebScreen()),
    );
  }

  Future<void> _continueWithoutRecommendedPermissions() async {
    if (!_accepted || !_corePermissionsReady || _processing) return;
    setState(() => _processing = true);
    try {
      await _activateAndOpen();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Activation impossible : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _continueSetup() async {
    if (!_accepted || _processing) return;

    setState(() => _processing = true);

    try {
      if (!_notifications) {
        await NotificationService.instance.demanderNotifications();
      } else if (!_exactAlarms) {
        await NotificationService.instance.demanderAlarmesExactes();
      } else if (!_fullScreen) {
        await NotificationService.instance.demanderPleinEcran();
      } else if (!_battery) {
        await NotificationService.instance.demanderExclusionBatterie();
      } else {
        await _activateAndOpen();
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 500));
      await _refreshPermissions();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Autorisation impossible : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _toggleConsent(bool? value) async {
    final accepted = value ?? false;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_consentKey, accepted);
    if (mounted) setState(() => _accepted = accepted);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF03121E),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD5AE32)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF03121E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.alarm_rounded,
                color: Color(0xFFD5AE32),
                size: 58,
              ),
              const SizedBox(height: 18),
              const Text(
                'Activer le réveil Maranatha',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'L’administrateur programme une prédication. À l’heure choisie, votre téléphone la démarre automatiquement comme un réveil.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFB8C3CD),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 26),
              _PermissionTile(
                icon: Icons.notifications_active_rounded,
                title: 'Notifications',
                subtitle: 'Affiche le réveil sur l’écran verrouillé.',
                granted: _notifications,
              ),
              _PermissionTile(
                icon: Icons.schedule_rounded,
                title: 'Alarmes exactes',
                subtitle: 'Déclenche la prédication à l’heure programmée.',
                granted: _exactAlarms,
              ),
              _PermissionTile(
                icon: Icons.phone_android_rounded,
                title: 'Écran de réveil',
                subtitle: 'Montre les boutons Arrêter et Rappeler.',
                granted: _fullScreen,
              ),
              _PermissionTile(
                icon: Icons.battery_saver_rounded,
                title: 'Fonctionnement en arrière-plan',
                subtitle: 'Évite que l’économie de batterie bloque le réveil.',
                granted: _battery,
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: CheckboxListTile(
                  value: _accepted,
                  onChanged: _toggleConsent,
                  activeColor: const Color(0xFFD5AE32),
                  checkColor: const Color(0xFF03121E),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'J’accepte que Maranatha programme et démarre automatiquement les prédications choisies par l’église.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _accepted && !_processing ? _continueSetup : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD5AE32),
                  foregroundColor: const Color(0xFF03121E),
                  disabledBackgroundColor: const Color(0xFF4D5660),
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                child: _processing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Color(0xFF03121E),
                        ),
                      )
                    : Text(
                        _buttonLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              if (_accepted &&
                  _corePermissionsReady &&
                  _recommendedPermissionsMissing) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _processing
                      ? null
                      : _continueWithoutRecommendedPermissions,
                  child: const Text(
                    'Continuer sans les autorisations recommandées',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFB8C3CD)),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Chaque autorisation est demandée une seule fois. Vous pourrez ensuite fermer l’application : l’alarme restera programmée dans Android.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF7F8C98),
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: granted
              ? const Color(0x5538C172)
              : Colors.white.withValues(alpha: 0.09),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFD5AE32).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: const Color(0xFFD5AE32), size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF93A0AC),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            granted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: granted ? const Color(0xFF38C172) : const Color(0xFF687683),
            size: 23,
          ),
        ],
      ),
    );
  }
}
