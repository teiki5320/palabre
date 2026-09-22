import 'dart:async';

import 'package:flutter/material.dart';

import 'theme.dart';

/// Le quotidien du lendemain, en plein écran, entre la réponse et la carte
/// suivante.
///
/// Il était écrit sous la carte du jour, donc on le lisait distraitement
/// ou pas du tout : la conséquence de la veille arrivait sous la question
/// du lendemain, et les deux se gênaient. Ici il a l'écran pour lui, et
/// rien n'avance tant qu'on ne touche pas.
///
/// Ce n'est pas lu, c'est entendu : le journal de six heures, la station,
/// l'onde qui bouge, et la phrase posée en grand.
class QuotidienEcran extends StatefulWidget {
  const QuotidienEcran({
    super.key,
    required this.jour,
    required this.ligne,
    required this.onFini,
  });

  /// Le jour qui commence — celui de la carte qui suit, pas celui qu'on
  /// vient de jouer.
  final int jour;

  /// La brève. Jamais vide : l'écran ne s'ouvre pas quand il n'y a rien.
  final String ligne;

  final VoidCallback onFini;

  /// Le temps que met la phrase à s'écrire. Un appui la termine d'un coup.
  static const parCaractere = Duration(milliseconds: 9);

  @override
  State<QuotidienEcran> createState() => _QuotidienEcranState();
}

class _QuotidienEcranState extends State<QuotidienEcran> with SingleTickerProviderStateMixin {
  Timer? _frappe;
  int _jusqua = 0;

  late final AnimationController _onde =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void initState() {
    super.initState();
    _frappe = Timer.periodic(QuotidienEcran.parCaractere, (t) {
      if (!mounted) return t.cancel();
      setState(() => _jusqua++);
      if (_jusqua >= widget.ligne.length) t.cancel();
    });
  }

  @override
  void dispose() {
    _frappe?.cancel();
    _onde.dispose();
    super.dispose();
  }

  bool get _fini => _jusqua >= widget.ligne.length;

  void _touche() {
    if (!_fini) {
      _frappe?.cancel();
      setState(() => _jusqua = widget.ligne.length);
      return;
    }
    widget.onFini();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Couleurs.nuit,
      body: GestureDetector(
        onTap: _touche,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -1),
              radius: 1.3,
              colors: [Color(0xFF241F2C), Couleurs.nuit],
              stops: [0, .62],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Le jour en haut, comme sur l'écran des cartes : on sait
                  // tout de suite de quel matin on parle.
                  Row(
                    children: [
                      Text('JOUR ${widget.jour}', style: Textes.jour),
                      const Spacer(),
                      Text('06 H 00', style: Textes.surtitre),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      const _Pastille(),
                      const SizedBox(width: 9),
                      Text('RADIO NATIONALE · LE JOURNAL', style: Textes.surtitre),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(height: 46, child: _Onde(anim: _onde, vivante: !_fini)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Text(
                          widget.ligne.substring(0, _jusqua.clamp(0, widget.ligne.length)),
                          style: Textes.texteQuotidien,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: AnimatedOpacity(
                      opacity: _fini ? 1 : 0,
                      duration: const Duration(milliseconds: 260),
                      child: Text('TOUCHER POUR CONTINUER', style: Textes.surtitre),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Le point rouge de l'antenne.
class _Pastille extends StatefulWidget {
  const _Pastille();

  @override
  State<_Pastille> createState() => _PastilleState();
}

class _PastilleState extends State<_Pastille> with SingleTickerProviderStateMixin {
  late final AnimationController _a =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, _) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Couleurs.chair.withValues(alpha: .45 + .55 * _a.value),
          boxShadow: [
            BoxShadow(color: Couleurs.chair.withValues(alpha: .5 * _a.value), blurRadius: 10),
          ],
        ),
      ),
    );
  }
}

/// L'onde de la station : vingt-deux barres qui respirent, et qui
/// s'aplatissent quand la brève est finie de dire.
class _Onde extends StatelessWidget {
  const _Onde({required this.anim, required this.vivante});

  final AnimationController anim;
  final bool vivante;

  static const int barres = 22;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) => Row(
        children: [
          for (var i = 0; i < barres; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: vivante ? 6 + 40 * _part(i) : 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Couleurs.or.withValues(alpha: vivante ? .95 : .3),
                      Couleurs.or.withValues(alpha: .22),
                    ],
                  ),
                ),
              ),
            ),
            if (i < barres - 1) const SizedBox(width: 3),
          ],
        ],
      ),
    );
  }

  /// La hauteur d'une barre : une onde décalée d'une barre à l'autre, pour
  /// que ça ondule au lieu de clignoter ensemble.
  double _part(int i) {
    final t = (anim.value + i / barres) % 1;
    return .12 + .88 * (t < .5 ? t * 2 : (1 - t) * 2);
  }
}
