import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import 'motion.dart';

/// Le squelette commun à tous les écrans : un bandeau de couleur forte qui
/// porte le titre et le contrôle de contexte, puis un corps défilant dont la
/// première carte chevauche le bandeau. Sur un écran large (iPad), le corps
/// passe sur deux colonnes : `children` à gauche, `sideChildren` à droite.
class BandScaffold extends StatelessWidget {
  const BandScaffold({
    super.key,
    required this.title,
    this.eyebrow,
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
  }) : assert(children != null || body != null, 'children ou body');

  /// Couleur du bandeau (par défaut la couleur principale) et de son texte.
  final Color? color;
  final Color? onColor;

  /// Titre du bandeau, en Sora.
  final String title;

  /// Surtitre en capitales espacées : statut, date, progression.
  final String? eyebrow;

  /// Affiche le nom de l'app en haut du bandeau (onglets).
  final bool brand;

  /// Widget à gauche ; sinon un bouton retour si la route peut revenir.
  final Widget? leading;
  final List<Widget> actions;

  /// Contrôle de contexte sous le titre : curseur, recherche, progression.
  final Widget? control;

  /// Corps simple : liste défilante avec marges de 16 px, entrée en cascade.
  final List<Widget>? children;

  /// Colonne de droite sur écran large ; à la suite sur téléphone.
  final List<Widget>? sideChildren;

  /// Corps libre : l'appelant gère padding et défilement.
  final Widget? body;
  final Future<void> Function()? onRefresh;

  /// Zone fixe sous le corps (boutons du quiz).
  final Widget? bottom;

  /// Hauteur du chevauchement de la première carte sur le bandeau.
  static const overlap = 30.0;

  /// Largeur à partir de laquelle on est « large » : navigation latérale,
  /// deux colonnes.
  static const wideBreakpoint = 700.0;

  /// Largeurs maximales du contenu, téléphone et large.
  static const maxWidth = 680.0;
  static const maxWidthWide = 1240.0;

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
    final pad = EdgeInsets.fromLTRB(wide ? 32 : 16, 0, wide ? 32 : 16, 40);
    Widget content;
    if (body != null) {
      content = body!;
    } else if (wide && sideChildren != null && sideChildren!.isNotEmpty) {
      content = Padding(
        padding: EdgeInsets.only(left: pad.left, right: pad.right),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: ListView(padding: const EdgeInsets.only(bottom: 32), children: _staggered(children!))),
            const SizedBox(width: 32),
            Expanded(flex: 2, child: ListView(padding: const EdgeInsets.only(bottom: 32), children: _staggered(sideChildren!, 2))),
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
    final band = color ?? t.primary;
    return Scaffold(
      backgroundColor: t.background,
      body: Column(
        children: [
          _Band(title: title, eyebrow: eyebrow, brand: brand, leading: leading, actions: actions, control: control, color: band, onColor: onColor ?? t.onPrimary),
          Expanded(
            child: Stack(
              children: [
                Positioned(top: 0, left: 0, right: 0, height: overlap, child: ColoredBox(color: band)),
                Positioned.fill(child: content),
              ],
            ),
          ),
          if (bottom != null) SafeArea(top: false, child: BandScaffold.constrain(context, bottom!)),
        ],
      ),
    );
  }
}

class _Band extends StatelessWidget {
  const _Band({required this.title, this.eyebrow, required this.brand, this.leading, required this.actions, this.control, required this.color, required this.onColor});
  final Color color;
  final Color onColor;
  final String title;
  final String? eyebrow;
  final bool brand;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? control;

  @override
  Widget build(BuildContext context) {
    final wide = BandScaffold.isWide(context);
    final canPop = leading == null && Navigator.of(context).canPop();
    final lead = leading ??
        (canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => GoRouter.maybeOf(context) != null ? context.pop() : Navigator.of(context).pop(),
              )
            : null);
    final topRow = lead != null || brand || actions.isNotEmpty;
    final on = onColor;
    return ColoredBox(
      color: color,
      child: SafeArea(
        bottom: false,
        child: IconTheme(
          data: IconThemeData(color: on, size: 24),
          child: DefaultTextStyle(
            style: TextStyle(fontFamily: PalabreType.body, color: on),
            child: BandScaffold.constrain(
              context,
              Padding(
                padding: EdgeInsets.fromLTRB(lead != null ? 6 : (wide ? 32 : 20), wide ? 18 : 6, wide ? 24 : 8, BandScaffold.overlap + (wide ? 34 : 20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (topRow)
                      Row(
                        children: [
                          ?lead,
                          Expanded(
                            child: brand
                                ? Padding(
                                    padding: EdgeInsets.only(left: lead != null ? 4 : 0, top: 8),
                                    child: Text('Palabre', style: PalabreType.wordmark(on)),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          ...actions,
                        ],
                      ),
                    Padding(
                      padding: EdgeInsets.only(left: lead != null ? 14 : 0, right: 12, top: topRow ? 12 : 6),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(position: Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(anim), child: child),
                        ),
                        layoutBuilder: (current, previous) => Stack(alignment: Alignment.topLeft, children: [...previous, ?current]),
                        child: Column(
                          key: ValueKey('$eyebrow|$title'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (eyebrow != null && eyebrow!.isNotEmpty) ...[
                              Text(eyebrow!.toUpperCase(), style: PalabreType.eyebrow(on.withValues(alpha: 0.85))),
                              const SizedBox(height: 6),
                            ],
                            Text(title, style: PalabreType.title(on).copyWith(fontSize: wide ? 26 : 22)),
                          ],
                        ),
                      ),
                    ),
                    if (control != null)
                      Padding(
                        padding: EdgeInsets.only(left: lead != null ? 14 : 0, right: 12, top: 14),
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

/// Champ de recherche posé sur le bandeau.
class BandSearchField extends StatelessWidget {
  const BandSearchField({super.key, required this.hint, required this.onChanged});
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return TextField(
      onChanged: onChanged,
      style: TextStyle(color: t.onPrimary, fontWeight: FontWeight.w600),
      cursorColor: t.onPrimary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: t.onPrimary.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
        prefixIcon: Icon(Icons.search, size: 20, color: t.onPrimary),
        filled: true,
        fillColor: t.onPrimary.withValues(alpha: 0.18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.onPrimary.withValues(alpha: 0.6))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
