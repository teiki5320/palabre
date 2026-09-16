import 'package:flutter/material.dart';

import 'ecrans/accueil.dart';

/// L'application : un thème sombre, et l'accueil pour commencer.
class AppPresident extends StatelessWidget {
  const AppPresident({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Palabre',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFE9B44C),
        brightness: Brightness.dark,
        // La nuit du jeu, la même que celle des cartes et du logo : sans ça,
        // Material teinte le fond en brun et le logo se détache en rectangle.
        scaffoldBackgroundColor: const Color(0xFF14131A),
      ),
      home: const AccueilEcran(),
    );
  }
}
