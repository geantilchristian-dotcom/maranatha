import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';

class MaranathaLogoAnimation extends StatelessWidget {
  const MaranathaLogoAnimation({super.key, required this.controller});
  final AnimationController controller;
  @override
  Widget build(BuildContext context) {
    final appear = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.48, curve: Curves.easeOutBack),
    );
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        final wave1 = 1.0 + (0.15 * t);
        final wave2 = 1.0 + (0.28 * t);
        final waveOpacity = (1.0 - t).clamp(0.0, 1.0);
        return SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Transform.scale(
                scale: wave2,
                child: Opacity(
                  opacity: waveOpacity * .16,
                  child: Container(
                    width: 222,
                    height: 222,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF0067FF),
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: wave1,
                child: Opacity(
                  opacity: waveOpacity * .28,
                  child: Container(
                    width: 222,
                    height: 222,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0067FF),
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ),
              ScaleTransition(
                scale: appear,
                child: Container(
                  width: 222,
                  height: 222,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Color(0xFF70A9FF),
                        Color(0xFF2477FF),
                        Color(0xFF004BE7),
                      ],
                    ),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x44004BE7),
                        blurRadius: 34,
                        spreadRadius: 7,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      AppAssets.appIcon,
                      width: 208,
                      height: 208,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
