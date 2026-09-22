import 'package:flutter/material.dart';

enum AdminSection {
  dashboard,
  home,
  library,
  programme,
  direct,
  studies,
  prayers,
  members,
  donations,
  messages,
  notifications,
  settings,
}

extension AdminSectionData on AdminSection {
  String get title {
    switch (this) {
      case AdminSection.dashboard:
        return 'Tableau de bord';
      case AdminSection.home:
        return 'Page d accueil';
      case AdminSection.library:
        return 'Bibliotheque';
      case AdminSection.programme:
        return 'Programme';
      case AdminSection.direct:
        return 'Direct';
      case AdminSection.studies:
        return 'Etudes bibliques';
      case AdminSection.prayers:
        return 'Prieres';
      case AdminSection.members:
        return 'Membres';
      case AdminSection.donations:
        return 'Dons';
      case AdminSection.messages:
        return 'Messages';
      case AdminSection.notifications:
        return 'Notifications';
      case AdminSection.settings:
        return 'Parametres';
    }
  }

  String get description {
    switch (this) {
      case AdminSection.dashboard:
        return 'Vue generale de MARANATHA';
      case AdminSection.home:
        return 'Affiches, verset et contenus de l accueil';
      case AdminSection.library:
        return 'Livres, audios, videos et predications';
      case AdminSection.programme:
        return 'Calendrier et programmes de l eglise';
      case AdminSection.direct:
        return 'Predications programmees et diffusions';
      case AdminSection.studies:
        return 'Publications des etudes bibliques';
      case AdminSection.prayers:
        return 'Contenus et demandes de priere';
      case AdminSection.members:
        return 'Membres et demandes d adhesion';
      case AdminSection.donations:
        return 'Contributions et suivi des dons';
      case AdminSection.messages:
        return 'Commentaires et messages recus';
      case AdminSection.notifications:
        return 'Notifications envoyees aux fideles';
      case AdminSection.settings:
        return 'Configuration generale de MARANATHA';
    }
  }

  IconData get icon {
    switch (this) {
      case AdminSection.dashboard:
        return Icons.dashboard_outlined;
      case AdminSection.home:
        return Icons.home_outlined;
      case AdminSection.library:
        return Icons.collections_bookmark_outlined;
      case AdminSection.programme:
        return Icons.calendar_month_outlined;
      case AdminSection.direct:
        return Icons.podcasts_outlined;
      case AdminSection.studies:
        return Icons.school_outlined;
      case AdminSection.prayers:
        return Icons.volunteer_activism_outlined;
      case AdminSection.members:
        return Icons.groups_outlined;
      case AdminSection.donations:
        return Icons.payments_outlined;
      case AdminSection.messages:
        return Icons.forum_outlined;
      case AdminSection.notifications:
        return Icons.notifications_outlined;
      case AdminSection.settings:
        return Icons.settings_outlined;
    }
  }
}
