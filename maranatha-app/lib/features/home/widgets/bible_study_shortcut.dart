import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import 'home_shortcut.dart';

class BibleStudyShortcut extends StatelessWidget {
  const BibleStudyShortcut({super.key});
  @override
  Widget build(BuildContext context) {
    return HomeShortcut(
      icon: AppIcons.study,
      label: 'Étude biblique',
      onTap: () {},
    );
  }
}
