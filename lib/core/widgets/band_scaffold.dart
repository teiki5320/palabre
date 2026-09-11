import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import 'motion.dart';
import 'soft_card.dart';

/// Le squelette commun à tous les écrans, style « affiche » : fond uni,
/// en-tête sur le fond (wordmark ou retour, actions, eyebrow en pastille,
/// titre géant, trait orange), puis le corps défilant. `color` est la couleur
/// de section : wordmark, icônes, onglet actif, ombres dures en sombre.
class BandScaffold extends StatelessWidget {
  const BandScaffold({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.clock,
    this.brand = false,
    this.leading,
    this.actions = const [],
    this.control,
    this.children,
    this.sideChildren,
    this.body,
    this.onRefresh,
    this.bottom,
    this.color,
    this.onColor,
    this.compact = false,
    this.titleWidget,
  }) : assert(children != null || body != null, 'children ou body');

  /// Couleur de section et couleur de texte sur cette couleur.
  final Color? color;
  final Color? onColor;

  /// Titre en `poster`.
  final String title;

  /// Remplace le titre texte (en-tête compact du quiz).
  final Widget? titleWidget;

  /// Eyebrow dans une pastille bordée.
  final String? eyebrow;

  /// Texte d'horloge à côté de l'eyebrow (icône schedule).
  final String? clock;

  /// Sous-titre 14 px sous le titre.
  final String? subtitle;

  /// Affiche le wordmark « Palabre » (onglets).
  final bool brand;

  /// Widget à gauche ; sinon un bouton retour si la route peut revenir.
  final Widget? leading;
  final List<Widget> actions;

  /// Contrôle de contexte sous le titre : curseur, recherche, progression.
  final Widget? control;

  /// Corps simple : liste défilante avec marges de 22 px, entrée en cascade.
  final List<Widget>? children;

  /// Colonne de droite sur écran large ; à la suite sur téléphone.
  final List<Widget>? sideChildren;

  /// Corps libre : l'appelant gère padding et défilement.
  final Widget? body;
  final Future<void> Function()? onRefresh;

  /// Zone fixe sous le corps.
  final Widget? bottom;

  /// En-tête réduit sur une seule ligne (quiz).
  final bool compact;

  /// Conservé pour compatibilité : plus de chevauchement.
  static const overlap = 0.0;

  /// Largeur à partir de laquelle on est « large » : deux colonnes.
  static const wideBreakpoint = 700.0;

  /// Largeurs maximales du contenu, téléphone et large.
  static const maxWidth = 680.0;
  static const maxWidthWide = 1240.0;

  /// Marges latérales.
  static const side = 22.0;

  static bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= wideBreakpoint;

