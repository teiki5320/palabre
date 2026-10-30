import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Ce que le jeu s'autorise de mémoire pour les images décodées.
///
/// Flutter en garde cent mégaoctets par défaut, un chiffre décidé pour un
/// téléphone confortable. Ici une seule plaque de palais pèse 15,7 Mo une
/// fois décodée, le bureau en affiche deux en fondu et le balcon garde une
/// boucle de six : le plafond par défaut laisse le jeu occuper autant de
/// mémoire que le système lui en prête, et sur un appareil d'entrée de
/// gamme — `minSdk` 24, donc deux gigaoctets sont dans la cible — c'est ce
/// qui le fait tuer en arrière-plan.
///
/// Quarante mégaoctets tiennent le bureau et sa carte au mur, ou une boucle
/// de balcon entière. Au-delà, Flutter rejette la plus ancienne et la
/// redécode si on y revient : une fraction de seconde de travail plutôt
/// qu'un risque d'être tué.
const int memoireDesImages = 40 * 1024 * 1024;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSizeBytes = memoireDesImages;
  runApp(const ProviderScope(child: AppPresident()));
}
