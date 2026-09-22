import 'package:flutter/material.dart';

import '../moteur/pays.dart';
import 'theme.dart';

/// La carte du pays, en grand. Le jour ou la nuit selon l'heure du palais,
/// et les lieux qui s'allument à mesure qu'une carte les nomme.
///
/// L'image n'a pas un mot écrit dessus : les noms sont posés ici, donc ils
/// peuvent s'éteindre, et l'image de nuit se superpose exactement à celle
/// de jour — un fondu suffit à passer de l'une à l'autre.
class CartePaysEcran extends StatelessWidget {
  const CartePaysEcran({super.key, required this.nuit, required this.connus});

  final bool nuit;
  final Set<String> connus;

  static const String imageDuJour = 'assets/images/palais/carte/jour.jpg';
  static const String imageDeNuit = 'assets/images/palais/carte/nuit.jpg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Couleurs.nuit,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  children: [
                    Text(nuit ? 'LE PAYS, CETTE NUIT' : 'LE PAYS, AUJOURD\'HUI',
                        style: Textes.surtitre),
                    const Spacer(),
                    Text('${connus.length} / ${lieuxDuPays.length} LIEUX',
                        style: Textes.surtitre),
                  ],
                ),
              ),
              Expanded(child: Center(child: PlaqueDuPays(nuit: nuit, connus: connus))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Text('TOUCHER POUR REVENIR', style: Textes.surtitre),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La plaque elle-même, sans cadre ni habillage : elle sert en grand comme
/// en vignette au mur du bureau.
class PlaqueDuPays extends StatelessWidget {
  const PlaqueDuPays({
    super.key,
    required this.nuit,
    required this.connus,
    this.avecNoms = true,
  });

  final bool nuit;
  final Set<String> connus;

  /// Faux pour la vignette au mur : à cette taille, un nom serait illisible
  /// et brouillerait l'image.
  final bool avecNoms;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 2,
      child: LayoutBuilder(builder: (context, c) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(CartePaysEcran.imageDuJour, fit: BoxFit.cover),
            AnimatedOpacity(
              opacity: nuit ? 1 : 0,
              duration: const Duration(milliseconds: 900),
              child: Image.asset(CartePaysEcran.imageDeNuit, fit: BoxFit.cover),
            ),
            if (avecNoms)
              for (final lieu in lieuxDuPays)
                if (connus.contains(lieu.id))
                  Positioned(
                    left: lieu.x * c.maxWidth - 90,
                    top: lieu.y * c.maxHeight - 26,
                    width: 180,
                    child: _Etiquette(lieu: lieu),
                  ),
          ],
        );
      }),
    );
  }
}

class _Etiquette extends StatelessWidget {
  const _Etiquette({required this.lieu});

  final Lieu lieu;

  @override
  Widget build(BuildContext context) {
    final capitale = lieu.taille == TailleDuNom.capitale;
    final quartier = lieu.taille == TailleDuNom.quartier;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: capitale ? 11 : (quartier ? 13 : 7),
          height: capitale ? 11 : (quartier ? 13 : 7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: quartier ? Colors.transparent : (capitale ? Couleurs.creme : Couleurs.or),
            border: quartier
                ? Border.all(color: Couleurs.or.withValues(alpha: .85), width: 1.5)
                : null,
            boxShadow: quartier
                ? null
                : [
                    BoxShadow(
                      color: (capitale ? Couleurs.or : Couleurs.or).withValues(alpha: .35),
                      blurRadius: 6,
                      spreadRadius: 3,
                    ),
                    const BoxShadow(color: Colors.black87, blurRadius: 5),
                  ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          lieu.nom.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: capitale ? Polices.titre : Polices.corps,
            fontSize: capitale ? 14 : (quartier ? 9.5 : 10.5),
            fontWeight: capitale ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: capitale ? 2.6 : 1.4,
            color: quartier ? Couleurs.or : Couleurs.creme,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
              Shadow(color: Colors.black87, blurRadius: 10),
            ],
          ),
        ),
      ],
    );
  }
}