  static Widget constrain(BuildContext context, Widget child) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: isWide(context) ? maxWidthWide : maxWidth), child: child),
      );

  static List<Widget> _staggered(List<Widget> items, [int offset = 0]) => [
        for (var i = 0; i < items.length; i++) AnimatedEntrance(index: i + offset, child: items[i]),
      ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final wide = isWide(context);
    final pad = EdgeInsets.fromLTRB(wide ? 32 : side, 18, wide ? 32 : side, 40);
    Widget content;
    if (body != null) {
      content = body!;
    } else if (wide && sideChildren != null && sideChildren!.isNotEmpty) {
      content = Padding(
        padding: EdgeInsets.only(left: pad.left, right: pad.right),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: ListView(padding: const EdgeInsets.only(top: 18, bottom: 32), children: _staggered(children!))),
            const SizedBox(width: 32),
            Expanded(flex: 2, child: ListView(padding: const EdgeInsets.only(top: 18, bottom: 32), children: _staggered(sideChildren!, 2))),
          ],
        ),
      );
    } else {
      content = ListView(padding: pad, children: _staggered([...children!, ...?sideChildren]));
    }
    if (onRefresh != null) {
      content = RefreshIndicator(onRefresh: onRefresh!, color: t.primary, backgroundColor: t.card, child: content);
    }
    content = BandScaffold.constrain(context, content);
    final section = color ?? t.primary;
    final on = onColor ?? t.onPrimary;
    return SectionScope(
      color: section,
      onColor: on,
      child: Scaffold(
        backgroundColor: t.background,
        body: Column(
          children: [
            _Header(
              title: title,
              titleWidget: titleWidget,
              eyebrow: eyebrow,
              clock: clock,
              subtitle: subtitle,
              brand: brand,
              leading: leading,
              actions: actions,
              control: control,
              compact: compact,
            ),
            Expanded(child: content),
            if (bottom != null) SafeArea(top: false, child: BandScaffold.constrain(context, bottom!)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.titleWidget, this.eyebrow, this.clock, this.subtitle, required this.brand, this.leading, required this.actions, this.control, required this.compact});
  final String title;
  final Widget? titleWidget;
  final String? eyebrow;
  final String? clock;
  final String? subtitle;
  final bool brand;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? control;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final wide = BandScaffold.isWide(context);
    final section = context.sectionColor;
    final canPop = leading == null && Navigator.of(context).canPop();
    final lead = leading ??
        (canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => GoRouter.maybeOf(context) != null ? context.pop() : Navigator.of(context).pop(),
              )
            : null);
    final topRow = lead != null || brand || actions.isNotEmpty || compact;
    final sideMargin = wide ? 32.0 : BandScaffold.side;
    return ColoredBox(
      color: t.background,
      child: SafeArea(
        bottom: false,
        child: IconTheme(
          data: IconThemeData(color: section, size: 24),
          child: DefaultTextStyle(
            style: TextStyle(fontFamily: PalabreType.body, color: t.ink),
            child: BandScaffold.constrain(
              context,
              Padding(
                padding: EdgeInsets.fromLTRB(sideMargin, 14, sideMargin, compact ? 0 : 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (topRow)
                      SizedBox(
                        height: 36,
                        child: Row(
                          children: [
                            ?lead,
                            if (lead != null) const SizedBox(width: 6),
                            Expanded(
                              child: compact
                                  ? Center(child: titleWidget ?? Text(title, style: TextStyle(fontFamily: PalabreType.display, fontSize: 15, fontWeight: FontWeight.w800, color: section)))
                                  : brand
                                      ? Text('Palabre', style: PalabreType.wordmark(section))
                                      : const SizedBox.shrink(),
                            ),
                            ...actions,
                          ],
                        ),
                      ),
                    if (!compact)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(anim), child: child),
                        ),
                        layoutBuilder: (current, previous) => Stack(alignment: Alignment.topLeft, children: [...previous, ?current]),
                        child: Column(
                          key: ValueKey('$eyebrow|$clock|$title'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((eyebrow != null && eyebrow!.isNotEmpty) || clock != null) ...[
                              SizedBox(height: topRow ? 18 : 4),
                              Row(
                                children: [
                                  if (eyebrow != null && eyebrow!.isNotEmpty) Flexible(child: Pill(label: eyebrow!)),
                                  if (clock != null) ...[
                                    const SizedBox(width: 8),
                                    Icon(Icons.schedule, size: 16, color: t.muted),
                                    const SizedBox(width: 4),
                                    Flexible(child: Text(clock!, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.muted))),
                                  ],
                                ],
                              ),
                            ],
                            SizedBox(height: eyebrow == null && clock == null ? (topRow ? 16 : 4) : 14),
                            titleWidget ?? Text(title, style: PalabreType.poster(t.ink).copyWith(fontSize: wide ? 40 : 34)),
                            if (subtitle != null) ...[
                              const SizedBox(height: 8),
                              Text(subtitle!, style: TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w500, color: t.muted)),
                            ],
                            const SizedBox(height: 14),
                            Container(width: 56, height: 6, decoration: BoxDecoration(color: t.accent, borderRadius: BorderRadius.circular(3))),
                          ],
                        ),
                      ),
                    if (control != null)
                      Padding(
                        padding: EdgeInsets.only(top: compact ? 6 : 18),
                        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: wide ? 760 : double.infinity), child: control),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Champ de recherche : bord 2 px, fond carte, icône en couleur de section.
class BandSearchField extends StatelessWidget {
  const BandSearchField({super.key, required this.hint, required this.onChanged});
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return TextField(
      onChanged: onChanged,
      style: TextStyle(color: t.ink, fontWeight: FontWeight.w700),
      cursorColor: context.sectionColor,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(Icons.search, size: 20, color: context.sectionColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
