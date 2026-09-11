import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'motion.dart';

/// Couleur de section de l'écran courant (Question, Testez-vous, Gouvernement,
/// Assemblée). Posée par `BandScaffold`, lue par les cartes pour l'ombre dure
/// en mode sombre et par les éléments choisis.
class SectionScope extends InheritedWidget {
  const SectionScope({super.key, required this.color, required this.onColor, required super.child});
  final Color color;
  final Color onColor;

  static SectionScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SectionScope>();

  @override
  bool updateShouldNotify(SectionScope old) => old.color != color || old.onColor != onColor;
}

extension SectionContext on BuildContext {
  /// Couleur de section, la couleur principale par défaut.
  Color get sectionColor => SectionScope.maybeOf(this)?.color ?? tokens.primary;
  Color get onSectionColor => SectionScope.maybeOf(this)?.onColor ?? tokens.onPrimary;

  /// Ombre dure : encre en clair, couleur de section en sombre.
  Color get hardShadowColor => tokens.isDark ? sectionColor : tokens.hardShadow;
}

/// Ombre portée dure : décalage sans flou. Sur appui, l'enfant s'enfonce
/// (translation et ombre réduites).
class HardShadow extends StatefulWidget {
  const HardShadow({super.key, required this.child, this.offset = 4, this.color, this.radius = 16, this.onTap, this.shape = BoxShape.rectangle});
  final Widget child;
  final double offset;
  final Color? color;
  final double radius;
  final VoidCallback? onTap;
  final BoxShape shape;

  @override
  State<HardShadow> createState() => _HardShadowState();
}

class _HardShadowState extends State<HardShadow> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? context.hardShadowColor;
    final pressed = _down && widget.onTap != null;
    final d = pressed ? 2.0 : widget.offset;
    final shift = pressed ? widget.offset - 2 : 0.0;
    final motion = !reduceMotion(context);
    final box = AnimatedContainer(
      duration: Duration(milliseconds: motion ? 90 : 0),
      transform: Matrix4.translationValues(shift, shift, 0),
      decoration: BoxDecoration(
        shape: widget.shape,
        borderRadius: widget.shape == BoxShape.circle ? null : BorderRadius.circular(widget.radius),
        boxShadow: [PalabreTokens.hard(c, d)],
      ),
      child: widget.child,
    );
    if (widget.onTap == null) return box;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: box,
    );
  }
}

/// Carte crème ou nuit : bord 2 px, rayon 16 à 22, ombre dure 4/4.
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color, this.margin = const EdgeInsets.only(bottom: 10), this.radius = 16, this.shadow = 4, this.borderColor});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry margin;
  final double radius;
  final double shadow;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final br = BorderRadius.circular(radius);
    final inner = Container(
      decoration: BoxDecoration(color: color ?? t.card, borderRadius: br, border: Border.all(color: borderColor ?? t.border, width: 2)),
      child: ClipRRect(borderRadius: BorderRadius.circular(radius - 2), child: Padding(padding: padding, child: child)),
    );
    return Padding(
      padding: margin,
      child: HardShadow(offset: shadow, radius: radius, onTap: onTap, child: inner),
    );
  }
}

/// Carte avec un titre : une section d'une fiche.
class CardSection extends StatelessWidget {
  const CardSection({super.key, required this.title, this.trailing, this.leading, required this.children});
  final String title;
  final Widget? trailing;
  final Widget? leading;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Expanded(child: Text(title, style: PalabreType.cardTitle(t.ink))),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

/// Séparateur fin à l'intérieur d'une carte.
class CardDivider extends StatelessWidget {
  const CardDivider({super.key, this.space = 10});
  final double space;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: space),
        child: Divider(height: 1, thickness: 1, color: context.tokens.line),
      );
}

/// Trait « affiche » : 1.5 px dans la couleur d'encre, 2 px aux extrémités.
class PosterRule extends StatelessWidget {
  const PosterRule({super.key, this.thick = false});
  final bool thick;
  @override
  Widget build(BuildContext context) => Container(height: thick ? 2 : 1.5, color: context.tokens.border);
}

/// Liste « affiche » : lignes séparées par un trait, premier et dernier en 2 px.
class PosterList extends StatelessWidget {
  const PosterList({super.key, required this.children, this.closed = true});
  final List<Widget> children;

  /// Trait de fermeture après le dernier élément.
  final bool closed;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            PosterRule(thick: i == 0),
            children[i],
          ],
          if (closed && children.isNotEmpty) const PosterRule(thick: true),
        ],
      );
}

