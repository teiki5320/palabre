import 'package:flutter/material.dart';

/// La palette du jeu. Une seule couleur d'accent, l'or : elle ne sert qu'à
/// dire « c'est ici que ça se joue » (la selection, l'etiquette de reponse,
/// la jauge visee). Tout le reste est nuit et creme.
abstract final class Couleurs {
  /// Fond de tout ecran, et fond d'une carte.
  static const nuit = Color(0xFF14131A);

  /// Panneaux, carte suivante, tirette de vignettes.
  static const nuitClair = Color(0xFF1C1A23);

  /// Bas du degrade pose sur les portraits.
  static const encre = Color(0xFF080709);

  /// L'accent unique.
  static const or = Color(0xFFE9B44C);

  /// Texte principal.
  static const creme = Color(0xFFF6EFE4);

  /// Texte secondaire pose sur une image.
  static const cremeDoux = Color(0xFFE3D9C9);

  /// Ce qu'on affiche a la place d'un portrait manquant.
  static const aplat = Color(0xFF26222E);

  /// Separateurs.

  /// Bordures et fond d'une jauge au repos.
  static const bordure = Color(0x2EFFFFFF);
}

/// Les deux familles embarquees dans `assets/polices/`. Elles sont livrees
/// avec l'application : le jeu doit s'afficher juste sans reseau.
abstract final class Polices {
  /// Titres et libelles forts.
  static const titre = 'Bricolage';

  /// Texte courant, jauges, boutons.
  static const corps = 'PublicSans';
}

/// L'echelle typographique des maquettes, nommee une fois pour toutes.
/// Chaque style porte deja sa couleur par defaut ; `copyWith` sert aux
/// variantes d'etat (une jauge visee passe en or, un libelle inactif
/// s'efface).
abstract final class Textes {
  /// Le nom du parcours, plein cadre sur son portrait.
  static const nomParcours = TextStyle(
    fontFamily: Polices.titre,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.02,
    letterSpacing: -0.4,
    color: Couleurs.creme,
  );

  /// Le meme, sur un ecran court.
  static const nomParcoursCourt = TextStyle(
    fontFamily: Polices.titre,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.02,
    letterSpacing: -0.4,
    color: Couleurs.creme,
  );

  /// « QUI ETIEZ-VOUS AVANT ? », et le compteur de pages.
  static const surtitre = TextStyle(
    fontFamily: Polices.corps,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.8,
    color: Couleurs.or,
  );

  /// La ligne sous le nom du parcours.
  static const sousTitre = TextStyle(
    fontFamily: Polices.corps,
    fontSize: 14,
    height: 1.35,
    color: Color(0xA6F6EFE4),
  );

  /// Le nom d'une jauge, au-dessus de sa barre.
  static const nomJauge = TextStyle(
    fontFamily: Polices.corps,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: Color(0x99F6EFE4),
  );

  /// « +12 » ou « −12 » sous une jauge visee.
  static const deltaJauge = TextStyle(
    fontFamily: Polices.corps,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: Couleurs.or,
  );

  /// « JOUR 12 ».
  static const jour = TextStyle(
    fontFamily: Polices.titre,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.6,
    color: Couleurs.creme,
  );

  /// « election au jour 30 », a cote du jour.
  static const echeance = TextStyle(
    fontFamily: Polices.corps,
    fontSize: 11,
    color: Color(0x66F6EFE4),
  );

  /// Le titre du personnage, en haut du bandeau d'une carte.
  static const titrePersonnage = TextStyle(
    fontFamily: Polices.corps,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.8,
    color: Couleurs.or,
  );

  /// Ce que dit le personnage.
  static const texteCarte = TextStyle(
    fontFamily: Polices.corps,
    fontSize: 18,
    height: 1.38,
    color: Couleurs.creme,
  );

  /// L'etiquette qui apparait dans le coin pendant le geste.
  static const etiquette = TextStyle(
    fontFamily: Polices.corps,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.8,
    color: Couleurs.or,
  );

  /// Les deux reponses rappelees sous la carte, au repos.
  static const rappel = TextStyle(
    fontFamily: Polices.corps,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: Color(0x59F6EFE4),
  );

  /// Le bouton plein, nuit sur or.
  static const bouton = TextStyle(
    fontFamily: Polices.corps,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Couleurs.nuit,
  );
}

/// Le theme de l'application. Material n'y apporte plus ni teinte de
/// surface ni elevation : toutes les ombres du jeu sont ecrites a la main.
ThemeData theme() {
  const rayon = 14.0;
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: Couleurs.or,
    scaffoldBackgroundColor: Couleurs.nuit,
    fontFamily: Polices.corps,
  );
  return base.copyWith(
    canvasColor: Couleurs.nuit,
    cardTheme: const CardThemeData(surfaceTintColor: Colors.transparent, elevation: 0),
    dialogTheme: const DialogThemeData(surfaceTintColor: Colors.transparent),
    textTheme: base.textTheme.apply(
      fontFamily: Polices.corps,
      bodyColor: Couleurs.creme,
      displayColor: Couleurs.creme,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Couleurs.or,
        foregroundColor: Couleurs.nuit,
        disabledBackgroundColor: const Color(0x59E9B44C),
        disabledForegroundColor: const Color(0x9914131A),
        minimumSize: const Size.fromHeight(56),
        textStyle: Textes.bouton,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rayon)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Couleurs.or,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: Color(0x8CE9B44C)),
        textStyle: Textes.bouton.copyWith(color: Couleurs.or, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rayon)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x0AFFFFFF),
      hintStyle: const TextStyle(fontSize: 16, color: Color(0x73F6EFE4)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rayon),
        borderSide: const BorderSide(color: Couleurs.bordure),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rayon),
        borderSide: const BorderSide(color: Couleurs.bordure),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rayon),
        borderSide: const BorderSide(color: Couleurs.or, width: 1.5),
      ),
    ),
  );
}
