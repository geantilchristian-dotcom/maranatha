import 'package:flutter/material.dart';

import 'bible_page.dart';

class BibleLoadingPage
    extends StatelessWidget {
  const BibleLoadingPage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    /*
     * BiblePage possÃ¨de maintenant son propre squelette.
     * Aucun Ã©cran blanc ni dÃ©lai artificiel ici.
     */
    return const BiblePage();
  }
}
