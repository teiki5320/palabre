import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contenu/chargement.dart';
import '../moteur/jauges.dart';
import '../moteur/modeles.dart';
import '../moteur/progression.dart';
import 'session.dart';
import 'theme.dart';

const _or = Couleurs.or;
const _creme = Couleurs.cremeDoux;

/// L'écran de collection : les exploits gagnés et les fins découvertes,
/// dans un seul endroit, atteint depuis l'accueil. Ce qui n'est pas encore
/// acquis reste en silhouette, sans son titre : c'est ce qui donne envie de
/// le chercher, jamais de le révéler en douce.
class CollectionEcran extends ConsumerWidget {
  const CollectionEcran({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contenu = ref.watch(contenuProvider);
    final progression = ref.watch(progressionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Exploits et fins')),
      body: contenu.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Contenu illisible : $e')),
        data: (c) => progression.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Progression illisible : $e')),
          data: (p) => _Collection(contenu: c, progression: p),
        ),
      ),
    );
  }
}

class _Collection extends StatelessWidget {
  const _Collection({required this.contenu, required this.progression});

  final Contenu contenu;
  final Progression progression;

  @override
  Widget build(BuildContext context) {
    final exploitsObtenus = contenu.exploits.where((e) => progression.exploits.contains(e.id)).length;
    final finsDecouvertes = contenu.fins.where((f) => progression.finsDecouvertes.contains(f.id)).length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            children: [
              const _TitreSection('Exploits'),
              for (final exploit in contenu.exploits)
                _LigneExploit(exploit: exploit, obtenu: progression.exploits.contains(exploit.id)),
              const SizedBox(height: 22),
              const _TitreSection('Fins'),
              for (final fin in contenu.fins)
                _LigneFin(fin: fin, decouverte: progression.finsDecouvertes.contains(fin.id)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Text(
            '$exploitsObtenus exploit${exploitsObtenus > 1 ? 's' : ''} sur ${contenu.exploits.length} · '
            '$finsDecouvertes fin${finsDecouvertes > 1 ? 's' : ''} sur ${contenu.fins.length}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _TitreSection extends StatelessWidget {
  const _TitreSection(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      texte,
      style: const TextStyle(color: _or, letterSpacing: 1.2, fontWeight: FontWeight.w800, fontSize: 13),
    ),
  );
}

class _LigneExploit extends StatelessWidget {
  const _LigneExploit({required this.exploit, required this.obtenu});

  final Exploit exploit;
  final bool obtenu;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: obtenu ? 1 : 0.45,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Le titre ne s'affiche que quand l'exploit est acquis : le
            // laisser voir avant, même grisé, en dirait déjà trop.
            if (obtenu)
              Text(
                exploit.titre,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            if (obtenu) const SizedBox(height: 2),
            Text(exploit.description, style: const TextStyle(color: _creme, fontSize: 13, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

class _LigneFin extends StatelessWidget {
  const _LigneFin({required this.fin, required this.decouverte});

  final Fin fin;
  final bool decouverte;

  @override
  Widget build(BuildContext context) {
    // Une fin d'élection (sans jauge) reste « les urnes » ; les autres
    // pointent leur jauge fautive, jamais son chiffre.
    final indice = fin.jauge == null ? 'les urnes' : fin.jauge!.nom;
    return Opacity(
      opacity: decouverte ? 1 : 0.45,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          decouverte ? fin.titre : 'Fin inconnue · $indice',
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
