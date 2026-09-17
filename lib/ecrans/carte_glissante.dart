import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../moteur/partie.dart';
import 'theme.dart';

/// Une carte que l'on fait glisser à gauche ou à droite. Le geste est le seul
/// moyen de répondre : il n'y a pas de bouton.
class CarteGlissante extends StatefulWidget {
  const CarteGlissante({
    required Key key,
    required this.enfant,
    required this.onReponse,
    required this.onIntention,
    required this.onSortie,
    required this.libelleGauche,
    required this.libelleDroite,
  }) : super(key: key);

  final Widget enfant;

  /// Appelé une seule fois, quand le geste vaut réponse.
  final ValueChanged<Cote> onReponse;

  /// Appelé pendant le geste : le côté pressenti, ou null au centre.
  final ValueChanged<Cote?> onIntention;

  /// Appelé au départ de la carte, avant `onReponse` : c'est le moment où la
  /// carte suivante monte prendre sa place.
  final VoidCallback onSortie;

  final String libelleGauche;
  final String libelleDroite;

  /// Fraction de la largeur au-delà de laquelle le geste vaut réponse.
  static const double seuil = 0.35;

  /// Fraction à partir de laquelle on annonce l'intention.
  static const double seuilIntention = 0.08;

  /// Ce qui reste du geste une fois le seuil franchi. La carte freine sous le
  /// doigt : le joueur sent qu'il a dépassé le point de non-retour.
  static const double resistance = 0.6;

  /// Durée du retour au centre, et durée du départ.
  static const retour = Duration(milliseconds: 220);
  static const sortie = Duration(milliseconds: 260);

  @override
  State<CarteGlissante> createState() => _CarteGlissanteState();
}

class _CarteGlissanteState extends State<CarteGlissante> with SingleTickerProviderStateMixin {
  /// Ce que le doigt a parcouru, sans la résistance.
  double _dx = 0;
  double _largeur = 300;
  Cote? _intention;
  bool _sorti = false;

  late final AnimationController _anim = AnimationController(vsync: this, duration: CarteGlissante.retour)
    ..addListener(() {
      final t = _course;
      if (t != null) setState(() => _dx = t.value);
    });
  Animation<double>? _course;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  /// Le décalage réellement appliqué. Jusqu'au seuil, la carte suit le doigt ;
  /// au-delà elle freine. Pendant le départ, plus de freinage : l'animation
  /// donne directement la position.
  double get _decalage {
    if (_sorti) return _dx;
    final limite = _largeur * CarteGlissante.seuil;
    if (_dx.abs() <= limite) return _dx;
    return (limite + (_dx.abs() - limite) * CarteGlissante.resistance) * (_dx.isNegative ? -1 : 1);
  }

  void _annonce(Cote? c) {
    if (c == _intention) return;
    // Le petit choc au franchissement : le joueur sait qu'à partir d'ici, ce
    // qu'il voit sur les jauges est ce qu'il obtiendra.
    if (c != null) HapticFeedback.selectionClick();
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

  void _ramene() {
    _annonce(null);
    _anim.duration = CarteGlissante.retour;
    _course = Tween<double>(
      begin: _dx,
      end: 0,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward(from: 0);
  }

  void _annule() {
    if (_sorti) return;
    _ramene();
  }

  void _lache(DragEndDetails d) {
    if (_sorti) return;
    if (_dx.abs() / _largeur < CarteGlissante.seuil) {
      _ramene();
      return;
    }
    final cote = _dx > 0 ? Cote.droite : Cote.gauche;
    final depart = _decalage;
    _sorti = true;
    // L'intention reste annoncée pendant la sortie : le joueur voit encore
    // ce qu'il vient de décider tant que la carte est à l'écran. C'est
    // l'écran qui l'efface, une fois la réponse appliquée.
    HapticFeedback.selectionClick();
    widget.onSortie();
    _dx = depart;
    _anim.duration = CarteGlissante.sortie;
    _course = Tween<double>(
      begin: depart,
      end: _largeur * 1.5 * (cote == Cote.droite ? 1 : -1),
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeIn));
    _anim.forward(from: 0).whenComplete(() => widget.onReponse(cote));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        _largeur = c.maxWidth;
        final decalage = _decalage;
        final angle = (decalage / _largeur).clamp(-1.0, 1.0) * 0.18;
        final visible = _dx.abs() / _largeur >= CarteGlissante.seuilIntention;
        return GestureDetector(
          onPanUpdate: _bouge,
          onPanEnd: _lache,
          onPanCancel: _annule,
          child: Transform.translate(
            offset: Offset(decalage, 0),
            child: Transform.rotate(
              // Le pivot est sous la carte : elle bascule comme une carte tenue
              // en main, pas comme une image qui tourne sur elle-même.
              angle: angle,
              alignment: const Alignment(0, 1.2),
              child: Stack(
                children: [
                  Positioned.fill(child: widget.enfant),
                  if (visible)
                    Positioned(
                      top: 18,
                      left: _dx > 0 ? 18 : null,
                      right: _dx > 0 ? null : 18,
                      // L'étiquette reste droite pendant que la carte bascule.
                      child: Transform.rotate(
                        angle: -angle,
                        child: _Etiquette(texte: _dx > 0 ? widget.libelleDroite : widget.libelleGauche),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Etiquette extends StatelessWidget {
  const _Etiquette({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Couleurs.or, width: 3),
        borderRadius: BorderRadius.circular(8),
        color: Colors.black.withValues(alpha: .55),
      ),
      child: Text(texte.toUpperCase(), style: Textes.etiquette),
    );
  }
}
