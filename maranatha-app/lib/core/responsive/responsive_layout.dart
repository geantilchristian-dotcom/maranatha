import 'package:flutter/material.dart';

import 'app_breakpoints.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= AppBreakpoints.desktopMin) {
          return desktop;
        }
        if (width >= AppBreakpoints.tabletMin) {
          return tablet;
        }
        return mobile;
      },
    );
  }
}
