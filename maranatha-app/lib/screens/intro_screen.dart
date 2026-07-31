import 'package:flutter/material.dart';

import 'alarm_setup_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  static const Color _gold = Color(0xFFD5AE32);
  static const Color _navy = Color(0xFF03121E);

  double _progress = 0;
  bool _opening = false;

  Future<void> _openDashboard() async {
    if (_opening) return;

    setState(() {
      _opening = true;
      _progress = 1;
    });

    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, animation, __) => const AlarmSetupScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final offset = Tween<Offset>(
            begin: const Offset(-0.08, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/intro/intro_background.jpg',
            fit: BoxFit.cover,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.43, 0.73, 1],
                colors: [
                  Color(0x12000000),
                  Color(0x42000000),
                  Color(0xA6000000),
                  Color(0xF4000000),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
              child: Column(
                children: [
                  const Spacer(flex: 7),
                  const Text(
                    'Bienvenue dans l’église\nMaranatha',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      height: 1.12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      shadows: [
                        Shadow(
                          color: Color(0xB3000000),
                          blurRadius: 18,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                  _buildSwipeButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeButton() {
    const height = 64.0;
    const knobSize = 52.0;
    const margin = 6.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDistance = (constraints.maxWidth - knobSize - (margin * 2))
            .clamp(0.0, 1000.0)
            .toDouble();

        void updateProgress(double deltaX) {
          if (_opening || maxDistance <= 0) return;
          setState(() {
            _progress = (_progress - (deltaX / maxDistance))
                .clamp(0.0, 1.0)
                .toDouble();
          });
        }

        void finishSwipe() {
          if (_progress >= 0.62) {
            _openDashboard();
          } else {
            setState(() => _progress = 0);
          }
        }

        return Semantics(
          button: true,
          label: 'Glissez vers la gauche pour entrer dans Maranatha',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) => updateProgress(details.delta.dx),
            onHorizontalDragEnd: (_) => finishSwipe(),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(height / 2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.17),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 140),
                    opacity: (1 - (_progress * 1.5)).clamp(0.0, 1.0).toDouble(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 70),
                      child: Text(
                        'Glissez vers la gauche',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: _opening
                        ? const Duration(milliseconds: 240)
                        : Duration.zero,
                    curve: Curves.easeOutCubic,
                    top: margin,
                    right: margin + (_progress * maxDistance),
                    child: GestureDetector(
                      onTap: _openDashboard,
                      child: Container(
                        width: knobSize,
                        height: knobSize,
                        decoration: const BoxDecoration(
                          color: _gold,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x55000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: _opening
                              ? const SizedBox(
                                  key: ValueKey('loading'),
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: _navy,
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_back_rounded,
                                  key: ValueKey('arrow'),
                                  color: _navy,
                                  size: 28,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
