import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../moteur/jauges.dart';
import '../moteur/modeles.dart';
import '../moteur/partie.dart';
import 'carte_glissante.dart';
import 'fin_ecran.dart';
import 'session.dart';

/// L'écran de jeu : les jauges en haut, la carte du jour au milieu.
class PartieEcran extends ConsumerStatefulWidget {
  const PartieEcran({super.key});

  @override
  ConsumerState<PartieEcran> createState() => _PartieEcranState();
}

class _PartieEcranState extends ConsumerState<PartieEcran> {
  Cote? _intention;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const Scaffold(body: SizedBox.shrink());
    if (session.terminee) return const FinEcran();

    final contenu = ref.watch(contenuProvider).requireValue;
    final carte = session.carte!;
    final personnage = contenu.personnages[carte.personnage];
    final parcours = contenu.parcoursParId(session.etat.parcours);
    final titre = parcours?.titre ?? 'Monsieur le Président';
    final reponse = _intention == Cote.gauche ? carte.gauche : (_intention == Cote.droite ? carte.droite : null);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _LigneJauges(jauges: session.etat.jauges, concernees: reponse?.effets.keys.toSet() ?? const {}),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('Jour ${session.etat.jour}',
                  style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: CarteGlissante(
                    key: ValueKey(carte.id),
                    libelleGauche: carte.gauche.libelle,
                    libelleDroite: carte.droite.libelle,
                    onIntention: (c) => setState(() => _intention = c),
                    onReponse: (c) {
                      setState(() => _intention = null);
                      ref.read(sessionProvider.notifier).repondA(c);
                    },
                    enfant: _Carte(
                      personnage: personnage,
                      humeur: carte.humeur,
                      texte: habille(carte.texte, nom: session.etat.nomJoueur, titre: titre),
                      nomJoueur: session.etat.nomJoueur,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Carte extends StatelessWidget {
  const _Carte({required this.personnage, required this.humeur, required this.texte, required this.nomJoueur});

  final Personnage? personnage;
  final Humeur humeur;
  final String texte;
  final String nomJoueur;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        color: const Color(0xFF14131A),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (personnage != null)
              Image.asset(
                personnage!.image(humeur),
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.35),
                // Tant que les portraits ne sont pas générés, un aplat suffit.
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF26222E)),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 34, 18, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xF2080709)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (personnage?.titre ?? '').toUpperCase(),
                      style: const TextStyle(color: Color(0xFFE9B44C), fontSize: 12, letterSpacing: 1.4, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(texte, style: const TextStyle(color: Color(0xFFF6EFE4), fontSize: 17, height: 1.35)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LigneJauges extends StatelessWidget {
  const _LigneJauges({required this.jauges, required this.concernees});

  final Jauges jauges;
  final Set<Jauge> concernees;

  static const _noms = {
    Jauge.peuple: 'Peuple',
    Jauge.armee: 'Armée',
    Jauge.caisses: 'Caisses',
    Jauge.presse: 'Presse',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          for (final j in Jauge.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  key: ValueKey('jauge_${j.name}'),
                  children: [
                    Text(
                      _noms[j]!,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: .6,
                        fontWeight: FontWeight.w700,
                        color: concernees.contains(j) ? const Color(0xFFE9B44C) : Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: jauges.valeur(j) / 100,
                        minHeight: concernees.contains(j) ? 9 : 6,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(
                          concernees.contains(j) ? const Color(0xFFE9B44C) : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
