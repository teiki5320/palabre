// Combien de cartes un joueur voit vraiment, et lesquelles il ne voit jamais.
//
// `contenu_reel_test.dart` prouve qu'une carte *peut* sortir, en cumulant
// 600 parties sur dix parcours et quatre stratégies. Ce n'est pas la même
// question que celle-ci : combien de cartes un joueur ordinaire rencontre
// en un mandat, et quelle part du contenu écrit il ne verra jamais.
//
// Usage : flutter test outils/mesure_couverture.dart
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

const parties = 1000;
const parcoursOuverts = ['general_parcours', 'professeure', 'syndicaliste', 'femme_affaires'];

void main() {
  test('couverture du contenu sur mille mandats', () async {
    final contenu = Contenu.depuisChaines(
      cartes: File('assets/contenu/cartes.json').readAsStringSync(),
      personnages: File('assets/contenu/personnages.json').readAsStringSync(),
      parcours: File('assets/contenu/parcours.json').readAsStringSync(),
      fins: File('assets/contenu/fins.json').readAsStringSync(),
      exploits: File('assets/contenu/exploits.json').readAsStringSync(),
      objets: File('assets/contenu/objets.json').readAsStringSync(),
      adversaires: File('assets/contenu/adversaires.json').readAsStringSync(),
      chambre: File('assets/contenu/chambre.json').readAsStringSync(),
    );
    final alea = Random(7);
    final compte = <String, int>{for (final c in contenu.cartes) c.id: 0};
    final parMandat = <int>[];
    var joursTotal = 0;

    for (var p = 0; p < parties; p++) {
      final quel = parcoursOuverts[p % parcoursOuverts.length];
      final depart = contenu.parcoursParId(quel)!;
      final adv = contenu.adversaires;
      var etat = EtatPartie(
        parcours: quel,
        nomJoueur: 'Test',
        jauges: depart.depart,
        adversaire: adv.isEmpty ? null : adv[alea.nextInt(adv.length)].id,
      );
      var vues = 0;
      while (evalue(etat) == null) {
        final carte = choisitCarte(paquet: contenu.cartes, etat: etat, alea: alea);
        if (carte == null) break;
        compte[carte.id] = (compte[carte.id] ?? 0) + 1;
        vues++;
        // Une main moyenne : on suit la jauge la plus basse.
        final basse = [Jauge.peuple, Jauge.armee, Jauge.caisses, Jauge.presse]
            .reduce((a, b) => etat.jauges.valeur(a) <= etat.jauges.valeur(b) ? a : b);
        final g = effetsReels(
              effets: carte.gauche.effets, style: etat.style, mandat: etat.mandat,
              atout: depart.atout)[basse] ??
            0;
        final d = effetsReels(
              effets: carte.droite.effets, style: etat.style, mandat: etat.mandat,
              atout: depart.atout)[basse] ??
            0;
        etat = repond(
          etat: etat,
          carte: carte,
          cote: g >= d ? Cote.gauche : Cote.droite,
          atout: depart.atout,
          qui: contenu.personnageDe(carte, depart, epouse: etat.epouse),
        );
      }
      parMandat.add(vues);
      joursTotal += vues;
    }

    final jamais = compte.entries.where((e) => e.value == 0).map((e) => e.key).toList()..sort();
    final rares = compte.entries.where((e) => e.value > 0 && e.value <= 5).length;
    parMandat.sort();
    final tampon = StringBuffer()
      ..writeln('cartes;sorties')
      ..writeAll(
          (compte.entries.toList()..sort((a, b) => a.value.compareTo(b.value)))
              .map((e) => '${e.key};${e.value}'),
          '\n');
    Directory('sources/mesures').createSync(recursive: true);
    File('sources/mesures/couverture.csv').writeAsStringSync(tampon.toString());

    // ignore: avoid_print
    print('mandats            : $parties');
    // ignore: avoid_print
    print('jours moyens       : ${(joursTotal / parties).toStringAsFixed(1)}');
    // ignore: avoid_print
    print('mediane des jours  : ${parMandat[parMandat.length ~/ 2]}');
    // ignore: avoid_print
    print('cartes du paquet   : ${contenu.cartes.length}');
    // ignore: avoid_print
    print('jamais sorties     : ${jamais.length}');
    // ignore: avoid_print
    print('sorties 1 a 5 fois : $rares');
    // ignore: avoid_print
    print(jamais.take(40).join(', '));
  });
}
