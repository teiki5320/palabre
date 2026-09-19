import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/moteur/denouement.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/modeles.dart';
import 'package:president/moteur/partie.dart';
import 'package:president/moteur/tirage.dart';

/// Ce qu'un joueur voit vraiment des histoires en cent jours.
///
/// Les chaînes existent dans le paquet ; la question est de savoir combien
/// en croise un mandat, et combien il en voit finir. On le mesure en
/// jouant, pas en comptant les cartes.
///
///   flutter test outils/mesure_histoires.dart
void main() {
  test('ce que mille mandats voient des histoires', () async {
    Future<String> lis(String n) => File('assets/contenu/$n.json').readAsString();
    final contenu = Contenu.depuisChaines(
      cartes: await lis('cartes'),
      personnages: await lis('personnages'),
      parcours: await lis('parcours'),
      fins: await lis('fins'),
      exploits: await lis('exploits'),
      objets: await lis('objets'),
    );

    final chaines = <String, int>{}; // id de chaîne -> rang le plus haut
    for (final c in contenu.cartes) {
      final ch = c.chaine;
      if (ch == null) continue;
      chaines[ch.id] = max(chaines[ch.id] ?? 0, ch.rang);
    }

    const parties = 1000;
    final alea = Random(7);
    final depart = contenu.parcoursParId('general_parcours')!;

    var joursTotal = 0;
    var cartesTotal = 0;
    var maillonsTotal = 0;
    final commencees = <String, int>{};
    final finies = <String, int>{};
    final histoiresParPartie = <int>[];
    final finiesParPartie = <int>[];

    for (var p = 0; p < parties; p++) {
      var etat = EtatPartie(parcours: depart.id, nomJoueur: 'Awa', jauges: depart.depart);
      final vuesChaines = <String, int>{};
      var cartes = 0;
      while (true) {
        if (evalue(etat) != null) break;
        final carte = choisitCarte(paquet: contenu.cartes, etat: etat, alea: alea);
        if (carte == null) break;
        cartes++;
        final ch = carte.chaine;
        if (ch != null) {
          if (ch.rang > 1) maillonsTotal++;
          vuesChaines[ch.id] = max(vuesChaines[ch.id] ?? 0, ch.rang);
        }
        // Le joueur attentif de l'equilibrage : il vise le centre sur les
        // effets reels, et se trompe une fois sur quatre.
        int ecart(Reponse r) {
          final apres = etat.jauges.applique(
            effetsReels(effets: r.effets, style: etat.style, mandat: etat.mandat, atout: depart.atout),
          );
          return Jauge.values.fold(0, (s, j) => s + (apres.valeur(j) - 50).abs());
        }
        final cote = alea.nextInt(4) == 0
            ? (alea.nextBool() ? Cote.gauche : Cote.droite)
            : (ecart(carte.gauche) <= ecart(carte.droite) ? Cote.gauche : Cote.droite);
        etat = repond(etat: etat, carte: carte, cote: cote, atout: depart.atout);
      }
      joursTotal += etat.jour - 1;
      cartesTotal += cartes;
      var ici = 0;
      var iciFinies = 0;
      for (final e in vuesChaines.entries) {
        commencees[e.key] = (commencees[e.key] ?? 0) + 1;
        ici++;
        if (e.value >= (chaines[e.key] ?? 99)) {
          finies[e.key] = (finies[e.key] ?? 0) + 1;
          iciFinies++;
        }
      }
      histoiresParPartie.add(ici);
      finiesParPartie.add(iciFinies);
    }

    double moy(List<int> l) => l.fold(0, (a, b) => a + b) / l.length;

    // ignore: avoid_print
    print('''
MILLE MANDATS, JOUEUR ATTENTIF
  jours tenus en moyenne        : ${(joursTotal / parties).toStringAsFixed(1)}
  cartes vues en moyenne        : ${(cartesTotal / parties).toStringAsFixed(1)}
  suites d'histoire vues        : ${(maillonsTotal / parties).toStringAsFixed(1)} par mandat
  histoires entamees            : ${moy(histoiresParPartie).toStringAsFixed(1)} par mandat
  histoires menees a leur fin   : ${moy(finiesParPartie).toStringAsFixed(2)} par mandat
  mandats sans aucune histoire finie : ${finiesParPartie.where((x) => x == 0).length} sur $parties
  mandats avec au moins 3 finies     : ${finiesParPartie.where((x) => x >= 3).length} sur $parties
''');

    final jamaisFinies = chaines.keys.where((k) => (finies[k] ?? 0) == 0).toList()..sort();
    // ignore: avoid_print
    print('HISTOIRES QU AUCUN DES MILLE MANDATS N A VUES FINIR : ${jamaisFinies.length} sur ${chaines.length}');
    for (final k in jamaisFinies) {
      // ignore: avoid_print
      print('   $k  (entamee dans ${commencees[k] ?? 0} mandats sur $parties)');
    }

    expect(parties, 1000);
  });
}
