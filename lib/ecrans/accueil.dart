import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../moteur/etat_partie.dart';
import '../moteur/jauges.dart';
import '../moteur/modeles.dart';
import '../sauvegarde/sauvegarde.dart';
import 'collection_ecran.dart';
import 'partie_ecran.dart';
import 'session.dart';
import 'theme.dart';

/// Matrice de conversion en niveaux de gris, pour un portrait ou une
/// vignette de parcours verrouille.
const _grise = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

/// Sous un ecran de cette hauteur, la zone image et le nom du parcours
/// passent a leurs tailles courtes.
const _hauteurEcranCourt = 740.0;

/// Premier ecran : une galerie plein cadre des parcours possibles. On
/// glisse pour choisir qui l'on etait avant d'etre elu, on donne son nom, on
/// prend ses fonctions — ou on reprend une partie en cours.
class AccueilEcran extends ConsumerStatefulWidget {
  const AccueilEcran({super.key});

  @override
  ConsumerState<AccueilEcran> createState() => _AccueilEcranState();
}

class _AccueilEcranState extends ConsumerState<AccueilEcran> {
  final _nom = TextEditingController();
  final _page = PageController();

  /// L'index de page du PageView : le parcours choisi est celui qu'on
  /// regarde. Le nom, lui, vit dans _nom et survit au changement de page
  /// puisque le champ n'est jamais reconstruit par page.
  int _choisi = 0;

  EtatPartie? _enCours;

  @override
  void initState() {
    super.initState();
    _relisSauvegarde();
  }

  /// Relit la sauvegarde sur l'appareil. A rappeler chaque fois que l'accueil
  /// redevient visible : une partie peut avoir ete perdue ou quittee entre
  /// temps, et le bouton « Reprendre » doit refleter l'etat reel. La
  /// progression est invalidee au meme endroit, pour que la liste des
  /// parcours reflete aussitot ce qu'un mandat qui vient de finir a
  /// debloque.
  Future<void> _relisSauvegarde() async {
    ref.invalidate(progressionProvider);
    final e = await Sauvegarde.lis();
    if (mounted) setState(() => _enCours = e);
  }

