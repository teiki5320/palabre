import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

/// Le squelette commun à tous les écrans : un bandeau de couleur forte qui
/// porte le titre et le contrôle de contexte, puis un corps défilant dont la
/// première carte chevauche le bandeau. Remplace `AppBar` partout.
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
    this.body,
    this.onRefresh,
    this.bottom,
  }) : assert(children != null || body != null, 'children ou body');

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

  /// Corps simple : liste défilante avec marges de 16 px.
  final List<Widget>? children;

  /// Corps libre : l'appelant gère padding et défilement.
  final Widget? body;
  final Future<void> Function()? onRefresh;

  /// Zone fixe sous le corps (boutons du quiz).
  final Widget? bottom;

  /// Hauteur du chevauchement de la première carte sur le bandeau.
  static const overlap = 30.0;

  /// Largeur maximale du contenu : sur iPad, les cartes restent lisibles au
  /// centre au lieu de s'étirer d'un bord à l'autre.
  static const maxWidth = 680.0;

  static Widget constrain(Widget child) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget content = body ?? ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 32), children: children!);
    if (onRefresh != null) {
      content = RefreshIndicator(onRefresh: onRefresh!, color: t.primary, backgroundColor: t.card, child: content);
    }
    content = BandScaffold.constrain(content);
    return Scaffold(
      backgroundColor: t.background,
      body: Column(
        children: [
          _Band(title: title, eyebrow: eyebrow, brand: brand, leading: leading, actions: actions, control: control),
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: overlap,
                  child: ColoredBox(color: t.primary),
                ),
                Positioned.fill(child: content),
              ],
            ),
          ),
          if (bottom != null) SafeArea(top: false, child: BandScaffold.constrain(bottom!)),
        ],
      ),
    );
  }
}

class _Band extends StatelessWidget {
  const _Band({required this.title, this.eyebrow, required this.brand, this.leading, required this.actions, this.control});
  final String title;
  final String? eyebrow;
  final bool brand;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? control;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final canPop = leading == null && Navigator.of(context).canPop();
    final lead =
        leading ??
        (canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => GoRouter.maybeOf(context) != null ? context.pop() : Navigator.of(context).pop(),
              )
            : null);
    final topRow = lead != null || brand || actions.isNotEmpty;
    return ColoredBox(
      color: t.primary,
      child: SafeArea(
        bottom: false,
        child: IconTheme(
          data: IconThemeData(color: t.onPrimary, size: 24),
          child: DefaultTextStyle(
            style: TextStyle(fontFamily: PalabreType.body, color: t.onPrimary),
            child: BandScaffold.constrain(
              Padding(
                padding: EdgeInsets.fromLTRB(lead != null ? 6 : 20, 6, 8, BandScaffold.overlap + 20),
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
                                    child: Text('Palabre', style: PalabreType.wordmark(t.onPrimary)),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          ...actions,
                        ],
                      ),
                    Padding(
                      padding: EdgeInsets.only(left: lead != null ? 14 : 0, right: 12, top: topRow ? 12 : 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (eyebrow != null && eyebrow!.isNotEmpty) ...[
                            Text(eyebrow!.toUpperCase(), style: PalabreType.eyebrow(t.onPrimary.withValues(alpha: 0.85))),
                            const SizedBox(height: 6),
                          ],
                          Text(title, style: PalabreType.title(t.onPrimary)),
                          if (control != null) Padding(padding: const EdgeInsets.only(top: 14), child: control),
                        ],
                      ),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: t.onPrimary.withValues(alpha: 0.6)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
