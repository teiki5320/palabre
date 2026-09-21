import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../moteur/denouement.dart';
import '../moteur/etat_partie.dart';
import '../moteur/memoire.dart';
import '../moteur/progression.dart';
import 'session.dart';
import 'sons.dart';
import 'theme.dart';

/// Ce que le centième jour a donné, quand le mandat s'est terminé par une
/// élection et qu'on sait qui était en face. Rend null dans tous les autres
/// cas — une chute ne se compte pas en points.
///
/// L'écart est celui que le moteur a tranché : la moyenne du peuple et de la
/// presse contre la force de l'opposant. On le dit en points, sans accorder
/// un seul participe au joueur, dont on ne connaît pas le genre.
String? resultatDuScrutin({
  required Denouement denouement,
  required EtatPartie etat,
  required Adversaire? adversaire,
}) {
  if (denouement.type == TypeDenouement.chute) return null;
  if (adversaire == null) return null;
  final ecart = (((etat.jauges.peuple + etat.jauges.presse) / 2) - etat.force).round();
  final gagnee = denouement.type == TypeDenouement.electionGagnee;
  if (ecart == 0) return 'En face, ${adversaire.nom}. Il s\'en est fallu de rien.';
  final points = ecart.abs() == 1 ? '1 point' : '${ecart.abs()} points';
  return gagnee
      ? 'En face, ${adversaire.nom}. Vous avez fait $points de mieux.'
      : 'En face, ${adversaire.nom}. Il vous manquait $points.';
}

/// Les widgets de la zone « Vous avez débloqué » : un exploit par ligne avec
/// son titre et sa description, un parcours débloqué par ligne avec son
/// nom. Une liste à concaténer dans la colonne, jamais un widget seul, pour
/// que l'appelant puisse ne rien insérer du tout quand il n'y a rien.
List<Widget> _nouveautes(Nouveautes nouveautes) => [
  const SizedBox(height: 22),
  Text('Vous avez débloqué', style: Textes.surtitre.copyWith(fontSize: 13, letterSpacing: 1.2)),
  const SizedBox(height: 10),
  for (final exploit in nouveautes.exploits)
    Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exploit.titre,
            style: Textes.sousTitre.copyWith(
              color: Couleurs.creme,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            exploit.description,
            style: Textes.sousTitre.copyWith(color: Couleurs.cremeDoux, fontSize: 13, height: 1.3),
          ),
        ],
      ),
    ),
  for (final parcours in nouveautes.parcours)
    Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        'Nouveau parcours : ${parcours.nom}',
        style: Textes.sousTitre.copyWith(color: Couleurs.creme, fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
];

/// Ce qu'on voit quand le mandat s'arrête : la fin écrite, les jours tenus,
/// et l'invitation à recommencer.
class FinEcran extends ConsumerStatefulWidget {
  const FinEcran({super.key});

  @override
  ConsumerState<FinEcran> createState() => _FinEcranState();
}

class _FinEcranState extends ConsumerState<FinEcran> {
  @override
  void initState() {
    super.initState();
    // Une seule fois, à l'arrivée sur l'écran. Dans `build` il se rejouerait
    // à chaque reconstruction — et un mandat ne se termine qu'une fois.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final denouement = ref.read(sessionProvider)?.denouement;
      if (denouement == null) return;
      ref.read(sonsProvider).joue(
            denouement.type == TypeDenouement.electionGagnee ? Son.reelu : Son.battu,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (session == null || !session.terminee) return const Scaffold(body: SizedBox.shrink());

    final fin = session.fin;
    final jours = session.etat.jour - 1;
    final gagnee = session.denouement!.type == TypeDenouement.electionGagnee;
    final scrutin = resultatDuScrutin(
      denouement: session.denouement!,
      etat: session.etat,
      adversaire: ref.watch(contenuProvider).value?.adversaireParId(session.etat.adversaire),
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (fin != null)
            Image.asset(
              'assets/images/${fin.image}',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Couleurs.nuitClair),
            )
          else
            Container(color: Couleurs.nuitClair),
          Container(color: Colors.black.withValues(alpha: 0.55)),
          SafeArea(
            child: LayoutBuilder(
              // Alignement en bas pour un texte court, défilement pour une
              // fin longue qui déborderait sur un petit écran.
              builder: (context, contraintes) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: contraintes.maxHeight),
                  child: Cadre(
                    enfant: Padding(
                      padding: const EdgeInsets.all(26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            gagnee ? 'RÉÉLU' : 'FIN DU MANDAT',
                            style: Textes.surtitre.copyWith(fontSize: 12, letterSpacing: 2.5),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            fin?.titre ?? "Le mandat s'arrête",
                            style: Textes.nomParcoursCourt.copyWith(fontSize: 30, height: 1.1),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            fin?.texte ?? '',
                            style: Textes.sousTitre.copyWith(
                              color: Couleurs.cremeDoux,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Vous avez tenu $jours jours.',
                            style: Textes.sousTitre.copyWith(fontSize: 15),
                          ),
                          if (scrutin != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              scrutin,
                              style: Textes.sousTitre.copyWith(
                                color: Couleurs.cremeDoux,
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                          ],
                          // Rien du tout quand il n'y a rien : ni titre, ni
                          // espace, sous peine de laisser un trou orphelin.
                          // Une fin inédite n'entre pas dans ce compte : elle
                          // est déjà annoncée par le titre et le texte
                          // au-dessus, ce n'est pas à cette zone de la répéter.
                          if (session.nouveautes.exploits.isNotEmpty ||
                              session.nouveautes.parcours.isNotEmpty)
                            ..._nouveautes(session.nouveautes),
                          const SizedBox(height: 26),
                          if (gagnee)
                            // Empilés : côte à côte, « Continuer, deuxième
                            // mandat » s'étalait sur trois lignes.
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    ref.read(sessionProvider.notifier).arrete();
                                    Navigator.of(context).popUntil((r) => r.isFirst);
                                  },
                                  child: const Text('Reprendre ses fonctions'),
                                ),
                                const SizedBox(height: 10),
                                FilledButton(
                                  // Rien à naviguer : l'écran de jeu affiche
                                  // déjà FinEcran conditionnellement, il se
                                  // remontre tout seul dès que la session
                                  // n'est plus terminée.
                                  onPressed: () => ref.read(sessionProvider.notifier).mandatSuivant(),
                                  child: const Text('Continuer, deuxième mandat'),
                                ),
                              ],
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () {
                                  ref.read(sessionProvider.notifier).arrete();
                                  Navigator.of(context).popUntil((r) => r.isFirst);
                                },
                                child: const Text('Reprendre ses fonctions'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