/// Ligne « affiche » cliquable : icône en couleur de section, libellé, chevron.
class PosterRow extends StatelessWidget {
  const PosterRow({super.key, required this.icon, required this.label, this.trailing = Icons.chevron_right, this.onTap, this.trailingWidget});
  final IconData icon;
  final String label;
  final IconData trailing;
  final Widget? trailingWidget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.sectionColor),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: TextStyle(fontFamily: PalabreType.body, fontSize: 14, fontWeight: FontWeight.w700, color: t.ink))),
            trailingWidget ?? Icon(trailing, size: 22, color: t.muted),
          ],
        ),
      ),
    );
  }
}

/// Pastille bordée : eyebrow en capitales. `selected` : fond couleur de
/// section. `disabled` : bord et texte désactivés.
class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, this.icon, this.onBand = false, this.selected = false, this.disabled = false, this.onTap, this.trailing, this.color});
  final String label;
  final IconData? icon;

  /// Conservé pour compatibilité : sans effet, il n'y a plus de bandeau.
  final bool onBand;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Couleur de fond quand la pastille est sélectionnée (défaut : section).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final section = color ?? context.sectionColor;
    final on = color == null ? context.onSectionColor : (color!.computeLuminance() > 0.5 ? t.ink : Colors.white);
    final fg = selected ? on : (disabled ? t.disabled : t.ink);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 5)],
        Flexible(child: Text(label.toUpperCase(), overflow: TextOverflow.ellipsis, style: PalabreType.eyebrow(fg).copyWith(fontFeatures: const [FontFeature.tabularFigures()]))),
        if (trailing != null) ...[const SizedBox(width: 4), trailing!],
      ],
    );
    final box = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? section : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? section : (disabled ? t.disabled : t.border), width: 1.5),
      ),
      child: content,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(999), child: box),
    );
  }
}

/// Case carrée 22 px, rayon 6, bord 2 px ; cochée = fond section + check.
class SquareCheck extends StatelessWidget {
  const SquareCheck({super.key, required this.checked, this.disabled = false, this.onDark = false});
  final bool checked;
  final bool disabled;

  /// Vrai quand la case est posée sur un fond de couleur de section.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final section = context.sectionColor;
    final fill = onDark ? (t.isDark ? t.ink : Colors.white) : section;
    final tick = onDark ? (t.isDark ? t.background : section) : context.onSectionColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? fill : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: checked ? fill : (disabled ? t.disabled : t.border), width: 2),
      ),
      child: checked ? Icon(Icons.check, size: 16, color: tick, weight: 700) : null,
    );
  }
}

/// Bouton d'action : fond orange, bord 2 px, rayon 16, hauteur 56, Sora 800,
/// ombre dure 4/4. `outlined` : fond carte, rayon 14, hauteur 54, ombre 3/3.
class ActionButton extends StatelessWidget {
  const ActionButton({super.key, required this.label, this.onPressed, this.icon, this.busy = false, this.outlined = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = onPressed != null && !busy;
    final radius = outlined ? 14.0 : 16.0;
    final fg = outlined ? t.ink : t.onAccent;
    final bg = outlined ? t.card : t.accent;
    final child = Container(
      height: outlined ? 54 : 56,
      decoration: BoxDecoration(
        color: enabled ? bg : t.background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: enabled ? t.border : t.disabled, width: 2),
      ),
      alignment: Alignment.center,
      child: busy
          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 18, color: enabled ? fg : t.disabled), const SizedBox(width: 6)],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: outlined
                        ? TextStyle(fontFamily: PalabreType.body, fontSize: 14, fontWeight: FontWeight.w800, color: enabled ? fg : t.disabled)
                        : TextStyle(fontFamily: PalabreType.display, fontSize: 17, fontWeight: FontWeight.w800, color: enabled ? fg : t.disabled),
                  ),
                ),
              ],
            ),
    );
    if (!enabled) return child;
    return Semantics(button: true, label: label, child: HardShadow(offset: outlined ? 3 : 4, radius: radius, onTap: onPressed, child: child));
  }
}

/// Gros pourcentage : chiffre en Sora 800, « % » plus petit et atténué.
class BigPercent extends StatelessWidget {
  const BigPercent(this.value, {super.key, this.size = 30, this.animate = true, this.color});
  final int value;
  final double size;
  final bool animate;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = PalabreType.big(color ?? t.ink).copyWith(fontSize: size);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        animate ? AnimatedNumber(value: value, style: style) : Text('$value', style: style),
        Text(' %', style: TextStyle(fontFamily: PalabreType.display, fontSize: size * 0.53, fontWeight: FontWeight.w800, color: t.muted)),
      ],
    );
  }
}
