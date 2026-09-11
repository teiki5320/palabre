import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Le mouvement de l'app : une entrée en cascade, des chiffres qui comptent,
/// des boutons qui répondent au doigt. Tout respecte la réduction des
/// animations demandée par le système.

bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Fondu + glissement vers le haut, décalé selon l'index dans la liste.
class AnimatedEntrance extends StatefulWidget {
  const AnimatedEntrance({super.key, required this.child, this.index = 0, this.delayStep = const Duration(milliseconds: 55), this.duration = const Duration(milliseconds: 380), this.offset = 18});
  final Widget child;
  final int index;
  final Duration delayStep;
  final Duration duration;
  final double offset;

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  bool _started = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reduceMotion(context)) {
      _c.value = 1;
      return;
    }
    final delay = widget.delayStep * widget.index.clamp(0, 8);
    _timer = Timer(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _a,
        builder: (_, child) => Opacity(
          opacity: _a.value,
          child: Transform.translate(offset: Offset(0, (1 - _a.value) * widget.offset), child: child),
        ),
        child: widget.child,
      );
}

/// Un entier qui compte jusqu'à sa valeur.
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({super.key, required this.value, required this.style, this.suffix = '', this.duration = const Duration(milliseconds: 700)});
  final int value;
  final TextStyle style;
  final String suffix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return Text('$value$suffix', style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text('${v.round()}$suffix', style: style),
    );
  }
}

/// Réduit légèrement l'enfant tant que le doigt est posé.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.onTap, this.scale = 0.92, this.shape});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final ShapeBorder? shape;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      );
}

/// État vide dessiné : un motif de cercles concentriques et une icône, un
/// titre, une phrase. Jamais une donnée inventée.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.color});
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = color ?? t.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: CustomPaint(
              painter: _RingsPainter(c),
              child: Center(
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(color: t.card, shape: BoxShape.circle, boxShadow: [t.cardShadow]),
                  child: Icon(icon, size: 30, color: c),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: PalabreType.cardTitle(t.ink)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(subtitle!, textAlign: TextAlign.center, style: PalabreType.note(t.muted)),
            ),
          ],
        ],
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var i = 3; i >= 1; i--) {
      final paint = Paint()..color = color.withValues(alpha: 0.05 * i);
      canvas.drawCircle(center, size.width / 2 * (i / 3), paint);
    }
    final dots = Paint()..color = color.withValues(alpha: 0.35);
    for (var k = 0; k < 6; k++) {
      final angle = k * math.pi / 3 + 0.4;
      final r = size.width / 2 - 8;
      canvas.drawCircle(center + Offset(r * _cos(angle), r * _sin(angle)), 3, dots);
    }
  }

  static double _cos(double a) => math.cos(a);
  static double _sin(double a) => math.sin(a);

  @override
  bool shouldRepaint(covariant _RingsPainter old) => old.color != color;
}
