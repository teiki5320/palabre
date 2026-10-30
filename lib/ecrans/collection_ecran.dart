import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contenu/chargement.dart';
import '../moteur/jauges.dart';
import '../moteur/modeles.dart';
import '../moteur/palais.dart';
import '../moteur/progression.dart';
import 'session.dart';
import 'theme.dart';

const _or = Couleurs.or;
const _creme = Couleurs.cremeDoux;

/// L'écran de collection : les exploits gagnés, les fins découvertes et ce
/// qu'on a acheté au palais, dans un seul endroit, atteint depuis
/// l'accueil. Ce qui n'est pas encore acquis reste en silhouette, sans son
/// titre : c'est ce qui donne envie de le chercher, jamais de le révéler
/// en douce.
///
/// Les objets font exception et s'affichent en clair, achetés ou non : le
/// catalogue est déjà ouvert dans chaque pièce du palais, et le cacher ici
/// n'aurait protégé aucun secret. Ce qu'on ne savait pas, jusqu'ici, c'est
/// ce qu'on possède déjà — il fallait faire le tour des cinq pièces pour
/// le découvrir.
class CollectionEcran extends ConsumerWidget {
  const CollectionEcran({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contenu = ref.watch(contenuProvider);
    final progression = ref.watch(progressionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Exploits, fins et palais')),
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
    final objetsAcquis = contenu.objets.where((o) => progression.objets.contains(o.id)).length;

    return Cadre(
      enfant: Column(
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
                const SizedBox(height: 22),
                const _TitreSection('Le palais'),
                // Pièce par pièce, dans l'ordre où l'on s'y promène, et
                // du moins cher au plus cher dans chacune — le même ordre
                // que le tiroir, pour qu'on retrouve ce qu'on y a vu.
                for (final piece in Piece.values)
                  if (contenu.objetsDe(piece).isNotEmpty) ...[
                    _SousTitre(piece.nom),
                    for (final objet in contenu.objetsDe(piece))
                      _LigneObjet(objet: objet, acquis: progression.objets.contains(objet.id)),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Text(
              '$exploitsObtenus exploit${exploitsObtenus > 1 ? 's' : ''} sur ${contenu.exploits.length} · '
              '$finsDecouvertes fin${finsDecouvertes > 1 ? 's' : ''} sur ${contenu.fins.length} · '
              '$objetsAcquis objet${objetsAcquis > 1 ? 's' : ''} sur ${contenu.objets.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
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

class _SousTitre extends StatelessWidget {
  const _SousTitre(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          texte,
          style: const TextStyle(color: _creme, fontSize: 12, letterSpacing: 1.1),
        ),
      );
}

/// Une ligne du palais. Contrairement aux exploits et aux fins, le nom est
/// toujours lisible : le prix d'un objet qu'on n'a pas est ce qui donne
/// envie de revenir, et le cacher ne protégerait rien.
class _LigneObjet extends StatelessWidget {
  const _LigneObjet({required this.objet, required this.acquis});

  final Objet objet;
  final bool acquis;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: acquis ? 1 : 0.45,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                acquis ? Icons.check : Icons.remove,
                size: 14,
                color: acquis ? _or : _creme,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  objet.nom,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              Text(
                acquis ? 'au palais' : '${objet.prix} caisses',
                style: const TextStyle(color: _creme, fontSize: 12),
              ),
            ],
          ),
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
