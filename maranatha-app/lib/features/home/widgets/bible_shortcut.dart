import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import 'home_shortcut.dart';

class BibleShortcut extends StatelessWidget {
  const BibleShortcut({super.key});
  @override
  Widget build(BuildContext context) {
    return HomeShortcut(
      icon: AppIcons.bible,
      label: 'Bible',
      primary: true,
      onTap: () {},
    );
  }
}
