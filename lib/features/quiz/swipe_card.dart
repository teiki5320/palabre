import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import 'quiz_models.dart';

/// Permet aux boutons de déclencher la même sortie animée qu'un balayage.
class SwipeController extends ChangeNotifier {
  Answer? _pending;

  void fling(Answer answer) {
    _pending = answer;
    notifyListeners();
  }

  Answer? takePending() {
    final a = _pending;
    _pending = null;
    return a;
  }
}

/// Une carte que l'on glisse à droite (d'accord), à gauche (pas d'accord) ou
/// vers le haut (neutre). Le geste est le seul mode de réponse ; « passer »
/// et « important » restent des commandes à part.
class SwipeCard extends StatefulWidget {
  const SwipeCard({
    required Key key,
    required this.child,
    required this.controller,
    required this.onAnswer,
    required this.agreeLabel,
    required this.disagreeLabel,
    this.stampColor,
    this.onStampColor,
    this.neutralLabel = 'Neutre',
  }) : super(key: key);

  final String neutralLabel;

  /// Couleur de l'étiquette de swipe (défaut : couleur principale).
  final Color? stampColor;
  final Color? onStampColor;

  final Widget child;
  final SwipeController controller;
  final ValueChanged<Answer> onAnswer;
  final String agreeLabel;
  final String disagreeLabel;

  /// Fraction de la largeur (ou de la hauteur, vers le haut) au-delà de
  /// laquelle le geste vaut réponse.
  static const threshold = 0.35;
  static const thresholdUp = 0.22;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with SingleTickerProviderStateMixin {
  Offset _drag = Offset.zero;
  Size _size = const Size(360, 320);
  Answer? _exiting;
  Animation<Offset>? _tween;
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 250))
    ..addListener(() {
      final tw = _tween;
      if (tw != null) setState(() => _drag = tw.value);
    });

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onController);
  }

  @override
  void didUpdateWidget(SwipeCard old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onController);
      widget.controller.addListener(_onController);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onController);
    _anim.dispose();
    super.dispose();
  }

  void _onController() {
    final a = widget.controller.takePending();
    if (a != null) _exit(a);
  }

  Duration get _duration => MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 250);

  void _exit(Answer a) {
    if (_exiting != null) return;
    _exiting = a;
    final w = _size.width;
    final h = _size.height;
    final target = switch (a) {
      Answer.accord => Offset(w * 1.4, _drag.dy),
      Answer.desaccord => Offset(-w * 1.4, _drag.dy),
      Answer.neutre => Offset(_drag.dx, -h * 1.3),
      _ => Offset(_drag.dx, h * 0.6),
    };
    _tween = Tween(begin: _drag, end: target).animate(CurvedAnimation(parent: _anim, curve: Curves.easeIn));
    _anim.duration = _duration;
    HapticFeedback.selectionClick();
    _anim.forward(from: 0).whenComplete(() {
      if (mounted) widget.onAnswer(a);
    });
  }

  void _spring() {
    _tween = Tween(begin: _drag, end: Offset.zero).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutBack));
    _anim.duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 320);
    _anim.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _tween = null);
    });
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_exiting != null || _anim.isAnimating) return;
    // Vers le haut : mouvement libre ; vers le bas : freiné, rien ne s'y joue.
    final dy = _drag.dy + d.delta.dy;
    setState(() => _drag = Offset(_drag.dx + d.delta.dx, dy < 0 ? dy : dy * 0.15));
  }

  void _onEnd(DragEndDetails d) {
    if (_exiting != null) return;
    final limit = _size.width * SwipeCard.threshold;
    final limitUp = _size.height * SwipeCard.thresholdUp;
    if (_drag.dx.abs() > limit && _drag.dx.abs() >= -_drag.dy) {
      _exit(_drag.dx > 0 ? Answer.accord : Answer.desaccord);
    } else if (-_drag.dy > limitUp) {
      _exit(Answer.neutre);
    } else {
      _spring();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.hasBoundedWidth) _size = Size(constraints.maxWidth, constraints.hasBoundedHeight ? constraints.maxHeight : _size.height);
      // Étiquette : opacité proportionnelle au glissement, 80 px pour être pleine.
      final vertical = -_drag.dy > _drag.dx.abs();
      final agree = vertical ? 0.0 : (_drag.dx / 80).clamp(0.0, 1.0);
      final disagree = vertical ? 0.0 : (-_drag.dx / 80).clamp(0.0, 1.0);
      final neutral = vertical ? (-_drag.dy / 80).clamp(0.0, 1.0) : 0.0;
      final stampBg = widget.stampColor ?? t.primary;
      final stampFg = widget.onStampColor ?? t.onPrimary;
      final fading = _exiting == Answer.passer;
      return GestureDetector(
        onPanUpdate: _onUpdate,
        onPanEnd: _onEnd,
        child: Transform.translate(
          offset: _drag,
          child: Transform.rotate(
            angle: _drag.dx / 20 * 3.14159 / 180,
            child: Opacity(
              opacity: fading ? (1 - _anim.value).clamp(0.0, 1.0) : 1,
              child: Stack(
                children: [
                  widget.child,
                  Positioned(
                    top: 22,
                    right: 22,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: agree,
                        child: SwipeStamp(label: widget.agreeLabel, bg: stampBg, fg: stampFg),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 22,
                    right: 22,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: disagree,
                        child: SwipeStamp(label: widget.disagreeLabel, bg: t.ink, fg: t.card),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 22,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: neutral,
                        child: Center(child: SwipeStamp(label: widget.neutralLabel, bg: t.card, fg: t.ink, outlined: true)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Étiquette de balayage, réutilisée par la démonstration de l'onglet.
class SwipeStamp extends StatelessWidget {
  const SwipeStamp({super.key, required this.label, required this.bg, required this.fg, this.outlined = false});
  final String label;
  final Color bg;
  final Color fg;
  final bool outlined;
  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: -6 * 3.14159 / 180,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6), border: outlined ? Border.all(color: fg, width: 2) : null),
          child: Text(label.toUpperCase(), style: TextStyle(fontFamily: PalabreType.display, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: fg)),
        ),
      );
}
