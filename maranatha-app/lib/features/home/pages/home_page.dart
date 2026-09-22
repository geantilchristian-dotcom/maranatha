import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_layout.dart';
import '../desktop/home_desktop.dart';
import '../mobile/home_mobile.dart';
import '../tablet/home_tablet.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: HomeMobile(),
      tablet: HomeTablet(),
      desktop: HomeDesktop(),
    );
  }
}
