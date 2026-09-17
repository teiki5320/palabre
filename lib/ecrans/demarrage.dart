import 'package:flutter/material.dart';

import '../sauvegarde/sauvegarde.dart';
import 'accueil.dart';
import 'intro_ecran.dart';
import 'theme.dart';

/// Ce que l'application montre en s'ouvrant : l'intro au tout premier
/// lancement, l'accueil ensuite.
class Demarrage extends StatefulWidget {
  const Demarrage({super.key});

  @override
  State<Demarrage> createState() => _DemarrageState();
}

class _DemarrageState extends State<Demarrage> {
  /// null tant qu'on n'a pas lu l'appareil : on ne montre rien plutôt que de
  /// faire clignoter une intro à quelqu'un qui l'a déjà vue.
  bool? _introVue;

  @override
  void initState() {
    super.initState();
    Sauvegarde.introVue().then((vue) {
      if (mounted) setState(() => _introVue = vue);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vue = _introVue;
    if (vue == null) return const Scaffold(backgroundColor: Couleurs.nuit, body: SizedBox.shrink());
    if (vue) return const AccueilEcran();
    return IntroEcran(
      onFini: () {
        Sauvegarde.noteIntroVue();
        setState(() => _introVue = true);
      },
    );
  }
}
