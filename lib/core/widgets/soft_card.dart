import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Carte claire qui flotte sur le fond : rayon 18, ombre douce, sans bordure.
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color, this.margin = const EdgeInsets.only(bottom: 12)});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry margin;

  static const radius = 18.0;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final border = BorderRadius.circular(radius);
    Widget inner = Padding(padding: padding, child: child);
    if (onTap != null) {
      inner = Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: border, child: inner),
      );
    }
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color ?? t.card, borderRadius: border, boxShadow: [t.cardShadow]),
        child: ClipRRect(borderRadius: border, child: inner),
      ),
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

/// Séparateur à l'intérieur d'une carte.
class CardDivider extends StatelessWidget {
  const CardDivider({super.key, this.space = 10});
  final double space;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: space),
        child: Divider(height: 1, thickness: 1, color: context.tokens.line),
      );
}

/// Pastille : thème, progression, filtre. Sur le bandeau elle est blanche à
/// 18 % ; sélectionnée, elle prend la couleur forte.
class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, this.icon, this.onBand = false, this.selected = false, this.onTap, this.trailing});
  final String label;
  final IconData? icon;
  final bool onBand;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final Color bg;
    final Color fg;
    if (selected) {
      bg = onBand ? t.onPrimary : t.primary;
      fg = onBand ? t.primary : t.onPrimary;
    } else if (onBand) {
      bg = t.onPrimary.withValues(alpha: 0.18);
      fg = t.onPrimary;
    } else {
      bg = t.primarySoft;
      fg = t.primary;
    }
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 5)],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: fg, fontFeatures: const [FontFeature.tabularFigures()]))),
        if (trailing != null) ...[const SizedBox(width: 4), trailing!],
      ],
    );
    final box = Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: content,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(999), child: box),
    );
  }
}
