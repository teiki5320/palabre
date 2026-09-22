import 'package:flutter/material.dart';

import '../moteur/ciel.dart';
import 'theme.dart';

export '../moteur/ciel.dart' show Astre, CielDuJour, cielDe;

/// Le hublot de la ligne du jour : un astre qui s'y lève et s'y couche.
///
/// Dix-neuf pixels, collés à « JOUR 17 ». Il est posé là où l'œil va déjà
/// chercher le temps, et nulle part dans l'image : un astre dans la carte
/// entre en concurrence avec le portrait, celui-ci n'y touche pas.
class CadranDuJour extends StatelessWidget {
  const CadranDuJour({super.key, required this.ciel});

  final CielDuJour ciel;

  /// Le hublot, et l'astre dedans.
  static const double cote = 19;
  static const double _astre = 9;

  /// La course, en fraction du hublot. L'astre sort par le bas au lever et
  /// au coucher : c'est ce qui fait sentir l'heure sans dessiner d'horizon.
  static const double _depart = .10;
  static const double _arrivee = .62;
  static const double _bas = .56;
  static const double _haut = .12;

  @override
  Widget build(BuildContext context) {
    final nuit = ciel.astre == Astre.lune;
    final x = cote * (_depart + (_arrivee - _depart) * ciel.course);
    final y = cote * (_bas - (_bas - _haut) * ciel.hauteur);
    return IgnorePointer(
      child: Container(
        width: cote,
        height: cote,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Couleurs.encre,
          border: Border.all(color: Couleurs.bordure),
        ),
        child: Stack(
          children: [
            Positioned(
              left: x,
              top: y,
              width: _astre,
              height: _astre,
              child: _Astre(nuit: nuit, phase: ciel.phase, hauteur: ciel.hauteur),
            ),
          ],
        ),
      ),
    );
  }
}

class _Astre extends StatelessWidget {
  const _Astre({required this.nuit, required this.phase, required this.hauteur});

  final bool nuit;
  final double phase;

  /// La lueur faiblit quand l'astre rase le bord du hublot.
  final double hauteur;

  @override
  Widget build(BuildContext context) {
    final force = .45 + .55 * hauteur;
    // La lueur est portée par un fond à part, en dehors du découpage de la
    // phase : dessinée sur le disque, elle serait rognée avec lui et la lune
    // n'éclairerait plus rien.
    final lueur = BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: (nuit ? const Color(0xFFF6EFE4) : Couleurs.or)
              .withValues(alpha: .45 * force),
          blurRadius: 7,
          spreadRadius: 1,
        ),
      ],
    );
    const disque = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-.35, -.4),
          colors: [Color(0xFFFBF6EC), Color(0xFFD8CFC0), Color(0xFFA79C8C)],
          stops: [0, .62, 1],
        ),
      ),
    );
    if (!nuit) {
      return DecoratedBox(
        decoration: lueur,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment(-.35, -.4),
              colors: [Color(0xFFFFE7A8), Couleurs.or, Color(0xFFC98B22)],
              stops: [0, .62, 1],
            ),
          ),
        ),
      );
    }
    // La phase : un second disque, couleur du hublot et de même taille, qui
    // découvre la lune en glissant vers la droite. Décalé d'une fraction de
    // sa propre largeur : zéro le couvre entièrement, un le sort du cadre.
    // C'est pour ça qu'il doit faire exactement la taille de la lune — plus
    // grand, aucun décalage ne la découvrirait jamais.
    return DecoratedBox(
      decoration: lueur,
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            disque,
            FractionalTranslation(
              translation: Offset(phase, 0),
              child: const DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, color: Couleurs.encre),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
