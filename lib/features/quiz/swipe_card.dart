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

/// Une carte que l'on glisse à droite (d'accord) ou à gauche (pas d'accord).
/// Le balayage est un raccourci : les boutons suffisent toujours.
class SwipeCard extends StatefulWidget {
  const SwipeCard({
    required Key key,
    required this.child,
    required this.controller,
    required this.onAnswer,
    required this.agreeLabel,
    required this.disagreeLabel,
  }) : super(key: key);

  final Widget child;
  final SwipeController controller;
  final ValueChanged<Answer> onAnswer;
  final String agreeLabel;
  final String disagreeLabel;

  /// Fraction de la largeur au-delà de laquelle le geste vaut réponse.
  static const threshold = 0.35;

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
    setState(() => _drag += Offset(d.delta.dx, d.delta.dy * 0.15));
  }

  void _onEnd(DragEndDetails d) {
    if (_exiting != null) return;
    final limit = _size.width * SwipeCard.threshold;
    if (_drag.dx.abs() > limit) {
      _exit(_drag.dx > 0 ? Answer.accord : Answer.desaccord);
    } else {
      _spring();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.hasBoundedWidth) _size = Size(constraints.maxWidth, constraints.hasBoundedHeight ? constraints.maxHeight : _size.height);
      final w = _size.width;
      final limit = w * SwipeCard.threshold;
      final agree = (_drag.dx / limit).clamp(0.0, 1.0);
      final disagree = (-_drag.dx / limit).clamp(0.0, 1.0);
      final fading = _exiting == Answer.neutre || _exiting == Answer.passer;
      return GestureDetector(
        onHorizontalDragUpdate: _onUpdate,
        onHorizontalDragEnd: _onEnd,
        child: Transform.translate(
          offset: _drag,
          child: Transform.rotate(
            angle: _drag.dx / w * 0.21,
            child: Opacity(
              opacity: fading ? (1 - _anim.value).clamp(0.0, 1.0) : 1,
              child: Stack(
                children: [
                  widget.child,
                  Positioned(
                    top: 14,
                    left: 14,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: agree,
                        child: _Stamp(label: widget.agreeLabel, bg: t.primary, fg: t.onPrimary),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: disagree,
                        child: _Stamp(label: widget.disagreeLabel, bg: t.ink, fg: t.card),
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

class _Stamp extends StatelessWidget {
  const _Stamp({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: TextStyle(fontFamily: PalabreType.display, fontSize: 13, fontWeight: FontWeight.w800, color: fg)),
      );
}
