import 'package:flutter/material.dart';

import 'theme.dart';

/// La leçon du geste, sur la toute première carte d'un joueur.
///
/// L'intro l'a dit en mots ; ici on le montre sur la carte elle-même. Une
/// main traverse d'un bord à l'autre, les deux réponses sont découvertes —
/// elles n'apparaissent normalement que pendant le geste — et tout
/// s'efface au premier contact du doigt. Elle ne revient jamais.
class LeconDuGeste extends StatefulWidget {
  const LeconDuGeste({super.key, required this.gauche, required this.droite});

  final String gauche;
  final String droite;

  @override
  State<LeconDuGeste> createState() => _LeconDuGesteState();
}

class _LeconDuGesteState extends State<LeconDuGeste> with SingleTickerProviderStateMixin {
  /// Trois passages, puis la main s'arrête et les deux réponses restent
  /// lisibles. Une main qui balaie sans fin finirait par agacer, et rien
  /// à l'écran ne doit tourner indéfiniment sous les yeux du joueur.
  static const int tours = 3;

  late final AnimationController _a =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  int _fait = 0;

  @override
  void initState() {
    super.initState();
    _a.addStatusListener((etat) {
      if (etat != AnimationStatus.completed) return;
      _fait++;
      if (_fait < tours && mounted) _a.forward(from: 0);
    });
    _a.forward();
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _a,
        builder: (context, _) {
          // Un aller-retour : la main part du centre, va à droite, revient,
          // va à gauche, revient. On montre les deux côtés sans rien dire.
          final t = _a.value;
          final glisse = t < .5
              ? Curves.easeInOut.transform(_pic(t * 2))
              : -Curves.easeInOut.transform(_pic((t - .5) * 2));
          final vivacite = 1 - (glisse.abs() * .35);
          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Couleurs.encre.withValues(alpha: .55),
                        Couleurs.encre.withValues(alpha: .2),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                top: 22,
                child: Column(
                  children: [
                    Text('GLISSEZ POUR RÉPONDRE', style: Textes.surtitre),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Choix(texte: '← ${widget.gauche}', vif: glisse < -.1),
                        _Choix(texte: '${widget.droite} →', vif: glisse > .1),
                      ],
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment(glisse * .62, .52),
                child: Opacity(
                  opacity: vivacite,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Couleurs.creme.withValues(alpha: .13),
                      border: Border.all(color: Couleurs.creme.withValues(alpha: .5), width: 1.4),
                    ),
                    child: Icon(Icons.swipe_outlined,
                        color: Couleurs.creme.withValues(alpha: .92), size: 26),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Un aller-retour de 0 à 1 à 0, avec un temps d'arrêt aux deux bouts.
  double _pic(double t) {
    if (t < .25) return t * 4;
    if (t < .5) return 1;
    if (t < .75) return (.75 - t) * 4;
    return 0;
  }
}

class _Choix extends StatelessWidget {
  const _Choix({required this.texte, required this.vif});

  final String texte;
  final bool vif;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Couleurs.encre.withValues(alpha: vif ? .9 : .6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: vif ? Couleurs.or : Couleurs.bordure),
      ),
      child: Text(
        texte,
        style: Textes.surtitre.copyWith(color: vif ? Couleurs.or : Couleurs.cremeDoux),
      ),
    );
  }
}
