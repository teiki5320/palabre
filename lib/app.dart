import 'package:flutter/material.dart';

import 'ecrans/accueil.dart';
import 'ecrans/theme.dart';

/// L'application : le thème du jeu, et l'accueil pour commencer.
class AppPresident extends StatelessWidget {
  const AppPresident({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Palabre',
      debugShowCheckedModeBanner: false,
      theme: theme(),
      home: const AccueilEcran(),
    );
  }
}