  @override
  void dispose() {
    _nom.dispose();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contenu = ref.watch(contenuProvider);
    final etatProgression = ref.watch(progressionProvider);

    // Le contenu ET la progression avant de dessiner : afficher les parcours
    // des que le contenu est la montrerait une fraction de seconde comme
    // verrouille un parcours que le joueur a deja gagne.
    return Scaffold(
      backgroundColor: Couleurs.nuit,
      body: contenu.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Contenu illisible : $e')),
        data: (c) => etatProgression.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Progression illisible : $e')),
          data: (progression) {
            final parcours = c.parcours;
            if (parcours.isEmpty) return const SizedBox.shrink();
            final choisi = _choisi.clamp(0, parcours.length - 1);
            bool debloque(Parcours p) => p.ouvertDesLeDebut || progression.parcoursDebloques.contains(p.id);
            final actuel = parcours[choisi];
            final verrouille = !debloque(actuel);
            final pret = !verrouille && _nom.text.trim().isNotEmpty;

            final taille = MediaQuery.sizeOf(context);
            final courte = taille.height < _hauteurEcranCourt;

            // Ce que le bas réclame vraiment : les vignettes, le champ, le
            // bouton, et « Reprendre » quand une partie est en cours. Sans
            // cette mesure, la zone image prend ses 68 % coûte que coûte et
            // pousse « Prendre mes fonctions » hors de l'écran.
            final basNecessaire = 64.0 + 16 + (_enCours != null ? 58 : 0) + 52 + 10 + 56 + 18 + 30;

            return SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, contraintes) {
                  final hauteurImage = math.min(
                    taille.height * (courte ? 0.60 : 0.68),
                    contraintes.maxHeight - basNecessaire,
                  );
                  return Column(
                    children: [
                      SizedBox(
                        height: hauteurImage,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            PageView(
                              controller: _page,
                              onPageChanged: (i) => setState(() => _choisi = i),
                              children: [
                                for (final p in parcours)
                                  _PortraitParcours(parcours: p, verrouille: !debloque(p)),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(26, 60, 26, 0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    'assets/icone/marque.png',
                                    height: 44,
                                    errorBuilder: (_, __, ___) => const SizedBox(height: 44),
                                  ),
                                  const Spacer(),
                                  Text('${choisi + 1} / ${parcours.length}', style: Textes.surtitre),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    tooltip: 'Exploits et fins',
                                    icon: Icon(
                                      Icons.emoji_events_outlined,
                                      color: Couleurs.creme.withValues(alpha: .65),
                                    ),
                                    onPressed: () async {
                                      await Navigator.of(context)
                                          .push(MaterialPageRoute(builder: (_) => const CollectionEcran()));
                                      await _relisSauvegarde();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 220),
                                      switchInCurve: Curves.easeOut,
                                      switchOutCurve: Curves.easeOut,
                                      transitionBuilder: (child, animation) => FadeTransition(
                                        opacity: animation,
                                        child: AnimatedBuilder(
                                          animation: animation,
                                          builder: (context, enfant) => Transform.translate(
                                            offset: Offset(0, (1 - animation.value) * 8),
                                            child: enfant,
                                          ),
                                          child: child,
                                        ),
                                      ),
                                      child: _IdentiteParcours(
                                        key: ValueKey(actuel.id),
                                        parcours: actuel,
                                        verrouille: verrouille,
                                        courte: courte,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 220),
                                      switchInCurve: Curves.easeOut,
                                      switchOutCurve: Curves.easeOut,
                                      transitionBuilder: (child, animation) => FadeTransition(
                                        opacity: animation,
                                        child: AnimatedBuilder(
                                          animation: animation,
                                          builder: (context, enfant) => Transform.translate(
                                            offset: Offset(0, (1 - animation.value) * 8),
                                            child: enfant,
                                          ),
                                          child: child,
                                        ),
                                      ),
                                      child: _JaugesDepart(
                                        key: ValueKey(actuel.id),
                                        depart: actuel.depart,
                                        verrouille: verrouille,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _VignettesParcours(
                                parcours: parcours,
                                actuel: choisi,
                                debloque: debloque,
                                onTap: (i) => _page.animateToPage(
                                  i,
                                  duration: const Duration(milliseconds: 260),
                                  curve: Curves.easeOut,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_enCours != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      ref.read(sessionProvider.notifier).reprend(_enCours!);
                                      await Navigator.of(context)
                                          .push(MaterialPageRoute(builder: (_) => const PartieEcran()));
                                      await _relisSauvegarde();
                                    },
                                    child: Text('Reprendre le jour ${_enCours!.jour}'),
                                  ),
                                ),
                              TextField(
                                controller: _nom,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(hintText: 'Votre nom'),
                              ),
                              const SizedBox(height: 10),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 160),
                                opacity: pret ? 1 : .6,
                                child: FilledButton(
                                  onPressed: !pret
                                      ? null
                                      : () async {
                                          final p = c.parcoursParId(actuel.id)!;
                                          ref
                                              .read(sessionProvider.notifier)
                                              .demarre(parcours: p, nom: _nom.text.trim());
                                          await Navigator.of(context)
                                              .push(MaterialPageRoute(builder: (_) => const PartieEcran()));
                                          await _relisSauvegarde();
                                        },
                                  child: const Text('Prendre mes fonctions'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Le portrait plein cadre d'un parcours, avec son degrade et, s'il est
/// verrouille, un traitement en niveaux de gris.
class _PortraitParcours extends StatelessWidget {
  const _PortraitParcours({required this.parcours, required this.verrouille});

  final Parcours parcours;
  final bool verrouille;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      parcours.image,
      fit: BoxFit.cover,
      alignment: const Alignment(0, -0.6),
      errorBuilder: (_, __, ___) => Container(color: Couleurs.aplat),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        verrouille
            ? Opacity(
                opacity: .55,
                child: ColorFiltered(colorFilter: _grise, child: image),
              )
            : image,
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, .22, .42, .66],
              colors: [
                Couleurs.nuit.withValues(alpha: .55),
                Colors.transparent,
                Colors.transparent,
                Couleurs.nuit,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Surtitre, nom du parcours, et sous-titre — ou, verrouille, la condition
/// de deblocage a la place du sous-titre.
class _IdentiteParcours extends StatelessWidget {
  const _IdentiteParcours({
    super.key,
    required this.parcours,
    required this.verrouille,
    required this.courte,
  });

  final Parcours parcours;
  final bool verrouille;
  final bool courte;

  @override
  Widget build(BuildContext context) {
    final sousTitre = verrouille
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 16, color: Couleurs.or),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  parcours.conditionDeblocage ?? '',
                  style: Textes.sousTitre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          )
        : Text(
            parcours.accroche.isEmpty ? parcours.titre : '${parcours.titre} · ${parcours.accroche}',
            style: Textes.sousTitre,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('QUI ÉTIEZ-VOUS AVANT ?', style: Textes.surtitre),
        const SizedBox(height: 6),
        Text(
          parcours.nom,
          style: courte ? Textes.nomParcoursCourt : Textes.nomParcours,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        sousTitre,
      ],
    );
  }
}

/// Les quatre jauges de depart du parcours ; la plus haute ressort en or,
/// sauf parcours verrouille ou toutes restent en retrait.
class _JaugesDepart extends StatelessWidget {
  const _JaugesDepart({super.key, required this.depart, required this.verrouille});

  final Jauges depart;
  final bool verrouille;

  @override
  Widget build(BuildContext context) {
    Jauge plusHaute = Jauge.values.first;
    for (final j in Jauge.values) {
      if (depart.valeur(j) > depart.valeur(plusHaute)) plusHaute = j;
    }

    return Row(
      children: [
        for (final j in Jauge.values) ...[
          if (j != Jauge.values.first) const SizedBox(width: 10),
          Expanded(child: _colonneJauge(j, en: !verrouille && j == plusHaute)),
        ],
      ],
    );
  }

  Widget _colonneJauge(Jauge j, {required bool en}) {
    final couleur = verrouille ? Couleurs.creme.withValues(alpha: .35) : (en ? Couleurs.or : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          j.nom.toUpperCase(),
          style: couleur == null ? Textes.nomJauge : Textes.nomJauge.copyWith(color: couleur),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 4,
            child: Stack(
              children: [
                // Positioned.fill des deux cotes : dans une Stack, une boite
                // decoree sans enfant se dimensionne a zero et la barre
                // disparait. Et le remplissage part de la gauche, pas du
                // centre, qui est le defaut de FractionallySizedBox.
                const Positioned.fill(child: ColoredBox(color: Couleurs.bordure)),
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (depart.valeur(j) / 100).clamp(0, 1),
                    child: ColoredBox(color: couleur ?? Couleurs.creme),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// La rangee de vignettes : un rectangle par parcours, celui qu'on regarde
/// souligne d'un trait or, les autres selon leur etat.
class _VignettesParcours extends StatelessWidget {
  const _VignettesParcours({
    required this.parcours,
    required this.actuel,
    required this.debloque,
    required this.onTap,
  });

  final List<Parcours> parcours;
  final int actuel;
  final bool Function(Parcours) debloque;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < parcours.length; i++) ...[
          if (i != 0) const SizedBox(width: 10),
          _Vignette(
            parcours: parcours[i],
            courante: i == actuel,
            verrouille: !debloque(parcours[i]),
            onTap: () => onTap(i),
          ),
        ],
      ],
    );
  }
}

class _Vignette extends StatelessWidget {
  const _Vignette({
    required this.parcours,
    required this.courante,
    required this.verrouille,
    required this.onTap,
  });

  final Parcours parcours;
  final bool courante;
  final bool verrouille;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      parcours.image,
      width: 52,
      height: 64,
      fit: BoxFit.cover,
      alignment: const Alignment(0, -0.5),
      errorBuilder: (_, __, ___) => Container(width: 52, height: 64, color: Couleurs.aplat),
    );

    Widget contenu = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: verrouille
          ? Opacity(
              opacity: .40,
              child: ColorFiltered(colorFilter: _grise, child: image),
            )
          : Opacity(opacity: courante ? 1 : .70, child: image),
    );

    if (verrouille) {
      contenu = Stack(
        alignment: Alignment.center,
        children: [
          contenu,
          const Icon(Icons.lock_outline, size: 14, color: Couleurs.or),
        ],
      );
    }

    return GestureDetector(
      key: ValueKey('vignette-${parcours.id}'),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          // La bordure dit « vous regardez celui-ci », le cadenas dit « il est
          // ferme » : un parcours verrouille garde donc sa bordure, sinon on
          // ne sait plus a quelle page on est.
          border: Border.all(color: courante ? Couleurs.or : Colors.transparent, width: 2),
        ),
        child: contenu,
      ),
    );
  }
}
