import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maranatha/core/constants/app_assets.dart';

class MaranathaSplashBootstrap extends StatefulWidget {
  const MaranathaSplashBootstrap({
    super.key,
    required this.child,
    this.minimumDuration = const Duration(milliseconds: 3000),
  });
  final Widget child;
  final Duration minimumDuration;
  @override
  State<MaranathaSplashBootstrap> createState() =>
      _MaranathaSplashBootstrapState();
}

class _MaranathaSplashBootstrapState extends State<MaranathaSplashBootstrap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;
  Timer? _timer;
  bool _showSplash = true;
  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
    _timer = Timer(widget.minimumDuration, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showSplash = false;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_showSplash)
          Positioned.fill(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Material(
                color: Colors.white,
                child: _MaranathaSplashView(controller: _waveController),
              ),
            ),
          ),
      ],
    );
  }
}

class _MaranathaSplashView extends StatelessWidget {
  const _MaranathaSplashView({required this.controller});
  final AnimationController controller;
  static const Color _titleColor = Color(0xFF24282F);
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final width = media?.size.width ?? 430;
    final compact = width < 390;
    final logoSize = compact ? 150.0 : 190.0;
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AppAssets.appIcon,
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                SizedBox(height: compact ? 22 : 28),
                Text(
                  'CEMM EGLISE MARANATHA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _titleColor,
                    fontSize: compact ? 18 : 22,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 28),
                _WaterLoadingDots(controller: controller),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WaterLoadingDots extends StatelessWidget {
  const _WaterLoadingDots({required this.controller});
  final AnimationController controller;
  static const List<Color> _colors = <Color>[
    Color(0xFFE72B35),
    Color(0xFFFF8B22),
    Color(0xFFFFBD22),
    Color(0xFF39BE70),
    Color(0xFF2998EC),
  ];
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 46,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final time = controller.value * math.pi * 2;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_colors.length, (index) {
              final phase = index * 0.72;
              final wave = math.sin((time * 1.20) - phase);
              final secondWave = math.sin((time * 0.72) - phase);
              final vertical = wave * 8.0;
              final horizontal = secondWave * 1.7;
              final scale =
                  0.82 + ((math.cos((time * 1.20) - phase) + 1) / 2) * 0.28;
              final opacity =
                  0.55 + ((math.sin((time * 1.20) - phase) + 1) / 2) * 0.45;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Transform.translate(
                  offset: Offset(horizontal, vertical),
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: _WaterDot(color: _colors[index]),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _WaterDot extends StatelessWidget {
  const _WaterDot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.40),
          radius: 1.05,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            color.withValues(alpha: 0.94),
            color,
          ],
          stops: const <double>[0.0, 0.28, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.24),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),
    );
  }
}
