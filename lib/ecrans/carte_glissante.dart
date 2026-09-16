import 'package:flutter/material.dart';

import '../moteur/partie.dart';

/// Une carte que l'on fait glisser à gauche ou à droite. Le geste est le seul
/// moyen de répondre : il n'y a pas de bouton.
class CarteGlissante extends StatefulWidget {
  const CarteGlissante({
    required Key key,
    required this.enfant,
    required this.onReponse,
    required this.onIntention,
    required this.libelleGauche,
    required this.libelleDroite,
  }) : super(key: key);

  final Widget enfant;

  /// Appelé une seule fois, quand le geste vaut réponse.
  final ValueChanged<Cote> onReponse;

  /// Appelé pendant le geste : le côté pressenti, ou null au centre.
  final ValueChanged<Cote?> onIntention;

  final String libelleGauche;
  final String libelleDroite;

  /// Fraction de la largeur au-delà de laquelle le geste vaut réponse.
  static const double seuil = 0.35;

  /// Fraction à partir de laquelle on annonce l'intention.
  static const double seuilIntention = 0.08;

  @override
  State<CarteGlissante> createState() => _CarteGlissanteState();
}

class _CarteGlissanteState extends State<CarteGlissante> with SingleTickerProviderStateMixin {
  double _dx = 0;
  double _largeur = 300;
  Cote? _intention;
  bool _sorti = false;

  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
        ..addListener(() {
          final t = _retour;
          if (t != null) setState(() => _dx = t.value);
        });
  Animation<double>? _retour;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _annonce(Cote? c) {
    if (c == _intention) return;
    _intention = c;
    widget.onIntention(c);
  }

  void _bouge(DragUpdateDetails d) {
    if (_sorti) return;
    setState(() => _dx += d.delta.dx);
    final part = _dx.abs() / _largeur;
    if (part < CarteGlissante.seuilIntention) {
      _annonce(null);
    } else {
      _annonce(_dx > 0 ? Cote.droite : Cote.gauche);
    }
  }

  void _lache(DragEndDetails d) {
    if (_sorti) return;
    final part = _dx.abs() / _largeur;
    if (part >= CarteGlissante.seuil) {
      final cote = _dx > 0 ? Cote.droite : Cote.gauche;
      _sorti = true;
      _annonce(null);
      _retour = Tween<double>(begin: _dx, end: _dx > 0 ? _largeur * 1.5 : -_largeur * 1.5)
          .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
      _anim.forward(from: 0).whenComplete(() => widget.onReponse(cote));
      return;
    }
    _annonce(null);
    _retour = Tween<double>(begin: _dx, end: 0).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      _largeur = c.maxWidth;
      final part = (_dx / _largeur).clamp(-1.0, 1.0);
      final visible = _dx.abs() / _largeur >= CarteGlissante.seuilIntention;
      return GestureDetector(
        onPanUpdate: _bouge,
        onPanEnd: _lache,
        child: Transform.translate(
          offset: Offset(_dx, 0),
          child: Transform.rotate(
            angle: part * 0.18,
            child: Stack(
              children: [
                Positioned.fill(child: widget.enfant),
                if (visible)
                  Positioned(
                    top: 18,
                    left: _dx > 0 ? 18 : null,
                    right: _dx > 0 ? null : 18,
                    child: _Etiquette(texte: _dx > 0 ? widget.libelleDroite : widget.libelleGauche),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _Etiquette extends StatelessWidget {
  const _Etiquette({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE9B44C), width: 3),
        borderRadius: BorderRadius.circular(8),
        color: Colors.black54,
      ),
      child: Text(
        texte,
        style: const TextStyle(color: Color(0xFFE9B44C), fontWeight: FontWeight.w800, letterSpacing: 1.2),
      ),
    );
  }
}
