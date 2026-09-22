import 'package:flutter/material.dart';

import '../moteur/ciel.dart';
import 'theme.dart';

export '../moteur/ciel.dart' show Astre, CielDuJour, cielDe;

/// L'astre dans le ciel de la carte, et la lueur qu'il pose sur le portrait.
///
/// Il est posé entre l'image et le bandeau de texte : il éclaire le visage
/// sans jamais passer devant ce qui se dit. Sa course tient dans le tiers
/// haut de la carte, là où les portraits n'ont que du ciel ou du plafond.
class CielDeLaCarte extends StatelessWidget {
  const CielDeLaCarte({super.key, required this.ciel});

  final CielDuJour ciel;

  /// Où l'astre se lève et se couche, en fraction de la largeur. Il ne
  /// touche pas les bords : un astre coupé en deux par le cadre ne se lit
  /// pas comme un astre.
  static const double _lever = .15;
  static const double _coucher = .85;

  /// L'horizon et le zénith, en fraction de la hauteur.
  static const double _horizon = .30;
  static const double _zenith = .12;

  @override
  Widget build(BuildContext context) {
    final nuit = ciel.astre == Astre.lune;
    final x = _lever + (_coucher - _lever) * ciel.course;
    final y = _horizon - (_horizon - _zenith) * ciel.hauteur;
    // La lueur faiblit quand l'astre rase l'horizon : c'est ce qui fait
    // sentir le lever et le coucher sans montrer d'horizon.
    final force = .45 + .55 * ciel.hauteur;

    return LayoutBuilder(builder: (context, bornes) {
      final l = bornes.maxWidth, h = bornes.maxHeight;
      final taille = l * .105;
      final halo = l * .62;
      return IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              left: l * x - halo / 2,
              top: h * y - halo / 2,
              width: halo,
              height: halo,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (nuit ? const Color(0xFFD6E0FF) : Couleurs.or)
                          .withValues(alpha: (nuit ? .16 : .24) * force),
                      Colors.transparent,
                    ],
                    stops: const [0, .68],
                  ),
                ),
              ),
            ),
            Positioned(
              left: l * x - taille / 2,
              top: h * y - taille / 2,
              width: taille,
              height: taille,
              child: _Astre(nuit: nuit, phase: ciel.phase, force: force),
            ),
          ],
        ),
      );
    });
  }
}

class _Astre extends StatelessWidget {
  const _Astre({required this.nuit, required this.phase, required this.force});

  final bool nuit;
  final double phase;
  final double force;

  @override
  Widget build(BuildContext context) {
    final disque = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-.35, -.4),
          colors: nuit
              ? const [Color(0xFFFBF6EC), Color(0xFFD8CFC0), Color(0xFFA79C8C)]
              : const [Color(0xFFFFE7A8), Couleurs.or, Color(0xFFC98B22)],
          stops: const [0, .62, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: (nuit ? const Color(0xFFF6EFE4) : Couleurs.or)
                .withValues(alpha: .40 * force),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
    );
    if (!nuit) return disque;
    // La phase : un second disque, couleur du ciel, qui découvre la lune en
    // glissant. À la cinquième nuit il est sorti du cadre, et elle est pleine.
    return ClipOval(
      child: Stack(
        fit: StackFit.expand,
        children: [
          disque,
          FractionallySizedBox(
            widthFactor: 1.18,
            heightFactor: 1.18,
            alignment: Alignment(-1 + 2.4 * phase, 0),
            child: const DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, color: Couleurs.nuit),
            ),
          ),
        ],
      ),
    );
  }
}
